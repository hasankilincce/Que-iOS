import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

@MainActor
class AddPostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedPostType: PostType = .question
    @Published var backgroundImage: UIImage? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var showImagePicker: Bool = false
    @Published var showCamera: Bool = false
    
    // Answer için parent question seçimi
    @Published var selectedParentQuestion: Post? = nil
    @Published var availableQuestions: [Post] = []
    @Published var isLoadingQuestions: Bool = false
    
    private let maxContentLength = 280
    
    var remainingCharacters: Int {
        maxContentLength - content.count
    }
    
    var isContentValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && content.count <= maxContentLength
    }
    
    var canPost: Bool {
        guard isContentValid && !isLoading else { return false }
        
        // Answer ise parent question seçilmiş olmalı
        if selectedPostType == .answer {
            return selectedParentQuestion != nil
        }
        
        return true
    }
    
    // Post tipini değiştir
    func changePostType(to newType: PostType) {
        selectedPostType = newType
        
        // Answer seçildiğinde available questions'ı yükle
        if newType == .answer && availableQuestions.isEmpty {
            Task {
                await loadAvailableQuestions()
            }
        }
        
        // Post tipini değiştirirken formu temizle
        clearForm()
    }
    
    // Answer için mevcut soruları yükle
    func loadAvailableQuestions() async {
        isLoadingQuestions = true
        
        do {
            let querySnapshot = try await Firestore.firestore()
                .collection("posts")
                .whereField("postType", isEqualTo: "question")
                .order(by: "createdAt", descending: true)
                .limit(to: 50) // Son 50 soruyu getir
                .getDocuments()
            
            availableQuestions = querySnapshot.documents.compactMap { doc in
                Post(id: doc.documentID, data: doc.data())
            }
        } catch {
            errorMessage = "Sorular yüklenirken hata oluştu: \(error.localizedDescription)"
        }
        
        isLoadingQuestions = false
    }
    
    // Arkaplan fotoğrafı ekleme
    func setBackgroundImage(_ image: UIImage) {
        // 9:16 aspect ratio'ya göre resize et (dikey format)
        backgroundImage = resizeImageToAspectRatio(image, aspectRatio: 9.0/16.0)
    }
    
    // Arkaplan fotoğrafını kaldır
    func removeBackgroundImage() {
        backgroundImage = nil
    }
    
    // Parent question seç
    func selectParentQuestion(_ question: Post) {
        selectedParentQuestion = question
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
            
            // Arkaplan fotoğrafını yükle (varsa)
            var backgroundImageURL: String? = nil
            if let image = backgroundImage {
                backgroundImageURL = try await uploadBackgroundImage(image)
            }
            
            // Post'u Firestore'a kaydet
            var postData: [String: Any] = [
                "userId": user.uid,
                "username": username,
                "displayName": displayName,
                "userPhotoURL": userData["photoURL"] as? String ?? "",
                "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
                "postType": selectedPostType.rawValue,
                "likesCount": 0,
                "commentsCount": 0,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // Arkaplan fotoğrafı varsa ekle
            if let backgroundImageURL = backgroundImageURL {
                postData["backgroundImageURL"] = backgroundImageURL
            }
            
            // Answer ise parent question ID'sini ekle
            if selectedPostType == .answer, let parentQuestion = selectedParentQuestion {
                postData["parentQuestionId"] = parentQuestion.id
            }
            
            try await Firestore.firestore()
                .collection("posts")
                .addDocument(data: postData)
            
            // Success - reset form
            clearForm()
            successMessage = selectedPostType == .question ? "Sorunuz başarıyla paylaşıldı!" : "Cevabınız başarıyla paylaşıldı!"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Private helper: Arkaplan fotoğrafı yükleme
    private func uploadBackgroundImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PostError.imageProcessingFailed
        }
        
        let fileName = "\(UUID().uuidString)_background.jpg"
        let storageRef = Storage.storage().reference()
            .child("background_images")
            .child(fileName)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // Helper: Image'ı belirli aspect ratio'ya resize et
    private func resizeImageToAspectRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let targetSize = CGSize(width: 720, height: 720 / aspectRatio) // 9:16 için 720x1280
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // Form temizle
    func clearForm() {
        content = ""
        backgroundImage = nil
        selectedParentQuestion = nil
        errorMessage = nil
        successMessage = nil
    }
}

// Error enum
enum PostError: LocalizedError {
    case userDataNotFound
    case imageProcessingFailed
    case uploadFailed
    case parentQuestionRequired
    
    var errorDescription: String? {
        switch self {
        case .userDataNotFound:
            return "Kullanıcı bilgileri alınamadı."
        case .imageProcessingFailed:
            return "Fotoğraf işlenirken hata oluştu."
        case .uploadFailed:
            return "Fotoğraf yüklenirken hata oluştu."
        case .parentQuestionRequired:
            return "Cevap vermek için bir soru seçmelisiniz."
        }
    }
} 