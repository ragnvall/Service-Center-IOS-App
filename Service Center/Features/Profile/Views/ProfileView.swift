//
//  ProfileView.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/29/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var curImage: UIImage?
    @ObservedObject var jobStatusManager: JobStatusManager
    @ObservedObject var locationManager: LocationManager
    private let defaultImage = UIImage(systemName: "person.circle.fill")
    @State private var skills: [String] = []
    @State private var curName: String = ""
    @State private var curDescr: String = ""
    private let db: Firestore

    init(db: Firestore, jobStatusManager: JobStatusManager, locationManager: LocationManager) {
        self.db = db
        self._jobStatusManager = ObservedObject(wrappedValue: jobStatusManager)  // Injected here
        self._locationManager = ObservedObject(wrappedValue: locationManager)  // Injected here
    }
    
    func updateLocation(completion: @escaping () -> Void) {
        print("Update profile location")
        authViewModel.fetchCurrentUser { success in
            DispatchQueue.main.async {
                if success {
                    print("Success: users fetched for location")
                    if let profile = authViewModel.currentUser {
                        locationManager.location = CLLocationCoordinate2D(latitude: profile.locationLat ?? -1, longitude: profile.locationLng ?? -1)
                        print("Fetched location")
                        completion()
                    } else {
                        print("Failed to fetch user in settingsview")
                    }
                }
            }
        }
    }

    func updateProfileImage() {
        authViewModel.fetchCurrentUser { success in
            DispatchQueue.main.async {
                if success, let profile = authViewModel.currentUser,
                   let imgURL = URL(string: profile.profile_pic) {
                    DispatchQueue.global(qos: .background).async {
                        if let data = try? Data(contentsOf: imgURL),
                           let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                curImage = image
                            }
                        } else {
                            DispatchQueue.main.async {
                                curImage = self.defaultImage
                            }
                        }
                    }
                }
            }
        }
    }

    func loadSkills() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let data = snapshot?.data(), let fetchedSkills = data["skills"] as? [String] {
                DispatchQueue.main.async {
                    self.skills = fetchedSkills
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if let profile = authViewModel.currentUser {
                    VStack(spacing: 10) {
                        // Profile Image & Settings Button
                        HStack {
                            Spacer()
                            NavigationLink(destination: SettingsView(locationManager: locationManager, curName: $curName, curDescr: $curDescr, selectedImage: $curImage, db: db)) {
                                Image(systemName: "gearshape")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }

                        // Profile Picture
                        VStack {
                            if let image = curImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(Circle())
                            }
                        }

                        // Name & Location
                        Text(profile.fullname)
                            .font(.title2)
                            .bold()

                        VStack {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.gray)
                                Text(locationManager.neighborhood ?? "Neighborhood Unknown")
                                    .foregroundColor(.gray)
                            }
                            Text(locationManager.city ?? "Unknown city")
                                .foregroundColor(.gray)
                        }

                        // Description
                        VStack(alignment: .leading) {
                            Text("About Me")
                                .font(.headline)
                            Text(profile.description)
                                .font(.body)
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        }
                        .padding(.horizontal)

                        // Stats Section
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(profile.postsCreated ?? 0)")
                                    .font(.title2)
                                    .bold()
                                Text("Posts Created")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            VStack {
                                Text("\(profile.reviewsCreated ?? 0)")
                                    .font(.title2)
                                    .bold()
                                Text("Reviews Given")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical)

                        // Skills Section
                        VStack(alignment: .leading) {
                            Text("Skills")
                                .font(.headline)

                            // Display first 3 skills as blue bubble-style tags
                            HStack {
                                ForEach(skills.prefix(3), id: \.self) { skill in
                                    Text(skill)
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.blue))
                                }
                            }

                            // View More Button (if there are more than 3 skills)
                            if skills.count > 3 {
                                NavigationLink(destination: SkillsPageView(skills: skills)) {
                                    Text("View \(skills.count - 3)+ more...")
                                        .font(.footnote)
                                        .foregroundColor(.blue)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Use UserPostsHorizontalView for horizontal scrolling of posts
                        UserPostsHorizontalView(jobStatusManager: jobStatusManager, locationManager: locationManager, username: profile.username)
                            .padding(.vertical)

                        LimitedReviewsView(username: profile.username)

                        // Sign Out Button
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            Text("Sign Out")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .onAppear {
                        curName = profile.fullname
                        curDescr = profile.description
                    }
                } else {
                    Text("Profile loading...")
                }
            }
            .onAppear {
                updateLocation() {
                    locationManager.getAreaFromCoords() { Neighborhood, City, PostalCode in
                        print("neighborhood: \(Neighborhood ?? "") city: \(City ?? "")")
                    }
                }
                updateProfileImage()
                authViewModel.fetchCurrentUser { success in
                    if success {
                        firebaseManager.loadPosts()
                        loadSkills()
                    }
                }
            }
        }
    }
}

#Preview {
    let dummyJobStatusManager = JobStatusManager()
    let dummyLocationManager = LocationManager()
    let db = Firestore.firestore() // Use actual Firestore instance or a mock
    let mockUser = User(profile_pic: "https://example.com/sample-profile.jpg", id: "123", fullname: "John Doe", email: "johndoe@example.com", description: "iOS Developer", locationLat: 37.7749, locationLng: -122.4194, username: "johndoe", skills: ["Swift", "Xcode", "Firebase"])

    let mockAuthViewModel = AuthViewModel()
    mockAuthViewModel.currentUser = mockUser

    return ProfileView(db: db, jobStatusManager: dummyJobStatusManager, locationManager: dummyLocationManager)
        .environmentObject(mockAuthViewModel) // Provide the mock AuthViewModel
}
