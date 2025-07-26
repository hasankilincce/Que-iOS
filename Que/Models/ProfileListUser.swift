import Foundation

struct ProfileListUser: Identifiable, Hashable {
    let id: String
    let displayName: String
    let username: String
    let photoURL: String?
    var isFollowing: Bool? = nil
} 