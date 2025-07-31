import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct LoginPage: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: Field?
    @State private var showRegister = false
    @State private var showReset = false
    
    enum Field { case username, password }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    Text("Giriş Yap")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 8)
                    Text("Kullanıcı adı ve şifre ile giriş yap")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                    VStack(spacing: 16) {
                        TextField("Kullanıcı adı", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .username)
                        HStack {
                            if showPassword {
                                TextField("Şifre", text: $viewModel.password)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Şifre", text: $viewModel.password)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .password)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    Spacer()
                    Button(action: {
                        Task {
                            await viewModel.login()
                        }
                    }) {
                        Text("Giriş Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(
                                LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(22)
                    }
                    .padding(.bottom, 16)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    HStack {
                        Button("Kayıt Ol") { showRegister = true }
                            .foregroundColor(.purple)
                        Spacer()
                        Button("Şifremi Unuttum") { showReset = true }
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                if viewModel.isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterPage()
            }
            .navigationDestination(isPresented: $showReset) {
                // ResetPasswordPage() // Buraya şifre sıfırlama ekranı eklenebilir
                Text("Şifre sıfırlama ekranı")
            }
        }
    }
    

}


#Preview {
    LoginPage()
} 
