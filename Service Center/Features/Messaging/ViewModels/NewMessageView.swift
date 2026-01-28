import SwiftUI
import Combine

class UserSearchViewModel: ObservableObject {
    @Published var usernames: [(id: String, username: String?)] = []
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var error: String?
    @Published var recentUserIds: [String] = [] {
        didSet {
            filterUsers()
        }
    }
    
    private let firebaseService = FirebaseMessage.shared
    private var searchDebouncer: AnyCancellable?
    
    init() {
        // Debounce the search text changes.
        searchDebouncer = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterUsers()
            }
        loadAllUsers()
    }
    
    // Full list of users from Firebase.
    private var allUsernames: [(id: String, username: String?)] = [] {
        didSet {
            filterUsers()
        }
    }
    
    func loadAllUsers() {
        isSearching = true
        print("🔄 Starting user load")
        
        firebaseService.getAllUsernames { [weak self] (users: [(id: String, username: String)]) in
            DispatchQueue.main.async {
                self?.allUsernames = users
                self?.isSearching = false
            }
        }
    }
    
    private func filterUsers() {
        if searchText.isEmpty {
            // When not searching, show users with recent selections first.
            let recentUsers = allUsernames.filter { recentUserIds.contains($0.id) }
            let otherUsers = allUsernames.filter { !recentUserIds.contains($0.id) }
            // Combine and limit to the top 10.
            usernames = Array((recentUsers + otherUsers).prefix(10))
        } else {
            // Filter users based on the search text.
            usernames = allUsernames.filter { user in
                guard let username = user.username else { return false }
                return username.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search by username", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
    }
}

struct UserRowView: View {
    let username: String
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
            Text("@\(username)")
                .foregroundColor(.primary)
                .padding(.leading, 8)
        }
    }
}

struct NewMessageView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UserSearchViewModel  // Injected view model
    @ObservedObject var messagesViewModel: MessagesViewModel
    var onUserSelected: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBarView(searchText: $viewModel.searchText)
                
                if viewModel.isSearching {
                    ProgressView().padding()
                } else if viewModel.usernames.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.usernames, id: \.id) { userId, username in
                            if let username = username {
                                Button {
                                    // Update the recent list:
                                    if let index = viewModel.recentUserIds.firstIndex(of: userId) {
                                        viewModel.recentUserIds.remove(at: index)
                                    }
                                    viewModel.recentUserIds.insert(userId, at: 0)
                                    
                                    onUserSelected(userId, username)
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    UserRowView(username: username)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("New Message")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
