//
//  RatingServiceView.swift
//  Service Center
//
//  Created by Alan Lam on 2/23/25.
//

import SwiftUI
import FirebaseFirestore

struct RatingServiceView: View {
    var post: PostCardData
    @State private var selectedRating: Int = 1
    @State private var comment: String = ""  // Track the user's comment
    @State private var header: String = ""  // Track the user's review title
    @State private var showConfirmationView: Bool = false  // State to trigger navigation
    @State private var isSubmitted: Bool = false  // Track if submit button was pressed
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Post title with accepted user name as subheader
                    VStack {
                        Text(post.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        Text("by \(post.acceptedRequest ?? "Unknown User")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, -15)
                    }
                    Spacer()
                    
                    // Rating section
                    VStack(alignment: .center, spacing: 10) {
                        Text("How would you rate this service?")
                            .font(.headline)
                            .padding(.bottom, 10)
                        
                        HStack(spacing: 5) {
                            ForEach(1..<6) { star in
                                Image(systemName: "star.fill")
                                    .foregroundColor(star <= selectedRating ? .yellow : .gray)
                                    .onTapGesture {
                                        selectedRating = star
                                    }
                            }
                        }
                        .padding(.bottom, 15)
                        
                        // Display the current rating
                        Text("Current Rating: \(selectedRating) star(s)")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                        
                        // Review title input box
                        Text("Review Title:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        TextField("Enter a title for your review", text: $header)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 15)
                        
                        // Show error message for header if it's empty and submit button was pressed
                        if isSubmitted && header.isEmpty {
                            Text("Review title is required.")
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.top, -20)
                        }
                        
                        // Comment box (TextEditor for multi-line input)
                        Text("Leave a Comment:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        TextEditor(text: $comment)
                            .frame(height: 120)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .border(Color.gray, width: 1)
                            .padding(.bottom, 20)
                        
                        if isSubmitted && comment.isEmpty {
                            Text("Comment is required.")
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.top, -25)
                        }
                        
                        // Button to submit the rating and comment
                        Button(action: {
                            isSubmitted = true  // Mark that the user has attempted to submit
                            submitRatingAndComment()
                        }) {
                            Text("Submit Rating & Comment")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                    }
                }
                .padding()
                // Navigate when showConfirmationView is true
                .navigationDestination(isPresented: $showConfirmationView) {
                    ReviewConfirmationView()
                }
            }
        }
    }
    
    // Function to handle rating and comment submission
    private func submitRatingAndComment() {
        // Check if either the review title or comment is empty
        if header.isEmpty || comment.isEmpty {
            return  // Do nothing if fields are empty (error messages will show)
        }
        
        print("Submitted rating of \(selectedRating) stars for the post titled: \(post.title)")
        print("User's comment: \(comment)")

        FirebaseManager.shared.updateJobStatus(forPostId: post.documentId, newJobStatus: "Closed") { success in
            if success {
                print("Job status set to Closed")
            }
        }
        
        let rating = Rating(
            stars: selectedRating,
            review: comment,
            reviewer: authViewModel.currentUser?.username ?? "Unknown",
            job: post.title,
            reviewTitle: header,
            date: Date()
        )

        // Append the rating to the accepted user's profile
        Task {
            do {
                try await AuthManager.shared.appendUserRating(username: post.acceptedRequest ?? "", rating: rating)
            } catch {
                print("Failed to add rating: \(error.localizedDescription)")
            }
        }

        // Increment the reviewsCreated field for the current user
        incrementReviewsCreatedForCurrentUser()

        // Trigger navigation to the confirmation view
        showConfirmationView = true
    }

    // Function to increment the reviewsCreated for the current user
    private func incrementReviewsCreatedForCurrentUser() {
        guard let currentUser = authViewModel.currentUser else {
            print("No current user found")
            return
        }
        
        // Increment the reviewsCreated field for the current user
        FirebaseManager.shared.updateReviewsCreated(uid: currentUser.id, action: "increment") { success in
            if success {
                print("reviewsCreated field incremented successfully")
            } else {
                print("Failed to increment reviewsCreated")
            }
        }
    }
}

struct ReviewConfirmationView: View {
    var body: some View {
        VStack {
            Text("Thank you for your review!")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Your rating and comment have been submitted.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(-180)
    }
}
