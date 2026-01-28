import FirebaseFirestore
import FirebaseAuth

class FirebaseMessage {
    static let shared = FirebaseMessage()
    private let db = Firestore.firestore()
    
    func sendChatMessage(to receiverId: String, from senderId: String, text: String) {
        let chatId = [senderId, receiverId].sorted().joined(separator: "_")
        print("📤 FirebaseMessage sendMessage called")
        
        // Add to messages subcollection
        let messageRef = db.collection("chats").document(chatId).collection("messages").document()
        let messageData: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "messageText": text,
            "timestamp": Timestamp()
        ]
        
        // Update chat preview
        let previewData: [String: Any] = [
            "id": receiverId,
            "senderId": senderId,
            "receiverId": receiverId,
            "lastMessage": text,
            "timestamp": Timestamp(),
            "hasUnreadMessage": true,
            "username": AuthManager.shared.currentUser?.username ?? ""
        ]
        
        // Batch write to ensure both operations complete
        let batch = db.batch()
        batch.setData(messageData, forDocument: messageRef)
        batch.setData(previewData, forDocument: db.collection("chats").document(chatId))
        
        batch.commit { error in
            if let error = error {
                print("❌ Error saving message: \(error.localizedDescription)")
            } else {
                print("✅ Message saved successfully")
            }
        }
    }
    
    func observeChatPreviews(for userId: String, completion: @escaping ([MessageUser]) -> Void) {
        db.collection("chats")
            .whereFilter(Filter.orFilter([
                Filter.whereField("senderId", isEqualTo: userId),
                Filter.whereField("receiverId", isEqualTo: userId)
            ]))
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching chat previews: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let previews = documents.compactMap { document -> MessageUser? in
                    do {
                        var preview = try document.data(as: MessageUser.self)
                        preview.id = document.documentID
                        return preview
                    } catch {
                        print("❌ Error decoding preview: \(error)")
                        return nil
                    }
                }
                
                completion(previews)
            }
    }
    
    func observeChatMessages(for chatId: String, completion: @escaping ([ChatMessage]) -> Void) {
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }

                let messages = documents.compactMap { document -> ChatMessage? in
                    var data = document.data()
                    data["id"] = document.documentID
                    return try? Firestore.Decoder().decode(ChatMessage.self, from: data)
                }

                completion(messages)
            }
    }

    func getAllUsernames(completion: @escaping ([(id: String, username: String)]) -> Void) {
        db.collection("users")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching users: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let users = documents.compactMap { document -> (id: String, username: String)? in
                    guard let username = document.data()["username"] as? String else {
                        return nil
                    }
                    return (id: document.documentID, username: username)
                }
                
                completion(users)
            }
    }
}
