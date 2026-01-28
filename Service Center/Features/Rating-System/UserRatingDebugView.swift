//
//  UserRatingDebugView.swift
//  Service Center
//
//  Created by Alan Lam on 2/24/25.
//

import SwiftUI

struct UserRatingDebugView: View {
    @State private var username: String = ""
    @State private var userFound: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    private var authManager = AuthManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("User Rating Debugger")
                    .font(.title)
                    .bold()

                // Input for username
                TextField("Enter Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .onSubmit {
                        submitUsername()
                    }

                // Button to submit username and check if user exists
                Button(action: {
                    submitUsername()
                }) {
                    Text("Submit Username")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Error message (if user is not found)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .italic()
                }

                // Show these buttons if the user is found
                if userFound {
                    VStack(spacing: 15) {
                        Button(action: {
                            Task {
                                await printUserRatings(username: username)
                            }
                        }) {
                            Text("Print Ratings")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            Task {
                                await deleteUserRatings(username: username)
                            }
                        }) {
                            Text("Delete All Ratings")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        NavigationLink(destination: LimitedReviewsView(username: username)) {
                            Text("Go to Reviews")
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .overlay(
                // Show loading indicator while the operation is in progress
                isLoading ? AnyView(ProgressView("Loading...").progressViewStyle(CircularProgressViewStyle())) : AnyView(EmptyView()),
                alignment: .center
            )
        }
    }

    // Function to handle the button action when "Enter" is pressed or the button is clicked
    private func submitUsername() {
        Task {
            await checkIfUserExists(username: username)
        }
    }

    private func checkIfUserExists(username: String) async {
        isLoading = true
        do {
            _ = try await authManager.fetchUserByUsername(username: username)
            userFound = true
            errorMessage = nil
            print("Gathering data for \(username)")
        } catch {
            userFound = false
            errorMessage = "User with username \(username) not found."
        }
        isLoading = false
    }

    private func printUserRatings(username: String) async {
        do {
            try await authManager.printUserRatings(username: username)
        } catch {
            errorMessage = "Failed to fetch ratings: \(error.localizedDescription)"
        }
    }

    private func deleteUserRatings(username: String) async {
        do {
            try await authManager.deleteUserRatings(username: username)
        } catch {
            errorMessage = "Failed to delete ratings: \(error.localizedDescription)"
        }
    }
}

struct UserRatingDebugView_Previews: PreviewProvider {
    static var previews: some View {
        UserRatingDebugView()
    }
}
