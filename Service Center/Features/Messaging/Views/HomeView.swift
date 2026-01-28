//  HomeView.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showNewMessage = false
    @StateObject private var userSearchViewModel = UserSearchViewModel()
    // New state to hold the conversation we want to navigate to.
    @State private var selectedConversation: (userId: String, username: String, profileImageUrl: String?)? = nil

    // Search bar remains the same.
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading)
            
            TextField("Search by username", text: $viewModel.searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.none)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // Header remains unchanged.
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
    
    // Updated messages list with swipe-to-delete functionality.
    private var messagesList: some View {
        List {
            ForEach(viewModel.filteredChatPreviewsHomeView) { message in
                MessageListItem(
                    message: message,
                    viewModel: viewModel,
                    currentUserId: authManager.currentUser?.id ?? ""
                )
            }
            .onDelete(perform: deleteRow)
        }
        .listStyle(PlainListStyle())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                header
                messagesList
            }
            .navigationBarHidden(true)
            // Programmatic navigation: when selectedConversation is non-nil, push ChatView.
            .navigationDestination(isPresented: Binding<Bool>(
                get: { selectedConversation != nil },
                set: { newValue in if !newValue { selectedConversation = nil } }
            )) {
                if let conversation = selectedConversation {
                    ChatView(
                        messagesViewModel: viewModel,
                        otherUserId: conversation.userId,
                        otherUsername: conversation.username,
                        otherProfileImageUrl: ""  // Provide a default (or real) profile image URL here
                    )
                }
            }

            // NewMessageView sheet remains as before, but now its callback updates selectedConversation.
            .sheet(isPresented: $showNewMessage) {
                NewMessageView(
                    viewModel: userSearchViewModel,
                    messagesViewModel: viewModel
                ) { userId, username in
                    selectedConversation = (userId: userId, username: username, profileImageUrl: "")
                    showNewMessage = false
                }
            }
        }
    }
    
    // Delete the conversation at the given offsets.
    private func deleteRow(at offsets: IndexSet) {
        offsets.forEach { index in
            let conversation = viewModel.filteredChatPreviewsHomeView[index]
            viewModel.deleteConversation(conversationId: conversation.id)
        }
    }
}


// Your existing MessageListItem can remain the same.
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
                otherUsername: message.username,  // This must be the other user's name!
                otherProfileImageUrl: message.profileImageUrl ?? ""
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
