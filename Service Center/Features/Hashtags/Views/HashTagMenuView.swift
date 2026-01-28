//
//  HashTagMenuView.swift
//  Service Center
//
//  Created by Kevin on 2/13/25.
//
///View displays interface for adding/removing hashTags to a parent view.
///Consists of:
///Hashtag display: list of selected hashtags, with option to remove individual hashtags
///Hashtag search: search for hashtags in firestore currently, or allows users to create new hashtags to add to hashtag list

import SwiftUI

struct HashTagMenuView: View {
    @StateObject var viewModel: HashTagViewModel //Instance of hashTag Viewmodel to store selected hashtags, add/remove hashtags
    @State private var curHashTag: String = ""
    @State private var isPressing: String? = nil
    //filteredSuggestions: given curHashTag, return list ofsuggestions that could fit that
    var filteredSuggestions: [String] {
        guard !curHashTag.isEmpty else {return []}
        let filtered = viewModel.existingHashTags.filter {
            $0.lowercased().contains(curHashTag.lowercased())
        }
        return filtered
    }
    
    var body: some View {
        ScrollView {
            VStack {
                FlexibleStack(spacing : 10, alignment: .leading) {
                    ForEach(viewModel.selectedHashTags, id : \.self) {tag in
                        TagView(tag: tag, color: .blue, icon: "xmark.circle.fill") {
                            viewModel.removeHashtag(hashTag: tag)
                        }
                    }
                }.frame(minHeight: 50)
                Divider()
            
                // Hashtag input
                VStack {
                    HStack {
                        
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        TextField("Hashtags", text: $curHashTag)
                            .font(.system(size: 16))
                            .lineLimit(3...6)
                            .onSubmit {
                                viewModel.addHashTag(hashTag: curHashTag)
                                print("\(viewModel.selectedHashTags)")
                                curHashTag = ""
                            }
                        
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    
                    if (!filteredSuggestions.isEmpty) {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(filteredSuggestions.prefix(4).indices, id: \.self) { index in
                                    if index > 0 {Divider()}
                                    let suggestion = filteredSuggestions[index]
                                    HStack {
                                        Text("#\(suggestion)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 8)
                                    }
                                    .background(isPressing == suggestion ? Color.gray.opacity(0.3) : Color.clear)
                                    
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged {_ in
                                                self.isPressing = suggestion
                                            }
                                            .onEnded { _ in
                                                viewModel.addHashTag(hashTag: suggestion)
                                                curHashTag = ""
                                                self.isPressing = nil
                                            }
                                    )
                                    
                                }
                            }
                            .frame(maxHeight: 200)
                            
                        }
                    }
                }
            }
        }
    }
}

struct HashTagMenuView_Previews: PreviewProvider {
    static var previews: some View {
        HashTagMenuView(viewModel: HashTagViewModel())
            .previewLayout(.sizeThatFits) // This lets the preview fit the content
            .padding()
    }
}


