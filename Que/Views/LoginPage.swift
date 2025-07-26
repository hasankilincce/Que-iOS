import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct LoginPage: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
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
                        TextField("Kullanıcı adı", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .username)
                        HStack {
                            if showPassword {
                                TextField("Şifre", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Şifre", text: $password)
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
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    Spacer()
                    Button(action: {
                        login()
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
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
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
                if isLoading {
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
    
    func login() {
        isLoading = true
        errorMessage = nil
        let functions = Functions.functions(region: "us-east1")
        functions.httpsCallable("loginWithUsername").call(["username": username, "password": password]) { result, error in
            if let error = error as NSError? {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            guard let data = (result?.data as? [String: Any]),
                  let email = data["email"] as? String else {
                self.isLoading = false
                self.errorMessage = "Kullanıcı bulunamadı veya e-posta eksik."
                return
            }
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    // Başarılı giriş, ana sayfaya yönlendir
                }
            }
        }
    }
}


#Preview {
    LoginPage()
} 
