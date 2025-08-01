import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var usernameAvailable: Bool? = nil
    @Published var usernameValidationMessage: String? = nil
    private var usernameCheckTask: Task<Void, Never>? = nil
    private lazy var functions = Functions.functions(region: "us-east1")
    
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
                    let callResult = try await self.functions.httpsCallable("checkUsernameAvailable").call(["username": username])
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
                    self.usernameValidationMessage = "Kullanıcı adı kullanılabilir."
                } else {
                    self.usernameAvailable = false
                    self.usernameValidationMessage = "Kullanıcı adı uygun değil."
                }
            case .failure(let error as NSError):
                self.usernameAvailable = false
                if let details = error.userInfo["details"] as? String {
                    self.usernameValidationMessage = details
                } else if let message = error.userInfo["NSLocalizedDescription"] as? String {
                    self.usernameValidationMessage = message
                } else {
                    self.usernameValidationMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveUserToFirestore(uid: String, email: String?, phone: String?, username: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let displayName = username // veya başka bir displayName kaynağı
        let keywords = RegisterViewModel.generateSearchKeywords(displayName: displayName, username: username)
        var data: [String: Any] = [
            "uid": uid,
            "username": username,
            "displayName": displayName,
            "searchKeywords": keywords
        ]
        if let email = email { data["email"] = email }
        if let phone = phone { data["phone"] = phone }
        db.collection("users").document(uid).setData(data) { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    static func generateSearchKeywords(displayName: String, username: String) -> [String] {
        let nameParts = displayName.lowercased().split(separator: " ").map { String($0) }
        var keywords: Set<String> = []
        for part in nameParts { keywords.insert(part) }
        keywords.insert(displayName.lowercased())
        keywords.insert(username.lowercased())
        return Array(keywords)
    }
} 
