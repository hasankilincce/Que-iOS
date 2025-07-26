import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

@MainActor
class AddPostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedImages: [UIImage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var showImagePicker: Bool = false
    @Published var showCamera: Bool = false
    
    private let maxImages = 4
    private let maxContentLength = 280
    
    var remainingCharacters: Int {
        maxContentLength - content.count
    }
    
    var isContentValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && content.count <= maxContentLength
    }
    
    var canPost: Bool {
        isContentValid && !isLoading
    }
    
    // Fotoğraf ekleme
    func addImage(_ image: UIImage) {
        guard selectedImages.count < maxImages else {
            errorMessage = "En fazla \(maxImages) fotoğraf ekleyebilirsiniz."
            return
        }
        selectedImages.append(image)
    }
    
    // Fotoğraf silme
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    // Gönderi oluştur
    func createPost() async {
        guard canPost else { return }
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Kullanıcı oturumu bulunamadı."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Kullanıcı bilgilerini al
            let userDoc = try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .getDocument()
            
            guard let userData = userDoc.data(),
                  let username = userData["username"] as? String,
                  let displayName = userData["displayName"] as? String else {
                throw PostError.userDataNotFound
            }
            
            // Fotoğrafları yükle
            var imageURLs: [String] = []
            for (index, image) in selectedImages.enumerated() {
                let imageURL = try await uploadImage(image, index: index)
                imageURLs.append(imageURL)
            }
            
            // Post'u Firestore'a kaydet
            let postData: [String: Any] = [
                "userId": user.uid,
                "username": username,
                "displayName": displayName,
                "userPhotoURL": userData["photoURL"] as? String ?? "",
                "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
                "imageURLs": imageURLs,
                "likesCount": 0,
                "commentsCount": 0,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await Firestore.firestore()
                .collection("posts")
                .addDocument(data: postData)
            
            // Success - reset form
            content = ""
            selectedImages = []
            successMessage = "Gönderiniz başarıyla paylaşıldı!"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Private helper: Fotoğraf yükleme
    private func uploadImage(_ image: UIImage, index: Int) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PostError.imageProcessingFailed
        }
        
        let fileName = "\(UUID().uuidString)_\(index).jpg"
        let storageRef = Storage.storage().reference()
            .child("post_images")
            .child(fileName)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // Form temizle
    func clearForm() {
        content = ""
        selectedImages = []
        errorMessage = nil
        successMessage = nil
    }
}

// Error enum
enum PostError: LocalizedError {
    case userDataNotFound
    case imageProcessingFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .userDataNotFound:
            return "Kullanıcı bilgileri alınamadı."
        case .imageProcessingFailed:
            return "Fotoğraf işlenirken hata oluştu."
        case .uploadFailed:
            return "Fotoğraf yüklenirken hata oluştu."
        }
    }
} 