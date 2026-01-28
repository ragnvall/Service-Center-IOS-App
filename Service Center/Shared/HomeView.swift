import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showNewMessage = false
    
    
    // Search bar component
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading)
            
            TextField("Search by username", text: $viewModel.searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // Header component
    private var header: some View {
        HStack {
            Text("Direct messages")
                .font(.title2)
                .bold()
            Spacer()
            Text("\(viewModel.unreadRequestsCount) request\(viewModel.unreadRequestsCount == 1 ? "" : "s")")
                .foregroundColor(.gray)
            
            Button(action: { showNewMessage = true }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding(.leading, 8)
        }
        .padding()
    }
    
    // Messages list component
    private var messagesList: some View {
        ScrollView {
            if viewModel.filteredChatPreviewsHomeView.isEmpty && !viewModel.searchText.isEmpty {
                Text("No messages found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredChatPreviewsHomeView) { message in
                        MessageListItem(
                            message: message,
                            viewModel: viewModel,
                            currentUserId: authManager.currentUser?.id ?? ""
                        )
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            if authManager.isLoading {
                ProgressView("Loading...")
            } else {
                VStack(spacing: 0) {
                    searchBar
                    header
                    messagesList
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showNewMessage) {
                    NewMessageView(messagesViewModel: viewModel)
                }
            }
        }
    }
}

// Separate view for message list items
struct MessageListItem: View {
    let message: MessageUser
    let viewModel: MessagesViewModel
    let currentUserId: String
    
    var otherUserId: String {
        message.senderId == currentUserId ? message.receiverId : message.senderId
    }
    
    var body: some View {
        NavigationLink(
            destination: ChatView(
                messagesViewModel: viewModel,
                otherUserId: otherUserId,
                otherUsername: message.username
            )
        ) {
            MessageRow(
                message: message,
                isCurrentUserSender: message.senderId == currentUserId,
                messagesViewModel: viewModel
            )
        }
    }
}
