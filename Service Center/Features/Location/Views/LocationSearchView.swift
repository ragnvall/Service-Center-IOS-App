//
//  LocationSearchView.swift
//  Service Center
///
///Displays the search bar, and recommended searches in LocationMapView
///This view consists of:
///A search bar
///A list of suggestions
///This view updates LocationMapView
//  Created by Kevin on 2/15/25.
//

import SwiftUI
import MapKit



struct LocationSearchView: View {
    var onRegionSelected : (MKCoordinateRegion) -> Void //Closure that returns the selected location option's region
    @StateObject var locationSearchViewModel = LocationSearchViewModel()
    @State private var isPressing: String? = nil
    
    //From a search request, get a entry that will be displayed in the search suggestions
    func getPlace(from address: AddressResult) {
        let request = MKLocalSearch.Request()
        let title = address.title
        let subTitle = address.subtitle
        print(subTitle)
        //Parse request into user friendly format
        request.naturalLanguageQuery = subTitle.contains(title)
                ? subTitle : title + ", " + subTitle
                
        Task {
            let response = try await MKLocalSearch(request: request).start()
            await MainActor.run {
                //return the region of selected search results
                let region = response.boundingRegion
                onRegionSelected(region)
            }
        }
    }
    
    var body: some View {
        VStack {
            //Text field for user to type in location queries
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                TextField("Type in location", text: $locationSearchViewModel.searchableText)
                    .autocorrectionDisabled(true)
                    .font(.body)
                    .padding(.vertical, 10)
                    .onReceive(
                        //Tries to get possible location from search query
                        locationSearchViewModel.$searchableText.debounce(
                            for: .seconds(0.25),
                            scheduler: DispatchQueue.main
                        )
                    ) {
                        locationSearchViewModel.searchAddress($0)
                    }

            }
            
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .frame(height:20)
            
            if (!locationSearchViewModel.results.isEmpty) {
                //Displays possible locations from query
                List(locationSearchViewModel.results) { address in
                    HStack {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        VStack(alignment: .leading) {
                            Text(address.title)
                            Text(address.subtitle)
                        }
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .background(isPressing == (address.subtitle + address.title) ? Color.gray.opacity(0.3) : Color.clear)
                    
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged {_ in
                                self.isPressing = address.subtitle + address.title
                            }
                            .onEnded { _ in
                                getPlace(from: address) //set region
                                locationSearchViewModel.searchableText = "" //reset search, clear dropdown
                                locationSearchViewModel.reset_results()
                                self.isPressing = nil
                            }
                    )
                      
                }.listStyle(.plain)
                .scrollContentBackground(.hidden)
                
            } else {
                Spacer()
            }
                
            
           
        }.edgesIgnoringSafeArea(.bottom)
    }
}


struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(onRegionSelected: { _ in })
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
