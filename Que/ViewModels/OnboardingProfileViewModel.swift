import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseFunctions
import SwiftUI

@MainActor
class OnboardingProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var localProfileImage: UIImage? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var success: Bool = false
    @Published var usernameAvailable: Bool? = nil
    @Published var usernameValidationMessage: String? = nil
    @Published var photoURL: String = ""
    private var usernameCheckTask: Task<Void, Never>? = nil
    private lazy var functions = Functions.functions()
    
    func selectProfilePhoto(_ image: UIImage) {
        self.localProfileImage = image
    }
    
    func validateUsername(_ username: String) -> String? {
        let regex = "^[a-z0-9](?!.*[_.]{2})[a-z0-9._]{1,28}[a-z0-9]$"
        let pred = NSPredicate(format: "SELF MATCHES[c] %@", regex)
        if username.count < 3 || username.count > 30 {
            return "Kullanıcı adı 3-30 karakter olmalı."
        }
        if !pred.evaluate(with: username) {
            return "Sadece harf, rakam, nokta ve alt çizgi kullanılabilir. Başta/sonda veya arka arkaya nokta/alt çizgi olamaz."
        }
        return nil
    }
    
    func checkUsernameAvailability() {
        usernameCheckTask?.cancel()
        let username = self.username
        if let validationError = validateUsername(username) {
            self.usernameAvailable = false
            self.usernameValidationMessage = validationError
            return
        }
        self.usernameValidationMessage = nil
        self.usernameAvailable = nil
        usernameCheckTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000) // debounce
            
            guard let self = self else { return }
            
            // Firebase Functions call'ını detached task içinde yap ve sadece sendable data döndür
            let result: Result<[String: Any]?, Error> = await Task.detached {
                do {
                    let callResult = try await self.functions.httpsCallable("validateAndReserveUsername").call(["username": username])
                    return .success(callResult.data as? [String: Any])
                } catch {
                    return .failure(error)
                }
            }.value
            
            // Sonucu main actor'da işle
            switch result {
            case .success(let dict):
                if let dict = dict, dict["available"] as? Bool == true {
                    self.usernameAvailable = true
                    self.usernameValidationMessage = "Kullanıcı adı kullanılabilir ve rezerve edildi."
                } else {
                    self.usernameAvailable = false
                    self.usernameValidationMessage = "Kullanıcı adı uygun değil."
                }
            case .failure(let error as NSError):
                self.usernameAvailable = false
                // Firebase Functions HttpsError'ın message'ı
                if let details = error.userInfo["NSLocalizedDescription"] as? String {
                    self.usernameValidationMessage = details
                } else {
                    self.usernameValidationMessage = error.localizedDescription
                }
            }
        }
    }
    
    func validateFields() -> Bool {
        if username.trimmingCharacters(in: .whitespaces).isEmpty ||
            displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Kullanıcı adı ve görünen ad zorunludur."
            return false
        }
        if usernameAvailable != true {
            errorMessage = usernameValidationMessage ?? "Kullanıcı adı uygun değil."
            return false
        }
        return true
    }
    
    func saveProfile(user: User) async {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "username": username,
            "displayName": displayName,
            "bio": bio,
            "photoURL": photoURL
        ]
        
        do {
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
            self.isLoading = false
            self.success = true
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
} 