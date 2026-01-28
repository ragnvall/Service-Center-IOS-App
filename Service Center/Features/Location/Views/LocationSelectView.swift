//
//  LocationSelectView.swift
//  Service Center
//
//  Created by Kevin on 2/20/25.
//
///Component linking to LocationMapView, allowing users to see and edit their location information(in profile, filtering, creating posts)
///Consists of:
///Display of map centered on current location(links to LocationMapView)
///Derived neighborhood and city

import SwiftUI
import MapKit

struct LocationSelectView: View {
    @ObservedObject var locationManager: LocationManager //Instance of locationManager, passed down through whichever parent view is using this component
    @State private var isMapViewPresent: Bool = false
    var onLocationChange: ((CLLocationCoordinate2D?)->Void)? //Closure that returns the current location to parent view
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        
        GeometryReader { geometry in //Geometry reader to dynamically size view based on parent view
            VStack(spacing:0) {
                VStack {
                    //Clickable snapshot of the current location map, allows to edit location through LocationMapView
                    Button() {
                        isMapViewPresent = true
                    } label: {
                        Image(uiImage: locationManager.snapshot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: locationManager.snapshot.size.width, height: locationManager.snapshot.size.height*0.75)
                            .clipped()
                    }
                }
                //Shows locationMapView if above snapshot is clicked
                .fullScreenCover(isPresented: $isMapViewPresent) {
                    LocationMapView(locationManager: locationManager) {
                        //On closure called in locationMapView:
                        newLocation in
                        //set locationManager location
                        locationManager.location = newLocation
                        //generate new snapshot to reflect updated location
                        locationManager.generateSnapshot(size: CGSize(width: locationManager.width, height: locationManager.height))
                        //update displayed neighborhood and city
                        locationManager.getAreaFromCoords() { Neighborhood, City, PostalCode in
                            print("area from coords succeeded")
                        //pass the optional closure(needed when you need something to happen on change of location, ie need to change firebase vals automatically when changed)
                            onLocationChange?(newLocation)
                        }
                    }
                }
                
                //Display neighborhood and city
                VStack(spacing:5) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)
                        
                        
                        Text(locationManager.neighborhood ?? "Unknown neighborhood")
                            .foregroundColor(.gray)
                    }
                    Text(locationManager.city ?? "Unknown neighborhood")
                        .foregroundColor(.black)
                }.frame(width: geometry.size.width, height: geometry.size.height*0.25)
                    .background(Color.gray.opacity(0.2))
                    .clipped()
                    //.clipShape(RoundedRectangle(cornerRadius: 10))
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onAppear() {
                if !locationManager.firstRender {
                    //Set width and height of this view on first render: due to bugs where, if a parent renders this view multiple times, after the first time it will be rendered with a frame size of 0x0, causing a crash
                    
                    authViewModel.fetchCurrentUser { success in
                        DispatchQueue.main.async {
                            if success, let profile = authViewModel.currentUser {
                                //If user hasnt set location, sets location to -1,-1(used in the snapshot, and opening mapview)
                                locationManager.location = CLLocationCoordinate2D(latitude: profile.locationLat ?? -1, longitude: profile.locationLng ?? -1)
                                locationManager.firstRender = true
                                
                                locationManager.width = geometry.size.width
                                locationManager.height = geometry.size.height
                                
                                //gets starting neighborhood, city, and generates intial snapshot
                                locationManager.getAreaFromCoords() { Neighborhood, City, PostalCode in
                                }
                                
                                print("Generating snapshot at: \(locationManager.location?.latitude ?? -1), \(locationManager.location?.longitude ?? -1), with width \(locationManager.width), \(locationManager.height)")
                                locationManager.generateSnapshot(size: CGSize(width: locationManager.width, height: locationManager.height))
                                print("Snapshot generated")
                                
                            }else {
                                print("Failed to fetch user(fetchCurrentUser)")
                            }
                        }
                    }
                } else {
                    
                    locationManager.getAreaFromCoords() { Neighborhood, City, PostalCode in
                    }
                    
                    print("Generating snapshot at: \(locationManager.location?.latitude ?? -1), \(locationManager.location?.longitude ?? -1), with width \(locationManager.width), \(locationManager.height)")
                    locationManager.generateSnapshot(size: CGSize(width: locationManager.width, height: locationManager.height))
                    print("Snapshot generated")
                }
                  
            }
        }
    }
}


struct LocationSelectPreview: PreviewProvider {
    static var previews: some View {
        let dummyLocationManager = LocationManager()
        let mockUser = User(
            profile_pic: "https://c02.purpledshub.com/uploads/sites/40/2023/08/JI230816Cosmos220-6d9254f-edited-scaled.jpg",
            id: "123",
            fullname: "John Doe",
            email: "johndoe@gmail.com",
            description: "iOS Developer",
            locationLat: 36.9741,
            locationLng: -122.0308,
            username: "johndoe",
            skills: ["Swift", "Xcode", "Firebase"]
        )
        
        // Create a mock AuthViewModel and set the currentUser
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.currentUser = mockUser
        
        return LocationSelectView(locationManager: dummyLocationManager).environmentObject(mockAuthViewModel)
    }
}
