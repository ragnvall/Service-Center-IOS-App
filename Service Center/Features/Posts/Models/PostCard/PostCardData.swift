//
//  PostCardData.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/21/25.
//
import Foundation

// Data model that represents a post
struct PostCardData: Identifiable, Codable {
    // Post properties matching Firebase data structure
    var documentId: String
    let profile_img: String    // URL or name of profile image
    let profile_name: String   // Name of the post creator
    let title: String          // Title of post
    let profile_id: String     // Unique ID of the post creator
    let image: String          // URL or name of post image
    var imageUrls: [String]?   // Additional image URLs for multiple images
    var like_count: Int        // Number of likes (changed to var)
    let comment_count: Int     // Number of comments
    let view_count: Int        // Number of views
    let description: String    // Post description/caption
    var price: String?         // Price of the service
    var timeUnit: String?      // Time unit (Per Hour, Per Day, No Time)
    let tags: [String]
    var jobStatus: String      // Job status (e.g., "In Progress", "Accepted", "Completed")
    var jobRequests: [String]  // List of users who requested the job
    var acceptedRequest: String? // User who accepted the job, if any
    let locationLat: Double
    let locationLng: Double
    let neighborhood: String
    let city: String
    var isLikedByCurrentUser: Bool = false  //track like status
    let dateCreated: Date
    
    var id: String {
        return documentId
    }
}
