import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var jobStatusManager = JobStatusManager()
    @StateObject var locationManager = LocationManager()
    @State private var selectedTab = 0
    let db = Firestore.firestore()

    var body: some View {
        VStack {
            if authViewModel.userSession != nil {
                // Check if onboarding is completed
                if authViewModel.isNewUser && !authViewModel.hasCompletedOnboarding {
                    // ✅ Show OnboardingView only for new users
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else {
                    TabView(selection: $selectedTab) {
                        HomeView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                            .tabItem {
                                Label("Messages", systemImage: "bubble.left.fill")
                            }
                            .tag(1)
                        
                        HomeScreenView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                            .tabItem({
                                Label("Home", systemImage: "house")
                            })
                            .tag(0)
                        CreatePostView(selectedTab: $selectedTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                            .tabItem {
                                Label("Posts", systemImage: "plus.circle")
                            }
                            .tag(2)
                        
                        ProfileView(db: db, jobStatusManager: jobStatusManager, locationManager: locationManager)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                            .tabItem {
                                Label("Profile", systemImage: "person.crop.circle")
                            }
                            .tag(3)
                    }
                }
            } else {
                // If the user is not logged in, show the LoginView
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            // When ContentView appears, try to fetch the current user
            authViewModel.fetchCurrentUser { success in
                if success {
                    print("Successfully fetched user.")
                } else {
                    print("Failed to fetch user.")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
