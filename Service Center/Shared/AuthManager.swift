import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - AuthManager
/// A singleton class that manages authentication state and user data throughout the app
/// This manager provides centralized access to user authentication status and data
final class AuthManager: ObservableObject {
    // MARK: - Singleton Setup
    /// Shared instance that should be used throughout the app
    /// Usage: let authManager = AuthManager.shared
    static let shared = AuthManager()
    
    // MARK: - Published Properties
    /// The current user's data. Will be updated automatically when auth state changes
    /// Observable by SwiftUI views using @StateObject
    @Published public var currentUser: User?
    
    /// Indicates if a user is currently logged in
    /// True if user is authenticated, false otherwise
    @Published private(set) var isAuthenticated: Bool = false
    
    /// Indicates if the manager is currently loading user data
    /// Used to show loading states in the UI
    @Published private(set) var isLoading: Bool = true
    
    /// Stores any error messages that occur during authentication operations
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    /// Firebase Authentication instance
    private let auth = Auth.auth()
    
    /// Firebase Firestore database instance
    private let db = Firestore.firestore()
    
    /// Handler for Firebase authentication state changes
    /// Stored so we can remove the listener when needed
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    /// Private initializer to enforce singleton pattern
    /// Sets up authentication state monitoring
    private init() {
        setupAuthStateHandler()
    }
    
    // MARK: - Auth State Handling
    /// Sets up a listener for authentication state changes
    /// This method is called automatically when the manager is initialized
    private func setupAuthStateHandler() {
        // Add a listener that will be called whenever the auth state changes
        authStateHandler = auth.addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            // If we have a user, they're authenticated
            if let user = user {
                self.isAuthenticated = true
                self.fetchUserData(for: user.uid)
            } else {
                // No user - clear all authentication state
                self.isAuthenticated = false
                self.currentUser = nil
                self.isLoading = false
            }
        }
    }
    
    // MARK: - User Data Management
    /// Fetches user data from Firestore for a given user ID
    /// - Parameter uid: The Firebase user ID to fetch data for
    private func fetchUserData(for uid: String) {
        self.isLoading = true
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard var data = snapshot?.data() else {
                    self.errorMessage = "No user data found"
                    self.isLoading = false
                    return
                }
                
                // Check for required fields. For example, if "uid" is missing or empty, add it.
                if let fetchedUID = data["uid"] as? String, fetchedUID.isEmpty {
                    data["uid"] = uid
                } else if data["uid"] == nil {
                    data["uid"] = uid
                }
                
                // Check other fields as needed. For instance, if you expect a profile_pic and it's missing:
                if data["profile_pic"] == nil {
                    data["profile_pic"] = "" // or a default URL string
                }
                
                // You could also check fields like "postsCreated" and "reviewsCreated"
                if data["postsCreated"] == nil {
                    data["postsCreated"] = 0
                }
                if data["reviewsCreated"] == nil {
                    data["reviewsCreated"] = 0
                }
                
                // Optionally, update the Firestore doc with these defaults so next time the data is complete:
                self.db.collection("users").document(uid).updateData(data) { updateError in
                    if let updateError = updateError {
                        print("Error updating user defaults: \(updateError.localizedDescription)")
                    }
                }
                
                // Create your User object using the updated dictionary.
                self.currentUser = User(
                    profile_pic: data["profile_pic"] as? String ?? "",
                    id: data["uid"] as? String ?? "", // now should be non-empty
                    fullname: data["fullname"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    locationLat: data["locationLat"] as? Double ?? 0.0,
                    locationLng: data["locationLng"] as? Double ?? 0.0,
                    username: data["username"] as? String ?? "",
                    skills: data["skills"] as? [String] ?? [],
                    ratings: data["ratings"] as? [Rating] ?? [],
                    postsCreated: data["postsCreated"] as? Int ?? 0,
                    reviewsCreated: data["reviewsCreated"] as? Int ?? 0
                )
                
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Public Methods
    /// Returns the current user synchronously from memory
    /// - Returns: The current user object if available, nil otherwise
    /// This method is fast but may not have the most up-to-date data
    /// Use when you need quick access to user data and freshness isn't critical
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    /// Fetches the latest user data from Firebase
    /// - Returns: The updated user object
    /// - Throws: AuthError if user is not authenticated or data cannot be fetched
    /// This method makes a network call and should be used when you need the most current data
    func refreshCurrentUser() async throws -> User {
        // Ensure we have a logged in user
        guard let uid = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        // Use continuation to wrap the Firebase callback-based API
        // This allows us to use async/await syntax with Firebase
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("users").document(uid).getDocument { snapshot, error in
                // If we got an error, pass it to the continuation
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Ensure we have data
                guard let data = snapshot?.data() else {
                    continuation.resume(throwing: AuthError.noUserData)
                    return
                }
                
                // Create and return the user object
                let user = User(
                    profile_pic: data["profile_pic"] as? String ?? "",
                    id: data["uid"] as? String ?? "",
                    fullname: data["fullname"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    locationLat: data["locationLat"] as? Double ?? 0.0,
                    locationLng: data["locationLng"] as? Double ?? 0.0,
                    username: data["username"] as? String ?? "",
                    skills: data["skills"] as? [String] ?? [],
                    ratings: data["ratings"] as? [Rating] ?? [],
                    postsCreated: data["postsCreated"] as? Int ?? 0,
                    reviewsCreated: data["reviewsCreated"] as? Int ?? 0
                )
                
                // Update the current user in memory
                DispatchQueue.main.async {
                    self.currentUser = user
                }
                
                // Return the fresh user data
                continuation.resume(returning: user)
            }
        }
    }
    
    // MARK: - Fetch User by Username
    /// Fetches a user by their username from Firestore.
    /// - Parameter username: The username to search for in Firestore.
    /// - Returns: The `User` object if the user is found.
    /// - Throws: An error if the user is not found or if fetching the user fails.
    func fetchUserByUsername(username: String) async throws -> User {
        // Query Firestore for a user with the provided username
        let userQuery = db.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
        
        // Fetch the user document asynchronously
        let snapshot = try await userQuery.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw AuthError.noUserData  // If no user document is found
        }
        
        // Map the data from Firestore into a User object
        let data = document.data()
        
        let user = User(
            profile_pic: data["profile_pic"] as? String ?? "",
            id: data["uid"] as? String ?? "",
            fullname: data["fullname"] as? String ?? "",
            email: data["email"] as? String ?? "",
            description: data["description"] as? String ?? "",
            locationLat: data["locationLat"] as? Double ?? 0.0,
            locationLng: data["locationLng"] as? Double ?? 0.0,
            username: data["username"] as? String ?? "",
            skills: data["skills"] as? [String] ?? [],
            ratings: data["ratings"] as? [Rating] ?? [],
            postsCreated: data["postsCreated"] as? Int ?? 0,
            reviewsCreated: data["reviewsCreated"] as? Int ?? 0
        )
        
        return user
    }
    
    func fetchUserById(_ uid: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user by ID: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = snapshot?.data() else {
                print("No data found for uid \(uid)")
                completion(nil)
                return
            }
            let user = User(
                profile_pic: data["profile_pic"] as? String ?? "",
                id: data["uid"] as? String ?? uid,
                fullname: data["fullname"] as? String ?? "",
                email: data["email"] as? String ?? "",
                description: data["description"] as? String ?? "",
                locationLat: data["locationLat"] as? Double ?? 0.0,
                locationLng: data["locationLng"] as? Double ?? 0.0,
                username: data["username"] as? String ?? "",
                skills: data["skills"] as? [String] ?? [],
                ratings: data["ratings"] as? [Rating] ?? [],
                postsCreated: data["postsCreated"] as? Int ?? 0,
                reviewsCreated: data["reviewsCreated"] as? Int ?? 0
            )
            DispatchQueue.main.async {
                completion(user)
            }
        }
    }


    
    /// Appends a new rating to the user's ratings array in Firestore.
    /// - Parameters:
    ///   - username: The username of the user whose rating is to be appended.
    ///   - rating: The `Rating` struct to append to the user's ratings.
    func appendUserRating(username: String, rating: Rating) async throws {
        // Step 1: Fetch the user document based on the username
        let userQuery = db.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
        
        // Fetch the user document asynchronously
        let snapshot = try await userQuery.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw AuthError.noUserData
        }
        
        // Step 2: Fetch the current ratings array from the document
        var ratings = document.data()["ratings"] as? [[String: Any]] ?? []
        
        // Step 3: Append the new rating to the ratings array
        // Create the dictionary representation of the rating
        let newRating: [String: Any] = [
            "id": rating.id.uuidString,
            "stars": rating.stars,
            "review": rating.review,
            "reviewer": rating.reviewer,
            "job": rating.job,
            "reviewTitle": rating.reviewTitle,
            "date": rating.date
        ]
        
        // Add the new rating to the existing ratings array
        ratings.append(newRating)
        
        // Step 4: Use Firestore batch to update the ratings array in the user document
        let batch = db.batch()
        let userRef = db.collection("users").document(document.documentID)
        
        // Update the ratings field (we're just replacing the entire array)
        batch.updateData([
            "ratings": ratings
        ], forDocument: userRef)
        
        // Commit the batch write
        try await batch.commit()
        
        print("Rating added successfully to \(username)'s profile!")
    }

    // Fetches user reviews based on the username
    func fetchUserReviews(username: String) async throws -> [Rating] {
        // Query Firestore for a user with the provided username
        let userQuery = db.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
        
        // Fetch the user document asynchronously
        let snapshot = try await userQuery.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw AuthError.noUserData  // If no user document is found
        }
        
        // Map the ratings data from Firestore into an array of Rating objects
        if let ratingsData = document.data()["ratings"] as? [[String: Any]] {
            var ratings: [Rating] = []
            
            for ratingData in ratingsData {
                if let stars = ratingData["stars"] as? Int,
                   let review = ratingData["review"] as? String,
                   let reviewer = ratingData["reviewer"] as? String,
                   let job = ratingData["job"] as? String,
                   let reviewTitle = ratingData["reviewTitle"] as? String,
                   let timestamp = ratingData["date"] as? Timestamp {
                    let date = timestamp.dateValue()
                    let rating = Rating(
                        stars: stars,
                        review: review,
                        reviewer: reviewer,
                        job: job,
                        reviewTitle: reviewTitle,
                        date: date
                    )
                    
                    ratings.append(rating)
                }
            }
            
            return ratings
        } else {
            return []  // Return an empty array if no ratings are found
        }
    }
    
    func printUserRatings(username: String) async throws {
        do {
            // Fetch the user from Firestore
            let userDoc = try await Firestore.firestore()
                .collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            
            guard let user = userDoc.documents.first else {
                print("No user found with username \(username)")
                return
            }
            
            // Fetch the ratings from the user's document
            if let ratings = user.data()["ratings"] as? [[String: Any]], !ratings.isEmpty {
                print("Ratings for user \(username):")
                for rating in ratings {
                    if let stars = rating["stars"] as? Int,
                       let review = rating["review"] as? String,
                       let reviewer = rating["reviewer"] as? String,
                       let job = rating["job"] as? String,
                       let reviewTitle = rating["reviewTitle"] as? String,
                       let timestamp = rating["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        print("Job: \(job), Rating: \(stars) stars, Reviewer: \(reviewer), Review: \(review)")
                        print("Header: \(reviewTitle), Posted on: \(date)")
                        print()
                    }
                }
            } else {
                print("User \(username) has no ratings")
            }
        } catch {
            print("Failed to fetch ratings for user \(username): \(error.localizedDescription)")
        }
    }

    func deleteUserRatings(username: String) async throws {
        do {
            // Fetch the user from Firestore
            let userDoc = try await Firestore.firestore()
                .collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            
            guard let user = userDoc.documents.first else {
                print("No user found with username \(username)")
                return
            }
            
            // Delete the ratings array for the user
            try await deleteRatingsForUser(userID: user.documentID)
            
            print("Ratings for user \(username) have been deleted.")
        } catch {
            print("Failed to delete ratings for user \(username): \(error.localizedDescription)")
            throw error
        }
    }

    private func deleteRatingsForUser(userID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Firestore.firestore().collection("users").document(userID).updateData([
                "ratings": []  // Empty the ratings array
            ]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Signs out the current user
    /// - Throws: FirebaseAuth.AuthError if sign out fails
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func fetchUsername(for userId: String) async throws -> String {
        let userDoc = try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument()
        
        return try userDoc.data(as: User.self).username
    }
}



// MARK: - Auth Errors
/// Custom error types for authentication operations
enum AuthError: Error {
    /// Thrown when trying to perform an operation that requires authentication
    case notAuthenticated
    /// Thrown when user document exists in Authentication but not in Firestore
    case noUserData
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .noUserData:
            return "No user data found"
        }
    }
}

#if DEBUG
extension AuthManager {
    func setMockUser(_ user: User) {
        self.currentUser = user
    }
}
#endif
