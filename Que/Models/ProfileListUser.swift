import Foundation

struct ProfileListUser: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let username: String
    let photoURL: String?
    var isFollowing: Bool? = nil
    
    // Convenience initializer for Firestore data
    init(id: String, data: [String: Any]) {
        self.id = id
        self.displayName = data["displayName"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String
        self.isFollowing = data["isFollowing"] as? Bool
    }
    
    // Manual initializer
    init(id: String, displayName: String, username: String, photoURL: String?, isFollowing: Bool? = nil) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.photoURL = photoURL
        self.isFollowing = isFollowing
    }
} 