//
//  FilterSideMenuView.swift
//  Service Center
//
//  Created by Kevin on 2/13/25.
//
///View displays a side menu for filtering posts in HomeScreenView

import SwiftUI
import MapKit

struct FilterSideMenuView: View {
    @Binding var isShowing: Bool //determines whether menu is showoing
    @Binding var filteringHashTags: [String] //The hashtags that should be applied to search
    @Binding var filteringLocation: CLLocationCoordinate2D //Location tha tshould be applied to search
    @Binding var filteringRange: Double //Distance from location that should be included in search
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var hashtagViewModel = HashTagViewModel()
    @StateObject private var locationManager = LocationManager()
    //On load of the view, load into selectedHashTags the already selected hashtags in the parent view
    
    @State var selectedFilterType: FilterTypes? = nil //determines which menu is showing
    
    enum FilterTypes: String, CaseIterable {
        case hashtags = "Hashtags"
        case location = "Location"
    }
    @ViewBuilder
    private var filterSelectionOptions: some View {
        Text("Search filter options")
            .font(.headline)
            .padding(.top, 30)
        Divider()
        ForEach(FilterTypes.allCases, id: \.self) { filter in
            Button(action: {
                selectedFilterType = filter
            }) {
                Text(filter.rawValue)
                    .contentShape(Rectangle())
                    .padding()
                    .foregroundColor(.primary)
            }
            Divider()
            
        }
        Spacer()
        Button(action: {
            //On click of search, set all filter vals
            //Filtering location: if there is genuinely no location(ie, even the user location is not set), just display all posts
            filteringHashTags = hashtagViewModel.selectedHashTags
            filteringLocation = locationManager.location ?? CLLocationCoordinate2D(latitude: -1, longitude: -1)
            isShowing.toggle()
        }) {
            Text("Search with filters")
        }
    }
    
    @ViewBuilder
    private var selectedFilterView: some View {
        switch selectedFilterType {
        case .hashtags:
            
            VStack {
                HStack {
                    Button {
                        selectedFilterType = nil
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                    Text("Hashtag filter options")
                        .font(.headline)
                    
                }.padding(.top, 30)
                HashTagMenuView(viewModel: hashtagViewModel)
            }
            
        case .location:
            
            VStack {
                HStack {
                    Button {
                        selectedFilterType = nil
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                    Text("Set search location").font(.headline)
                    
                }.padding(.top, 30)
                NavigationView {
                    LocationFilterView(locationManager: locationManager, range: $filteringRange)
                        
                }
                
            }
            
        default:
            VStack {
                Text("INVALID")
            }
        }
    }
    
    
    var body: some View {
        
        ZStack {
            if isShowing {
                Rectangle()
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowing.toggle()
                    }
                
                HStack {
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Group {
                            if selectedFilterType == nil {
                                filterSelectionOptions
                            } else {
                                selectedFilterView
                            }
                        }
                        
                        
                        Spacer()
                        
                    }
                    .padding()
                    .frame(width: 270, alignment: .trailing)
                    .background(.white)
                    //.shadow(radius : 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    
                    Spacer()
                }
                
            }
        }.onAppear {
            print("View is reloading")
            hashtagViewModel.selectedHashTags = filteringHashTags
        }
        .transition(.move(edge: .trailing))
        .animation(.easeInOut, value: isShowing)
        .onChange(of: selectedFilterType) {
            // This code runs whenever the selectedFilterType changes
            print("Selected Filter Type changed to: \(selectedFilterType)")
            
        }
        .onAppear {
            //get tag info for displaying in hashtag menu
            firebaseManager.fetchUniqueTags { uniqueTags in
                hashtagViewModel.existingHashTags = uniqueTags
            }
        }
    }
    
}


struct FilterSideMenuPreview: PreviewProvider {
    static var previews: some View {
        let mockUser = User(
            profile_pic: "https://c02.purpledshub.com/uploads/sites/40/2023/08/JI230816Cosmos220-6d9254f-edited-scaled.jpg",
            id: "123",
            fullname: "John Doe",
            email: "johndoe@gmail.com",
            description: "iOS Developer",
            locationLat: 0.0,
            locationLng: 0.0,
            username: "johndoe",
            skills: ["Swift", "Xcode", "Firebase"]
        )
        
        // Create a mock AuthViewModel and set the currentUser
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.currentUser = mockUser
        
        return FilterSideMenuView(isShowing: .constant(true),filteringHashTags: .constant([]), filteringLocation: .constant(CLLocationCoordinate2D(latitude: 1, longitude: 2)), filteringRange: .constant(20.0)).environmentObject(mockAuthViewModel)
    }
}

