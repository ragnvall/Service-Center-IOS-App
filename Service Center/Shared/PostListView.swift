//
//  PostListView.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

// PostListView.swift
import SwiftUI

struct PostListView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingCreatePost = false
    let searchText: String
    var filteredPosts: [PostCardData] {
        if searchText.isEmpty {
            return firebaseManager.posts
        } else {
            return firebaseManager.posts.filter { post in
                post.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) { // Add spacing between posts
                    ForEach(filteredPosts) { postData in
                        PostCard(data: postData)
                            .padding(.horizontal) // Add horizontal padding
                            .frame(maxWidth: .infinity) // Ensure the card takes full width
                            .aspectRatio(contentMode: .fill) // Keep images in proper aspect ratio
                    }
                }
                .padding(.vertical) // Add vertical padding
            }
            .refreshable {
                firebaseManager.loadPosts()
            }
            .onAppear {
                firebaseManager.loadPosts()
            }
            .navigationTitle("Posts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingCreatePost = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost, onDismiss: {
                firebaseManager.loadPosts()
            }) {
                NavigationStack {
                    CreatePostView()
                }
            }
        }
    }
}

struct PostListView_Previews: PreviewProvider {
    static var previews: some View {
        PostListView(searchText: "")
    }
}
