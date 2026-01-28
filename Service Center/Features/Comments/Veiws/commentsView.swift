import SwiftUI

struct CommentsView: View {
    let postId: String
    @StateObject var viewModel = CommentsViewModel()
    @State private var commentText: String = ""
    
    // Use AuthManager as an environment object.
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            List {
                // Display top-level comments (parentCommentId == nil)
                ForEach(viewModel.comments.filter { $0.parentCommentId == nil }) { comment in
                    VStack(alignment: .leading, spacing: 8) {
                        CommentRow(comment: comment,
                                   onReply: { replyText, parentComment in
                                    viewModel.sendComment(for: postId,
                                                          text: replyText,
                                                          parentCommentId: parentComment.id) { success in
                                        if success {
                                            print("Reply sent successfully")
                                        }
                                    }
                                   },
                                   onDelete: { comment in
                                    viewModel.deleteComment(comment) { success in
                                        if success {
                                            print("Comment deleted")
                                        }
                                    }
                                   })
                        .environmentObject(authManager)
                        
                        // Display replies for this comment (nested)
                        ForEach(viewModel.comments.filter { $0.parentCommentId == comment.id }) { reply in
                            CommentRow(comment: reply,
                                       indentLevel: 1,
                                       onReply: { replyText, parentComment in
                                           viewModel.sendComment(for: postId,
                                                                 text: replyText,
                                                                 parentCommentId: parentComment.id) { success in
                                               if success {
                                                   print("Reply sent successfully")
                                               }
                                           }
                                       },
                                       onDelete: { reply in
                                           viewModel.deleteComment(reply) { success in
                                               if success {
                                                   print("Comment deleted")
                                               }
                                           }
                                       })
                            .environmentObject(authManager)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // Input for new top-level comment
            HStack {
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    viewModel.sendComment(for: postId, text: commentText) { success in
                        if success {
                            commentText = ""
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
        }
        .navigationTitle("Comments")
        .onAppear {
            viewModel.observeComments(for: postId)
        }
    }
}
