import SwiftUI

struct CommentRow: View {
    let comment: Comment
    var indentLevel: Int = 0
    var onReply: ((String, Comment) -> Void)?  // Called when a reply is sent.
    var onDelete: ((Comment) -> Void)?          // Called when deletion is requested.
    
    @State private var showReplyField = false
    @State private var replyText: String = ""
    @State private var showDeleteConfirmation = false
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Profile image placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                VStack(alignment: .leading) {
                    Text(comment.username)
                        .font(.headline)
                    Text(comment.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                // Show reply button only if this is a top-level comment
                if comment.parentCommentId == nil {
                    Button(action: {
                        withAnimation { showReplyField.toggle() }
                    }) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .foregroundColor(.blue)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 8)
                }
                // Delete button visible only if current user is the comment’s owner.
                if authManager.currentUser?.id == comment.userId {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Comment"),
                            message: Text("Are you sure you want to delete this comment?"),
                            primaryButton: .destructive(Text("Delete")) {
                                onDelete?(comment)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .padding(.leading, CGFloat(indentLevel * 20))
            
            Text(comment.text)
                .font(.body)
                .padding(.leading, CGFloat(indentLevel * 20 + 8))
            
            if showReplyField {
                HStack {
                    TextField("Write a reply...", text: $replyText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Post") {
                        if !replyText.trimmingCharacters(in: .whitespaces).isEmpty {
                            onReply?(replyText, comment)
                            replyText = ""
                            withAnimation { showReplyField = false }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.leading, CGFloat((indentLevel + 1) * 20))
            }
        }
        .padding(.vertical, 8)
    }
}
