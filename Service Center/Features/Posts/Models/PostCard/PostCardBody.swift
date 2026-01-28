//
//  PostCardBody.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import SwiftUI

struct PostCardBody: View {
    let post_image_name: String
    var imageUrls: [String]?
    @Binding var like_count: Int  // Changed to binding
    let comment_count: Int
    let view_count: Int
    let description: String
    var price: String?
    var timeUnit: String?
    let tags: [String]
    let locationLat: Double
    let locationLng: Double
    let neighborhood: String
    let city: String
    let postId: String  // Added postId
    @Binding var isLiked: Bool  // Added binding for like status
    let onLikeToggle: () -> Void  // Added callback for like button tap
    
    @State private var currentImageIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Changed spacing to 0 for tight UI
            // Image section with pagination if multiple images
            ZStack(alignment: .bottom) {
                if let imageUrls = imageUrls, !imageUrls.isEmpty {
                    // If we have multiple images
                    TabView(selection: $currentImageIndex) {
                        // Main image
                        imageView(urlString: post_image_name)
                            .tag(0)
                        
                        // Additional images
                        ForEach(imageUrls.indices, id: \.self) { index in
                            imageView(urlString: imageUrls[index])
                                .tag(index + 1)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 200)
                    
                    // Image counter indicator
                    if (imageUrls.count > 0) {
                        HStack {
                            Spacer()
                            Text("\(currentImageIndex + 1)/\(imageUrls.count + 1)")
                                .font(.caption)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(8)
                        }
                    }
                } else {
                    // Single image display (original behavior)
                    imageView(urlString: post_image_name)
                        .frame(height: 200)
                }
            }
            
            // Description section
            Text(description)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
            
            // Hashtags displayed
            FlexibleStack (spacing : 10, alignment: .center) {
                ForEach(tags, id : \.self) {tag in
                    HStack (spacing: 10) {
                        Text("#\(tag)")
                        //Future feature, on click tag takes you to a search that filters by that tag
                    }
                    .frame(height: 35)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 15)
                    .background {
                        Capsule()
                            .fill(.blue)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
            
            // Interaction bar with price
            HStack {
                Button(action: {
                    onLikeToggle()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .white)
                        Text(like_count.formattedString())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "text.bubble")
                    Text(comment_count.formattedString())
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "eye")
                    Text(view_count.formattedString())
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Display price with time unit if available
                if let price = price, !price.isEmpty {
                    HStack(spacing: 3) {
                        Text("$\(price)")
                            .bold()
                        if let timeUnit = timeUnit, timeUnit != "Per Service" {
                            Text(timeUnit == "Per Hour" ? "/hr" : "/day")
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Fallback to the hardcoded value if no price is set
                    Text("No Price")
                        .bold()
                        .padding(.horizontal)
                }
            }
            .font(.callout)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.8))
        }
        .shadow(radius: 5)
    }
    
    // Helper function to create image views
    private func imageView(urlString: String) -> some View {
        // Calculate a fixed width (adjust the padding as needed)
        let width = UIScreen.main.bounds.width - 40

        return AsyncImage(url: URL(string: urlString)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 200)
                    .clipped()
            } else if phase.error != nil {
                // Display a failure image
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 200)
                    .clipped()
            } else {
                // Placeholder while loading
                ZStack {
                    Color.gray.opacity(0.3)
                    ProgressView()
                }
                .frame(width: width, height: 200)
            }
        }
    }


    
    // Preview provider with the updated parameters
    struct PostCardBody_Previews: PreviewProvider {
        static var previews: some View {
            PostCardBody(
                post_image_name: "example_image",
                imageUrls: ["example_image2", "example_image3"],
                like_count: .constant(120),  // Using constant binding for preview
                comment_count: 45,
                view_count: 1000,
                description: "This is a sample post description.",
                price: "85",
                timeUnit: "Per Hour",
                tags: ["SwiftUI", "iOS", "App Development"],
                locationLat: 0.0,
                locationLng: 0.0,
                neighborhood: "Queens",
                city: "New York",
                postId: "sample-id",
                isLiked: .constant(false),  // Using constant binding for preview
                onLikeToggle: {}  // Empty closure for preview
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
