import Foundation
import FirebaseAuth

class SettingsViewModel: ObservableObject {
    @Published var errorMessage: String? = nil
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Uygulama state'inizi güncelleyin (ör: ana ekrana yönlendirme)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // İleride diğer ayar fonksiyonları buraya eklenebilir
} 