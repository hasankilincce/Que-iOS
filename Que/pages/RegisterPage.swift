import SwiftUI

struct RegisterPage: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isRegistered = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Kayıt Ol")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            SecureField("Şifre", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Şifre Tekrar", text: $viewModel.confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            Button(action: {
                viewModel.register { success in
                    if success {
                        appState.isLoggedIn = true
                    }
                }
            }) {
                Text("Kayıt Ol")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
            Button("Girişe Dön") {
                dismiss()
            }
            Spacer()
        }
        .padding()
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        )
        .navigationDestination(isPresented: $isRegistered) {
            HomePage()
        }
    }
}

#Preview {
    RegisterPage()
} 