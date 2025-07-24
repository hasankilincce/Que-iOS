import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

class EditProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var photoURL: String = ""
    @Published var localProfileImage: UIImage? = nil // Geçici seçilen fotoğraf
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    let userId: String
    private var listener: ListenerRegistration?
    
    init(userId: String) {
        self.userId = userId
        listenProfileChanges()
    }
    
    deinit {
        listener?.remove()
    }
    
    func listenProfileChanges() {
        let db = Firestore.firestore()
        listener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            if let data = snapshot?.data() {
                self?.displayName = data["displayName"] as? String ?? ""
                self?.email = data["email"] as? String ?? ""
                self?.photoURL = data["photoURL"] as? String ?? ""
            }
        }
    }
    
    // Sadece seçilen fotoğrafı geçici olarak göster
    func selectProfilePhoto(_ image: UIImage) {
        self.localProfileImage = image
    }
    
    @MainActor
    func saveProfile(completion: (() -> Void)? = nil) {
        guard let user = Auth.auth().currentUser, user.uid == userId else { return }
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        // Eğer yeni fotoğraf seçildiyse önce Storage'a yükle
        if let image = localProfileImage {
            Task {
                do {
                    let ref = Storage.storage().reference().child("profile_images/\(userId).jpg")
                    let data = image.jpegData(compressionQuality: 0.85) ?? Data()
                    _ = try await ref.putDataAsync(data)
                    let url = try await ref.downloadURL()
                    self.photoURL = url.absoluteString
                    changeRequest.photoURL = url
                    // Firestore'da da güncellenecek
                    self.updateFirestoreProfile(changeRequest: changeRequest, completion: completion)
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        } else {
            if !photoURL.isEmpty {
                changeRequest.photoURL = URL(string: photoURL)
            }
            self.updateFirestoreProfile(changeRequest: changeRequest, completion: completion)
        }
    }
    
    private func updateFirestoreProfile(changeRequest: UserProfileChangeRequest, completion: (() -> Void)? = nil) {
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            let db = Firestore.firestore()
            db.collection("users").document(self?.userId ?? "").updateData([
                "displayName": self?.displayName ?? "",
                "photoURL": self?.photoURL ?? ""
            ]) { err in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let err = err {
                        self?.errorMessage = err.localizedDescription
                    } else {
                        self?.successMessage = "Profil başarıyla güncellendi."
                        self?.localProfileImage = nil // Kaydedince geçici fotoğrafı sıfırla
                        completion?()
                    }
                }
            }
        }
    }
} 
