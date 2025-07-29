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
    @Published var isVideoProcessing: Bool = false
    @Published var showVideoProcessingComplete: Bool = false
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
        // Test: Sıkıştırma öncesi ve sonrası boyutları karşılaştır
        ImageCompressionTest.testCompression(image)
        
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
        isVideoProcessing = false
        showVideoProcessingComplete = false
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
            
            // Önce post'u oluştur (video için ID gerekli)
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
            
            // Answer ise parent question ID'sini ekle
            if selectedPostType == .answer, let parentQuestion = selectedParentQuestion {
                postData["parentQuestionId"] = parentQuestion.id
            }
            
            // Post'u Firestore'a kaydet ve ID'sini al
            let docRef = try await Firestore.firestore()
                .collection("posts")
                .addDocument(data: postData)
            
            let postId = docRef.documentID
            
            // Arkaplan medyasını yükle (varsa)
            var backgroundImageURL: String? = nil
            
            if let image = backgroundImage {
                backgroundImageURL = try await uploadBackgroundImage(image)
                
                // Fotoğraf URL'ini güncelle
                try await docRef.updateData([
                    "backgroundImageURL": backgroundImageURL as Any,
                    "mediaType": "image"
                ])
            } else if let videoURL = backgroundVideo {
                // Video için Firebase Functions formatında yükle
                try await uploadBackgroundVideo(videoURL, postId: postId)
                
                // Video işleme durumunu güncelle
                try await docRef.updateData([
                    "mediaType": "video"
                    // backgroundVideoURL alanını eklemiyoruz, Firebase Functions güncelleyecek
                ])
            }
            
            if backgroundVideo != nil {
                // Video işleniyor mesajı
                successMessage = "Video yüklendi ve işleniyor..."
                isVideoProcessing = true
            } else {
                successMessage = "Gönderi başarıyla oluşturuldu!"
                clearForm()
            }
            
        } catch {
            if let postError = error as? PostError {
                errorMessage = postError.localizedDescription
            } else {
                errorMessage = "Gönderi oluşturulurken hata oluştu: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    // Video işleme durumunu kontrol et
    func checkVideoProcessingStatus() async {
        guard isVideoProcessing else { return }
        
        do {
            // Kullanıcının en son video post'unu kontrol et
            guard let user = Auth.auth().currentUser else { return }
            
            // En basit sorgu: Sadece kullanıcının post'larını al (index gerektirmez)
            let querySnapshot = try await Firestore.firestore()
                .collection("posts")
                .whereField("userId", isEqualTo: user.uid)
                .limit(to: 20) // Son 20 post'u kontrol et
                .getDocuments()
            
            // Manuel olarak video post'larını ve backgroundVideoURL'i kontrol et
            for document in querySnapshot.documents {
                let data = document.data()
                
                // Sadece video post'larını kontrol et
                if let mediaType = data["mediaType"] as? String,
                   mediaType == "video",
                   let backgroundVideoURL = data["backgroundVideoURL"] as? String,
                   !backgroundVideoURL.isEmpty {
                    // Video işleme tamamlandı
                    DispatchQueue.main.async {
                        self.isVideoProcessing = false
                        self.showVideoProcessingComplete = true
                        self.successMessage = "Video işleme tamamlandı!"
                    }
                    return
                }
            }
        } catch {
            print("Video işleme durumu kontrol edilirken hata: \(error)")
        }
    }
    
    // Arkaplan fotoğrafını Firebase Storage'a yükle
    private func uploadBackgroundImage(_ image: UIImage) async throws -> String {
        // 9:16 format için özel sıkıştırma kullan
        guard let compressedImage = ImageCompressionHelper.compressImageForPostWithAspectRatio(image),
              let imageData = compressedImage.jpegData(compressionQuality: ImageCompressionHelper.mediumQuality) else {
            throw PostError.imageCompressionFailed
        }
        
        // Debug: Dosya boyutunu logla
        let fileSize = ImageCompressionHelper.formatFileSize(imageData)
        print("📸 Post image compressed with 9:16 ratio: \(fileSize)")
        
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("post_images/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // Arkaplan video'sunu Firebase Storage'a yükle
    private func uploadBackgroundVideo(_ videoURL: URL, postId: String) async throws {
        // Video dosyasının var olup olmadığını kontrol et
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw PostError.videoUploadFailed
        }
        
        // Firebase Functions için özel format: post_videos/<ID>/src.mov
        let storageRef = Storage.storage().reference().child("post_videos/\(postId)/src.mov")
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        do {
            _ = try await storageRef.putFileAsync(from: videoURL, metadata: metadata)
            
            // Video yüklendi, Firebase Functions video işleme başlayacak
            print("🎬 Video uploaded to Firebase Functions processing path: post_videos/\(postId)/src.mov")
        } catch {
            print("❌ Video upload error: \(error)")
            throw PostError.videoUploadFailed
        }
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