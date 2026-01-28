//
//  DetailedPostView.swift
//  Service Center
//
//  Created by Alan Lam on 2/7/25.
//  Updated by [Your Name] on [Today’s Date]
import SwiftUI
import FirebaseFirestore
import Combine

struct DetailedPostView: View {
    @State var post: PostCardData
    @State private var user: User? = nil
    @State private var showUserDetails = false
    @State private var isProfileViewPresented = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDeleteConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    @State private var destination: AnyView? = nil
    
    // Job Request States
    @State private var isRequestAccepted = false
    @State private var showRequestsView = false
    
    // Bookmark States
    @State private var isPostSaved = false
    @State private var isSavingPost = false
    
    // Comments view model for inline preview
    @StateObject var commentsViewModel = CommentsViewModel()
    
    // Observed objects for job status and location
    @ObservedObject var jobStatusManager: JobStatusManager
    @ObservedObject var locationManager: LocationManager
    
    // For rating/navigation – we'll navigate to RatingServiceView when job is completed.
    @State private var showRatingServiceView = false
    
    @State private var postOwnerEmail: String? = nil // Email of the user who posted the job
    @State private var postOwnerFullname: String? = nil // Full name of the user who posted the job
    @State private var acceptedUserFullname: String? = nil // Full name of the accepted user


    init(post: PostCardData, jobStatusManager: JobStatusManager, locationManager: LocationManager) {
        self._post = State(initialValue: post)
        self.jobStatusManager = jobStatusManager
        self.locationManager = locationManager
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Post Title
                    Text(post.title)
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 16)
                    
                    // MARK: User Info Row
                    HStack(spacing: 12) {
                        if let profileURL = URL(string: post.profile_img) {
                            AsyncImage(url: profileURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(width: 48, height: 48)
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                case .failure:
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 48, height: 48)
                                        .overlay(Image(systemName: "person.fill")
                                            .foregroundColor(.gray))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "person.fill")
                                    .foregroundColor(.gray))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.profile_name)
                                .font(.headline)
                                .onTapGesture { fetchUserDetailsForProfile() }
                            Text(
                                Calendar.current.isDateInToday(post.dateCreated)
                                ? "Posted Today"
                                : {
                                    let components = Calendar.current.dateComponents([.day], from: post.dateCreated, to: Date())
                                    let days = components.day ?? 0
                                    return days == 0 ? "Posted 1d ago" : "Posted \(days)d ago"
                                }()
                            )
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Bookmark Button
                        if let currentUser = authViewModel.currentUser {
                            Button {
                                toggleBookmark(currentUser: currentUser)
                            } label: {
                                Image(systemName: isPostSaved ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                    .padding(8)
                            }
                            .background(
                                Circle().fill(Color.white)
                                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
                            )
                            .disabled(isSavingPost)
                        }
                    }
                    
                    // MARK: Location and Price Info
                    HStack {
                        if !post.neighborhood.isEmpty || !post.city.isEmpty {
                            Text("\(post.neighborhood)\(post.neighborhood.isEmpty || post.city.isEmpty ? "" : ", ")\(post.city)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if let price = post.price, !price.isEmpty {
                            Text("\(price)/hr")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .bold()
                        }
                    }
                    
                    // MARK: Post Image
                    ZStack {
                        Color.white
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        if let url = URL(string: post.image) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable().scaledToFit()
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(8)
                        } else {
                            Image(systemName: "photo")
                                .resizable().scaledToFit()
                                .foregroundColor(.gray)
                                .padding(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fit)
                    
                    // MARK: Like, View, and Comment Count
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill").foregroundColor(.red)
                            Text("\(post.like_count)")
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("\(post.view_count)")
                        }
                        Spacer()
                        NavigationLink(destination: CommentsView(postId: post.documentId)) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.right")
                                Text("\(post.comment_count)")
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                    
                    Divider()
                    
                    // MARK: About This Service
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this service")
                            .font(.headline)
                        Text(post.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // MARK: Comments Inline Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comments").font(.headline)
                        let topLevelComments = commentsViewModel.comments.filter { $0.parentCommentId == nil }
                        if !topLevelComments.isEmpty {
                            ForEach(topLevelComments.prefix(3)) { comment in
                                CommentRow(comment: comment,
                                           onReply: { replyText, parentComment in
                                    commentsViewModel.sendComment(for: post.documentId,
                                                                  text: replyText,
                                                                  parentCommentId: parentComment.id) { success in
                                        if success { print("Reply sent successfully") }
                                    }
                                },
                                           onDelete: { comment in
                                    commentsViewModel.deleteComment(comment) { success in
                                        if success { print("Comment deleted") }
                                    }
                                })
                                .environmentObject(authViewModel)
                            }
                        } else {
                            Text("No comments yet.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        NavigationLink(destination: CommentsView(postId: post.documentId)) {
                            Text(topLevelComments.count < 3 ? "Comment" : "See All Comments")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Divider()
                    
                    // MARK: Status Section
                    // Show "Start Job" button only for the user who has requested and has been accepted
                    if post.jobStatus == "Accepted" && post.acceptedRequest == authViewModel.currentUser?.username {
                        Button(action: {
                            setJobStatusToInProgress()
                        }) {
                            Text("Start Job")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    
                    // Show "Complete Job" and "Cancel Job" buttons when job is in progress
                    if post.jobStatus == "In Progress" && post.acceptedRequest == authViewModel.currentUser?.username {
                        HStack {
                            Button(action: {
                                setJobStatusToCompleted()
                                completeJobEmailSetup()
                            }) {
                                Text("Complete Job")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                            Spacer()
                            
                            Button(action: {
                                cancelJob()
                            }) {
                                Text("Cancel Job")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                    }
                                        
                    // rate service button
                    if post.jobStatus == "Completed", let currentUser = authViewModel.currentUser, post.profile_id == currentUser.username {
                        NavigationLink(
                            destination: RatingServiceView(post: post),
                            label: {
                                Text("Rate Service")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.yellow)
                                    .cornerRadius(10)
                            }
                        )
                        .padding(.top)
                    }

                    if let currentUser = authViewModel.currentUser {
                        // If the post owner is the current user, show view requests button
                        if post.profile_id == currentUser.username {
                            if let acceptedUser = post.acceptedRequest {
                                // If a user has been accepted, display who it is
                                Text("Accepted by: \(acceptedUser)")
                                    .foregroundColor(.green)
                                    .padding(.top)
                            } else {
                                Button(action: {
                                    showRequestsView = true // Show the requests view
                                }) {
                                    Text("View Requests")
                                        .foregroundColor(isRequestAccepted ? .gray : .white)
                                        .padding()
                                        .background(isRequestAccepted ? Color.gray.opacity(0.5) : Color.blue)
                                        .cornerRadius(10)
                                }
                                .padding(.top)
                                .disabled(isRequestAccepted)  // Disable if request is accepted
                            }
                        }
                        // If the user is not the post owner
                        else {
                            // Only show the "Request Job" button if job status is "Open"
                            if post.jobStatus == "Open" {
                                if !post.jobRequests.contains(currentUser.username) {
                                    // If the user hasn't requested yet
                                    Button(action: {
                                        requestJob()
                                    }) {
                                        Text("Request Job")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.orange)
                                            .cornerRadius(10)
                                    }
                                    .padding(.top)
                                } else {
                                    // If the user has already requested, show the "Cancel Request" button
                                    Button(action: {
                                        cancelJobRequest()
                                    }) {
                                        Text("Cancel Request")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.red)
                                            .cornerRadius(10)
                                    }
                                    .padding(.top)
                                }
                            }
                        }
                    }
                    Divider()
                    
                    // MARK: Delete Post Button (Only for Post Owner)
                    if let currentUser = authViewModel.currentUser, post.profile_id == currentUser.username {
                        Button(action: {
                            showDeleteConfirmation.toggle()
                        }) {
                            Text("Delete Post")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                        .confirmationDialog("Are you sure you want to delete this post?", isPresented: $showDeleteConfirmation) {
                            Button("Delete", role: .destructive) {
                                deletePost()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            authViewModel.fetchCurrentUser { success in
                if success {
                    print("Current user session fetched")
                    checkIfPostIsSaved()
                    if let username = authViewModel.currentUser?.username {
                        FirebaseManager.shared.incrementViewCount(for: post.documentId, userId: username)
                    }
                }
            }
            FirebaseManager.shared.refreshPosts(searchText: "", searchTags: []) { updatedPosts in
                if let updatedPost = updatedPosts.first(where: { $0.documentId == post.documentId }) {
                    self.post = updatedPost
                }
            }
            commentsViewModel.observeComments(for: post.documentId)
        }
        .onDisappear {
            if !showRatingServiceView {
                self.presentationMode.wrappedValue.dismiss()
            }
        }

        
        // NavigationLink to RequestsView
        NavigationLink(destination: RequestsView(post: post,
                                                 isRequestAccepted: $isRequestAccepted,
                                                 jobStatusManager: jobStatusManager),
                       isActive: $showRequestsView) {
            EmptyView()
        }
        
        // NavigationLink to RatingServiceView (directly after "Complete Job")
        NavigationLink(destination: RatingServiceView(post: post),
                       isActive: $showRatingServiceView) {
            EmptyView()
        }
        
        // NavigationLink for Profile View
        NavigationLink(destination: destination, isActive: $isProfileViewPresented) {
            EmptyView()
        }
    }
}

// MARK: - Helper Functions
extension DetailedPostView {
    private func fetchUserDetailsForProfile() {
        FirebaseManager.shared.getUserDetails(username: post.profile_id) { fetchedUser in
            if let fetchedUser = fetchedUser, let currentUser = authViewModel.currentUser {
                if fetchedUser.username == currentUser.username {
                    self.destination = AnyView(ProfileView(db: Firestore.firestore(), jobStatusManager: jobStatusManager, locationManager: locationManager))
                } else {
                    self.destination = AnyView(OtherUserProfileView(db: Firestore.firestore(), user: fetchedUser))
                }
                self.isProfileViewPresented = true
            }
        }
    }
    
    private func requestJob() {
        guard let currentUser = authViewModel.currentUser else { return }
        FirebaseManager.shared.requestJob(postId: post.documentId, userId: currentUser.username) { success in
            if success {
                print("Job request sent successfully")
                FirebaseManager.shared.refreshPosts(searchText: "", searchTags: []) { updatedPosts in
                    if let updatedPost = updatedPosts.first(where: { $0.documentId == post.documentId }) {
                        self.post = updatedPost
                    }
                }
            }
        }
    }
    
    private func cancelJobRequest() {
        guard let currentUser = authViewModel.currentUser else { return }
        FirebaseManager.shared.cancelJobRequest(postId: post.documentId, userId: currentUser.username) { success in
            if success {
                print("Job request canceled successfully")
                FirebaseManager.shared.refreshPosts(searchText: "", searchTags: []) { updatedPosts in
                    if let updatedPost = updatedPosts.first(where: { $0.documentId == post.documentId }) {
                        self.post = updatedPost
                    }
                }
            }
        }
    }
    
    private func setJobStatusToInProgress() {
        post.jobStatus = "In Progress"
        FirebaseManager.shared.updateJobStatus(forPostId: post.documentId, newJobStatus: "In Progress") { success in
            if success {
                print("Job status set to In Progress")
            }
        }
    }
    
    private func setJobStatusToCompleted() {
        // Update local state immediately so the UI shows "Completed"
        post.jobStatus = "Completed"
        self.post = post

        FirebaseManager.shared.updateJobStatus(forPostId: post.documentId, newJobStatus: "Completed") { success in
            if success {
                print("Job status updated to Completed in Firestore")
                // Force a full refresh of posts
                if let currentUserId = AuthManager.shared.currentUser?.id {
                    FirebaseManager.shared.loadPosts(currentUserId: currentUserId)
                } else {
                    FirebaseManager.shared.loadPosts()
                }
                // Optionally, if your refresh method uses a completion:
                FirebaseManager.shared.refreshPosts(searchText: "", searchTags: []) { updatedPosts in
                    DispatchQueue.main.async {
                        FirebaseManager.shared.posts = updatedPosts
                        FirebaseManager.shared.objectWillChange.send()
                    }
                }
            } else {
                print("Failed to update job status in Firestore")
            }
        }
    }

    private func cancelJob() {
        // Ensure we have an accepted user to remove
        guard let acceptedUser = post.acceptedRequest else {
            print("No accepted user to cancel.")
            return
        }

        // Step 1: Remove the accepted user from jobRequests array
        FirebaseManager.shared.rejectJobRequest(postId: post.documentId, userId: acceptedUser) { success in
            if success {
                print("\(acceptedUser) has canceled job.")
                
                // Remove the accepted user from jobRequests
                post.jobRequests.removeAll { $0 == acceptedUser }
                
                // Step 2: Reset acceptedRequest and update jobStatus to "Open"
                post.jobStatus = "Open"
                post.acceptedRequest = nil
                isRequestAccepted = false
                
                // Step 3: Update Firestore with the new values
                let postRef = Firestore.firestore().collection("posts").document(post.documentId)
                postRef.updateData([
                    "jobRequests": post.jobRequests,
                    "acceptedRequest": FieldValue.delete(),
                    "jobStatus": "Open"
                ]) { error in
                    if let error = error {
                        print("Error updating job status and job requests in Firestore: \(error.localizedDescription)")
                    } else {
                        print("Job status, acceptedRequest, and jobRequests successfully updated in Firestore.")
                    }
                }
            } else {
                print("Failed to cancel the job from \(acceptedUser).")
            }
        }
    }


    private func deletePost() {
        FirebaseManager.shared.deletePost(postData: post) { success in
            if success {
                print("Post deleted successfully.")
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func checkIfPostIsSaved() {
        guard let currentUser = authViewModel.currentUser else { return }
        FirebaseSavePosts.shared.isPostSaved(postId: post.documentId, userId: currentUser.username) { isSaved in
            self.isPostSaved = isSaved
        }
    }
    
    private func toggleBookmark(currentUser: User) {
        isSavingPost = true
        if isPostSaved {
            FirebaseSavePosts.shared.unsavePost(postId: post.documentId, userId: currentUser.username) { success in
                self.isSavingPost = false
                if success {
                    self.isPostSaved = false
                    print("Post unsaved successfully")
                } else {
                    print("Failed to unsave post")
                }
            }
        } else {
            FirebaseSavePosts.shared.savePost(postId: post.documentId, userId: currentUser.username) { success in
                self.isSavingPost = false
                if success {
                    self.isPostSaved = true
                    print("Post saved successfully")
                } else {
                    print("Failed to save post")
                }
            }
        }
    }
    
    private func completeJobEmailSetup() {
        // Fetch post owner details
        FirebaseManager.shared.getUserDetails(username: post.profile_id) { fetchedUser in
            if let fetchedUser = fetchedUser {
                self.postOwnerEmail = fetchedUser.email
                self.postOwnerFullname = fetchedUser.fullname
            }
        }
        
        // Fetch accepted user's details (if there's an accepted user)
        if let acceptedUserId = post.acceptedRequest {
            FirebaseManager.shared.getUserDetails(username: acceptedUserId) { fetchedUser in
                if let fetchedUser = fetchedUser {
                    self.acceptedUserFullname = fetchedUser.fullname
                }
            }
        }
        
        // Once the necessary details are fetched, trigger email sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let postOwnerEmail = self.postOwnerEmail,
               let postOwnerFullname = self.postOwnerFullname,
               let acceptedUserFullname = self.acceptedUserFullname {
                let jobTitle = self.post.title
                sendJobCompletedEmail(to: postOwnerEmail, postOwnerFullname, jobTitle, acceptedUserFullname)
            }
        }
    }
}

struct DetailedPostView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyJobStatusManager = JobStatusManager()
        let dummyLocationManager = LocationManager()
        let dummyDateCreated = Date()
        return DetailedPostView(
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
                jobRequests: [],
                locationLat: 0.0,
                locationLng: 0.0,
                neighborhood: "Queens",
                city: "New York",
                dateCreated: dummyDateCreated
            ),
            jobStatusManager: dummyJobStatusManager,
            locationManager: dummyLocationManager
        )
        .environmentObject(AuthViewModel())
    }
}
