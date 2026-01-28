import SwiftUI

struct MessageRow: View {
    let message: MessageUser
    let isCurrentUserSender: Bool
    @ObservedObject var messagesViewModel: MessagesViewModel
    
    var otherPersonUsername: String {
        // Always get the other person's ID
        let otherUserId = isCurrentUserSender ? message.receiverId : message.senderId
        return messagesViewModel.usernames[otherUserId] ?? "Loading..."
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(otherPersonUsername)
                    .font(.system(size: 16, weight: .semibold))
                HStack(spacing: 4) {
                    if isCurrentUserSender {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    Text(message.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)

                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.formattedTime)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                if message.hasUnreadMessage && !isCurrentUserSender {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear {
            // Fetch the other person's username
            let otherUserId = isCurrentUserSender ? message.receiverId : message.senderId
            messagesViewModel.fetchUsername(for: otherUserId)
        }
    }
}
