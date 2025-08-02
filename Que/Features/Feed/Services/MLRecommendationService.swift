import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore

class MLRecommendationService: ObservableObject {
    static let shared = MLRecommendationService()
    
    @Published var mlPredictions: [String: Double] = [:]
    @Published var isMLEnabled: Bool = false
    
    private let functions = Functions.functions(region: "us-east1")
    private var predictionCache: [String: (prediction: Double, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 saat
    
    private init() {
        checkMLAvailability()
    }
    
    // MARK: - ML Availability Check
    
    private func checkMLAvailability() {
        functions.httpsCallable("checkMLAvailability").call { [weak self] result, error in
            if let data = result?.data as? [String: Any],
               let isAvailable = data["isAvailable"] as? Bool {
                DispatchQueue.main.async {
                    self?.isMLEnabled = isAvailable
                }
            }
        }
    }
    
    // MARK: - ML Predictions
    
    func getMLPrediction(for post: Post, userProfile: UserProfile) async -> Double {
        let cacheKey = "\(post.id)_\(userProfile.userId)"
        
        // Cache kontrolü
        if let cached = predictionCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            return cached.prediction
        }
        
        // ML model'den tahmin al
        let prediction = await requestMLPrediction(post: post, userProfile: userProfile)
        
        // Cache'e kaydet
        predictionCache[cacheKey] = (prediction: prediction, timestamp: Date())
        
        return prediction
    }
    
    private func requestMLPrediction(post: Post, userProfile: UserProfile) async -> Double {
        let requestData: [String: Any] = [
            "postId": post.id,
            "userId": userProfile.userId,
            "postFeatures": extractPostFeatures(post),
            "userFeatures": extractUserFeatures(userProfile),
            "interactionHistory": userProfile.interactionHistory.map { interaction in
                [
                    "postId": interaction.postId,
                    "type": interaction.interactionType.rawValue,
                    "timestamp": interaction.timestamp.timeIntervalSince1970,
                    "duration": interaction.duration ?? 0
                ]
            }
        ]
        
        do {
            let result = try await functions.httpsCallable("getMLPrediction").call(requestData)
            
            if let data = result.data as? [String: Any],
               let prediction = data["prediction"] as? Double {
                return prediction
            }
        } catch {
            print("ML prediction error: \(error)")
        }
        
        return 0.5 // Default score
    }
    
    // MARK: - Feature Extraction
    
    private func extractPostFeatures(_ post: Post) -> [String: Any] {
        return [
            "contentLength": post.content.count,
            "hasVideo": post.hasBackgroundVideo,
            "hasImage": post.hasBackgroundImage,
            "isQuestion": post.isQuestion,
            "isAnswer": post.isAnswer,
            "likesCount": post.likesCount,
            "commentsCount": post.commentsCount,
            "ageInHours": Date().timeIntervalSince(post.createdAt) / 3600,
            "contentKeywords": extractKeywords(from: post.content),
            "userFollowers": 0, // TODO: Implement
            "userReputation": 0 // TODO: Implement
        ]
    }
    
    private func extractUserFeatures(_ userProfile: UserProfile) -> [String: Any] {
        let recentInteractions = userProfile.interactionHistory
            .filter { $0.timestamp > Date().addingTimeInterval(-7 * 24 * 3600) } // Son 7 gün
        
        let likeRate = recentInteractions.isEmpty ? 0.0 :
            Double(recentInteractions.filter { $0.interactionType == .like }.count) /
            Double(recentInteractions.count)
        
        let avgViewDuration = recentInteractions
            .compactMap { $0.duration }
            .reduce(0.0, +) / Double(max(recentInteractions.count, 1))
        
        return [
            "interestsCount": userProfile.interests.count,
            "followingCount": userProfile.followingIds.count,
            "totalInteractions": userProfile.interactionHistory.count,
            "recentLikeRate": likeRate,
            "avgViewDuration": avgViewDuration,
            "preferredContentTypes": extractPreferredContentTypes(userProfile),
            "activityLevel": calculateActivityLevel(userProfile),
            "engagementScore": calculateEngagementScore(userProfile)
        ]
    }
    
    private func extractKeywords(from content: String) -> [String] {
        // Basit keyword extraction
        let words = content.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        // En sık kullanılan kelimeleri al
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
        
        return Array(wordCounts)
    }
    
    private func extractPreferredContentTypes(_ userProfile: UserProfile) -> [String: Double] {
        let recentInteractions = userProfile.interactionHistory
            .filter { $0.timestamp > Date().addingTimeInterval(-30 * 24 * 3600) } // Son 30 gün
        
        var typePreferences: [String: Int] = [:]
        
        for _ in recentInteractions {
            // Post türüne göre tercih hesapla
            // Bu kısım daha karmaşık olabilir
            typePreferences["general", default: 0] += 1
        }
        
        let total = Double(typePreferences.values.reduce(0, +))
        return typePreferences.mapValues { Double($0) / total }
    }
    
    private func calculateActivityLevel(_ userProfile: UserProfile) -> Double {
        let recentDays = 7.0
        let recentInteractions = userProfile.interactionHistory
            .filter { $0.timestamp > Date().addingTimeInterval(-recentDays * 24 * 3600) }
        
        let dailyAverage = Double(recentInteractions.count) / recentDays
        
        // 0-1 arası normalize et
        return min(dailyAverage / 10.0, 1.0) // 10+ günlük etkileşim = maksimum aktivite
    }
    
    private func calculateEngagementScore(_ userProfile: UserProfile) -> Double {
        let recentInteractions = userProfile.interactionHistory
            .filter { $0.timestamp > Date().addingTimeInterval(-7 * 24 * 3600) }
        
        var score = 0.0
        
        for interaction in recentInteractions {
            switch interaction.interactionType {
            case .like:
                score += 1.0
            case .comment:
                score += 2.0
            case .share:
                score += 3.0
            case .view:
                score += 0.1
            case .skip:
                score -= 0.5
            default:
                break
            }
        }
        
        return max(score / 10.0, 0.0) // 0-1 arası normalize et
    }
    
    // MARK: - Batch Predictions
    
    func getBatchPredictions(for posts: [Post], userProfile: UserProfile) async -> [String: Double] {
        var predictions: [String: Double] = [:]
        
        await withTaskGroup(of: (String, Double).self) { group in
            for post in posts {
                group.addTask {
                    let prediction = await self.getMLPrediction(for: post, userProfile: userProfile)
                    return (post.id, prediction)
                }
            }
            
            for await (postId, prediction) in group {
                predictions[postId] = prediction
            }
        }
        
        return predictions
    }
    
    // MARK: - Model Training Feedback
    
    func sendTrainingFeedback(postId: String, userAction: UserInteraction.InteractionType, prediction: Double) {
        let feedbackData: [String: Any] = [
            "postId": postId,
            "userId": Auth.auth().currentUser?.uid ?? "",
            "action": userAction.rawValue,
            "prediction": prediction,
            "timestamp": Timestamp(date: Date())
        ]
        
        functions.httpsCallable("sendTrainingFeedback").call(feedbackData) { result, error in
            if let error = error {
                print("Training feedback error: \(error)")
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        predictionCache.removeAll()
    }
    
    func clearExpiredCache() {
        let now = Date()
        predictionCache = predictionCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheExpiration
        }
    }
} 