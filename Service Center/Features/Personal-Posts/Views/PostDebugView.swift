//
//  PostDebugView.swift
//  Service Center
//
//  Created by Alan Lam on 3/4/25.
//

import SwiftUI
import FirebaseFirestore

struct PostDebugView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var authManager = AuthManager.shared
    
    // State variables to manage alert visibility
    @State private var showDeleteAllPostsAlert = false
    @State private var showResetPostsCreatedAlert = false
    @State private var showResetReviewsCreatedAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Post Debug View")
                    .font(.headline)
                    .bold(true)
                
                // Button to delete all posts with confirmation alert
                Button(action: {
                    showDeleteAllPostsAlert = true
                }) {
                    Text("Delete All Posts")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding()
                .alert(isPresented: $showDeleteAllPostsAlert) {
                    Alert(
                        title: Text("Warning! ⚠️"),
                        message: Text("Delete posts for all users? You will have to manually reset the posts count of each user."),
                        primaryButton: .destructive(Text("Delete")) {
                            firebaseManager.deleteAllPosts { success in
                                if success {
                                    print("All posts deleted successfully.")
                                } else {
                                    print("Failed to delete all posts.")
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                // Button to reset postsCreated to 0 with confirmation alert
                Button(action: {
                    showResetPostsCreatedAlert = true
                }) {
                    Text("Reset Posts Created")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                .alert(isPresented: $showResetPostsCreatedAlert) {
                    Alert(
                        title: Text("Confirm Reset"),
                        message: Text("Set the post count of current user to 0? You will have to manually delete all posts."),
                        primaryButton: .destructive(Text("Reset")) {
                            resetPostsCreated()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                // Button to reset reviewsCreated to 0 with confirmation alert
                Button(action: {
                    showResetReviewsCreatedAlert = true
                }) {
                    Text("Reset Reviews Created")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding()
                .alert(isPresented: $showResetReviewsCreatedAlert) {
                    Alert(
                        title: Text("Confirm Reset"),
                        message: Text("Set the review count for current user to 0? You will have to manually delete all reviews."),
                        primaryButton: .destructive(Text("Reset")) {
                            resetReviewsCreated()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                // Navigation link to UserRatingDebugView
                NavigationLink(destination: UserRatingDebugView()) {
                    Text("Go to User Rating Debug")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Post Debug")
        }
    }
    
    // Function to reset postsCreated to 0
    private func resetPostsCreated() {
        guard var user = authManager.currentUser else {
            print("User not authenticated")
            return
        }
        
        // Reset postsCreated field
        user.postsCreated = 0
        
        // Update the user document in Firestore
        updateUserInFirestore(user: user, field: "postsCreated", value: 0) { success in
            if success {
                authManager.currentUser?.postsCreated = 0
                print("Posts created reset to 0.")
            } else {
                print("Failed to reset posts created.")
            }
        }
    }
    
    // Function to reset reviewsCreated to 0
    private func resetReviewsCreated() {
        guard var user = authManager.currentUser else {
            print("User not authenticated")
            return
        }
        
        // Reset reviewsCreated field
        user.reviewsCreated = 0
        
        // Update the user document in Firestore
        updateUserInFirestore(user: user, field: "reviewsCreated", value: 0) { success in
            if success {
                authManager.currentUser?.reviewsCreated = 0
                print("Reviews created reset to 0.")
            } else {
                print("Failed to reset reviews created.")
            }
        }
    }
    
    // Function to update specific user field in Firestore
    private func updateUserInFirestore(user: User, field: String, value: Int, completion: @escaping (Bool) -> Void) {
        // Directly use the user.id since it's non-optional in the User struct
        let userId = user.id
        
        // Reference to the user document in Firestore
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        // Update the specified field (postsCreated or reviewsCreated) with the given value
        userRef.updateData([
            field: value
        ]) { error in
            if let error = error {
                print("Error updating user: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

struct PostDebugView_Previews: PreviewProvider {
    static var previews: some View {
        PostDebugView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
