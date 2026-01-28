//
//  RootView.swift
//  Service Center
//
//  Created by Robert Agnvall on 3/6/25.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoading {
                // Show a loading spinner or placeholder
                LoadingView()
            } else if let user = authManager.currentUser, !user.id.isEmpty {
                // The user is fully loaded, proceed to main content
                ContentView()
            } else {
                // No user found; show a login or onboarding screen
                LoginView()
            }
        }
    }
}

// Example loading view
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView("Loading user data...")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
