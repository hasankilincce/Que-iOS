import Foundation
import FirebaseAuth

class HomeViewModel: ObservableObject {
    @Published var displayName: String = ""
    
    init() {
        if let user = Auth.auth().currentUser {
            self.displayName = user.displayName ?? user.email ?? "Kullanıcı"
        } else {
            self.displayName = "Kullanıcı"
        }
    }
    
    func signOut(completion: (() -> Void)? = nil) {
        do {
            try Auth.auth().signOut()
            completion?()
        } catch {
            print("Çıkış yapılamadı: \(error.localizedDescription)")
        }
    }
} 