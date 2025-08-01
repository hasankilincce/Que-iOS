import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

class EditProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var bio: String = ""
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
                self?.username = data["username"] as? String ?? ""
                self?.bio = data["bio"] as? String ?? ""
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
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let ref = Storage.storage().reference().child("profile_images/\(userId)_\(timestamp).jpg")
                    
                    guard let data = ImageCompressionHelper.createJPEGDataForProfile(image) else {
                        throw NSError(domain: "ImageCompression", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fotoğraf sıkıştırılamadı"])
                    }
                    
                    // Debug: Dosya boyutunu logla
                    let fileSize = ImageCompressionHelper.formatFileSize(data)
                    print("👤 Profile image compressed: \(fileSize)")
                    
                    _ = try await ref.putDataAsync(data)
                    let url = try await ref.downloadURL()
                    // (İsteğe bağlı) Eski fotoğrafı sil:
                    /*
                    if !photoURL.isEmpty, let oldURL = URL(string: photoURL), let oldPath = oldURL.pathComponents.dropFirst(2).joined(separator: "/") as String? {
                        let oldRef = Storage.storage().reference(withPath: oldPath)
                        try? await oldRef.delete()
                    }
                    */
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
            let keywords = EditProfileViewModel.generateSearchKeywords(displayName: self?.displayName ?? "", username: self?.username ?? "")
            db.collection("users").document(self?.userId ?? "").updateData([
                "displayName": self?.displayName ?? "",
                "username": self?.username ?? "",
                "bio": self?.bio ?? "",
                "photoURL": self?.photoURL ?? "",
                "searchKeywords": keywords
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
    
    static func generateSearchKeywords(displayName: String, username: String) -> [String] {
        let nameParts = displayName.lowercased().split(separator: " ").map { String($0) }
        var keywords: Set<String> = []
        for part in nameParts { keywords.insert(part) }
        keywords.insert(displayName.lowercased())
        keywords.insert(username.lowercased())
        return Array(keywords)
    }
} 
