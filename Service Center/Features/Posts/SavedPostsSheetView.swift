//
//  SavedPostsSheetView.swift
//  Service Center
//
//  Created by Leo Ifrim on 2/28/25.
//
import SwiftUI

struct SavedPostsSheetView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var savedPosts: [PostCardData] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if savedPosts.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No saved posts")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(savedPosts, id: \.documentId) { post in
                            PostCard(
                                data: post,
                                jobStatus: .constant(post.jobStatus)
                            )
                            .frame(maxWidth: .infinity)
                            // No horizontal padding to allow cards to extend to edges
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            loadSavedPosts()
        }
    }
    
    private func loadSavedPosts() {
        guard let currentUser = authViewModel.currentUser else {
            isLoading = false
            return
        }
        
        FirebaseSavePosts.shared.getSavedPosts(userId: currentUser.username) { posts in
            self.savedPosts = posts
            self.isLoading = false
        }
    }
}
