import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth

struct RegisterPage: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var step: Int = 0
    @State private var emailOrPhone: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState private var focusedField: RegisterField?
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                if step == 0 {
                    Text("Kayıt Ol")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 8)
                    Text("Telefon numarası veya e-posta ile kaydol")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                    TextField("Telefon numarası veya e-posta", text: $emailOrPhone)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 32)
                        .focused($focusedField, equals: .emailOrPhone)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Spacer()
                    Button(action: {
                        withAnimation { step = 1 }
                        focusedField = .username
                    }) {
                        Text("Devam")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(
                                LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(22)
                    }
                    .padding(.bottom, 32)
                    .disabled(!isValidEmailOrPhone(emailOrPhone))
                } else if step == 1 {
                    Text("Kullanıcı Adı ve Şifre")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 8)
                    Text("Kullanıcı adın herkese açık olacak. Şifreni unutma!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                    VStack(spacing: 16) {
                        TextField("Kullanıcı adı", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: viewModel.username) { newValue in
                                let lower = newValue.lowercased()
                                if lower != newValue { viewModel.username = lower }
                                viewModel.checkUsernameAvailability()
                            }
                            .focused($focusedField, equals: .username)
                        if let msg = viewModel.usernameValidationMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(viewModel.usernameAvailable == true ? .green : .red)
                                .padding(.top, -8)
                        }
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
                        if !password.isEmpty && password.count < 6 {
                            Text("Şifre en az 6 karakter olmalı.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                    Button(action: {
                        withAnimation { step = 2 }
                    }) {
                        Text("Devam")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(
                                LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(22)
                    }
                    .padding(.bottom, 32)
                    .disabled(!(viewModel.usernameAvailable == true && password.count >= 6))
                } else if step == 2 {
                    RegisterFinalStepView(emailOrPhone: emailOrPhone, username: viewModel.username, password: password)
                }
            }
            if isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView()
            }
            if let error = errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    Spacer()
                }
            }
        }
    }
    
    func isValidEmailOrPhone(_ value: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let phoneRegex = "^\\+?[0-9]{10,15}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return emailPred.evaluate(with: value) || phonePred.evaluate(with: value)
    }
    
    func checkUsernameAvailability() {
        // Burada onboardingdeki gibi function ile kontrol çağrısı yapılmalı
        // (Kısa örnek, ViewModel'e taşınabilir)
        // ...
    }
}

struct RegisterFinalStepView: View {
    let emailOrPhone: String
    let username: String
    let password: String
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RegisterViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Hesabın oluşturuluyor...")
                .font(.title2.bold())
            if isLoading {
                ProgressView()
            }
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding(.top, 100)
        .onAppear {
            registerUser()
        }
    }
    
    func registerUser() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        if emailOrPhone.contains("@") {
            // E-posta ile kayıt
            Auth.auth().createUser(withEmail: emailOrPhone, password: password) { result, error in
                if let error = error as NSError? {
                    isLoading = false
                    if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        errorMessage = "Bu e-posta ile zaten bir hesap var."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    return
                }
                guard let uid = result?.user.uid else {
                    isLoading = false
                    errorMessage = "Kullanıcı oluşturulamadı."
                    return
                }
                viewModel.saveUserToFirestore(uid: uid, email: emailOrPhone, phone: nil, username: username) { success in
                    isLoading = false
                    if success {
                        // Onboarding'e yönlendir
                        appState.needsOnboarding = true
                        dismiss()
                    } else {
                        errorMessage = "Kullanıcı verileri kaydedilemedi."
                    }
                }
            }
        } else {
            // Telefon ile kayıt (örnek, gerçek uygulamada SMS doğrulama gerekir)
            isLoading = false
            errorMessage = "Telefon ile kayıt için SMS doğrulama entegrasyonu gereklidir."
        }
    }
}
