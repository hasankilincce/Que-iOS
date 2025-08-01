import Foundation
import FirebaseFirestore

struct NotificationItem: Identifiable, Codable {
    let id: String
    let type: String
    let fromUserId: String
    let fromDisplayName: String
    let fromUsername: String
    let fromPhotoURL: String?
    let createdAt: Date
    let isRead: Bool
    // Ekstra alanlar (like, comment, mention için)
    let postId: String?
    let commentText: String?
    
    enum NotificationType: String, CaseIterable {
        case follow = "follow"
        case like = "like"
        case comment = "comment"
        case mention = "mention"
        
        var displayText: String {
            switch self {
            case .follow: return "seni takip etmeye başladı"
            case .like: return "gönderini beğendi"
            case .comment: return "gönderine yorum yaptı"
            case .mention: return "bir gönderide seni etiketledi"
            }
        }
        
        var iconName: String {
            switch self {
            case .follow: return "person.badge.plus"
            case .like: return "heart.fill"
            case .comment: return "message.fill"
            case .mention: return "at"
            }
        }
    }
    
    // Convenience initializer for Firestore data
    init(id: String, data: [String: Any]) {
        self.id = id
        self.type = data["type"] as? String ?? ""
        self.fromUserId = data["fromUserId"] as? String ?? ""
        self.fromDisplayName = data["fromDisplayName"] as? String ?? ""
        self.fromUsername = data["fromUsername"] as? String ?? ""
        self.fromPhotoURL = data["fromPhotoURL"] as? String
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.isRead = data["isRead"] as? Bool ?? false
        self.postId = data["postId"] as? String
        self.commentText = data["commentText"] as? String
    }
} 