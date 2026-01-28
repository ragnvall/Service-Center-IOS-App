import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class MessagesViewModel: ObservableObject {
    @Published var chatPreviews: [MessageUser] = []  // For chat list
    @Published var messages: [ChatMessage] = []      // For individual chat messages
    @Published var filteredChatPreviews: [MessageUser] = []
    @Published var searchText: String = ""
    @Published var unreadRequestsCount: Int = 0
    @Published var currentUserId: String = ""
    @Published var currentUsername: String = ""
    @Published var error: String? = nil
    @Published var usernames: [String: String] = [:]
    
    private var searchDebouncer: AnyCancellable?
    private let firebaseMessage = FirebaseMessage.shared
    private let authManager = AuthManager.shared
    
    init() {
        print("🔄 MessagesViewModel init started")
        print("👤 AuthManager.shared.currentUser: \(String(describing: authManager.currentUser))")
        
        if authManager.isLoading {
            print("⏳ AuthManager is still loading...")
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if !self.authManager.isLoading {
                    print("✅ AuthManager finished loading")
                    self.setupWithCurrentUser()
                    timer.invalidate()
                }
            }
        } else {
            print("🔄 Setting up with current user immediately")
            setupWithCurrentUser()
            searchDebouncer = $searchText
                        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                        .sink { [weak self] _ in
                            self?.objectWillChange.send()
                        }
        }
    }
    
    func fetchUsername(for userId: String) {
        // Check cache first
        if usernames[userId] != nil { return }
        
        Task { [weak self] in
            do {
                let usersRef = Firestore.firestore().collection("users")
                let userDoc = try await usersRef.document(userId).getDocument()
                
                if let userData = userDoc.data(),
                   let username = userData["username"] as? String {
                    await MainActor.run {
                        self?.usernames[userId] = username
                    }
                }
            } catch {
                print("❌ Error fetching username for \(userId): \(error)")
            }
        }
    }
    
    private func setupWithCurrentUser() {
        if let currentUser = authManager.currentUser {
            print("✅ Current user found: \(currentUser.id)")
            self.currentUserId = currentUser.id
            self.currentUsername = currentUser.username
            observeChatPreviews(for: currentUser.id)
        } else {
            print("⚠️ No current user found in AuthManager")
            self.error = "No current user found"
        }
    }
    
    private func filterChatPreviews() {
        print("🔍 Filtering chat previews with search text: \(searchText)")
        if searchText.isEmpty {
            filteredChatPreviews = chatPreviews
        } else {
            filteredChatPreviews = chatPreviews.filter { preview in
                preview.username.lowercased().contains(searchText.lowercased()) ||
                preview.lastMessage.lowercased().contains(searchText.lowercased())
            }
        }
        print("✅ Found \(filteredChatPreviews.count) chat previews after filtering")
    }
    
    var filteredChatPreviewsHomeView: [MessageUser] {
        if searchText.isEmpty {
            return Array(chatPreviews.prefix(10)) // Show only the latest 10 users
        } else {
            return chatPreviews.filter { message in
                let otherUsername = usernames[message.senderId == currentUserId ? message.receiverId : message.senderId] ?? ""
                return otherUsername.lowercased().contains(searchText.lowercased())
            }
        }
    }

    // For chat list
    private func observeChatPreviews(for userId: String) {
        print("👀 Starting to observe chat previews for userId: \(userId)")
        guard !userId.isEmpty else {
            print("⚠️ Cannot observe chat previews: Invalid user ID")
            self.error = "Cannot observe chat previews: Invalid user ID"
            return
        }

        firebaseMessage.observeChatPreviews(for: userId) { [weak self] previews in
            print("📨 Received \(previews.count) chat previews from Firebase")
            DispatchQueue.main.async {
                let sortedPreviews = previews.sorted {
                    $0.timestamp > $1.timestamp
                }
                self?.chatPreviews = Array(sortedPreviews.prefix(10)) // Take only the 10 most recent users
                print("✅ Updated chat previews array with \(sortedPreviews.prefix(10).count) previews")
                self?.filterChatPreviews()
            }
        }
    }

    
    // For individual chat messages
    func observeChatMessages(for otherUserId: String) {
        print("👀 Starting to observe chat messages with userId: \(otherUserId)")
        guard !otherUserId.isEmpty, !currentUserId.isEmpty else {
            print("⚠️ Cannot observe chat messages: Invalid user IDs")
            return
        }
        
        // Fetch username for the other user
        fetchUsername(for: otherUserId)
        
        let chatId = [currentUserId, otherUserId].sorted().joined(separator: "_")
        firebaseMessage.observeChatMessages(for: chatId) { [weak self] messages in
            print("📨 Received \(messages.count) chat messages from Firebase")
            DispatchQueue.main.async {
                self?.messages = messages.sorted {
                    $0.timestamp < $1.timestamp
                }
                print("✅ Updated chat messages array with \(messages.count) messages")
            }
        }
    }

}

extension MessagesViewModel {
    func sendMessage(to userId: String, text: String, imageUrl: String? = nil) {
        let chatId = [currentUserId, userId].sorted().joined(separator: "_")
        guard !chatId.isEmpty else {
            print("Error: chatId is empty. Cannot create Firestore document.")
            return
        }
        let messageRef = Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .document()
        
        let messageData: [String: Any] = [
            "senderId": currentUserId,
            "receiverId": userId,
            "messageText": text,
            "timestamp": Timestamp(),
            "imageUrl": imageUrl ?? ""
        ]
        
        // For chat preview updates.
        let previewData: [String: Any] = [
            "id": userId,
            "senderId": currentUserId,
            "receiverId": userId,
            // If there's no text, show a placeholder like "Image".
            "lastMessage": text.isEmpty ? "Image" : text,
            "timestamp": Timestamp(),
            "hasUnreadMessage": true,
            "username": currentUsername
        ]
        
        let batch = Firestore.firestore().batch()
        batch.setData(messageData, forDocument: messageRef)
        batch.setData(previewData, forDocument: Firestore.firestore().collection("chats").document(chatId))
        
        batch.commit { error in
            if let error = error {
                print("❌ Error saving message: \(error.localizedDescription)")
            } else {
                print("✅ Message saved successfully")
            }
        }
    }
    
    func uploadImageAndSend(to userId: String, image: UIImage, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("❌ Error: Could not convert image to JPEG")
            completion(false)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let uniqueId = UUID().uuidString
        let imageRef = storageRef.child("chat_images/\(uniqueId).jpg")
        print("🔄 [Upload] Starting upload for image with uniqueId: \(uniqueId)")
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("❌ [Upload] Error uploading image with uniqueId \(uniqueId): \(error.localizedDescription)")
                completion(false)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ [Upload] Error getting download URL for image with uniqueId \(uniqueId): \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let imageUrl = url?.absoluteString {
                    print("✅ [Upload] Image uploaded successfully with URL: \(imageUrl)")
                    self.sendMessage(to: userId, text: "", imageUrl: imageUrl)
                    completion(true)
                } else {
                    print("❌ [Upload] Failed: URL is nil for image with uniqueId \(uniqueId)")
                    completion(false)
                }
            }
        }
    }
}

extension MessagesViewModel {
    func deleteConversation(conversationId: String) {
        let conversationRef = Firestore.firestore().collection("chats").document(conversationId)
        conversationRef.delete { error in
            if let error = error {
                print("❌ Error deleting conversation: \(error.localizedDescription)")
            } else {
                print("✅ Conversation deleted successfully")
                DispatchQueue.main.async {
                    self.chatPreviews.removeAll { $0.id == conversationId }
                }
            }
        }
    }
}
