import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let userPhotoURL: String?
    let content: String
    let imageURLs: [String]
    let createdAt: Date
    var likesCount: Int
    var commentsCount: Int
    var isLiked: Bool = false
    var isBookmarked: Bool = false
    
    // Computed properties
    var hasImages: Bool {
        !imageURLs.isEmpty
    }
    
    var primaryImageURL: String? {
        imageURLs.first
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
        self.imageURLs = data["imageURLs"] as? [String] ?? []
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.likesCount = data["likesCount"] as? Int ?? 0
        self.commentsCount = data["commentsCount"] as? Int ?? 0
        self.isLiked = data["isLiked"] as? Bool ?? false
        self.isBookmarked = data["isBookmarked"] as? Bool ?? false
    }
    
    // Manual initializer
    init(id: String, userId: String, username: String, displayName: String, userPhotoURL: String?, content: String, imageURLs: [String] = [], createdAt: Date = Date(), likesCount: Int = 0, commentsCount: Int = 0, isLiked: Bool = false, isBookmarked: Bool = false) {
        self.id = id
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.userPhotoURL = userPhotoURL
        self.content = content
        self.imageURLs = imageURLs
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
    }
} 