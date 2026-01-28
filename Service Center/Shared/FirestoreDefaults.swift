//
//  FirestoreDefaults.swift
//  Service Center
//
//  Created by Robert Agnvall
//

import FirebaseFirestore

/// Injects default values into a Firestore data dictionary to ensure required keys are present for decoding.
/// This function adds defaults for keys that have previously caused issues:
/// - documentId: set to the snapshot’s documentID.
/// - jobRequests: an empty array if missing.
/// - isLikedByCurrentUser: false if missing.
/// - tags: an empty array if missing.
/// - like_count: 0 if missing.
/// - comment_count: 0 if missing.
/// - view_count: 0 if missing.
/// You can add further defaults as needed.
func injectDefaultValues(for data: [String: Any], snapshot: DocumentSnapshot) -> [String: Any] {
    var fixedData = data

    // Set documentId from snapshot if missing.
    if fixedData["documentId"] == nil {
        fixedData["documentId"] = snapshot.documentID
    }
    
    // Provide default empty array for jobRequests.
    if fixedData["jobRequests"] == nil {
        fixedData["jobRequests"] = [String]()
    }
    
    // Provide default false for isLikedByCurrentUser.
    if fixedData["isLikedByCurrentUser"] == nil {
        fixedData["isLikedByCurrentUser"] = false
    }
    
    // Provide default empty array for tags.
    if fixedData["tags"] == nil {
        fixedData["tags"] = [String]()
    }
    
    // Provide default numeric values if missing.
    if fixedData["like_count"] == nil {
        fixedData["like_count"] = 0
    }
    if fixedData["comment_count"] == nil {
        fixedData["comment_count"] = 0
    }
    if fixedData["view_count"] == nil {
        fixedData["view_count"] = 0
    }
    
    // You can add other defaults as needed.
    
    return fixedData
}
