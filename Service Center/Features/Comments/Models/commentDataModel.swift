//
//  commentDataModel.swift
//  Service Center
//
//  Created by Robert Agnvall on 3/4/25.
//

import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    var id: String = UUID().uuidString
    let postId: String?           // For top-level comments, set this to the post’s ID
    let parentCommentId: String?  // nil for top-level comments; non‑nil for replies
    let userId: String
    let username: String
    let text: String
    let timestamp: Date
}

