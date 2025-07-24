import Foundation
import Combine
import FirebaseAuth

class RegisterViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    func register(completion: @escaping (Bool) -> Void) {
        self.errorMessage = nil
        guard password == confirmPassword else {
            self.errorMessage = "Şifreler eşleşmiyor."
            completion(false)
            return
        }
        self.isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
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