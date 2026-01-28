// CreatePostView.swift
import SwiftUI
import UIKit
import os
import FirebaseAuth
import FirebaseFirestore

struct CreatePostView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var hashtagViewModel = HashTagViewModel()
    @StateObject private var authManager = AuthManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var locationManager = LocationManager()
    
    @Binding var selectedTab: Int
    
    @State private var selectedImage: UIImage?
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var price: String = ""
    @State private var timeUnit: String = "Per Hour"
    @State private var showingImagePicker = false
    @State private var isSubmitted: Bool = false  // Track if submit was attempted

    let timeUnits = ["Per Hour", "Per Day", "Per Service"]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Post Content") {
                    // Image selection button with validation
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Text(selectedImage == nil ? "Select Image" : "Change Image")
                            Spacer()
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                            }
                        }
                    }
                    if isSubmitted && selectedImage == nil {
                        Text("Image is required.")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, -20)
                    }
                    
                    // Title input with validation
                    TextField("Title", text: $title)
                        .foregroundColor(title.isEmpty && isSubmitted ? .red : .primary)
                    if isSubmitted && title.isEmpty {
                        Text("Title is required.")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, -20)
                    }
                    
                    // Description input with validation
                    TextField("Describe your service (min. 20 words)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(description.isEmpty && isSubmitted ? .red : .primary)
                    if isSubmitted && description.isEmpty {
                        Text("Description is required.")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, -25)
                    }
                    
                    // Price input with time unit
                    HStack {
                        Text("$")
                        TextField("Price", text: $price)
                            .keyboardType(.numberPad)
                        
                        Picker("", selection: $timeUnit) {
                            ForEach(timeUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    
                    // Tags selection
                    HashTagMenuView(viewModel: hashtagViewModel)
                }
                
                Section("Post location") {
                    VStack {
                        AnyView(LocationSelectView(locationManager: locationManager))
                            .frame(maxWidth:.infinity, alignment: .leading)
                            .listRowInsets(EdgeInsets())
                    }.frame(minWidth: 300, maxWidth:.infinity, minHeight: 300, alignment: .leading)
                }
                
                // Post button
                Section {
                    Button {
                        isSubmitted = true  // Mark the submission attempt
                        createPost()
                    } label: {
                        Text("Create Post")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.black)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PHPickerView(image: $selectedImage)
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if authManager.currentUser == nil {
                    try? await authManager.refreshCurrentUser()
                }
            }
            .onAppear {
                // Reset the error validation state when the view appears
                resetFields()
                isSubmitted = false  // Reset submission state to hide the error text
                
                firebaseManager.updateUniqueTags(newTags: hashtagViewModel.defaultHashTags) { success in
                    if success {
                        print("unique tags updated on view load")
                    }
                }
                
                firebaseManager.fetchUniqueTags { uniqueTags in
                    hashtagViewModel.existingHashTags = uniqueTags
                }
            }
        }
    }
    
    func resetFields() {
        selectedImage = nil
        title = ""
        description = ""
        price = ""
        timeUnit = "Per Hour"
        hashtagViewModel.selectedHashTags.removeAll()
    }

    func createPost() {
        // Check if title, description, or image is empty and show error messages
        if title.isEmpty || description.isEmpty || selectedImage == nil {
            return  // Do nothing if fields are empty (error messages will show)
        }
        
        guard authManager.isAuthenticated else {
            print("No user session - please log in")
            return
        }
        guard let image = selectedImage else {
            print("No image selected")
            return
        }
        guard let currentUser = authManager.getCurrentUser() else {
            print("No current user found")
            return
        }
        
        print("Starting image upload...")
        firebaseManager.uploadImage(image) { imageUrl in
            guard let imageUrl = imageUrl else {
                print("Failed to get image URL")
                return
            }
            
            print("Image uploaded successfully: \(imageUrl)")
            
            let newPost = PostCardData(
                documentId: UUID().uuidString,
                profile_img: "",
                profile_name: currentUser.fullname,
                title: title,
                profile_id: currentUser.username,
                image: imageUrl,
                like_count: 0,
                comment_count: 0,
                view_count: 0,
                description: description,
                price: price,
                timeUnit: timeUnit,
                tags: hashtagViewModel.selectedHashTags,
                jobStatus: "Open",
                jobRequests: [],
                locationLat: locationManager.location!.latitude,
                locationLng: locationManager.location!.longitude,
                neighborhood: locationManager.neighborhood ?? "",
                city: locationManager.city ?? "",
                dateCreated: Date()
            )
            
            firebaseManager.savePost(newPost)
            incrementPostsCreatedForCurrentUser()
            
            firebaseManager.updateUniqueTags(newTags: hashtagViewModel.selectedHashTags) { success in
                DispatchQueue.main.async {
                    if success {
                        selectedTab = 0
                        dismiss()
                    } else {
                        print("unique tags failed to update")
                    }
                }
            }
        }
    }
    
    func incrementPostsCreatedForCurrentUser() {
        guard let currentUser = authManager.getCurrentUser() else {
            print("No current user found")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(currentUser.id)
        
        userRef.updateData([
            "postsCreated": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error incrementing postsCreated: \(error.localizedDescription)")
            } else {
                print("postsCreated incremented successfully")
            }
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView(selectedTab: .constant(0))
            .environmentObject(AuthViewModel())
    }
}
