//
//  LocationFilterView.swift
//  Service Center
//
//  Created by Kevin on 2/19/25.
//
///View displays location filtering options within filter menu
///Allows user to modify search location and range
import SwiftUI
import MapKit
struct LocationFilterView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var range: Double
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        
            VStack(spacing: 10) {
                //Location selection
                LocationSelectView(locationManager: locationManager)
                    .padding()
                                    
                Text("Set search range").bold()
                //slider sets range of location search
                HStack {
                    Slider(
                        value: $range,
                        in: 0...100,
                        step: 1
                    )
                    
                }.padding()
                Text("\(range, specifier: "%.f") miles")
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
}


struct LocationFilterPreviews: PreviewProvider {
    static var previews: some View {
        let dummyLocationManager = LocationManager()
        let mockUser = User(
            profile_pic: "https://c02.purpledshub.com/uploads/sites/40/2023/08/JI230816Cosmos220-6d9254f-edited-scaled.jpg",
            id: "123",
            fullname: "John Doe",
            email: "johndoe@gmail.com",
            description: "iOS Developer",
            locationLat: 36.9741,
            locationLng: 122.0308,
            username: "johndoe",
            skills: ["Swift", "Xcode", "Firebase"]
        )
        
        // Create a mock AuthViewModel and set the currentUser
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.currentUser = mockUser
        
        return LocationFilterView(locationManager: dummyLocationManager, range: .constant(20.0)).environmentObject(mockAuthViewModel)
    }
}
