import SwiftUI
import GoogleSignInSwift


struct LoginPage: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showRegister = false
    @State private var showReset = false
    @State private var isLoggedIn = false
    @EnvironmentObject var appState: AppState
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return nil }
        return root
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Que - Giriş Yap")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("Şifre", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                Button(action: {
                    viewModel.login { success in
                        if success {
                            appState.isLoggedIn = true
                        }
                    }
                }) {
                    Text("Giriş Yap")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(viewModel.isLoading)
                GoogleSignInButton(action: {
                    if let rootVC = getRootViewController() {
                        viewModel.signInWithGoogle(presentingVC: rootVC) { success in
                            if success {
                                appState.isLoggedIn = true
                            }
                        }
                    }
                })
                .frame(height: 50)
                HStack {
                    Text("Hesabın yok mu?")
                    Button("Kayıt Ol") {
                        showRegister = true
                    }
                }
                Button("Şifremi Unuttum") {
                    showReset = true
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
            .navigationDestination(isPresented: $showRegister) {
                RegisterPage()
            }
            .navigationDestination(isPresented: $showReset) {
                ResetPasswordPage()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                HomePage()
            }
        }
    }
}


#Preview {
    LoginPage()
} 
