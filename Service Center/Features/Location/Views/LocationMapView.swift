//
//  LocationMapView.swift
//  Service Center
//
//  Created by Kevin on 2/14/25.
//

///Displays the basic location map(used within locationSelectView).
///
///Consists of:
///SearchBar(LocationSearchView)
///Interactive map
///Current location button
///Display of current location coordinates
///Save location button

import SwiftUI
import MapKit
import CoreLocationUI



//Extension of MKCoordinateRegion that allows checking for equality.
extension MKCoordinateRegion: @retroactive Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        if lhs.center.latitude == rhs.center.latitude && lhs.span.latitudeDelta == rhs.span.latitudeDelta && lhs.span.longitudeDelta == rhs.span.longitudeDelta {
            return true
        } else {
            return false
        }
    }
}
struct LocationMapView: View {
    @ObservedObject var locationManager: LocationManager //Instance of locationManager: passed down from parent view  locationSelectView
    @Environment(\.dismiss) var dismiss
    var onLocationSaved : (CLLocationCoordinate2D) -> Void //closure that activates when location save button clicked
    @State private var region : MKCoordinateRegion //Region that determines what part of the map is showing
    //@EnvironmentObject var authViewModel: AuthViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic //wrapper around region so it can be passed to a Map
    @State private var curCoords: CLLocationCoordinate2D? //current map coordinates, which are passed to parent view on closure
    
    
    init(locationManager: LocationManager, onLocationSaved: @escaping (CLLocationCoordinate2D) -> Void = { _ in}) {
        self.onLocationSaved = onLocationSaved
        self.locationManager = locationManager
        let initialRegion = MKCoordinateRegion(center: locationManager.location ?? CLLocationCoordinate2D(latitude: 32.6514, longitude: -161.4333), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)) //initializes intial map location(placer val, as on appear this is set)
        _region = State(initialValue: initialRegion)
        _cameraPosition = State(initialValue: .region(initialRegion))
    }
    
    var body: some View {
        VStack {
            HStack {
                Button() {
                    dismiss()
                } label: { //Exit button
                    HStack {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.blue)

                    }
                    .padding(.leading, 10)
                }
                Spacer()
                Text("Choose a location").font(.headline)
                Spacer()
            }
            .padding()
            
            
                            
            ZStack(alignment: .bottom){
                //Map display
                Map(position: $cameraPosition) {
                    
                }
                //Overlay to make it easy to see the current location
                .overlay(
                    Circle()
                        .fill(Color.blue)
                        .frame(width:30, height:30)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                )
                //On mapCameraChange(thru movement, or use of current location/searched location), updat curCoords
                .onMapCameraChange { cameraPosition in
                    curCoords = cameraPosition.region.center
                }
                //Displays search bar for location
                LocationSearchView { newRegion in
                    cameraPosition = .region(newRegion)
                }
                //Get user location button
                Button(action: {
                    locationManager.requestLocation()
                    if let userLoc = locationManager.location {
                        //sets cameraPosition(to shift the map view) and curCoords on user location recieved
                        cameraPosition = .region(MKCoordinateRegion(center: userLoc, span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)))
                        curCoords = userLoc
                    } else {
                        print("Location is nil")
                    }
                }) {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                        Text("Current location")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }.padding()
            }
            
            //Save button: returns a closure with the current centered location, and returns to parent view
            Button(action: {
                print("Saving location:")
                if let curUserCoords = curCoords {
                    onLocationSaved(curUserCoords)
                } else {
                    print("Location not saved: unknown location")
                }
                dismiss()
                
                
            }) {
                Text("Save location")
                
            }
            
        }
    }
}

#Preview {
    struct LocationMapViewPreviewWrapper: View {
        @StateObject private var locationManager = LocationManager()

        var body: some View {
            LocationMapView(locationManager: locationManager) { savedLocation in
                print("Saved location: \(savedLocation.latitude), \(savedLocation.longitude)")
            }
        }
    }

    return LocationMapViewPreviewWrapper()
}
