import Foundation

struct Rating: Codable {
    var id = UUID()
    var stars: Int
    var review: String
    var reviewer: String
    var job: String
    var reviewTitle: String
    var date: Date
}

struct User: Identifiable, Codable {
    let profile_pic: String
    let id: String
    let fullname: String
    let email: String
    let description: String
    let locationLat: Double?
    let locationLng: Double?
    let username: String // Added username field
    let skills: [String] // Added skills field
    var ratings: [Rating]?
    var postsCreated: Int?
    var reviewsCreated: Int?

    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}
