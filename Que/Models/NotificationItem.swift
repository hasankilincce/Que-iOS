import Foundation

struct NotificationItem: Identifiable {
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
} 