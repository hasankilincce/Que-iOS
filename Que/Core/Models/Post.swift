import Foundation
import FirebaseFirestore

// Post türlerini tanımlayan enum
enum PostType: String, CaseIterable, Codable {
    case question = "question"
    case answer = "answer"
    
    var displayName: String {
        switch self {
        case .question:
            return "Soru"
        case .answer:
            return "Cevap"
        }
    }
    
    var icon: String {
        switch self {
        case .question:
            return "questionmark.circle"
        case .answer:
            return "checkmark.circle"
        }
    }
}

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let userPhotoURL: String?
    let content: String
    let postType: PostType
    
    // Eski imageURLs field'ını backgroundImageURL ile değiştiriyoruz
    // Question ve Answer'lar için tek arkaplan fotoğrafı
    let backgroundImageURL: String?
    
    // Video desteği ekliyoruz
    let backgroundVideoURL: String?
    
    // Cloud Functions ile işlenen medya için
    let mediaType: String?
    let mediaURL: String?
    
    // Answer postları için parent question ID'si
    let parentQuestionId: String?
    
    let createdAt: Date
    var likesCount: Int
    var commentsCount: Int
    var isLiked: Bool = false
    var isBookmarked: Bool = false
    
    // Like state management için mutating fonksiyonlar
    mutating func toggleLike() {
        isLiked.toggle()
        likesCount += isLiked ? 1 : -1
    }
    
    mutating func setLikeState(liked: Bool, count: Int) {
        isLiked = liked
        likesCount = count
    }
    
    // Computed properties
    var hasBackgroundImage: Bool {
        backgroundImageURL != nil && !backgroundImageURL!.isEmpty
    }
    
    var hasBackgroundVideo: Bool {
        backgroundVideoURL != nil && !backgroundVideoURL!.isEmpty
    }
    
    var hasBackgroundMedia: Bool {
        hasBackgroundImage || hasBackgroundVideo || (mediaType != nil && mediaURL != nil)
    }
    
    var isQuestion: Bool {
        postType == .question
    }
    
    var isAnswer: Bool {
        postType == .answer
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    // Convenience initializer for Firestore data
    init(id: String, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.displayName = data["displayName"] as? String ?? ""
        self.userPhotoURL = data["userPhotoURL"] as? String
        self.content = data["content"] as? String ?? ""
        
        // PostType'ı parse et
        if let typeString = data["postType"] as? String,
           let type = PostType(rawValue: typeString) {
            self.postType = type
        } else {
            // Backward compatibility için eski postları question olarak kabul et
            self.postType = .question
        }
        
        self.backgroundImageURL = data["backgroundImageURL"] as? String
        self.backgroundVideoURL = data["backgroundVideoURL"] as? String
        self.mediaType = data["mediaType"] as? String
        self.mediaURL = data["mediaURL"] as? String
        self.parentQuestionId = data["parentQuestionId"] as? String
        
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.likesCount = data["likesCount"] as? Int ?? 0
        self.commentsCount = data["commentsCount"] as? Int ?? 0
        self.isLiked = data["isLiked"] as? Bool ?? false
        self.isBookmarked = data["isBookmarked"] as? Bool ?? false
    }
    
    // Manual initializer
    init(id: String, userId: String, username: String, displayName: String, userPhotoURL: String?, content: String, postType: PostType, backgroundImageURL: String? = nil, backgroundVideoURL: String? = nil, mediaType: String? = nil, mediaURL: String? = nil, parentQuestionId: String? = nil, createdAt: Date = Date(), likesCount: Int = 0, commentsCount: Int = 0, isLiked: Bool = false, isBookmarked: Bool = false) {
        self.id = id
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.userPhotoURL = userPhotoURL
        self.content = content
        self.postType = postType
        self.backgroundImageURL = backgroundImageURL
        self.backgroundVideoURL = backgroundVideoURL
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.parentQuestionId = parentQuestionId
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
    }
} 