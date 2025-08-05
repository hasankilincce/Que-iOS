import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RecommendationEngine: ObservableObject {
    static let shared = RecommendationEngine()
    
    @Published var userProfile: UserProfile?
    @Published var isPersonalized: Bool = false
    
    private let db = Firestore.firestore()
    private var currentAlgorithm: RecommendationAlgorithm = .hybrid
    
    // Cache
    private var userSimilarityCache: [String: Double] = [:]
    private var contentScoreCache: [String: Double] = [:]
    
    private init() {
        loadUserProfile()
    }
    
    // MARK: - User Profile Management
    
    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data() else { return }
            
            self.userProfile = UserProfile(id: userId, data: data)
            self.isPersonalized = self.userProfile?.hasInterests == true
        }
    }
    
    func updateUserInterests(_ interests: [String]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "interests": interests
        ]) { [weak self] error in
            if error == nil {
                self?.userProfile?.interests = interests
                self?.isPersonalized = !interests.isEmpty
            }
        }
    }
    
    func recordInteraction(postId: String, type: UserInteraction.InteractionType, duration: TimeInterval? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let interaction = UserInteraction(postId: postId, targetUserId: userId, interactionType: type, duration: duration)
        
        // Local cache'e ekle
        userProfile?.interactionHistory.append(interaction)
        
        // Firestore'a kaydet
        db.collection("users").document(userId).collection("interactions").addDocument(data: [
            "postId": postId,
            "interactionType": type.rawValue,
            "timestamp": Timestamp(date: interaction.timestamp),
            "duration": duration ?? 0
        ])
    }
    
    // MARK: - Recommendation Algorithms
    
    func getPersonalizedPosts() async -> [Post] {
        guard let userProfile = userProfile else { return [] }
        
        let posts = await fetchPosts()
        let scoredPosts = posts.map { post in
            ScoredPost(
                post: post,
                score: calculateRecommendationScore(for: post, userProfile: userProfile)
            )
        }
        
        // Score'a göre sırala
        return scoredPosts
            .sorted { $0.score > $1.score }
            .map { $0.post }
    }
    
    private func calculateRecommendationScore(for post: Post, userProfile: UserProfile) -> Double {
        let collaborativeScore = calculateCollaborativeScore(for: post, userProfile: userProfile)
        let contentBasedScore = calculateContentBasedScore(for: post, userProfile: userProfile)
        let recencyScore = calculateRecencyScore(for: post)
        let popularityScore = calculatePopularityScore(for: post)
        
        // Ağırlıklı ortalama
        return (collaborativeScore * 0.4) +
               (contentBasedScore * 0.3) +
               (recencyScore * 0.2) +
               (popularityScore * 0.1)
    }
    
    // MARK: - Collaborative Filtering
    
    private func calculateCollaborativeScore(for post: Post, userProfile: UserProfile) -> Double {
        // Benzer kullanıcıların bu post'u beğenip beğenmediğini kontrol et
        let similarUsers = findSimilarUsers(for: userProfile)
        
        var totalScore = 0.0
        var userCount = 0
        
        for similarUserId in similarUsers {
            if let score = userSimilarityCache[similarUserId] {
                // Benzer kullanıcının bu post'la etkileşimi var mı?
                let interactionScore = getInteractionScore(userId: similarUserId, postId: post.id)
                totalScore += score * interactionScore
                userCount += 1
            }
        }
        
        return userCount > 0 ? totalScore / Double(userCount) : 0.0
    }
    
    private func findSimilarUsers(for userProfile: UserProfile) -> [String] {
        // Basit implementasyon: Aynı ilgi alanlarına sahip kullanıcılar
        return userProfile.followingIds
    }
    
    // MARK: - Content-Based Filtering
    
    private func calculateContentBasedScore(for post: Post, userProfile: UserProfile) -> Double {
        var score = 0.0
        
        // İlgi alanları eşleşmesi
        let topicMatch = calculateTopicMatch(post: post, userProfile: userProfile)
        score += topicMatch * 0.4
        
        // İçerik türü tercihi
        let contentTypeMatch = calculateContentTypeMatch(post: post, userProfile: userProfile)
        score += contentTypeMatch * 0.3
        
        // Kullanıcı etkileşim geçmişi
        let historicalMatch = calculateHistoricalMatch(post: post, userProfile: userProfile)
        score += historicalMatch * 0.3
        
        return score
    }
    
    private func calculateTopicMatch(post: Post, userProfile: UserProfile) -> Double {
        // Post içeriğinde kullanıcının ilgi alanları var mı?
        let postContent = post.content.lowercased()
        let userInterests = userProfile.interests.map { $0.lowercased() }
        
        var matchCount = 0
        for interest in userInterests {
            if postContent.contains(interest) {
                matchCount += 1
            }
        }
        
        return Double(matchCount) / Double(userInterests.count)
    }
    
    private func calculateContentTypeMatch(post: Post, userProfile: UserProfile) -> Double {
        var score = 0.0
        
        // Video tercihi
        if post.hasBackgroundVideo && userProfile.preferences.showVideos {
            score += 0.5
        }
        
        // Resim tercihi
        if post.hasBackgroundImage && userProfile.preferences.showImages {
            score += 0.3
        }
        
        // Soru/Cevap tercihi
        if post.isQuestion && userProfile.preferences.showQuestions {
            score += 0.2
        } else if post.isAnswer && userProfile.preferences.showAnswers {
            score += 0.2
        }
        
        return score
    }
    
    private func calculateHistoricalMatch(post: Post, userProfile: UserProfile) -> Double {
        // Kullanıcının geçmiş etkileşimlerine bak
        let recentInteractions = userProfile.interactionHistory
            .filter { $0.timestamp > Date().addingTimeInterval(-7 * 24 * 3600) } // Son 7 gün
        
        var positiveInteractions = 0
        var totalInteractions = 0
        
        for interaction in recentInteractions {
            if interaction.interactionType == .like {
                positiveInteractions += 1
            }
            totalInteractions += 1
        }
        
        return totalInteractions > 0 ? Double(positiveInteractions) / Double(totalInteractions) : 0.5
    }
    
    // MARK: - Recency & Popularity
    
    private func calculateRecencyScore(for post: Post) -> Double {
        let hoursSinceCreation = Date().timeIntervalSince(post.createdAt) / 3600
        
        // Yeni post'lar daha yüksek skor alır
        if hoursSinceCreation < 24 {
            return 1.0
        } else if hoursSinceCreation < 168 { // 1 hafta
            return 0.7
        } else {
            return 0.3
        }
    }
    
    private func calculatePopularityScore(for post: Post) -> Double {
        let totalEngagement = post.likesCount + post.commentsCount
        
        // Logaritmik skorlama (çok popüler post'ları aşırı öne çıkarmamak için)
        return min(Double(totalEngagement) / 100.0, 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func fetchPosts() async -> [Post] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            // 1. Kullanıcının takip ettiği kişilerin post'larını getir
            let followingPosts = await fetchFollowingPosts(userId: userId)
            
            // 2. Genel akıştan son N post'u getir
            let generalPosts = await fetchGeneralPosts()
            
            // 3. Post'ları birleştir ve duplicate'ları kaldır
            var allPosts = followingPosts + generalPosts
            let uniquePosts = removeDuplicates(from: allPosts)
            
            // 4. Post'ları tarihe göre sırala
            return uniquePosts.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("❌ Error fetching posts: \(error)")
            return []
        }
    }
    
    private func fetchFollowingPosts(userId: String) async -> [Post] {
        do {
            // Kullanıcının takip ettiği kişileri al
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let userData = userDoc.data(),
                  let followingIds = userData["following"] as? [String] else {
                return []
            }
            
            // Takip edilen kişilerin son post'larını getir
            var followingPosts: [Post] = []
            
            for followingId in followingIds.prefix(20) { // En fazla 20 kişi
                let postsQuery = db.collection("posts")
                    .whereField("userId", isEqualTo: followingId)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 5) // Her kişiden en fazla 5 post
                
                let snapshot = try await postsQuery.getDocuments()
                let posts = snapshot.documents.compactMap { doc in
                    Post(id: doc.documentID, data: doc.data())
                }
                followingPosts.append(contentsOf: posts)
            }
            
            return followingPosts
            
        } catch {
            print("❌ Error fetching following posts: \(error)")
            return []
        }
    }
    
    private func fetchGeneralPosts() async -> [Post] {
        do {
            // Genel akıştan son 50 post'u getir
            let snapshot = try await db.collection("posts")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                Post(id: doc.documentID, data: doc.data())
            }
            
        } catch {
            print("❌ Error fetching general posts: \(error)")
            return []
        }
    }
    
    private func removeDuplicates(from posts: [Post]) -> [Post] {
        var uniquePosts: [Post] = []
        var seenIds = Set<String>()
        
        for post in posts {
            if !seenIds.contains(post.id) {
                uniquePosts.append(post)
                seenIds.insert(post.id)
            }
        }
        
        return uniquePosts
    }
    
    private func getInteractionScore(userId: String, postId: String) -> Double {
        // Kullanıcının belirli bir post'la etkileşim skoru
        return 0.5 // Placeholder
    }
}

// MARK: - Supporting Types

struct ScoredPost {
    let post: Post
    let score: Double
}

enum RecommendationAlgorithm: String, CaseIterable {
    case collaborative = "collaborative"
    case contentBased = "content_based"
    case hybrid = "hybrid"
    case random = "random"
    
    var displayName: String {
        switch self {
        case .collaborative: return "İşbirlikçi Filtreleme"
        case .contentBased: return "İçerik Tabanlı"
        case .hybrid: return "Karma"
        case .random: return "Rastgele"
        }
    }
} 