import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

@MainActor
class AddPostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedPostType: PostType = .question
    @Published var backgroundImage: UIImage? = nil
    @Published var backgroundVideo: URL? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    
    // Answer için parent question seçimi
    @Published var selectedParentQuestion: Post? = nil
    @Published var availableQuestions: [Post] = []
    
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
        do {
            let querySnapshot = try await Firestore.firestore()
                .collection("posts")
                .whereField("postType", isEqualTo: "question")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            availableQuestions = querySnapshot.documents.compactMap { doc in
                Post(id: doc.documentID, data: doc.data())
            }
        } catch {
            errorMessage = "Sorular yüklenirken hata oluştu: \(error.localizedDescription)"
        }
    }
    
    // Arkaplan fotoğrafı ekleme
    func setBackgroundImage(_ image: UIImage) {
        backgroundImage = image
        backgroundVideo = nil // Fotoğraf seçildiğinde video'yu temizle
    }
    
    // Arkaplan video'su ekleme
    func setBackgroundVideo(_ videoURL: URL) {
        backgroundVideo = videoURL
        backgroundImage = nil // Video seçildiğinde fotoğrafı temizle
    }
    
    // Arkaplan medyasını kaldır
    func removeBackgroundMedia() {
        backgroundImage = nil
        backgroundVideo = nil
    }
    
    // Formu temizle
    func clearForm() {
        content = ""
        backgroundImage = nil
        backgroundVideo = nil
        selectedParentQuestion = nil
        errorMessage = nil
        successMessage = nil
    }
    
    // Post oluştur
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
            
            // Arkaplan medyasını yükle (varsa)
            var backgroundImageURL: String? = nil
            var backgroundVideoURL: String? = nil
            
            if let image = backgroundImage {
                backgroundImageURL = try await uploadBackgroundImage(image)
            } else if let videoURL = backgroundVideo {
                backgroundVideoURL = try await uploadBackgroundVideo(videoURL)
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
            
            // Arkaplan medyası varsa ekle
            if let backgroundImageURL = backgroundImageURL {
                postData["backgroundImageURL"] = backgroundImageURL
            }
            if let backgroundVideoURL = backgroundVideoURL {
                postData["backgroundVideoURL"] = backgroundVideoURL
            }
            
            // Answer ise parent question ID'sini ekle
            if selectedPostType == .answer, let parentQuestion = selectedParentQuestion {
                postData["parentQuestionId"] = parentQuestion.id
            }
            
            let docRef = try await Firestore.firestore()
                .collection("posts")
                .addDocument(data: postData)
            
            successMessage = "Gönderi başarıyla oluşturuldu!"
            clearForm()
            
        } catch {
            if let postError = error as? PostError {
                errorMessage = postError.localizedDescription
            } else {
                errorMessage = "Gönderi oluşturulurken hata oluştu: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    // Arkaplan fotoğrafını Firebase Storage'a yükle
    private func uploadBackgroundImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PostError.imageCompressionFailed
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("post_images/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // Arkaplan video'sunu Firebase Storage'a yükle
    private func uploadBackgroundVideo(_ videoURL: URL) async throws -> String {
        let filename = "\(UUID().uuidString).mov"
        let storageRef = Storage.storage().reference().child("post_videos/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        _ = try await storageRef.putFileAsync(from: videoURL, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
}

// MARK: - Post Error
enum PostError: LocalizedError {
    case userDataNotFound
    case imageCompressionFailed
    case videoUploadFailed
    
    var errorDescription: String? {
        switch self {
        case .userDataNotFound:
            return "Kullanıcı bilgileri bulunamadı."
        case .imageCompressionFailed:
            return "Fotoğraf sıkıştırılamadı."
        case .videoUploadFailed:
            return "Video yüklenemedi."
        }
    }
} 