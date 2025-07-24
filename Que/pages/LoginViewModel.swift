import Foundation
import Combine
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import UIKit
import FirebaseCore // FirebaseApp için gerekli

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    func login(completion: @escaping (Bool) -> Void) {
        self.errorMessage = nil
        self.isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
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
