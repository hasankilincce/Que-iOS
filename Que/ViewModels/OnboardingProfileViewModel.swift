import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit
import FirebaseFunctions

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
        usernameCheckTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000) // debounce
            do {
                let result = try await self?.functions.httpsCallable("validateAndReserveUsername").call(["username": username])
                if let dict = result?.data as? [String: Any], dict["available"] as? Bool == true {
                    DispatchQueue.main.async {
                        self?.usernameAvailable = true
                        self?.usernameValidationMessage = "Kullanıcı adı kullanılabilir ve rezerve edildi."
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.usernameAvailable = false
                        self?.usernameValidationMessage = "Kullanıcı adı uygun değil."
                    }
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    self?.usernameAvailable = false
                    // Firebase Functions HttpsError'ın message'ı
                    if let details = error.userInfo["NSLocalizedDescription"] as? String {
                        self?.usernameValidationMessage = details
                    } else {
                        self?.usernameValidationMessage = error.localizedDescription
                    }
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
    
    @MainActor
    func saveProfile(completion: (() -> Void)? = nil) async {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "Kullanıcı oturumu yok."
            return
        }
        isLoading = true
        errorMessage = nil
        // Profil fotoğrafı yüklemesi (varsa)
        if let image = localProfileImage {
            do {
                let ref = Storage.storage().reference().child("profile_images/\(user.uid).jpg")
                let data = image.jpegData(compressionQuality: 0.85) ?? Data()
                _ = try await ref.putDataAsync(data)
                let url = try await ref.downloadURL()
                self.photoURL = url.absoluteString
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                return
            }
        }
        // Firestore'a kaydet
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "displayName": displayName,
            "bio": bio,
            "photoURL": photoURL
        ]
        db.collection("users").document(user.uid).setData(userData, merge: true) { [weak self] err in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let err = err {
                    self?.errorMessage = err.localizedDescription
                } else {
                    self?.success = true
                    completion?()
                }
            }
        }
    }
} 