//
//  HashTagViewModel.swift
//  Service Center
//
//  Created by Kevin on 2/13/25.
//
///Stores hashtag information and add/remove functionality
import SwiftUI


class HashTagViewModel: ObservableObject {
    @Published var selectedHashTags: [String] = [] //Currently selected hashtags
    @Published var existingHashTags: [String] = [] //Hashtags that have been used before/are in default hashtagas
    @Published var defaultHashTags: [String] = ["Cleaning", "Electronics", "Automobiles", "Household"] //default hashtags, can add more simply by adding to this list and re rendering component
    
    //Note: in production, we would need to clear out the uniqueTags data(unless you want to keep every single tag already in there)
    //if hashTag is valid, add to list selectedHashTags
    func addHashTag(hashTag: String) {
        guard !hashTag.isEmpty else { return }
        print("appending hashtag \(hashTag)")
        selectedHashTags.append(hashTag)
    }
    //Remove hashTag from selectedHashTags
    func removeHashtag(hashTag: String) {
        selectedHashTags.removeAll { $0 == hashTag }
    }
}



