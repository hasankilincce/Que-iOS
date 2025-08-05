import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class RealTimePersonalizationEngine: ObservableObject {
    static let shared = RealTimePersonalizationEngine()
    
    @Published var isActive: Bool = false
    @Published var currentFilters: [RealTimeContentFilter] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var realTimeScore: Double = 0.0
    
    private let analyticsService = AnalyticsService.shared
    private let mlFunctions = FirebaseMLFunctions.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Real-time scoring
    private var contentScores: [String: Double] = [:]
    private var userBehaviorPatterns: [String: BehaviorPattern] = [:]
    
    // Performance optimization
    private let scoreCache = NSCache<NSString, NSNumber>()
    private let filterCache = NSCache<NSString, NSArray>()
    
    private init() {
        setupRealTimeTracking()
        loadUserPreferences()
    }
    
    // MARK: - Setup
    
    private func setupRealTimeTracking() {
        // Kullanıcı davranışını real-time takip et
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRealTimeScore()
            }
            .store(in: &cancellables)
    }
    
    private func loadUserPreferences() {
        // Kullanıcı kimlik doğrulaması kontrolü
        guard let currentUser = Auth.auth().currentUser else {
            print("Kullanıcı giriş yapmamış, varsayılan tercihler kullanılıyor")
            self.userPreferences = UserPreferences.default
            self.updateFilters()
            return
        }
        
        // Kullanıcının token'ını yenile
        Task {
            do {
                // Token'ı yenile
                let token = try await currentUser.getIDToken(forcingRefresh: true)
                print("Kullanıcı token yenilendi: \(currentUser.uid)")
                
                let preferences = try await mlFunctions.getUserPreferences(userId: currentUser.uid)
                await MainActor.run {
                    self.userPreferences = UserPreferences(from: preferences)
                    self.updateFilters()
                    print("Kullanıcı tercihleri başarıyla yüklendi")
                }
            } catch {
                print("Error loading user preferences: \(error)")
                // Hata durumunda varsayılan tercihler kullan
                await MainActor.run {
                    self.userPreferences = UserPreferences.default
                    self.updateFilters()
                    print("Varsayılan kullanıcı tercihleri kullanılıyor")
                }
            }
        }
    }
    
    // MARK: - Real-time Content Scoring
    
    func calculateContentScore(for post: Post) -> Double {
        let cacheKey = "\(post.id)_\(userPreferences.qualityThreshold)" as NSString
        
        if let cachedScore = scoreCache.object(forKey: cacheKey) {
            return cachedScore.doubleValue
        }
        
        var score: Double = 0.0
        
        // 1. Content Type Preference (30%)
        let contentTypeScore = calculateContentTypeScore(post: post)
        score += contentTypeScore * 0.3
        
        // 2. User Interaction History (25%)
        let interactionScore = calculateInteractionScore(post: post)
        score += interactionScore * 0.25
        
        // 3. Content Quality (20%)
        let qualityScore = calculateQualityScore(post: post)
        score += qualityScore * 0.2
        
        // 4. Recency Factor (15%)
        let recencyScore = calculateRecencyScore(post: post)
        score += recencyScore * 0.15
        
        // 5. Social Proof (10%)
        let socialScore = calculateSocialProofScore(post: post)
        score += socialScore * 0.1
        
        // Cache the result
        scoreCache.setObject(NSNumber(value: score), forKey: cacheKey)
        
        return score
    }
    
    private func calculateContentTypeScore(post: Post) -> Double {
        let userPreferredTypes = userPreferences.allowedContentTypes
        
        if userPreferredTypes.contains(post.mediaType ?? "unknown") {
            return 1.0
        } else if userPreferredTypes.isEmpty {
            return 0.5 // Neutral score for users without preferences
        } else {
            return 0.2 // Lower score for non-preferred types
        }
    }
    
    private func calculateInteractionScore(post: Post) -> Double {
        let authorId = post.userId
        let userInteractions = userPreferences.interactionHistory
        
        // Check if user has interacted with this author before
        let authorInteractions = userInteractions.filter { $0.targetUserId == authorId }
        
        if authorInteractions.isEmpty {
            return 0.5 // Neutral score for new authors
        }
        
        // Calculate positive interaction ratio
        let positiveInteractions = authorInteractions.filter { $0.interactionType == .like || $0.interactionType == .share }.count
        let totalInteractions = authorInteractions.count
        
        return totalInteractions > 0 ? Double(positiveInteractions) / Double(totalInteractions) : 0.5
    }
    
    private func calculateQualityScore(post: Post) -> Double {
        var score: Double = 0.0
        
        // Content length factor
        let contentLength = post.content.count
        if contentLength > 50 && contentLength < 500 {
            score += 0.3
        } else if contentLength >= 500 {
            score += 0.2
        }
        
        // Media quality factor
        if post.hasBackgroundMedia {
            score += 0.4
        }
        
        // Engagement factor
        let engagementRate = Double(post.likesCount + post.commentsCount) / 100.0
        score += min(engagementRate, 0.3)
        
        return min(score, 1.0)
    }
    
    private func calculateRecencyScore(post: Post) -> Double {
        let timeSinceCreation = Date().timeIntervalSince(post.createdAt)
        let hoursSinceCreation = timeSinceCreation / 3600
        
        // Prefer recent content but not too recent
        if hoursSinceCreation < 1 {
            return 0.8
        } else if hoursSinceCreation < 24 {
            return 1.0
        } else if hoursSinceCreation < 168 { // 1 week
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateSocialProofScore(post: Post) -> Double {
        let totalEngagement = post.likesCount + post.commentsCount
        
        if totalEngagement > 100 {
            return 1.0
        } else if totalEngagement > 50 {
            return 0.8
        } else if totalEngagement > 10 {
            return 0.6
        } else if totalEngagement > 0 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    private func calculatePreferenceScore(post: Post) -> Double {
        // Check if post matches user's content preferences
        var score: Double = 0.0
        
        // Video preference
        if post.hasBackgroundVideo && userPreferences.showVideos {
            score += 0.4
        }
        
        // Image preference
        if post.hasBackgroundImage && userPreferences.showImages {
            score += 0.3
        }
        
        // Question preference
        if post.isQuestion && userPreferences.showQuestions {
            score += 0.3
        }
        
        return min(score, 1.0)
    }
    
    private func calculateBehaviorScore(post: Post) -> Double {
        // Analyze recent user behavior patterns
        let recentInteractions = userPreferences.interactionHistory
            .filter { Date().timeIntervalSince($0.timestamp) < 3600 } // Last hour
        
        let positiveInteractions = recentInteractions.filter { $0.interactionType == .like || $0.interactionType == .share }.count
        let totalInteractions = recentInteractions.count
        
        if totalInteractions == 0 {
            return 0.5 // Neutral score if no recent interactions
        }
        
        let positiveRatio = Double(positiveInteractions) / Double(totalInteractions)
        
        // If user is in a positive mood (high positive ratio), show more engaging content
        if positiveRatio > 0.7 {
            return post.likesCount > 10 ? 1.0 : 0.6
        } else if positiveRatio < 0.3 {
            // If user is in a negative mood, show safer content
            return post.likesCount < 50 ? 1.0 : 0.4
        } else {
            return 0.7 // Neutral behavior
        }
    }
    
    // MARK: - Dynamic Filtering
    
    func applyRealTimeFilters(to posts: [Post]) -> [Post] {
        guard isActive else { return posts }
        
        return posts.compactMap { post in
            let score = calculateContentScore(for: post)
            let passesFilters = currentFilters.allSatisfy { filter in
                filter.apply(to: post, score: score)
            }
            
            return passesFilters ? post : nil
        }.sorted { post1, post2 in
            calculateContentScore(for: post1) > calculateContentScore(for: post2)
        }
    }
    
    private func updateFilters() {
        currentFilters = generateDynamicFilters()
    }
    
    private func generateDynamicFilters() -> [RealTimeContentFilter] {
        var filters: [RealTimeContentFilter] = []
        
        // Quality filter
        filters.append(RealTimeContentFilter(
            name: "quality",
            type: .score,
            threshold: userPreferences.qualityThreshold
        ))
        
        // Content type filter
        if !userPreferences.allowedContentTypes.isEmpty {
            filters.append(RealTimeContentFilter(
                name: "content_type",
                type: .contentType,
                allowedTypes: userPreferences.allowedContentTypes
            ))
        }
        
        // Engagement filter
        filters.append(RealTimeContentFilter(
            name: "engagement",
            type: .engagement,
            minEngagement: userPreferences.minEngagement
        ))
        
        return filters
    }
    
    // MARK: - Real-time Score Updates
    
    private func updateRealTimeScore() {
        let recentInteractions = userPreferences.interactionHistory
            .filter { Date().timeIntervalSince($0.timestamp) < 3600 } // Last hour
        
        let positiveInteractions = recentInteractions.filter { $0.interactionType == .like || $0.interactionType == .share }.count
        let totalInteractions = recentInteractions.count
        
        realTimeScore = totalInteractions > 0 ? Double(positiveInteractions) / Double(totalInteractions) : 0.0
        
        // Adjust user preferences based on real-time behavior
        if realTimeScore > 0.7 {
            userPreferences.qualityThreshold = min(userPreferences.qualityThreshold + 0.1, 1.0)
        } else if realTimeScore < 0.3 {
            userPreferences.qualityThreshold = max(userPreferences.qualityThreshold - 0.1, 0.0)
        }
    }
    
    // MARK: - Behavior Pattern Analysis
    
    func analyzeBehaviorPattern(for userId: String) -> BehaviorPattern {
        let userInteractions = userPreferences.interactionHistory
            .filter { $0.targetUserId == userId }
        
        let pattern = BehaviorPattern(
            userId: userId,
            totalInteractions: userInteractions.count,
            positiveInteractions: userInteractions.filter { $0.interactionType == .like || $0.interactionType == .share }.count,
            lastInteractionTime: userInteractions.max(by: { $0.timestamp < $1.timestamp })?.timestamp,
            preferredContentTypes: extractPreferredContentTypes(from: userInteractions)
        )
        
        userBehaviorPatterns[userId] = pattern
        return pattern
    }
    
    private func extractPreferredContentTypes(from interactions: [UserInteraction]) -> [String] {
        // Analyze interaction patterns to determine preferred content types
        var typeCounts: [String: Int] = [:]
        
        for interaction in interactions {
            if let contentType = interaction.metadata["content_type"] {
                typeCounts[contentType, default: 0] += 1
            }
        }
        
        return typeCounts.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    // MARK: - Performance Optimization
    
    func clearCache() {
        scoreCache.removeAllObjects()
        filterCache.removeAllObjects()
    }
    
    func preloadScores(for posts: [Post]) {
        Task {
            for post in posts {
                _ = calculateContentScore(for: post)
            }
        }
    }
    

}

// MARK: - Supporting Models

struct RealTimeContentFilter {
    let name: String
    let type: FilterType
    let threshold: Double
    let allowedTypes: [String]
    let minEngagement: Int
    
    init(name: String, type: FilterType, threshold: Double = 0.5, allowedTypes: [String] = [], minEngagement: Int = 0) {
        self.name = name
        self.type = type
        self.threshold = threshold
        self.allowedTypes = allowedTypes
        self.minEngagement = minEngagement
    }
    
    func apply(to post: Post, score: Double) -> Bool {
        switch type {
        case .score:
            return score >= threshold
        case .contentType:
            return allowedTypes.isEmpty || allowedTypes.contains(post.mediaType ?? "unknown")
        case .engagement:
            return (post.likesCount + post.commentsCount) >= minEngagement
        }
    }
}

enum FilterType {
    case score
    case contentType
    case engagement
}

struct BehaviorPattern {
    let userId: String
    let totalInteractions: Int
    let positiveInteractions: Int
    let lastInteractionTime: Date?
    let preferredContentTypes: [String]
    
    var positiveRatio: Double {
        totalInteractions > 0 ? Double(positiveInteractions) / Double(totalInteractions) : 0.0
    }
    
    var isActive: Bool {
        guard let lastTime = lastInteractionTime else { return false }
        return Date().timeIntervalSince(lastTime) < 86400 // 24 hours
    }
} 