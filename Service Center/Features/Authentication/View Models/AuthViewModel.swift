import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

//ViewModel for handling authentication-related tasks in the ServiceCenter app.
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties (Observable State)
    
    /// Stores the current logged-in user session from Firebase Authentication.
    @Published var userSession: FirebaseAuth.User?
    
    /// Stores the currently authenticated user's details retrieved from Firestore.
    @Published var currentUser: User?
    
    /// Stores any error messages related to authentication processes.
    @Published var errorMessage: String?
    
    /// Tracks whether the username is already taken during registration.
    @Published var usernameTaken: Bool = false
    
    /// Stores a message related to password reset actions.
    @Published var passwordResetMessage: String?
    
    /// Stores user input values during authentication and registration.
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    
    /// Indicates whether the user has completed the onboarding process.
    @Published var hasCompletedOnboarding: Bool = false
    
    /// Tracks whether the user is newly registered.
    @Published var isNewUser: Bool = false
    
    /// Firestore database instance for fetching and storing user data.
    private let db = Firestore.firestore()
    
    
    
    // MARK: - Authentication (Login)
    /// Authenticates a user using either a username or an email address.
    /// - Parameters:
    ///   - usernameOrEmail: The username or email entered by the user.
    ///   - password: The password entered by the user.l)
    func authenticate(usernameOrEmail: String, password: String) {
        print("Attempting to log in with: \(usernameOrEmail)")
        
        if usernameOrEmail.contains("@") {
            // If the input contains "@", assume it's an email and attempt login directly.
            signInWithEmail(email: usernameOrEmail, password: password)
        } else {
            // If it's a username, fetch the associated email from Firestore.
            fetchEmailFromUsername(username: usernameOrEmail) { email in
                guard let email = email else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Invalid username or email."
                    }
                    return
                }
                self.signInWithEmail(email: email, password: password)
            }
        }
    }
    
    /// Logs in a user using email and password via Firebase Authentication.
    private func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                } else {
                    self.userSession = result?.user
                    self.errorMessage = nil
                    print("Login successful!")
                }
            }
        }
    }
    
    
    // MARK: - User Registration
    /// Registers a new user, ensuring the username is unique before proceeding.
    func register(username: String, email: String, password: String, fullname: String, completion: @escaping (Bool) -> Void) {
        checkIfUsernameExists(username: username) { exists in
            DispatchQueue.main.async {
                if exists {
                    self.usernameTaken = true
                    self.errorMessage = "Username is already taken."
                    completion(false)
                    return
                } else {
                    // Create a new user in Firebase Authentication
                    Auth.auth().createUser(withEmail: email, password: password) { result, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.errorMessage = error.localizedDescription
                                completion(false)
                                return
                            }
                            
                            guard let user = result?.user else { return }
                            self.isNewUser = true
                            self.userSession = user
                            self.errorMessage = nil
                            print("User registered successfully!")
                            
                            // Save user details to Firestore database
                            self.saveUserToFirestore(uid: user.uid, username: username, fullname: fullname, email: email)
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Username Validation
    /// Checks if a given username already exists in Firestore.
    func checkIfUsernameExists(username: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking username: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(!(snapshot?.documents.isEmpty ?? true))
                }
            }
        }
    }
    
    /// Retrieves an email address associated with a given username.
    private func fetchEmailFromUsername(username: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching email: \(error.localizedDescription)")
                completion(nil)
            } else {
                let email = snapshot?.documents.first?.data()["email"] as? String
                completion(email)
            }
        }
    }
    
    /// Fetches the currently authenticated user's details from Firestore.
    func fetchCurrentUser(completion: @escaping (Bool) -> Void) {
        guard let uid = userSession?.uid else {
            print("❌ User is not logged in")
            completion(false)
            return
        }
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to fetch user data: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = snapshot?.data() else {
                print("❌ No data found for the user")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                self.currentUser = User(
                    profile_pic: data["profile_pic"] as? String ?? "",
                    id: data["uid"] as? String ?? "",
                    fullname: data["fullname"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    locationLat: data["locationLat"] as? Double,
                    locationLng: data["locationLng"] as? Double,
                    username: data["username"] as? String ?? "",
                    skills: data["skills"] as? [String] ?? [],
                    ratings: data["ratings"] as? [Rating] ?? [],
                    postsCreated: data["postsCreated"] as? Int ?? 0,
                    reviewsCreated: data["reviewsCreated"] as? Int ?? 0
                )
                
                let onboardingStatus = data["hasCompletedOnboarding"] as? Bool ?? false
                print("✅ Firebase onboarding status: \(onboardingStatus)")
                
                self.hasCompletedOnboarding = onboardingStatus
                
                // ✅ Ensure onboarding only for new users
                if !self.hasCompletedOnboarding && self.isNewUser {
                    print("✅ Showing onboarding since this is a new user")
                } else {
                    self.isNewUser = false
                }
                
                completion(true)
            }
        }
    }
    
    
    // MARK: - Reset Password Function
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    let errorMessage = error.localizedDescription
                    
                    if errorMessage.contains("badly formatted") {
                        self.passwordResetMessage = "❌ Please enter a valid email address."
                    } else if errorMessage.contains("blocked all requests") {
                        self.passwordResetMessage = "⚠️ Too many attempts. Try again later."
                    } else if errorMessage.contains("Network error") {
                        self.passwordResetMessage = "⚠️ Check your internet connection and try again."
                    } else {
                        self.passwordResetMessage = "❌ \(errorMessage)" // Default error message
                    }
                } else {
                    self.passwordResetMessage = "✅ If an account exists for this email, a reset link has been sent."
                }
            }
        }
    }
    
    // Function to clear the error message when the user clicks "Close"
    func clearPasswordResetMessage() {
        DispatchQueue.main.async {
            self.passwordResetMessage = nil
        }
    }
    
    // MARK: - Complete Onboarding
    func completeOnboarding(skills: [String], description: String, location: String, isServiceProvider: Bool) {
        guard let userID = userSession?.uid else { return }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.setData([
            "skills": skills,
            "description": description,
            "location": location,
            "isServiceProvider": isServiceProvider,
            "hasCompletedOnboarding": true
        ], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
                } else {
                    self.hasCompletedOnboarding = true
                    self.isNewUser = false
                    print("✅ Onboarding completed successfully")
                    
                    // ✅ Fetch the updated user data to ensure UI updates
                    self.fetchCurrentUser { success in
                        if success {
                            print("✅ User data refreshed after onboarding")
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - User Management
    /// Logs out the currently authenticated user and clears session data
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil  // Clear the current user
            print("User successfully signed out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    
    // Save User to Firestore
    private func saveUserToFirestore(uid: String, username: String, fullname: String, email: String) {
        let data: [String: Any] = [
            "uid": uid,
            "username": username,
            "fullname": fullname,
            "email": email,
            "ratings": [],
            "hasCompletedOnboarding": false  // Set onboarding to false
        ]
        db.collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("Failed to save user data: \(error.localizedDescription)")
            } else {
                print("User data saved to Firestore successfully!")
            }
        }
    }
}
