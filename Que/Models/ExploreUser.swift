import Foundation

struct ExploreUser: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let username: String
    let photoURL: String?
    
    var _id: String { id } // For ForEach compatibility
} 