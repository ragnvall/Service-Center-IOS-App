import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    private let db = Firestore.firestore()
    
    func observeComments(for postId: String) {
        self.db.collection("posts").document(postId).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else {
                    print("Error fetching comments: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.comments = documents.compactMap { doc in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    do {
                        return try Firestore.Decoder().decode(Comment.self, from: data)
                    } catch {
                        print("Error decoding comment: \(error)")
                        return nil
                    }
                }
            }
    }
    
    func sendComment(for postId: String,
                     text: String,
                     parentCommentId: String? = nil,
                     completion: @escaping (Bool) -> Void) {
        guard let currentUser = AuthManager.shared.currentUser else {
            completion(false)
            return
        }
        let username = currentUser.username.isEmpty ? "Anonymous" : currentUser.username
        var commentData: [String: Any] = [
            "postId": postId,
            "userId": currentUser.id,
            "username": username,
            "text": text,
            "timestamp": Timestamp()
        ]
        if let parentId = parentCommentId {
            commentData["parentCommentId"] = parentId
        }
        
        let postRef = db.collection("posts").document(postId)
        postRef.collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error sending comment: \(error.localizedDescription)")
                completion(false)
            } else {
                // Only increment comment_count for top-level comments
                let incrementValue: Int64 = (parentCommentId == nil) ? 1 : 0
                postRef.updateData([
                    "comment_count": FieldValue.increment(incrementValue)
                ]) { err in
                    if let err = err {
                        print("Error incrementing comment_count: \(err.localizedDescription)")
                    }
                    completion(true)
                }
            }
        }
    }

    
    func deleteComment(_ comment: Comment, completion: @escaping (Bool) -> Void) {
        guard let postId = comment.postId else {
            completion(false)
            return
        }
        
        let postRef = db.collection("posts").document(postId)
        let commentsRef = postRef.collection("comments")
        
        // If the comment is top-level (no parent), delete all its replies as well.
        if comment.parentCommentId == nil {
            commentsRef.whereField("parentCommentId", isEqualTo: comment.id).getDocuments { snapshot, error in
                if let error = error {
                    print("Error querying replies: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let batch = self.db.batch()
                // Delete each reply in the batch.
                snapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                // Delete the main comment.
                let commentRef = commentsRef.document(comment.id)
                batch.deleteDocument(commentRef)
                
                batch.commit { batchError in
                    if let batchError = batchError {
                        print("Error committing batch delete: \(batchError.localizedDescription)")
                        completion(false)
                    } else {
                        // Only decrement comment_count by 1 since only top-level comments are counted.
                        postRef.updateData([
                            "comment_count": FieldValue.increment(Int64(-1))
                        ]) { err in
                            if let err = err {
                                print("Error decrementing comment_count: \(err.localizedDescription)")
                            }
                            completion(true)
                        }
                    }
                }
            }
        } else {
            // For a reply, delete it directly.
            let commentRef = commentsRef.document(comment.id)
            commentRef.delete { error in
                if let error = error {
                    print("Error deleting reply: \(error.localizedDescription)")
                    completion(false)
                } else {
                    // No change to comment_count for replies.
                    completion(true)
                }
            }
        }
    }

}
