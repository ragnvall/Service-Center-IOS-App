import SwiftUI
import Foundation
import PhotosUI
import FirebaseFirestore

// A helper struct to hold selected images.
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ChatView: View {
    @ObservedObject var messagesViewModel: MessagesViewModel
    
    let otherUserId: String
    let otherUsername: String
    let otherProfileImageUrl: String?
    
    // Keep the username passed in so we don't display "Loading..."
    @State private var fetchedUsername: String
    @State private var fetchedProfileImageUrl: String = ""
    
    // Navigation state for profile view
    @State private var isProfileViewPresented = false
    @State private var destination: AnyView? = nil
    
    // State for the input bar
    @State private var messageText = ""
    @State private var selectedImages: [IdentifiableImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    
    init(messagesViewModel: MessagesViewModel,
         otherUserId: String,
         otherUsername: String,
         otherProfileImageUrl: String?) {
        self.messagesViewModel = messagesViewModel
        self.otherUserId = otherUserId
        self.otherUsername = otherUsername
        self.otherProfileImageUrl = otherProfileImageUrl
        
        // Initialize fetchedUsername with the passed-in username.
        _fetchedUsername = State(initialValue: otherUsername)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header as a button
            Button(action: {
                navigateToProfile()
            }) {
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        // Profile image code
                        if !fetchedProfileImageUrl.isEmpty, let url = URL(string: fetchedProfileImageUrl) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    defaultProfileImage
                                }
                            }
                        } else {
                            defaultProfileImage
                        }
                        // Username text
                        Text(fetchedUsername)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.top, 16)      // Regular padding to keep it from the very top
                .padding(.bottom, -20)    // Minimal bottom padding
                .offset(y: -50)         // Moves the header up by 50 points
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.vertical, 2) // Reduced from 4 to 2
            
            // Hidden NavigationLink triggered when isProfileViewPresented becomes true.
            NavigationLink(destination: destination, isActive: $isProfileViewPresented) {
                EmptyView()
            }
            
            .hidden()
            
            // MARK: - Messages List
            if messagesViewModel.messages.isEmpty {
                Spacer()
                Text("No messages yet.")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messagesViewModel.messages, id: \.id) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == messagesViewModel.currentUserId
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // MARK: - Selected Images Preview
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedImages) { identifiableImage in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: identifiableImage.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                    .transition(.slide)
                                
                                Button(action: {
                                    withAnimation {
                                        if let index = selectedImages.firstIndex(where: { $0.id == identifiableImage.id }) {
                                            selectedImages.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // MARK: - Input Bar
            HStack {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(messageText.isEmpty && selectedImages.isEmpty)
            }
            .padding(.horizontal)
        }
        .onAppear {
            messagesViewModel.observeChatMessages(for: otherUserId)
            messagesViewModel.fetchUsername(for: otherUserId)
            fetchOtherUserDetails()
        }
        .photosPicker(isPresented: $showingImagePicker,
                      selection: $selectedItems,
                      maxSelectionCount: 5,
                      matching: .images)
        .onChange(of: selectedItems) { newItems in
            for newItem in newItems {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            selectedImages.append(IdentifiableImage(image: uiImage))
                        }
                    }
                }
            }
            selectedItems = []
        }
    }
    
    // A default profile image view for when no profile photo is available.
    private var defaultProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 60)
            .foregroundColor(.gray)
    }
    
    // MARK: - Fetch Other User Details from Firestore
    private func fetchOtherUserDetails() {
        Firestore.firestore()
            .collection("users")
            .document(otherUserId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user details: \(error.localizedDescription)")
                    return
                }
                guard let data = snapshot?.data() else {
                    print("No user data found for id \(otherUserId)")
                    return
                }
                if let firestoreUsername = data["username"] as? String, !firestoreUsername.isEmpty {
                    DispatchQueue.main.async {
                        fetchedUsername = firestoreUsername
                    }
                }
                if let profilePic = data["profile_pic"] as? String, !profilePic.isEmpty {
                    DispatchQueue.main.async {
                        fetchedProfileImageUrl = profilePic
                    }
                }
            }
    }
    
    // MARK: - Navigation to Profile
    private func navigateToProfile() {
        AuthManager.shared.fetchUserById(otherUserId) { fetchedUser in
            guard let user = fetchedUser else {
                print("No user found for id \(otherUserId)")
                return
            }
            
            destination = AnyView(OtherUserProfileView(db: Firestore.firestore(), user: user))
            isProfileViewPresented = true
        }
    }

    
    // MARK: - Sending Messages
    private func sendMessage() {
        if !selectedImages.isEmpty {
            uploadImagesSequentially()
        }
        if !messageText.isEmpty {
            FirebaseMessage.shared.sendChatMessage(
                to: otherUserId,
                from: messagesViewModel.currentUserId,
                text: messageText
            )
            messageText = ""
        }
    }
    
    private func uploadImagesSequentially() {
        guard !selectedImages.isEmpty else { return }
        let currentImage = selectedImages.first!
        
        func attemptUpload() {
            messagesViewModel.uploadImageAndSend(to: otherUserId, image: currentImage.image) { success in
                if success {
                    withAnimation {
                        selectedImages.removeFirst()
                    }
                    uploadImagesSequentially()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        attemptUpload()
                    }
                }
            }
        }
        attemptUpload()
    }
}

// MARK: - Simple MessageBubble
struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            VStack(alignment: .leading) {
                if let imageUrl = message.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 250)
                                .cornerRadius(12)
                        } else if phase.error != nil {
                            EmptyView()
                        } else {
                            ProgressView()
                        }
                    }
                }
                if !message.messageText.isEmpty {
                    Text(message.messageText)
                        .padding()
                        .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(10)
                }
            }
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal)
    }
}
