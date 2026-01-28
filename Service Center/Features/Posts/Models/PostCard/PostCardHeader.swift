//
//  PostCardHeader.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import SwiftUI

struct PostCardHeader: View {
    let profile_img: String
    let profile_name: String
    let profile_id: String
    let postData: PostCardData  // Accept PostCardData directly
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack {
            // Profile image with AsyncImage since it's coming from Firebase
            AsyncImage(url: URL(string: profile_img)) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile_name)
                    .font(.title3)
                    .bold()
                Text(profile_id)
                    .font(.footnote)
            }
            .foregroundColor(.white)

            Spacer()

            // Ellipsis Button (for deletion)
            Button(action: {
                //showDeleteConfirmation.toggle()   // UNCOMMENT THIS LINE TO ALLOW ANY USER TO DELETE A POST, FOR DEBUG ONLY
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .padding(.trailing, 8)
            }
            .confirmationDialog("Are you sure you want to delete this post?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    // Directly use FirebaseManager.shared to delete the post
                    FirebaseManager.shared.deletePost(postData: postData) { success in
                        if success {
                            print("Post deleted successfully.")
                        } else {
                            print("Failed to delete the post.")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    // Do nothing if cancelled
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.blue)
    }
}
