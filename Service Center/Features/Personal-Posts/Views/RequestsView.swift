//
//  RequestsView.swift
//  Service Center
//
//  Created by Alan Lam on 2/11/25.

import SwiftUI
import FirebaseFirestore

struct RequestsView: View {
    @State var post: PostCardData
    @Binding var isRequestAccepted: Bool  // Track if a request has been accepted
    @ObservedObject var jobStatusManager: JobStatusManager
    @Environment(\.presentationMode) var presentationMode  // To dismiss the view after accepting or rejecting a request
    @Environment(\.dismiss) var dismiss  // For dismissing the view programmatically when done

    @State private var acceptedUserId: String? = nil  // Track the accepted user ID
    @State private var destination: AnyView? = nil  // For navigation to the user's profile
    @State private var isProfileViewPresented: Bool = false  // To control navigation presentation
    @State private var acceptedUserEmail: String? = nil  // Store email of the accepted user
    @State private var acceptedUserFullname: String? = nil  // Store fullname of the accepted user
    @State private var acceptedJobTitle: String? = nil  // Store job title for email content

    var body: some View {
        VStack {
            Text("Job Requests")
                .font(.title)
                .padding()

            // List all job requests
            List(post.jobRequests, id: \.self) { userId in
                HStack {
                    Text(userId)  // Display the username
                        .lineLimit(1)  // Limit to 1 line
                        .truncationMode(.tail)  // Add "..." if the text overflows
                        .frame(maxWidth: 170, alignment: .leading)  // Limit text width and align to the left
                        .onTapGesture {
                            fetchUserDetailsForProfile(userId: userId)  // Fetch user details and navigate
                        }
                    
                    Spacer()  // Push the buttons to the right

                    // Accept button for each user request
                    Button(action: {
                        acceptRequest(fromUser: userId)
                    }) {
                        Text(acceptedUserId == userId ? "Accepted" : "Accept")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(acceptedUserId == userId ? Color.gray : Color.green)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(acceptedUserId == userId)  // Disable if already accepted

                    // Reject button for each user request
                    Button(action: {
                        rejectRequest(fromUser: userId)
                    }) {
                        Text("Reject")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.red)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 5)
            }
        }
        .navigationBarItems(trailing: Button("Close") {
            presentationMode.wrappedValue.dismiss()
        })
        .background(
            NavigationLink(destination: destination, isActive: $isProfileViewPresented) {
                EmptyView()
            }
        )
        .onDisappear {
            // Check if a user has been accepted and send the email when the view disappears
            if let email = acceptedUserEmail, let fullname = acceptedUserFullname, let jobTitle = acceptedJobTitle {
                sendJobRequestAcceptedEmail(to: email, fullname, jobTitle)
            }
        }
    }

    private func fetchUserDetailsForProfile(userId: String) {
        // Assuming a FirebaseManager method to get user details
        FirebaseManager.shared.getUserDetails(username: userId) { fetchedUser in
            if let fetchedUser = fetchedUser {
                // Only navigate if the user is not the current user
                self.destination = AnyView(OtherUserProfileView(db: Firestore.firestore(), user: fetchedUser))
                self.isProfileViewPresented = true
            }
        }
    }

    private func acceptRequest(fromUser userId: String) {
        // Update the job status to "Accepted" in Firebase
        FirebaseManager.shared.acceptJobRequest(postId: post.documentId, userId: userId) { success in
            if success {
                print("Request from \(userId) accepted.")
                jobStatusManager.jobStatus = "Accepted"
                post.acceptedRequest = userId
                post.jobStatus = "Accepted"
                isRequestAccepted = true
                acceptedUserId = userId
                
                // Store necessary details to send the email
                if let user = post.jobRequests.first(where: { $0 == userId }) {
                    FirebaseManager.shared.getUserDetails(username: user) { fetchedUser in
                        if let fetchedUser = fetchedUser {
                            acceptedUserEmail = fetchedUser.email
                            acceptedUserFullname = fetchedUser.fullname
                            acceptedJobTitle = post.title
                        }
                    }
                }
            }
        }
    }

    private func rejectRequest(fromUser userId: String) {
        // Reject the job request by removing the userId from jobRequests
        FirebaseManager.shared.rejectJobRequest(postId: post.documentId, userId: userId) { success in
            if success {
                print("Request from \(userId) rejected.")
                post.jobRequests.removeAll { $0 == userId }
                
                // If the rejected user is the accepted user, update job status to "Open" and reset acceptedUserId
                if userId == acceptedUserId {
                    post.jobStatus = "Open"
                    post.acceptedRequest = nil
                    isRequestAccepted = false
                    acceptedUserId = nil
                }
            }
        }
    }
}

struct RequestsView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyUsernames = (1...15).map { "user\($0)" }  // Generates dummy usernames user1, user2, ..., user15
        let extendedUsernames = dummyUsernames + ["averylongusernameexample"]

        RequestsView(
            post: PostCardData(
                documentId: "sampleDocumentId",
                profile_img: "profile_image_url",
                profile_name: "John Doe",
                title: "Amazing Post",
                profile_id: "12345",
                image: "post_image_url",
                like_count: 100,
                comment_count: 5,
                view_count: 1000,
                description: "This is a description.",
                tags: ["tag1", "tag2"],
                jobStatus: "Open",
                jobRequests: extendedUsernames,
                locationLat: 0.0,
                locationLng: 0.0,
                neighborhood: "Queens",
                city: "New York",
                dateCreated: Date()
            ),
            isRequestAccepted: .constant(false),
            jobStatusManager: JobStatusManager()
        )
    }
}
