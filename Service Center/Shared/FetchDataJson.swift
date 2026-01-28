//
//  FetchDataJson.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import Foundation

struct Post: Codable, Identifiable {
    enum CodingKeys: CodingKey{
        case image
        case like_count
        case comment_count
        case view_count
        case description
        case profile_img
        case profile_name
        case profile_id
    }
    var id = UUID()
    var image: String
    var like_count: Int
    var comment_count: Int
    var view_count: Int
    var description: String
    var profile_img: String
    var profile_name: String
    var profile_id: String
}

class ReadJsonData: ObservableObject {
   @Published var posts = [Post]()
   
   init() {
       loadData()
   }
   
    func loadData() {
        
        // First try with explicit path
        guard let url = Bundle.main.url(forResource: "Posts", withExtension: "json") else {
            print("json file not found")
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Looking for Posts.json...")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let posts = try JSONDecoder().decode([Post].self, from: data)
            self.posts = posts
            //print("Successfully decoded \(posts.count) posts")
        } catch {
            print("Error: \(error)")
        }
    }
    
    
}
