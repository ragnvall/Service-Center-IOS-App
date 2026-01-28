import FirebaseFirestore

class FirebaseSavePosts {
    static let shared = FirebaseSavePosts()
    private let db = Firestore.firestore()

    private init() {}

    private func getUserDocumentId(forUsername username: String, completion: @escaping (String?) -> Void) {
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                guard let document = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                completion(document.documentID)
            }
    }

    func savePost(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        getUserDocumentId(forUsername: userId) { documentId in
            guard let userDocId = documentId else {
                completion(false)
                return
            }

            let savedPostData: [String: Any] = [
                "postId": postId,
                "savedAt": FieldValue.serverTimestamp()
            ]

            self.db.collection("users").document(userDocId)
                .collection("savedPosts").document(postId)
                .setData(savedPostData) { error in
                    completion(error == nil)
                }
        }
    }

    func unsavePost(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        getUserDocumentId(forUsername: userId) { documentId in
            guard let userDocId = documentId else {
                completion(false)
                return
            }

            self.db.collection("users").document(userDocId)
                .collection("savedPosts").document(postId)
                .delete { error in
                    completion(error == nil)
                }
        }
    }

    func isPostSaved(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        getUserDocumentId(forUsername: userId) { documentId in
            guard let userDocId = documentId else {
                completion(false)
                return
            }

            self.db.collection("users").document(userDocId)
                .collection("savedPosts").document(postId)
                .getDocument { snapshot, error in
                    completion(snapshot?.exists ?? false)
                }
        }
    }

    func getSavedPostIds(userId: String, completion: @escaping ([String]) -> Void) {
        getUserDocumentId(forUsername: userId) { userDocId in
            if userDocId == nil {
                completion([])
                return
            }
            
            self.fetchSavedPostIds(userDocId: userDocId!, completion: completion)
        }
    }
    
    private func fetchSavedPostIds(userDocId: String, completion: @escaping ([String]) -> Void) {
        self.db.collection("users").document(userDocId)
            .collection("savedPosts")
            .order(by: "savedAt", descending: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    completion([])
                    return
                }

                var postIds: [String] = []
                for document in documents {
                    if let postId = document.data()["postId"] as? String {
                        postIds.append(postId)
                    }
                }

                completion(postIds)
            }
    }
    
    func getSavedPosts(userId: String, completion: @escaping ([PostCardData]) -> Void) {
        // First get the user document ID
        getUserDocumentId(forUsername: userId) { userDocId in
            if userDocId == nil {
                completion([])
                return
            }
            
            // Then get the saved post IDs
            self.fetchSavedPostIds(userDocId: userDocId!) { postIds in
                if postIds.isEmpty {
                    completion([])
                    return
                }
                
                // Then fetch each post
                self.fetchPostsFromIds(postIds: postIds, completion: completion)
            }
        }
    }
    
    private func fetchPostsFromIds(postIds: [String], completion: @escaping ([PostCardData]) -> Void) {
        var posts: [PostCardData] = []
        let group = DispatchGroup()
        let dbRef = self.db // Store reference to avoid capturing self
        
        for postId in postIds {
            group.enter()
            
            // Move the getDocument call to a separate method to reduce nesting
            fetchSinglePost(dbRef: dbRef, postId: postId) { post in
                if let post = post {
                    posts.append(post)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Sort by the same order as the IDs were retrieved (by savedAt timestamp)
            let sortedPosts = self.sortPostsInOrder(posts: posts, postIds: postIds)
            completion(sortedPosts)
        }
    }
    
    private func sortPostsInOrder(posts: [PostCardData], postIds: [String]) -> [PostCardData] {
        var result: [PostCardData] = []
        
        for postId in postIds {
            if let post = posts.first(where: { $0.documentId == postId }) {
                result.append(post)
            }
        }
        
        return result
    }

    private func fetchSinglePost(dbRef: Firestore, postId: String, completion: @escaping (PostCardData?) -> Void) {
        dbRef.collection("posts").document(postId).getDocument { snapshot, error in
            guard let document = snapshot, document.exists, let data = document.data() else {
                // Skip this post if it doesn't exist
                completion(nil)
                return
            }
            
            // Extract the timestamp and convert it to a Date
            let timestamp = data["timestamp"] as? Timestamp
            let dateCreated = timestamp?.dateValue() ?? Date()
            
            // Extract all needed fields with safe unwrapping
            let documentId = document.documentID
            let profileImg = data["profile_img"] as? String ?? ""
            let profileName = data["profile_name"] as? String ?? ""
            let title = data["title"] as? String ?? ""
            let profileId = data["profile_id"] as? String ?? ""
            let image = data["image"] as? String ?? ""
            let likeCount = data["like_count"] as? Int ?? 0
            let commentCount = data["comment_count"] as? Int ?? 0
            let viewCount = data["view_count"] as? Int ?? 0
            let description = data["description"] as? String ?? ""
            let tags = data["tags"] as? [String] ?? []
            let jobStatus = data["jobStatus"] as? String ?? "Open"
            let jobRequests = data["jobRequests"] as? [String] ?? []
            let acceptedRequest = data["acceptedRequest"] as? String
            let locationLat = data["locationLat"] as? Double ?? 0.0
            let locationLng = data["locationLng"] as? Double ?? 0.0
            let neighborhood = data["neighborhood"] as? String ?? ""
            let city = data["city"] as? String ?? ""
            let price = data["price"] as? String
            
            // Create the post object
            let post = PostCardData(
                documentId: documentId,
                profile_img: profileImg,
                profile_name: profileName,
                title: title,
                profile_id: profileId,
                image: image,
                like_count: likeCount,
                comment_count: commentCount,
                view_count: viewCount,
                description: description,
                price: price,
                tags: tags,
                jobStatus: jobStatus,
                jobRequests: jobRequests,
                acceptedRequest: acceptedRequest,
                locationLat: locationLat,
                locationLng: locationLng,
                neighborhood: neighborhood,
                city: city,
                dateCreated: dateCreated
            )
            
            completion(post)
        }
    }
}
