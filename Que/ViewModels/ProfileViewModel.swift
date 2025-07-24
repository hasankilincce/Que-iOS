import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var photoURL: String? = nil
    @Published var isCurrentUser: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    let userId: String
    
    init(userId: String? = nil) {
        let currentUser = Auth.auth().currentUser
        self.userId = userId ?? currentUser?.uid ?? ""
        self.isCurrentUser = (userId == nil) || (userId == currentUser?.uid)
        fetchUser()
    }
    
    func fetchUser() {
        self.isLoading = true
        self.errorMessage = nil
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let data = snapshot?.data() else {
                    self?.errorMessage = "Kullanıcı bulunamadı."
                    return
                }
                self?.displayName = data["displayName"] as? String ?? ""
                self?.email = data["email"] as? String ?? ""
                self?.photoURL = data["photoURL"] as? String
            }
        }
    }
} 