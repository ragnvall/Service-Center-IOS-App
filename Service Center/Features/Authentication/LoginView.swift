import SwiftUI

struct LoginView: View {
    @State private var usernameOrEmail: String = ""
    @State private var password: String = ""
    @State private var showForgotPassword = false // Controls Forgot Password pop-up
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var isUsernameFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Full-Screen Background Image from Figma
                Image("REGISTRATION (1)")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack {
                    // ✅ Back Button (Top Left)
                    HStack {
                        Button(action: {
                            // Dismiss the view or navigate back
                            // This works if presented modally
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.dismiss(animated: true, completion: nil)
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .frame(width: 20, height: 18)
                                .foregroundColor(.black)
                        }
                        .padding(.leading, 20)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 30)

                    Spacer()

                    // ✅ App Logo
                    Image("logo") // Replace with your logo asset if needed
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)

                    // ✅ Transparent Input Fields
                    VStack(spacing: 15) {
                        // Username or Email Field
                        TextField("Username or Email", text: $usernameOrEmail)
                            .autocapitalization(.none)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 300, height: 50)
                            .background(Color.white)
                            .cornerRadius(10)
                            .focused($isUsernameFocused)
                            .padding(.horizontal)

                        // Password Field
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 300, height: 50)
                            .background(Color.white)
                            .cornerRadius(10)
                            .focused($isPasswordFocused)
                            .padding(.horizontal)
                            .onSubmit {
                                authViewModel.authenticate(usernameOrEmail: usernameOrEmail, password: password)
                            }
                    }

                    // ✅ Login Button
                    Button(action: {
                        authViewModel.authenticate(usernameOrEmail: usernameOrEmail, password: password)
                    }) {
                        Text("Login")
                            .frame(width: 300, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)

                    // ✅ Error Message (if any)
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }

                    // ✅ Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        NavigationLink(destination: RegistrationView()) {
                            Text("Create one")
                                .foregroundColor(.red)
                                .bold()
                        }
                        .isDetailLink(false)
                    }
                    .padding(.top, 10)

                    // ✅ Forgot Password Section
                    HStack {
                        Text("Forgot password?")
                            .foregroundColor(.white.opacity(0.8))
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Reset Password")
                                .foregroundColor(.red)
                                .bold()
                        }
                    }
                    .padding(.top, 5)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            isUsernameFocused =  true
        }
        // ✅ Forgot Password Popup
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
            .previewDevice("iPhone 16 Pro")
    }
}
