import FirebaseFirestore
import PhotosUI
import SwiftUI
import os
import MapKit

struct SettingsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var locationManager: LocationManager
    @StateObject var profileViewModel: ProfileViewModel
    /// Binding vars passed in
    @Binding var curName: String
    @Binding var selectedImage: UIImage?
    @Binding var curDescr: String
    
    @State private var nameEdited: Bool = false
    @State private var profilePicEdited: Bool = true
    @State private var descrEdited: Bool = false
    @State private var showingImagePicker = false
    @State private var showingSavedPosts = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var newSkill: String = ""
    @State private var skills: [String] = []
    private let defaultImage = UIImage(systemName: "person.circle.fill")
    ///Location vars
    @State private var curLocationName: String = ""
    @State private var neighborhood: String? = ""
    @State private var city: String? = ""
    @State private var postalCode: String? = ""
    
    let logger = Logger()
    private let db: Firestore
    

    init(locationManager: LocationManager, curName: Binding<String>, curDescr: Binding<String>, selectedImage: Binding<UIImage?>, db: Firestore) {
        self.locationManager = locationManager
        self._curName = curName
        self._selectedImage = selectedImage
        //self._curLocation = curLocation
        self._curDescr = curDescr
        self.db = db
        let authViewModel = AuthViewModel()
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: authViewModel, db: db))
    }

    func uploadProfileImage(uid: String) {
        guard let image = selectedImage else {
            print("No image selected")
            return
        }
        firebaseManager.uploadImage(image) { imageUrl in
            guard let imageUrl = imageUrl else {
                print("Failed to get image URL")
                return
            }
            Task {
                await profileViewModel.modifyUserProfile(field: "profile_pic", newVal: imageUrl, uid: uid)
            }
        }
    }

    func loadSkills() {
        guard let userID = authViewModel.currentUser?.id else { return }
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let data = snapshot?.data(), let fetchedSkills = data["skills"] as? [String] {
                DispatchQueue.main.async {
                    self.skills = fetchedSkills
                }
            }
        }
    }

    func addSkill() {
        guard !newSkill.isEmpty, let userID = authViewModel.currentUser?.id else { return }
        let trimmedSkill = newSkill.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if skills.map({ $0.lowercased() }).contains(trimmedSkill) {
            return // Skill already exists, do nothing
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData([
            "skills": FieldValue.arrayUnion([newSkill])
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.skills.append(newSkill)
                    self.newSkill = ""
                }
            }
        }
    }

    func editSkill(at index: Int, newValue: String) {
        guard let userID = authViewModel.currentUser?.id else { return }
        let userRef = db.collection("users").document(userID)
        
        var updatedSkills = skills
        updatedSkills[index] = newValue

        userRef.updateData(["skills": updatedSkills]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.skills = updatedSkills
                }
            }
        }
    }

    func deleteSkill(at index: Int) {
        guard let userID = authViewModel.currentUser?.id else { return }
        let userRef = db.collection("users").document(userID)

        let skillToRemove = skills[index]
        userRef.updateData([
            "skills": FieldValue.arrayRemove([skillToRemove])
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.skills.remove(at: index)
                }
            }
        }
    }

    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
                .bold()
                .padding(.top, 10)
            if let profile = authViewModel.currentUser {
                Form {
                    // Saved Posts Section
                    Section {
                        Button(action: {
                            showingSavedPosts = true
                        }) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.blue)
                                Text("Saved Posts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Section(header: Text("Profile Picture").font(.title3)) {
                        Button(action: { showingImagePicker = true }) {
                            VStack {
                                Text(selectedImage == nil ? "Select Image" : "Change Image")
                                Spacer()
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        Button(action: {
                            logger.info("Profile change submit tapped")
                            uploadProfileImage(uid: profile.id)
                        }) {
                            Text("Save new profile picture")
                                .font(.headline)
                                .frame(width: 200, height: 10)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }

                    Section(header: Text("User location").font(.title3)) {
                        VStack {
                            AnyView(LocationSelectView(locationManager: locationManager) {newLocation in
                                print("updating location in firestore now")
                                Task {
                                    await profileViewModel.modifyUserProfile(field: "locationLat", newVal: newLocation?.latitude ?? -1, uid: profile.id)
                                    await profileViewModel.modifyUserProfile(field: "locationLng", newVal: newLocation?.longitude ?? -1, uid: profile.id)
                                }
                            })
                                .frame(maxWidth:.infinity, alignment: .leading)
                                .listRowInsets(EdgeInsets())
                            Spacer()
                        }.frame(minWidth: 300, maxWidth:.infinity, minHeight: 300, alignment: .leading)
                    }

                    Section(header: Text("Personal Information").font(.title3)) {
                        TextField("Enter full name", text: $curName)
                            .font(.title3)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                            .onChange(of: curName) {
                                nameEdited = true
                            }

                        TextField("Enter Description", text: $curDescr, axis: .vertical)
                            .font(.title2)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                            .onChange(of: curDescr) {
                                descrEdited = true
                            }

                        Button(action: {
                            Task {
                                if nameEdited {
                                    await profileViewModel.modifyUserProfile(field: "fullname", newVal: curName, uid: profile.id)
                                }
                                if descrEdited {
                                    await profileViewModel.modifyUserProfile(field: "description", newVal: curDescr, uid: profile.id)
                                }
                            }
                        }) {
                            Text("Save changes")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }

                    // Skills Section
                    Section(header: Text("Skills").font(.title3)) {
                        HStack {
                            TextField("Add a new skill", text: $newSkill)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: addSkill) {
                                Text("Add")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        List {
                            ForEach(skills.indices, id: \.self) { index in
                                HStack {
                                    TextField("Skill", text: $skills[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onSubmit {
                                            editSkill(at: index, newValue: skills[index])
                                        }
                                    Button(action: { deleteSkill(at: index) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    PHPickerView(image: $selectedImage)
                }
                .onAppear {
                    loadSkills()
                }
                .sheet(isPresented: $showingSavedPosts) {
                    // Wrap in NavigationView to provide navigation context within the sheet
                    NavigationView {
                        SavedPostsSheetView()
                            .environmentObject(authViewModel)
                            .navigationTitle("Saved Posts")
                            .navigationBarItems(trailing: Button("Done") {
                                showingSavedPosts = false
                            })
                    }
                }
            }
        }
    }
}
