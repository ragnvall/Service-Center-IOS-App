//
//  ProfileViewModel.swift
//  Service Center
//
//  Created by Kevin on 1/28/25
//
//Roles:

import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable {
    var id: String
    let fullname: String
    let description: String
}

final class ProfileViewModel: ObservableObject {
    //Workflow:
    //In contentView: no need to pass in user id, as:
    //We will have a condition check in content view
    //So if profileview is accessed, it means that loadUserProfile will return a user
    //ProfileView instantiates a ProfileViewModel, passing the uid
    //Profile view: displays profile
    //If not loaded, call ProfileViewModel's function fetchProfile, which
    @Published var userProfile: User?
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let authViewModel: AuthViewModel
    private let db: Firestore

    init(authViewModel: AuthViewModel, db: Firestore) {
        self.authViewModel = authViewModel
        self.db = db
    }
    
    
    
    
    // Modify user profile field in Firestore
    func modifyUserProfile<T>(field: String, newVal: T, uid: String) async {
        let userRef = db.collection("users").document(uid)
        do {
            try await userRef.updateData([
                field : newVal
            ])
            print("1. \(field) Field updated: \(newVal)")
            try await userRef.updateData([field : newVal])
            print("Field updated")
        } catch {
            print("Error updating field: \(error)")
        }
    }
}
