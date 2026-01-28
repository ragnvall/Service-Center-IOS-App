//
//  PostListView.swift
//  Service Center
//
//  Created by Robert Agnvall on 1/18/25.
//

import SwiftUI
import MapKit
import Foundation

func pointWithinRange(searchPoint: CLLocationCoordinate2D, lat: Double, long: Double, range: Double) -> Bool{
    let point = CLLocation(latitude: lat, longitude: long)
    let curLocationRef = CLLocation(latitude: searchPoint.latitude, longitude: searchPoint.longitude)
    var rangeInMiles = Measurement(value: range, unit: UnitLength.miles)
    var rangeInMeters = rangeInMiles.converted(to: UnitLength.meters).value
    if (curLocationRef.distance(from: point) <= rangeInMeters) {
        print("Post matched")
        print(curLocationRef.distance(from: point))
    }
    else {
        print(curLocationRef.distance(from: point))
    }
    return curLocationRef.distance(from: point) <= rangeInMeters
    
}

struct PostListView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var authManager = AuthManager.shared // Added AuthManager
    @State private var showingCreatePost = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var jobStatusManager: JobStatusManager
    let searchText: String
    let searchTags: [String]
    let searchLocation: CLLocationCoordinate2D
    let searchRange: Double
    let isFilteringLoc: Bool
    @State private var scrollToTopID = UUID() // Unique ID to trigger scrollTo action

    var filteredPosts: [PostCardData] {
        
        firebaseManager.posts.filter { post in
                let matchesText = searchText.isEmpty || post.title.localizedCaseInsensitiveContains(searchText)
                let matchesTags = searchTags.isEmpty || post.tags.contains { searchTags.contains($0) }
                let matchesLoc = !isFilteringLoc || pointWithinRange(searchPoint: searchLocation, lat: post.locationLat, long: post.locationLng, range: searchRange)
            return matchesText && matchesTags && matchesLoc
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    // Add a dummy view with the scrollToTopID at the top of the list
                    Color.clear.frame(height: 0).id(scrollToTopID)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPosts) { postData in
                            @State var jobStatus = postData.jobStatus
                            PostCard(data: postData, jobStatus: $jobStatus)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                //.aspectRatio(contentMode: .fill)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    if let currentUserId = authManager.currentUser?.id {
                        firebaseManager.loadPosts(currentUserId: currentUserId)
                    } else {
                        firebaseManager.loadPosts()
                    }
                }
                .onAppear {
                    // Load posts with user ID when view appears
                    if let currentUserId = authManager.currentUser?.id {
                        firebaseManager.loadPosts(currentUserId: currentUserId)
                    } else {
                        firebaseManager.loadPosts()
                    }
                }
                .overlay(
                    Button(action: {
                        withAnimation {
                            proxy.scrollTo(scrollToTopID, anchor: .top)
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Circle().fill(Color.white).shadow(radius: 5))
                            .padding(.bottom, 16)
                            .padding(.trailing, 20)
                    },
                    alignment: .bottomTrailing
                )
            }
        }
    }
}

struct PostListView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyJobStatusManager = JobStatusManager()
        PostListView(jobStatusManager: dummyJobStatusManager, searchText: "", searchTags: [], searchLocation: CLLocationCoordinate2D(latitude: 1, longitude: 1), searchRange: 20, isFilteringLoc: true)
            .environmentObject(AuthViewModel())
    }
}
