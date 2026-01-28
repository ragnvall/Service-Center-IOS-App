import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss // ✅ Allows dismissing the view

    var body: some View {
        NavigationStack {
            ZStack {
                // Keep your original background (if any)
                Color.white.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Forgot Password?")
                        .font(.title)
                        .bold()

                    Text("Enter your email and we’ll send you a password reset link.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // ✅ Keeping your original TextField styling
                    TextField("Email Address", text: $email)
                        .autocapitalization(.none)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // ✅ Keeping your original Reset Password Button
                    Button(action: {
                        authViewModel.resetPassword(email: email)
                    }) {
                        Text("Reset Password")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    // ✅ Keeping the original way of displaying error/success messages
                    if let message = authViewModel.passwordResetMessage {
                        Text(message)
                            .foregroundColor(message.contains("✅") ? .green : .red)
                            .padding()
                    }

                    // ✅ Keeping your original Close Button
                    Button("Close") {
                        authViewModel.clearPasswordResetMessage() // ✅ Clears error message
                        dismiss() // ✅ Dismiss view
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
    }
}

// Preview
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .environmentObject(AuthViewModel())
            .previewDevice("iPhone 14 Pro")
    }
}
