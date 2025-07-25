import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore

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
        usernameCheckTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000) // debounce
            do {
                let result = try await self?.functions.httpsCallable("checkUsernameAvailable").call(["username": username])
                if let dict = result?.data as? [String: Any], dict["available"] as? Bool == true {
                    DispatchQueue.main.async {
                        self?.usernameAvailable = true
                        self?.usernameValidationMessage = "Kullanıcı adı kullanılabilir."
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
                    if let details = error.userInfo["details"] as? String {
                        self?.usernameValidationMessage = details
                    } else if let message = error.userInfo["NSLocalizedDescription"] as? String {
                        self?.usernameValidationMessage = message
                    } else {
                        self?.usernameValidationMessage = error.localizedDescription
                    }
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
