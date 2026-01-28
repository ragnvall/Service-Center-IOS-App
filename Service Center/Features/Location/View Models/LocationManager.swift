//
//  LocationManager.swift
//  Service Center
//
//  Created by Kevin on 2/14/25.
//

//Location manager referencing this article: https://coledennis.medium.com/tutorial-connecting-core-location-to-a-swiftui-app-dc62563bd1de

import CoreLocation
import SwiftUI
import MapKit

///LocationManager handles location variables(location, region, location snapshot) and location permissions.

class LocationManager : NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager() //Location manager instance
    var location: CLLocationCoordinate2D? = nil //stores this instance's saved location in coordinates
    @Published var neighborhood: String? //stores the location's corresponding neighborhood
    @Published var city: String? //stores the location's corresponding city
    var firstRender: Bool = false //stores whether this locationManager has been rendered before: used because of bugs that occur with view rendering multiple times in swiftui
    var width: Double = 1.0 //Used to store the size of the generated snapshot
    var height: Double = 1.0 // above
    @Published var snapshot: UIImage = UIImage() //Stores a snapshot of the map centered at the current location

    ///Initializes the locationManager instance
   override init() {
      super.init()
      locationManager.delegate = self
   }
    ///gets current user location
    func requestLocation() {
        //Based on authorizationStatus(location permissions for this app)
        switch locationManager.authorizationStatus {
            case.notDetermined: // if location permissions haven't been set/requested
                print("Requesting location access for when in use")
                //request permission to use location when app in use
                locationManager.requestWhenInUseAuthorization()
            
            case .authorizedWhenInUse, .authorizedAlways: //If already authorized
                locationManager.requestLocation() //use the locationManager instance to get location
        case .denied, .restricted: //If location permissions have been denied
                print("Location access denied. Access in settings")
        default:
                break
        }
        
    }
    ///Generates a snapshot of the map centered at the current user location
    func generateSnapshot(size: CGSize) {
        
        guard let location = self.location else { //checks that there is a valid location set(failback test as location should always be intialized in app)
            print("Location is nil, cannot generate snapshot")
            return
        }
        
        //set snapshot parameters
        // Ensure the size is valid
           guard size.width > 0, size.height > 0 else {
               print("Invalid snapshot size: \(size.width)x\(size.height)")
               return
           }
        
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: self.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 50000, longitudinalMeters: 50000) //sets region(map center and range)
        options.size = size //passes in provided size
        options.scale = 1.0
        options.pointOfInterestFilter = .excludingAll //Tell snapshot to not show preset location markers
        
        print("Snapshot loc: \(self.location ?? CLLocationCoordinate2D(latitude: 0, longitude: -1))")
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else { return }
            DispatchQueue.main.async {
                self.snapshot = snapshot.image // return the snapshot
            }
        }
    }
    
    ///Sets the neigborhood and city of locationManager from the current location
    func getAreaFromCoords(completion: @escaping (String?, String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        if let curLoc = location {
            //Converts cur location to CLLocation so it can be passed to geocoder
            let locationObj = CLLocation(latitude: curLoc.latitude, longitude: curLoc.longitude)
            geocoder.reverseGeocodeLocation(locationObj, completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Failed to retrieve address")
                    completion(nil, nil, nil)
                    return
                }
                
                if let placemarks = placemarks, let placemark = placemarks.first { //sets the neighborhood and city vals
                    self.neighborhood = placemark.subLocality
                    self.city = placemark.locality
                    completion(placemark.locality, placemark.subLocality, placemark.postalCode)
                }
                else
                {
                    completion(nil, nil, nil)
                    print("No Matching Address Found")
                }
            })
        }
    }
    
    ///CLLocationManager  delegate functions:
    ///
    // Called on CLLocationManager successfully updates location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLoc = locations.first?.coordinate {
            print("location gotten in loc manager")
            location = newLoc
        } else {
            print("Failure retrieving location in locmanager")
        }
    }
    //Called on failure to update location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

}
