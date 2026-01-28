//
//  OtherUserProfileView.swift
//  Service Center
//
//  Created by Alan Lam on 2/7/25.
//

import SwiftUI
import FirebaseFirestore

struct OtherUserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    private let db: Firestore
    var user: User  // The user whose profile we're viewing
    
    // New state variables to hold posts and reviews counts
    @State private var postsCreated: Int = 0
    @State private var reviewsCreated: Int = 0
    
    init(db: Firestore, user: User) {
        self.db = db
        self.user = user
    }
    
    // Fetch user data to update postsCreated and reviewsCreated
    func loadUserStats() {
        db.collection("users").document(user.id).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                // Fetching postsCreated and reviewsCreated from Firestore
                DispatchQueue.main.async {
                    self.postsCreated = data["postsCreated"] as? Int ?? 0
                    self.reviewsCreated = data["reviewsCreated"] as? Int ?? 0
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    // Header Image and Profile Content
                    ZStack {
                        HStack {
                            VStack {
                                // Profile Image
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        // Action for following, messaging, etc.
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                }
                                .padding(.top, 30)
                                .padding(.trailing, 20)
                                
                                // Using AsyncImage to load the profile image
                                AsyncImage(url: URL(string: user.profile_pic)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                        .shadow(radius: 5)
                                } placeholder: {
                                    // Fallback image while loading or if profile_pic is missing
                                    if user.profile_pic.isEmpty || user.profile_pic == "default_url_or_empty_string" {
                                        Image(systemName: "person.circle.fill") // Default system image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                            .shadow(radius: 5)
                                    } else {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .frame(width: 100, height: 100)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    // Username, Location, and Description
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(user.fullname)")
                                .font(.title2)
                                .bold()
                        }.padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.gray)
                            Text("Unknown Location")  // Change to real location if available
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            VStack {
                                Text("Description:")
                                    .font(.title2)
                                    .bold()
                                    .padding(.top, 45)
                                
                                Text("\(user.description)")
                                    .font(.title2)
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                            }
                        }.padding(.horizontal)
                    }
                    
                    // Stats (hardcoded or dynamic from Firestore)
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(postsCreated)")
                                .font(.title2)
                                .bold()
                            Text("Posts Created")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("\(reviewsCreated)")
                                .font(.title2)
                                .bold()
                            Text("Reviews Given")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical)
                    
                    // Replace vertical posts with horizontal scrollable posts view
                    UserPostsHorizontalView(jobStatusManager: JobStatusManager(), locationManager: LocationManager(), username: user.username)
                    
                    LimitedReviewsView(username: user.username)
                    
                    Spacer()
                }
            }
            .onAppear {
                loadUserStats() // Fetch stats when the view appears
            }
        }
        .navigationViewStyle(.stack)
        .edgesIgnoringSafeArea(.top)
    }
}

struct OtherUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(
            profile_pic: "https://c02.purpledshub.com/uploads/sites/40/2023/08/JI230816Cosmos220-6d9254f-edited-scaled.jpg",
            id: "123",
            fullname: "John Doe",
            email: "johndoe@gmail.com",
            description: "iOS Developer",
            locationLat: 0.0,
            locationLng: 0.0,
            username: "johndoe",
            skills: []
        )
        
        return OtherUserProfileView(db: Firestore.firestore(), user: mockUser)
            .environmentObject(AuthViewModel()) // Provide the environment object for AuthViewModel
    }
}
