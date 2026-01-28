//
//  PostCard.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import SwiftUI

// SwiftUI view for displaying a single post
struct PostCard: View {
    let profile_img: String
    let profile_id: String
    let image: String
    let title: String
    @State var like_count: Int  // Changed to State
    let comment_count: Int
    let view_count: Int
    let description: String
    let hashTags: [String]
    let locationLat: Double
    let locationLng: Double
    let city: String
    let neighborhood: String
    @State var postData: PostCardData
    @Binding var jobStatus: String
    @StateObject var jobStatusManager = JobStatusManager()
    @StateObject var locationManager = LocationManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isLiked: Bool = false
    @State private var isProcessingLike = false
    @ObservedObject private var authManager = AuthManager.shared
    
    init(data: PostCardData, jobStatus: Binding<String>) {
        self.profile_img = data.profile_img
        self.profile_id = data.profile_id
        self.image = data.image
        self.title = data.title
        self._like_count = State(initialValue: data.like_count)
        self.comment_count = data.comment_count
        self.view_count = data.view_count
        self.description = data.description
        self.hashTags = data.tags
        self._jobStatus = jobStatus
        self._postData = State(initialValue: data)
        self.locationLat = data.locationLat
        self.locationLng = data.locationLng
        self.neighborhood = data.neighborhood
        self.city = data.city
        self._isLiked = State(initialValue: data.isLikedByCurrentUser)
        self.postData.jobRequests = []
        if postData.acceptedRequest == nil {
            postData.acceptedRequest = nil
        }
    }

    private var jobStatusColor: Color {
        switch jobStatus {
        case "Open":
            return .pink
        case "In Progress":
            return .yellow
        case "Accepted":
            return .orange
        case "Completed":
            return .green
        default:
            return .gray
        }
    }
    
    private func toggleLike() {
        // Prevent multiple rapid clicks
        guard !isProcessingLike else { return }
        
        guard let userId = authManager.currentUser?.id else {
            print("User not logged in")
            return
        }
        
        // Set flag to prevent multiple clicks
        isProcessingLike = true
        
        // Don't update the UI optimistically - wait for Firebase confirmation
        firebaseManager.toggleLike(for: postData.documentId, userId: userId) { [self] success, newLikeCount in
            DispatchQueue.main.async {
                if success {
                    print("Like status updated successfully. New count: \(newLikeCount)")
                    // Use the count from Firebase, not a local calculation
                    self.like_count = newLikeCount
                    self.isLiked.toggle()
                    // Update postData to maintain consistency
                    self.postData.like_count = newLikeCount
                    self.postData.isLikedByCurrentUser = self.isLiked
                } else {
                    print("Failed to update like status")
                }
                
                // Reset processing flag after operation completes
                self.isProcessingLike = false
            }
        }
    }

    var body: some View {
        NavigationLink(destination: DetailedPostView(post: postData, jobStatusManager: jobStatusManager, locationManager: locationManager)) {
            ZStack(alignment: .topTrailing) {
                // Content of the post
                VStack(spacing: 0) {
                    // Header with the Job Status Banner on top
                    ZStack {
                        PostCardHeader(
                            profile_img: profile_img,
                            profile_name: title,
                            profile_id: profile_id,
                            postData: postData
                        )
                        
                        // Job Status Banner overlay on the header
                        HStack {
                            Spacer()
                            Text(jobStatus)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(jobStatusColor)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .padding(.trailing, 50)
                        }
                        .padding(.top, 4) // Padding from the top of the header to the banner
                        .frame(maxWidth: .infinity, alignment: .topTrailing) // Ensures the banner is on the top-right
                    }
                    
                    // Updated PostCardBody with like functionality
                    PostCardBody(
                        post_image_name: image,
                        imageUrls: postData.imageUrls,
                        like_count: $like_count,
                        comment_count: comment_count,
                        view_count: view_count,
                        description: description,
                        price: postData.price,
                        timeUnit: postData.timeUnit,
                        tags: hashTags,
                        locationLat: locationLat,
                        locationLng: locationLng,
                        neighborhood: neighborhood,
                        city: city,
                        postId: postData.documentId,
                        isLiked: $isLiked,
                        onLikeToggle: toggleLike
                    )
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle()) // To avoid any default navigation button style
        .onAppear {
            // Check if the current user has liked this post when it appears
            if let userId = authManager.currentUser?.id {
                firebaseManager.checkIfUserLikedPost(postId: postData.documentId, userId: userId) { liked in
                    DispatchQueue.main.async {
                        self.isLiked = liked
                        self.postData.isLikedByCurrentUser = liked
                    }
                }
            }
        }
    }
}

// Preview provider for PostCard
struct PostCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = PostCardData(
            documentId: "sample-id",
            profile_img: "sample_profile",
            profile_name: "John Doe",
            title: "Sample Post",
            profile_id: "johndoe",
            image: "sample_image",
            like_count: 42,
            comment_count: 7,
            view_count: 120,
            description: "This is a sample post description for preview.",
            tags: ["Sample", "Preview", "SwiftUI"],
            jobStatus: "Open",
            jobRequests: [],
            locationLat: 40.7128,
            locationLng: -74.0060,
            neighborhood: "Manhattan",
            city: "New York",
            isLikedByCurrentUser: false,
            dateCreated: Date()
        )
        
        return PostCard(data: sampleData, jobStatus: .constant("Open"))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
