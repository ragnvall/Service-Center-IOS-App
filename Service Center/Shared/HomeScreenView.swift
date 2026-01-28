//
//  HomeScreenView.swift
//  Service Center
//
//  Created by Leo Ifrim on 2/6/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct HomeScreenView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var jobStatusManager = JobStatusManager()
    @StateObject private var authManager = AuthManager.shared // Added AuthManager
    @StateObject private var firebaseManager = FirebaseManager.shared // Added FirebaseManager
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showFilterMenu = false
    @State private var filteringHashTags :[String] = [] //Hashtags that should be applied to the search
    @State private var filteringLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @State private var filteringRange: Double = 20
    @State private var isFilteringLoc: Bool = true //if false, don't filter on location. Failsafe for if user location is not set, thus location is not set either
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // Safe area spacer for notch/status bar
                Color.clear
                    .frame(height: 0)
                    .background(Color(.systemBackground))
                    .padding(.top, 60)
                
                
                // Search bar
                HStack(spacing: 12) {
                    // Menu Button
                    // Search Field
                    HStack {
                        
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        TextField("Search Posts", text: $searchText)
                            .font(.system(size: 16))
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Filter Button
                    Button(action: {
                        showFilterMenu.toggle()
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Content area below search bar
                PostListView(jobStatusManager: jobStatusManager, searchText: searchText,
                             searchTags: filteringHashTags, searchLocation: filteringLocation, searchRange: filteringRange, isFilteringLoc: isFilteringLoc)
            }
            .edgesIgnoringSafeArea(.top) // Makes the view extend under the status bar
            FilterSideMenuView(isShowing: $showFilterMenu, filteringHashTags: $filteringHashTags, filteringLocation: $filteringLocation, filteringRange: $filteringRange)
        }
        .onAppear() {
            // Load posts with user ID for like status
            if let currentUserId = authManager.currentUser?.id {
                firebaseManager.loadPosts(currentUserId: currentUserId)
            } else {
                firebaseManager.loadPosts()
            }
            
            authViewModel.fetchCurrentUser { success in
                DispatchQueue.main.async {
                    if success, let profile = authViewModel.currentUser {
                        if let lat = profile.locationLat, let lng = profile.locationLng {
                            filteringLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                            //print("initial filtering location set to :\(String(describing: profile.locationLat)), \(String(describing: profile.locationLng))")
                            isFilteringLoc = true
                        } else {
                            print("nil loc(most likely user hasn't set location)")
                        }
                    } else {
                        print("Failed to fetch user(fetchCurrentUser)")
                    }
                }
            }
        }
    }
}

#Preview {
    HomeScreenView()
        .environmentObject(AuthViewModel())
}
