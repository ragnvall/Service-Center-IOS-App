//
//  LocationSearchViewModel.swift
//  Service Center
//
//  Created by Kevin on 2/16/25.
//
import SwiftUI
import MapKit

///ViewModel storing info on location search results, within LocationMapView
class LocationSearchViewModel: NSObject, ObservableObject{
    @Published private(set) var results: Array<AddressResult> = [] //Stores the list of search results to be displayed
    @Published var searchableText = "" //Text currently in search bar
    
    private lazy var locSearchCompleter: MKLocalSearchCompleter = { //instance onf MKLocalSearchCompleter, used to query IOS maps data for locations given a search query
        let completer = MKLocalSearchCompleter()
        completer.delegate = self
        completer.resultTypes = .address
        return completer
    }()
    ///Resets results of search
    func reset_results() {
        results = []
    }
    ///calls searchCompleter to get addresses matching the query
    func searchAddress(_ searchableText: String) {
        guard searchableText.isEmpty == false else { return }
        locSearchCompleter.queryFragment = searchableText
    }
}
extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    //on the MKLocalSearchCompleter completing(ie results fetched), set results
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            
            results = completer.results
                .filter { !$0.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains("search nearby") }
                .prefix(4)
                .map {
                    AddressResult(title: $0.title, subtitle: $0.subtitle)
                }
        }
    }
    //else, if it failed, print the error
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
}
