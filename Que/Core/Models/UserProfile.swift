import Foundation
import FirebaseFirestore

struct UserProfile: Codable {
    let userId: String
    let username: String
    let displayName: String
    let photoURL: String?
    
    // Kişiselleştirme için yeni alanlar
    var interests: [String] = []
    var preferredTopics: [String] = []
    var followingIds: [String] = []
    var blockedUserIds: [String] = []
    
    // Etkileşim geçmişi
    var interactionHistory: [UserInteraction] = []
    
    // Tercihler
    var preferences: UserPreferences
    
    // Computed properties
    var hasInterests: Bool {
        !interests.isEmpty
    }
    
    var hasPreferences: Bool {
        preferences.isConfigured
    }
    
    init(userId: String, username: String, displayName: String, photoURL: String? = nil) {
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.photoURL = photoURL
        self.preferences = UserPreferences()
    }
    
    init(id: String, data: [String: Any]) {
        self.userId = id
        self.username = data["username"] as? String ?? ""
        self.displayName = data["displayName"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String
        self.interests = data["interests"] as? [String] ?? []
        self.preferredTopics = data["preferredTopics"] as? [String] ?? []
        self.followingIds = data["followingIds"] as? [String] ?? []
        self.blockedUserIds = data["blockedUserIds"] as? [String] ?? []
        
        if let interactionData = data["interactionHistory"] as? [[String: Any]] {
            self.interactionHistory = interactionData.compactMap { UserInteraction(data: $0) }
        } else {
            self.interactionHistory = []
        }
        
        if let preferencesData = data["preferences"] as? [String: Any] {
            self.preferences = UserPreferences(data: preferencesData)
        } else {
            self.preferences = UserPreferences()
        }
    }
}

struct UserPreferences: Codable {
    var showQuestions: Bool = true
    var showAnswers: Bool = true
    var showVideos: Bool = true
    var showImages: Bool = true
    var preferredLanguage: String = "tr"
    var contentFilter: UserContentFilter = .moderate
    var notificationSettings: NotificationSettings = NotificationSettings()
    
    // Real-time personalization settings
    var qualityThreshold: Double = 0.5
    var minEngagementThreshold: Int = 0
    var preferredContentTypes: [String] = []
    var interactionHistory: [UserInteraction] = []
    var realTimeScoringEnabled: Bool = true
    var adaptiveThreshold: Bool = true
    var learningRate: Double = 0.1
    
    var isConfigured: Bool {
        // Kullanıcının tercihlerini yapılandırıp yapılandırmadığını kontrol et
        return true // Basit kontrol, daha karmaşık olabilir
    }
    
    init() {}
    
    init(data: [String: Any]) {
        self.showQuestions = data["showQuestions"] as? Bool ?? true
        self.showAnswers = data["showAnswers"] as? Bool ?? true
        self.showVideos = data["showVideos"] as? Bool ?? true
        self.showImages = data["showImages"] as? Bool ?? true
        self.preferredLanguage = data["preferredLanguage"] as? String ?? "tr"
        
        if let filterString = data["contentFilter"] as? String {
            self.contentFilter = UserContentFilter(rawValue: filterString) ?? .moderate
        }
        
        if let notificationData = data["notificationSettings"] as? [String: Any] {
            self.notificationSettings = NotificationSettings(data: notificationData)
        }
        
        // Real-time personalization settings
        self.qualityThreshold = data["qualityThreshold"] as? Double ?? 0.5
        self.minEngagementThreshold = data["minEngagementThreshold"] as? Int ?? 0
        self.preferredContentTypes = data["preferredContentTypes"] as? [String] ?? []
        self.realTimeScoringEnabled = data["realTimeScoringEnabled"] as? Bool ?? true
        self.adaptiveThreshold = data["adaptiveThreshold"] as? Bool ?? true
        self.learningRate = data["learningRate"] as? Double ?? 0.1
        
        if let interactionsData = data["interactionHistory"] as? [[String: Any]] {
            self.interactionHistory = interactionsData.compactMap { UserInteraction(data: $0) }
        }
    }
    
    init(from data: [String: Any]) {
        self.init(data: data)
    }
    
    static var `default`: UserPreferences {
        return UserPreferences()
    }
}

enum UserContentFilter: String, CaseIterable, Codable {
    case strict = "strict"
    case moderate = "moderate"
    case relaxed = "relaxed"
    
    var displayName: String {
        switch self {
        case .strict: return "Sıkı"
        case .moderate: return "Orta"
        case .relaxed: return "Rahat"
        }
    }
}

struct NotificationSettings: Codable {
    var likeNotifications: Bool = true
    var commentNotifications: Bool = true
    var followNotifications: Bool = true
    var questionNotifications: Bool = true
    
    init() {}
    
    init(data: [String: Any]) {
        self.likeNotifications = data["likeNotifications"] as? Bool ?? true
        self.commentNotifications = data["commentNotifications"] as? Bool ?? true
        self.followNotifications = data["followNotifications"] as? Bool ?? true
        self.questionNotifications = data["questionNotifications"] as? Bool ?? true
    }
}

struct UserInteraction: Codable {
    let postId: String
    let targetUserId: String
    let interactionType: InteractionType
    let timestamp: Date
    let duration: TimeInterval? // Video izleme süresi
    let metadata: [String: String]
    
    enum InteractionType: String, Codable {
        case like = "like"
        case unlike = "unlike"
        case comment = "comment"
        case share = "share"
        case view = "view"
        case skip = "skip"
        case report = "report"
    }
    
    init(postId: String, targetUserId: String, interactionType: InteractionType, duration: TimeInterval? = nil, metadata: [String: String] = [:]) {
        self.postId = postId
        self.targetUserId = targetUserId
        self.interactionType = interactionType
        self.timestamp = Date()
        self.duration = duration
        self.metadata = metadata
    }
    
    init(data: [String: Any]) {
        self.postId = data["postId"] as? String ?? ""
        self.targetUserId = data["targetUserId"] as? String ?? ""
        
        if let typeString = data["interactionType"] as? String,
           let type = InteractionType(rawValue: typeString) {
            self.interactionType = type
        } else {
            self.interactionType = .view
        }
        
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.duration = data["duration"] as? TimeInterval
        self.metadata = data["metadata"] as? [String: String] ?? [:]
    }
    
    init(from data: [String: Any]) {
        self.init(data: data)
    }
} 