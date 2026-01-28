import SwiftUI

struct RegistrationView: View {
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isRegistered = false
    @State private var isSecondStep = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image(isSecondStep ? "REGISTRATION (1)" : "REGISTRATION (1)")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    VStack(spacing: 15) {
                        Text("All your service needs in one place")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        if !isSecondStep {
                            CustomTextField(placeholder: "Email Address", text: $authViewModel.email, isSecure: false)
                            CustomTextField(placeholder: "Password", text: $authViewModel.password, isSecure: true)
                            CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .padding(.horizontal)
                            }
                            
                            Button(action: validateFirstStep) {
                                Text("Create Account")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 10)
                        } else {
                            Button(action: {
                                isSecondStep = false
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            }
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            
                            CustomTextField(placeholder: "Full Name", text: $authViewModel.fullname, isSecure: false)
                            CustomTextField(placeholder: "Username", text: $authViewModel.username, isSecure: false)
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .padding(.horizontal)
                            }
                            
                            Button(action: completeRegistration) {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(15)
                    .padding()
                    
                    if !isSecondStep {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.footnote)
                        NavigationLink(destination: LoginView()) {
                            Text("Log in")
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    
                    Spacer()
                }
            }
            .animation(.easeInOut, value: isSecondStep)
            
            if isRegistered {
                NavigationLink(destination: OnboardingView().environmentObject(authViewModel), isActive: $isRegistered) {
                    EmptyView()
                }
            }
        }
    }
    
    private func validateFirstStep() {
        if authViewModel.email.isEmpty || authViewModel.password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "All fields must be filled."
        } else if !authViewModel.email.lowercased().hasSuffix("@gmail.com") {
            errorMessage = "Please use a valid Gmail address."
        } else if authViewModel.password.count < 6 {
            errorMessage = "Password must be at least 6 characters long."
        } else if authViewModel.password != confirmPassword {
            errorMessage = "Passwords do not match."
        } else {
            isSecondStep = true
            errorMessage = nil
        }
    }
    
    private func completeRegistration() {
        if authViewModel.fullname.isEmpty || authViewModel.username.isEmpty {
            errorMessage = "All fields must be filled."
        } else {
            authViewModel.checkIfUsernameExists(username: authViewModel.username) { exists in
                DispatchQueue.main.async {
                    if exists {
                        errorMessage = "Username is already taken."
                    } else {
                        authViewModel.register(
                            username: authViewModel.username,
                            email: authViewModel.email,
                            password: authViewModel.password,
                            fullname: authViewModel.fullname
                        ) { success in
                            if success {
                                isRegistered = true
                            } else {
                                errorMessage = authViewModel.errorMessage
                            }
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Custom Text Field Component
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool

    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
        } else {
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
            .environmentObject(AuthViewModel())
    }
}
