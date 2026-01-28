//
//  AddressResult.swift
//  Service Center
//
//  Created by Kevin on 2/15/25.
//

import SwiftUI
///Simple struct representing a search result in LocationSearchView/LocationSearchViewModel's dropdown search
struct AddressResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}
