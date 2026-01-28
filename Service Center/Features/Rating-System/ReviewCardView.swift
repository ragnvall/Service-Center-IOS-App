//
//  ReviewCardView.swift
//  Service Center
//
//  Created by Alan Lam on 2/25/25.
//


import SwiftUI

struct ReviewCardView: View {
    var review: Rating
    @StateObject private var authManager = AuthManager.shared
    @State private var reviewer: User?  // Changed from `user` to `reviewer`

    // Helper function to format the date
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    // Fetch reviewer data
    private func fetchReviewerData() {
        Task {
            do {
                // Fetch user by the reviewer username
                reviewer = try await authManager.fetchUserByUsername(username: review.reviewer)
            } catch {
                print("Error fetching reviewer data: \(error)")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // First row: Profile pic and full name
            HStack(spacing: 15) {
                // Profile pic (use a placeholder if nil)
                if let reviewer = reviewer, let url = URL(string: reviewer.profile_pic), !reviewer.profile_pic.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable()
                             .scaledToFill()
                             .frame(width: 40, height: 40)
                             .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                } else {
                    // Placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                }
                
                // Full name
                if let reviewer = reviewer {
                    Text(reviewer.fullname)
                        .font(.headline)
                        .lineLimit(1)
                }
            }
            .padding(.bottom, 5)
            .onAppear {
                fetchReviewerData() // Fetch reviewer when the view appears
            }
            
            // Second row: Stars and review header
            HStack {
                // Rating stars
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < review.stars ? "star.fill" : "star")
                            .foregroundColor(index < review.stars ? .yellow : .gray)
                    }
                }
                
                Text(review.reviewTitle)
                    .fontWeight(.bold)
                    .lineLimit(1)
            }
            .padding(.bottom, 5)
            
            // Third row: Review Date
            Text("Reviewed on \(formattedDate(date: review.date))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 5)
            
            // Fourth row: Review text
            Text(review.review)
                .font(.body)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .padding(.bottom, 10)
    }
}
