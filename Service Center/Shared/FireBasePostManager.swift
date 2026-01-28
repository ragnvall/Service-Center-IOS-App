//
//  FireBaseManager.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/21/25.
//

// FirebaseManager.swift
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = FirebaseManager()
    
    // Firebase database and storage references
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // Published property that will notify SwiftUI views when posts change
    @Published var posts: [PostCardData] = []
    
    func updateUniqueTags(newTags: [String], completion: @escaping (Bool) -> Void) {
        let uniqueTagsRef = db.collection("metadata").document("uniqueTags")
        
        uniqueTagsRef.getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                if let existingTags = document.data()?["uniqueTags"] as? [String] {
                    let updatedUniqueTags = Array(Set(existingTags + newTags))
                    uniqueTagsRef.setData(["uniqueTags": updatedUniqueTags]) { error in
                        completion(error == nil)
                    }
                } else {
                    uniqueTagsRef.setData(["uniqueTags": newTags]) { error in
                        completion(error == nil)
                    }
                }
            }
            else {
                uniqueTagsRef.setData(["uniqueTags": newTags]) { error in
                    completion(error == nil)
                }
            }
        }
    }
    
    func fetchUniqueTags(completion: @escaping ([String]) -> Void) {
        db.collection("metadata").document("uniqueTags").getDocument { snapshot, error in
            if let data = snapshot?.data(), let tags = data["uniqueTags"] as? [String] {
                completion(tags)
            } else {
                print("Error fetching unique tags")
                completion([])
            }
        }
    }
    
    // New method to upload multiple images
    func uploadMultipleImages(_ images: [UIImage], completion: @escaping ([String]) -> Void) {
        var uploadedUrls: [String] = []
        let group = DispatchGroup()
        
        for image in images {
            group.enter()
            uploadImage(image) { imageUrl in
                if let url = imageUrl {
                    uploadedUrls.append(url)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedUrls)
        }
    }
    
    //MARK: Load Posts
    func loadPosts(currentUserId: String? = nil) {
        db.collection("posts")
                .order(by: "timestamp", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    guard let documents = snapshot?.documents else {
                        print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    // Create posts array without liked status first
                    let postsWithoutLikeStatus = documents.compactMap { document -> PostCardData? in
                        let data = document.data()
                        
                        // Get all image URLs if available (for multiple images)
                        let imageUrls = data["imageUrls"] as? [String] ?? []
                        
                        // Fetch jobRequests
                        let jobRequests = data["jobRequests"] as? [String] ?? []
                        
                        // Extract timestamp and convert to Date
                        let timestamp = data["timestamp"] as? Timestamp
                        let dateCreated = timestamp?.dateValue() ?? Date()
                        
                        return PostCardData(
                            documentId: document.documentID,
                            profile_img: data["profile_img"] as? String ?? "",
                            profile_name: data["profile_name"] as? String ?? "",
                            title: data["title"] as? String ?? "",
                            profile_id: data["profile_id"] as? String ?? "",
                            image: data["image"] as? String ?? "",
                            imageUrls: imageUrls,
                            like_count: data["like_count"] as? Int ?? 0,
                            comment_count: data["comment_count"] as? Int ?? 0,
                            view_count: data["view_count"] as? Int ?? 0,
                            description: data["description"] as? String ?? "",
                            price: data["price"] as? String ?? "",
                            timeUnit: data["timeUnit"] as? String ?? "Per Hour",
                            tags: data["tags"] as? [String] ?? [],
                            jobStatus: data["jobStatus"] as? String ?? "Open",
                            jobRequests: jobRequests,
                            acceptedRequest: data["acceptedRequest"] as? String,
                            locationLat: data["locationLat"] as? Double ?? 0.0,
                            locationLng: data["locationLng"] as? Double ?? 0.0,
                            neighborhood: data["neighborhood"] as? String ?? "",
                            city: data["city"] as? String ?? "",
                            dateCreated: dateCreated
                        )
                    }
                
                // Update the posts array
                self.posts = postsWithoutLikeStatus
                
                // If we have a current user ID, check liked status for each post
                if let currentUserId = currentUserId {
                    let userLikesRef = self.db.collection("userLikes").document(currentUserId)
                    
                    userLikesRef.getDocument { [weak self] (document, error) in
                        guard let self = self else { return }
                        
                        if let document = document, document.exists {
                            let likedPosts = document.data()?["likedPosts"] as? [String] ?? []
                            
                            // Update the liked status for each post
                            for index in 0..<self.posts.count {
                                let isLiked = likedPosts.contains(self.posts[index].documentId)
                                self.posts[index].isLikedByCurrentUser = isLiked
                            }
                            
                            // Notify observers that the posts have been updated with like status
                            self.objectWillChange.send()
                        } else if let error = error {
                            print("Error fetching user likes: \(error.localizedDescription)")
                        }
                    }
                }
            }
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("Failed to convert image to data")
            completion(nil)
            return
        }
        
        let imageName = "\(UUID().uuidString).jpg"
        let imageRef = storage.reference().child("posts/\(imageName)")
        
        // Add metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let url = url {
                    print("Successfully uploaded image with URL: \(url.absoluteString)")
                    completion(url.absoluteString)
                } else {
                    print("Failed to get download URL")
                    completion(nil)
                }
            }
        }
    }
    
    // Updated savePost method to include new fields
    func savePost(_ post: PostCardData) {
        // Create a dictionary with all the post data
        var postData: [String: Any] = [
            "profile_img": post.profile_img,
            "profile_name": post.profile_name,
            "title": post.title,
            "profile_id": post.profile_id,
            "image": post.image,
            "like_count": post.like_count,
            "comment_count": post.comment_count,
            "view_count": post.view_count,
            "description": post.description,
            "tags": post.tags,
            "jobStatus": post.jobStatus,
            "timestamp": FieldValue.serverTimestamp(),
            "locationLat": post.locationLat,
            "locationLng": post.locationLng,
            "neighborhood": post.neighborhood,
            "city": post.city
        ]
        
        // Add the new fields from the second image design
        if let price = post.price {
            postData["price"] = price
        }
        
        if let timeUnit = post.timeUnit {
            postData["timeUnit"] = timeUnit
        }
        
        // Add multiple image URLs if available
        if let imageUrls = post.imageUrls, !imageUrls.isEmpty {
            postData["imageUrls"] = imageUrls
        }
        
        db.collection("posts").addDocument(data: postData) { [weak self] error in
            if let error = error {
                print("Error saving post: \(error.localizedDescription)")
            } else {
                print("Post successfully saved")
                self?.loadPosts() // Reload posts after successful save
            }
        }
    }
    
    func getUserDetails(username: String, completion: @escaping (User?) -> Void) {
        // Reference to the "users" collection in Firestore
        db.collection("users")
            .whereField("username", isEqualTo: username) // Query users by username
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user details: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("No user found with username \(username)")
                    completion(nil)
                    return
                }
                
                // Extract user data from Firestore document
                let data = document.data()
                let user = User(
                    profile_pic: data["profile_pic"] as? String ?? "",
                    id: document.documentID, // Using document ID as user's unique ID
                    fullname: data["fullname"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    locationLat: data["locationLat"] as? Double ?? 0.0,
                    locationLng: data["locationLng"] as? Double ?? 0.0,
                    username: data["username"] as? String ?? "",
                    skills: data["skills"] as? [String] ?? []
                )
                
                completion(user)
            }
    }
    
    func updateJobStatus(forPostId postId: String, newJobStatus: String, completion: @escaping (Bool) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData(["jobStatus": newJobStatus]) { error in
            if let error = error {
                print("Error updating job status: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Job status updated successfully")
                completion(true)
            }
        }
    }
    
    func deletePost(postData: PostCardData, completion: @escaping (Bool) -> Void) {
        let postRef = db.collection("posts").document(postData.documentId)
        let username = postData.profile_id
        print("Attempting to delete post with ID: \(postData.documentId) for username: \(username)")

        // First, get the user document based on the username to get their user ID
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let userDoc = snapshot?.documents.first else {
                print("User not found for username: \(username)")
                completion(false)
                return
            }
            
            let userId = userDoc.documentID
            print("Found user with documentID: \(userId)")
            
            // Fetch the current postsCreated value for the user
            let userRef = self?.db.collection("users").document(userId)
            userRef?.getDocument { document, error in
                if let error = error {
                    print("Error fetching user document: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let document = document, document.exists else {
                    print("User document not found for id: \(userId)")
                    completion(false)
                    return
                }
                
                // If postsCreated doesn't exist, assume a default value of 0 and log a warning.
                var currentPostsCreated = document.data()?["postsCreated"] as? Int ?? 0
                if document.data()?["postsCreated"] == nil {
                    print("Warning: No postsCreated field found for user with id: \(userId). Assuming 0.")
                } else {
                    print("Current postsCreated: \(currentPostsCreated)")
                    currentPostsCreated = max(currentPostsCreated - 1, 0)
                    print("Updated postsCreated after decrement: \(currentPostsCreated)")
                }
                
                // Update the postsCreated field only if it existed
                if document.data()?["postsCreated"] != nil {
                    self?.updateUserPostsCreated(uid: userId, postsCreated: currentPostsCreated) { success in
                        if !success {
                            print("Failed to update postsCreated for user with id: \(userId)")
                            completion(false)
                            return
                        }
                        
                        // Now, delete the post after updating the user's postsCreated
                        postRef.delete { error in
                            if let error = error {
                                print("Error deleting post: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                print("Post successfully deleted.")
                                
                                // Remove the deleted post from the local posts array
                                self?.posts.removeAll { $0.documentId == postData.documentId }
                                
                                // Optionally, reload posts to ensure data is up-to-date
                                self?.loadPosts()
                                
                                completion(true)
                            }
                        }
                    }
                } else {
                    // If postsCreated field is missing, simply delete the post
                    postRef.delete { error in
                        if let error = error {
                            print("Error deleting post: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("Post successfully deleted (postsCreated field missing).")
                            self?.posts.removeAll { $0.documentId == postData.documentId }
                            self?.loadPosts()
                            completion(true)
                        }
                    }
                }
            }
        }
    }



    // WARNING: THIS IS A DEBUG FUNCTION
    func deleteAllPosts(completion: @escaping (Bool) -> Void) {
        let postsRef = db.collection("posts")
        
        // Fetch all posts
        postsRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Check if there are any documents to delete
            guard let documents = snapshot?.documents else {
                print("No posts found to delete.")
                completion(true)
                return
            }
            
            // Delete each post
            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                dispatchGroup.enter()
                postsRef.document(document.documentID).delete { deleteError in
                    if let deleteError = deleteError {
                        print("Error deleting post with ID \(document.documentID): \(deleteError.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            // Wait for all deletions to complete before calling completion
            dispatchGroup.notify(queue: .main) {
                // Clear the local posts array
                self?.posts.removeAll()
                self?.loadPosts() // Optionally reload the posts to refresh data
                completion(true)
            }
        }
    }

    
    func requestJob(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData([
            "jobRequests": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error requesting job: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Job request added successfully")
                completion(true)
            }
        }
    }
    
    func acceptJobRequest(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData([
            "acceptedRequest": userId,
            "jobStatus": "Accepted" // Automatically set the status to Accepted when a request is accepted
        ]) { error in
            if let error = error {
                print("Error accepting job request: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Job request accepted successfully")
                completion(true)
            }
        }
    }
    
    func rejectJobRequest(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData([
            "jobRequests": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                print("Error rejecting job request: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Job request rejected successfully")
                
                // If the rejected user is the accepted user, update the job status to "Open"
                postRef.updateData([
                    "jobStatus": "Open",
                    "acceptedRequest": FieldValue.delete()  // Remove the accepted user
                ]) { error in
                    if let error = error {
                        print("Error updating job status: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Job status updated to Open")
                        completion(true)
                    }
                }
            }
        }
    }
    
    func cancelJobRequest(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData([
            "jobRequests": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                print("Error canceling job request: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Job request canceled successfully")
                completion(true)
            }
        }
    }
    
    // This function queries firebase for any updates
    func refreshPosts(searchText: String, searchTags: [String], completion: @escaping ([PostCardData]) -> Void) {
        let query = db.collection("posts")
            .order(by: "timestamp", descending: true) // Ensure sorting by timestamp
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching updated posts: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }
            
            var updatedPosts = documents.compactMap { document -> PostCardData? in
                let data = document.data()
                let jobRequests = data["jobRequests"] as? [String] ?? []
                
                // Extract the timestamp and convert it to a Date
                let timestamp = data["timestamp"] as? Timestamp
                let dateCreated = timestamp?.dateValue() ?? Date()
                
                return PostCardData(
                    documentId: document.documentID,
                    profile_img: data["profile_img"] as? String ?? "",
                    profile_name: data["profile_name"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    profile_id: data["profile_id"] as? String ?? "",
                    image: data["image"] as? String ?? "",
                    like_count: data["like_count"] as? Int ?? 0,
                    comment_count: data["comment_count"] as? Int ?? 0,
                    view_count: data["view_count"] as? Int ?? 0,
                    description: data["description"] as? String ?? "",
                    tags: data["tags"] as? [String] ?? [],
                    jobStatus: data["jobStatus"] as? String ?? "Open",
                    jobRequests: jobRequests,
                    acceptedRequest: data["acceptedRequest"] as? String,
                    locationLat: data["locationLat"] as? Double ?? 0,
                    locationLng: data["locationLng"] as? Double ?? 0,
                    neighborhood: data["neighborhood"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    dateCreated: dateCreated  // Add the dateCreated field here
                )
            }
            
            // Filter based on search text and tags
            updatedPosts = updatedPosts.filter { post in
                [
                    searchText.isEmpty || post.title.localizedCaseInsensitiveContains(searchText),
                    searchTags.isEmpty || post.tags.contains { searchTags.contains($0) }
                ].reduce(true) { $0 && $1 }
            }
            
            // Return the updated posts (no overwrite, just check for changes)
            completion(updatedPosts)
        }
    }
    
    func updateUserPostsCreated(uid: String, postsCreated: Int, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(uid).updateData([
            "postsCreated": postsCreated
        ]) { error in
            if let error = error {
                print("Error updating postsCreated: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Function to increment or decrement reviewsCreated field for a user
    func updateReviewsCreated(uid: String, action: String, completion: @escaping (Bool) -> Void) {
        let userRef = db.collection("users").document(uid)
        
        // Fetch the current reviewsCreated value
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, document.exists,
                  var currentReviewsCreated = document.data()?["reviewsCreated"] as? Int else {
                print("No reviewsCreated field found for user")
                completion(false)
                return
            }
            
            // Modify the reviewsCreated value based on action (increment or decrement)
            if action == "increment" {
                currentReviewsCreated += 1
            } else if action == "decrement" {
                currentReviewsCreated -= 1
            } else {
                print("Invalid action. Please use 'increment' or 'decrement'.")
                completion(false)
                return
            }
            
            // Update the reviewsCreated field
            userRef.updateData([
                "reviewsCreated": currentReviewsCreated
            ]) { error in
                if let error = error {
                    print("Error updating reviewsCreated: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    func deleteReview(reviewId: String, completion: @escaping (Bool) -> Void) {
        let reviewRef = db.collection("reviews").document(reviewId)
        
        reviewRef.delete { error in
            if let error = error {
                print("Error deleting review: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Review successfully deleted.")
                completion(true)
            }
        }
    }

    // MARK: - Like Functionality
    
    // Method to toggle like status for a post
    func toggleLike(for postId: String, userId: String, completion: @escaping (Bool, Int) -> Void) {
        // Use a transaction to make this operation atomic
        let postRef = db.collection("posts").document(postId)
        let userLikesRef = db.collection("userLikes").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                // Get the latest post document first
                let postDocument = try transaction.getDocument(postRef)
                let currentLikeCount = postDocument.data()?["like_count"] as? Int ?? 0
                
                // Get the latest user likes document
                let userLikesDoc: DocumentSnapshot?
                do {
                    userLikesDoc = try transaction.getDocument(userLikesRef)
                } catch {
                    // Document doesn't exist yet
                    userLikesDoc = nil
                }
                
                let likedPosts = userLikesDoc?.exists == true ?
                                (userLikesDoc?.data()?["likedPosts"] as? [String] ?? []) : []
                let isCurrentlyLiked = likedPosts.contains(postId)
                
                // Calculate new like count based on actual current state
                let newLikeCount = isCurrentlyLiked ? max(0, currentLikeCount - 1) : currentLikeCount + 1
                
                // Update like count
                transaction.updateData(["like_count": newLikeCount], forDocument: postRef)
                
                // Update user likes
                if isCurrentlyLiked {
                    // Unlike
                    if userLikesDoc?.exists == true {
                        transaction.updateData(["likedPosts": FieldValue.arrayRemove([postId])], forDocument: userLikesRef)
                    }
                } else {
                    // Like
                    if userLikesDoc?.exists == true {
                        transaction.updateData(["likedPosts": FieldValue.arrayUnion([postId])], forDocument: userLikesRef)
                    } else {
                        transaction.setData(["likedPosts": [postId]], forDocument: userLikesRef)
                    }
                }
                
                return (newLikeCount, !isCurrentlyLiked)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { (result, error) in
            if let error = error {
                print("Error updating like: \(error)")
                completion(false, 0)
                return
            }
            
            guard let (newCount, _) = result as? (Int, Bool) else {
                completion(false, 0)
                return
            }
            
            completion(true, newCount)
        }
    }
        
    // Method to check if a user has liked a post
    func checkIfUserLikedPost(postId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let userLikesRef = db.collection("userLikes").document(userId)
        
        userLikesRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking user likes: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let document = document, document.exists {
                let likedPosts = document.data()?["likedPosts"] as? [String] ?? []
                let isLiked = likedPosts.contains(postId)
                
                // Update the local posts array to maintain consistency
                DispatchQueue.main.async { [weak self] in
                    if let index = self?.posts.firstIndex(where: { $0.documentId == postId }) {
                        self?.posts[index].isLikedByCurrentUser = isLiked
                    }
                }
                
                completion(isLiked)
            } else {
                completion(false)
            }
        }
    }
    func incrementViewCount(for postId: String, userId: String) {
        // Reference to the post document
        let postRef = db.collection("posts").document(postId)
        
        // Reference to track user views
        let userViewsRef = db.collection("userViews").document(userId)
        
        // Check if the user has already viewed this post
        userViewsRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking user views: \(error.localizedDescription)")
                return
            }
            
            let viewedPosts: [String]
            if let document = document, document.exists {
                viewedPosts = document.data()?["viewedPosts"] as? [String] ?? []
            } else {
                viewedPosts = []
            }
            
            // If user hasn't viewed this post yet
            if !viewedPosts.contains(postId) {
                // Run a transaction to safely update the view count
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    do {
                        // Get the current post document
                        let postDocument = try transaction.getDocument(postRef)
                        let currentViewCount = postDocument.data()?["view_count"] as? Int ?? 0
                        
                        // Increment the view count
                        transaction.updateData(["view_count": currentViewCount + 1], forDocument: postRef)
                        
                        // Add the post to the user's viewed posts
                        if document?.exists == true {
                            transaction.updateData(["viewedPosts": FieldValue.arrayUnion([postId])], forDocument: userViewsRef)
                        } else {
                            transaction.setData(["viewedPosts": [postId]], forDocument: userViewsRef)
                        }
                        
                        return currentViewCount + 1
                    } catch let error as NSError {
                        errorPointer?.pointee = error
                        return nil
                    }
                }) { (result, error) in
                    if let error = error {
                        print("Error incrementing view count: \(error.localizedDescription)")
                    }
                    
                    // No UI update here since we want it to show after page refresh
                    print("View count updated successfully")
                }
            } else {
                print("User has already viewed this post")
            }
        }
    }
}
