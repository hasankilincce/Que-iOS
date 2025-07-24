import Foundation
import Combine
import FirebaseAuth

class ResetPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var errorMessage: String? = nil
    @Published var infoMessage: String? = nil
    @Published var isLoading: Bool = false
    
    func resetPassword() {
        self.errorMessage = nil
        self.infoMessage = nil
        self.isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.infoMessage = "Şifre sıfırlama maili gönderildi."
                }
            }
        }
    }
} 