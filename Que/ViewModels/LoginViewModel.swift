import Foundation
import Combine
import FirebaseAuth
import FirebaseFunctions
import GoogleSignIn
import GoogleSignInSwift
import UIKit
import FirebaseCore

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var loginSuccess: Bool = false
    
    private let functions = Functions.functions(region: "us-east1")
    
    var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !password.isEmpty
    }
    
    func login() async {
        guard isFormValid else {
            errorMessage = "Kullanıcı adı ve şifre gerekli."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Username'i email'e çevir
            let result: Result<[String: Any]?, Error> = await Task.detached {
                do {
                    let callResult = try await self.functions.httpsCallable("loginWithUsername").call(["username": self.username, "password": self.password])
                    return .success(callResult.data as? [String: Any])
                } catch {
                    return .failure(error)
                }
            }.value
            
            switch result {
            case .success(let data):
                guard let data = data, let email = data["email"] as? String else {
                    throw LoginError.userNotFound
                }
                
                // Firebase Auth ile giriş yap
                try await Auth.auth().signIn(withEmail: email, password: password)
                loginSuccess = true
                
            case .failure(let error):
                throw error
            }
            
        } catch {
            if let authError = error as? AuthErrorCode {
                switch authError.code {
                case .userNotFound:
                    errorMessage = "Kullanıcı bulunamadı."
                case .wrongPassword:
                    errorMessage = "Yanlış şifre."
                case .invalidEmail:
                    errorMessage = "Geçersiz e-posta formatı."
                case .userDisabled:
                    errorMessage = "Hesap devre dışı bırakılmış."
                default:
                    errorMessage = "Giriş yapılırken hata oluştu."
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func signInWithGoogle(presentingVC: UIViewController, completion: @escaping (Bool) -> Void) {
        self.errorMessage = nil
        self.isLoading = true
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Google Client ID bulunamadı."
            self.isLoading = false
            completion(false)
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                    completion(false)
                }
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Google kimlik doğrulama başarısız."
                    self?.isLoading = false
                    completion(false)
                }
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
} 

// Error enum
enum LoginError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Kullanıcı bulunamadı veya e-posta eksik."
        case .invalidCredentials:
            return "Kullanıcı adı veya şifre hatalı."
        case .networkError:
            return "Ağ bağlantısı hatası."
        }
    }
} 
