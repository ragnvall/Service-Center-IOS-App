import SwiftUI
import FirebaseFirestore
import MapKit

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var locationManager = LocationManager()
    
    @State private var step = 1
    @State private var selectedSkills: [String] = []
    @State private var isServiceProvider: Bool?
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var errorMessage: String?
    
    
    
    
    var body: some View {
           ZStack {
               // 🌑 Full black background
               Color.black
                   .edgesIgnoringSafeArea(.all)
               
               VStack {
                   // 🔵 Progress Indicator (keeps original logic)
                   ProgressView(value: Double(step), total: 5)
                       .padding()
                       .progressViewStyle(LinearProgressViewStyle())
                   
                   // 📌 Onboarding Steps (keeps original flow)
                   Group {
                       switch step {
                       case 1: WelcomeStep(onNext: { step += 1 })
                       case 2: ServiceProviderStep(isServiceProvider: $isServiceProvider, onNext: { step += isServiceProvider == true ? 1 : 2 })
                       case 3: SkillSelectionStep(selectedSkills: $selectedSkills, onNext: { step += 1 })
                       case 4: DescriptionStep(description: $description, onNext: { step += 1 })
                       case 5: LocationStep(location: $location, locationManager: locationManager, onComplete: { saveOnboardingData() })
                       default: EmptyView()
                       }
                   }
                   .transition(.opacity)
                   .animation(.easeInOut, value: step)

                   if let errorMessage = errorMessage {
                       Text(errorMessage)
                           .foregroundColor(.red)
                           .font(.footnote)
                           .padding()
                   }
               }
           }
       }
    
    /// Saves the onboarding data to Firestore
    private func saveOnboardingData() {
        guard let userID = authViewModel.userSession?.uid else {
            errorMessage = "User ID not found."
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        var locationData: [String: Any] = [:]
        if !location.isEmpty, location != "Unknown location" {
            let components = location.split(separator: ",")
            if components.count == 2,
               let lat = Double(components[0].trimmingCharacters(in: .whitespaces)),
               let lng = Double(components[1].trimmingCharacters(in: .whitespaces)) {
                locationData = ["latitude": lat, "longitude": lng]
            }
        }
        
        let onboardingData: [String: Any] = [
            "skills": selectedSkills,
            "description": description,
            "locationLat": locationData["latitude"] ?? -1, // Store like SettingsView
            "locationLng": locationData["longitude"] ?? -1,
            "isServiceProvider": isServiceProvider ?? false,
            "hasCompletedOnboarding": true
        ]
        
        userRef.setData(onboardingData, merge: true) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save onboarding data: \(error.localizedDescription)"
                }
            } else {
                DispatchQueue.main.async {
                    authViewModel.hasCompletedOnboarding = true
                }
            }
        }
    }
}

    
struct WelcomeStep: View {
    var onNext: () -> Void

    var body: some View {
        ZStack {
            // 🌑 Full black background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 🚀 App Symbol (SF Symbol or Custom Logo)
                Image(systemName: "sparkles") // You can replace with your logo
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                // 🎨 Welcome Text
                VStack {
                    Text("Welcome to")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)

                    Text("Service Center")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.blue)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.black))

                // 🔴 Slogan
                Text("Your one-stop platform for all your needs!")
                    .font(.headline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // 📝 Subtext in White
                Text("Before you dive in, let's gather some information to enhance your experience.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                // 🔹 Get Started Button
                Button(action: onNext) {
                    Text("Get Started")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 10)
            }
        }
    }
}


struct ServiceProviderStep: View {
    @Binding var isServiceProvider: Bool?
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 🛠 Added an SF Symbol for a service provider concept
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            // Updated text to white for visibility
            Text("Are you a service provider?")
                .font(.title2)
                .bold()
                .foregroundColor(.white) // ✅ White text for black background

            // "Yes" & "No" Buttons with proper styling
            HStack(spacing: 20) {
                Button("Yes") {
                    isServiceProvider = true
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue) // Ensures it stands out on dark background

                Button("No") {
                    isServiceProvider = false
                    onNext()
                }
                .buttonStyle(.bordered)
                .tint(.gray) // Makes it more subtle
            }
        }
        .padding()
    }
}

struct SkillSelectionStep: View {
    @Binding var selectedSkills: [String]
    var onNext: () -> Void
    @State private var newSkill: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // 🌑 Full black background
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack {
                // 🔹 Title (Now White)
                Text("Select Your Skills")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                // 🔵 Input Field & Button
                HStack {
                    ZStack(alignment: .leading) {
                        // Custom Placeholder (Shows only when newSkill is empty)
                        if newSkill.isEmpty {
                            Text("Add a new skill")
                                .foregroundColor(.white.opacity(0.6)) // ✅ Placeholder slightly visible
                                .padding(.leading, 16)
                        }
                        TextField("", text: $newSkill)
                            .padding()
                            .background(Color.gray.opacity(0.3)) // ✅ Gray background for visibility
                            .cornerRadius(8)
                            .foregroundColor(.gray) // ✅ Typed text is now gray
                    }

                    Button("Add") {
                        addSkill()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()

                // 🚨 Error Message (If Any)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding()
                }

                // 🏷 Display Selected Skills in Ovals
                ScrollView(.vertical, showsIndicators: false) {
                    HStack {
                        ForEach(selectedSkills, id: \.self) { skill in
                            Text(skill)
                                .font(.body)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.blue))
                        }
                    }
                    .padding()
                }

                // ✅ Next Button
                Button(action: onNext) {
                    Text("Next")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
    }

    /// Adds a new skill with validation
    private func addSkill() {
        let trimmedSkill = newSkill.trimmingCharacters(in: .whitespacesAndNewlines).capitalized

        if trimmedSkill.isEmpty {
            errorMessage = "Skill cannot be empty."
            return
        }

        if selectedSkills.contains(trimmedSkill) {
            errorMessage = "Skill already added."
            return
        }

        selectedSkills.append(trimmedSkill)
        newSkill = ""
        errorMessage = nil
    }
}


struct DescriptionStep: View {
    @Binding var description: String
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 🖊️ Added an SF Symbol for description
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 50))
                .foregroundColor(.blue) // Symbol in blue

            // 📝 Updated Text with White Color
            Text("Tell us about yourself")
                .font(.title2)
                .bold()
                .foregroundColor(.white) // ✅ White text for dark background
            
            // 🏷️ Description TextField with White Text + Placeholder Workaround
            ZStack(alignment: .leading) {
                if description.isEmpty {
                    Text("Enter a short description")
                        .foregroundColor(.gray) // ✅ Gray Placeholder
                        .padding(.leading, 10)
                }

                TextField("", text: $description, axis: .vertical)
                    .foregroundColor(.white) // ✅ White text when typing
                    .padding()
                    .background(Color.gray.opacity(0.3)) // ✅ Slightly visible field
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)

            // ✅ "Next" Button (Stays the same)
            Button(action: onNext) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}



struct LocationStep: View {
    @Binding var location: String
    @ObservedObject var locationManager: LocationManager
    var onComplete: () -> Void

    @State private var showingMap = false
    @State private var selectedCoordinates: CLLocationCoordinate2D?

    var body: some View {
        VStack(spacing: 20) {
            // 📍 Location Symbol
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            // 🌍 White Header Text
            Text("Where are you located?")
                .font(.title2)
                .bold()
                .foregroundColor(.white)

            Button(action: {
                showingMap.toggle()
            }) {
                HStack {
                    Image(systemName: "map.fill") // 🌍 SF Symbol
                    Text("Show Map")
                        .fontWeight(.bold)
                }
                .foregroundColor(.blue) // 🔵 Text remains blue, but no background
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2) // 🟦 Thin blue border
                )
            }
            .padding(.horizontal, 30)
            .sheet(isPresented: $showingMap) {
                LocationMapView(locationManager: locationManager) { newLocation in
                    self.selectedCoordinates = newLocation
                    self.location = "\(newLocation.latitude), \(newLocation.longitude)"
                }
            }

            // 📍 Display Selected Coordinates (If Available)
            if let selectedCoords = selectedCoordinates {
                VStack {
                    Text("📌 Selected Location:")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Lat: \(selectedCoords.latitude), Lng: \(selectedCoords.longitude)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.3)))
                }
                .padding()
            }

            // ✅ "Finish" Button
            Button(action: {
                if selectedCoordinates == nil {
                    location = "Unknown location"
                }
                onComplete()
            }) {
                Text("Finish")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding()
        }
    }
}


#Preview {
   OnboardingView()
        .environmentObject(AuthViewModel())
}
