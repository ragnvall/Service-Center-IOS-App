//
//  LimitedReviewsView.swift
//  Service Center
//
//  Created by Alan Lam on 2/25/25.
//

import SwiftUI

struct LimitedReviewsView: View {
    @State private var reviews: [Rating] = []
    @State private var isLoading = true
    @State private var error: Error? = nil
    private var username: String
    private var authManager = AuthManager.shared
    
    init(username: String) {
        self.username = username
    }
    
    var body: some View {
        VStack {
            Text("Reviews")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            if isLoading {
                ProgressView("Loading Reviews...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if let error = error {
                Text("Failed to load reviews: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                if reviews.isEmpty {
                    Text("No reviews available.")
                        .padding()
                } else {
                    // Display only up to the first 2 reviews
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(reviews.prefix(2), id: \.id) { review in
                                ReviewCardView(review: review)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    NavigationLink(destination: UserReviewsView(username: username)) {
                        Text("View All Reviews")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.top, -10)
                            .underline()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadReviews()
            }
        }
        .padding()
    }
    
    private func loadReviews() async {
        do {
            reviews = try await authManager.fetchUserReviews(username: username)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
