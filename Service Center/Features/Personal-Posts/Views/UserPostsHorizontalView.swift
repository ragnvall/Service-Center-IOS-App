//
//  UserPostsHorizontalView.swift
//  Service Center
//
//  Created by Alan Lam on 3/4/25.
//

import SwiftUI

struct UserPostsHorizontalView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @ObservedObject var jobStatusManager: JobStatusManager
    @ObservedObject var locationManager: LocationManager
    let username: String // User-specific username parameter

    var body: some View {
        VStack(spacing: -16) {
            // First post: Larger and displayed above the horizontal scroll
            if let firstPost = firebaseManager.posts.first(where: { $0.profile_id == username }) {
                NavigationLink(destination: DetailedPostView(post: firstPost, jobStatusManager: jobStatusManager, locationManager: locationManager)) {
                    HStack(spacing: 16) {
                        // Image takes up the left half of the rectangle
                        AsyncImage(url: URL(string: firstPost.image)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 178, height: 152)
                                .cornerRadius(10)
                                .clipped() // Keep clipped for rounded corners
                        } placeholder: {
                            ZStack {
                                Color.gray.opacity(0.3)
                                    .frame(width: 178, height: 152) // Square placeholder
                                    .cornerRadius(12)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .frame(width: 40, height: 40)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstPost.title)
                                .font(.body)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .foregroundColor(.black)
                                .padding(.top, 0)

                            if let price = firstPost.price, let timeUnit = firstPost.timeUnit {
                                if price != "" {
                                    Text("$\(price)/" +
                                         (timeUnit == "Per Hour" ? "hr" :
                                            timeUnit == "Per Day" ? "day" :
                                            timeUnit == "Per Service" ? "service" : "")
                                    )
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                } else {
                                    Text("Price not available")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                }
                            }

                            Text(
                                Calendar.current.isDateInToday(firstPost.dateCreated)
                                ? "Posted Today"
                                : {
                                    let components = Calendar.current.dateComponents([.day], from: firstPost.dateCreated, to: Date())
                                    let days = components.day ?? 0
                                    return days == 0 ? "Posted 1d ago" : "Posted \(days)d ago"
                                }()
                            )
                            .font(.body) // Apply consistent font
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        }
                        .padding(8) // Adjust padding to move text more left
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.85) // Set width for the rectangle to align with horizontal scroll
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1))
                    .padding(.vertical)
                    .frame(height: 240) // Increase height for the larger post
                }
            }


            
            // Horizontal Scroll for the rest of the posts
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    // Filter posts for the specific user (excluding the first post)
                    let userPosts = firebaseManager.posts.filter { $0.profile_id == username }
                    
                    // Display the rest of the posts
                    ForEach(userPosts.filter { $0.id != firebaseManager.posts.first(where: { $0.profile_id == username })?.id }) { postData in
                        NavigationLink(destination: DetailedPostView(post: postData, jobStatusManager: jobStatusManager, locationManager: locationManager)) {
                            VStack {
                                ZStack {
                                    // Apply a rounded rectangle with black border around the image
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                        .frame(width: 72, height: 61) // Set a fixed size for the border around the image
                                    
                                    // Post image
                                    AsyncImage(url: URL(string: postData.image)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 61) // Image size
                                            .cornerRadius(10) // Apply rounded corners to the image
                                            .clipped() // Keep clipped for subposts to maintain the rounded corners
                                    } placeholder: {
                                        ZStack {
                                            Color.gray.opacity(0.3)
                                                .frame(width: 72, height: 61)
                                                .cornerRadius(12) // Rounded corners for placeholder
                                            
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                                .frame(width: 40, height: 40)
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 16) // Align the smaller posts by adding padding to the left
                        }
                    }
                }
                .padding(.horizontal) // Add padding around horizontal scroll to match the first post's container
            }
        }
        .onAppear {
            // Load posts when the view appears
            firebaseManager.loadPosts()
        }
    }
}

struct UserPostsHorizontalView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyJobStatusManager = JobStatusManager()
        let dummyLocationManager = LocationManager()
        UserPostsHorizontalView(jobStatusManager: dummyJobStatusManager, locationManager: dummyLocationManager, username: "johndoe")
    }
}
