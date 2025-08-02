import Foundation
import FirebaseAnalytics
import FirebaseAuth

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var isTrackingEnabled: Bool = true
    @Published var currentSession: AnalyticsSession?
    
    private let mlFunctions = FirebaseMLFunctions.shared
    private var sessionStartTime: Date?
    
    private init() {
        setupAnalytics()
    }
    
    // MARK: - Setup
    
    private func setupAnalytics() {
        Analytics.setAnalyticsCollectionEnabled(isTrackingEnabled)
        
        // Session başlat
        startSession()
    }
    
    // MARK: - Session Management
    
    func startSession() {
        sessionStartTime = Date()
        currentSession = AnalyticsSession(
            id: UUID().uuidString,
            startTime: sessionStartTime!,
            userId: Auth.auth().currentUser?.uid
        )
        
        logEvent("session_start", parameters: [
            "session_id": currentSession?.id ?? "",
            "user_id": Auth.auth().currentUser?.uid ?? "anonymous"
        ])
    }
    
    func endSession() {
        guard let session = currentSession,
              let startTime = sessionStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        logEvent("session_end", parameters: [
            "session_id": session.id,
            "duration_seconds": duration,
            "user_id": Auth.auth().currentUser?.uid ?? "anonymous"
        ])
        
        currentSession = nil
        sessionStartTime = nil
    }
    
    // MARK: - Event Tracking
    
    func logEvent(_ eventName: String, parameters: [String: Any] = [:]) {
        guard isTrackingEnabled else { return }
        
        // Firebase Analytics
        Analytics.logEvent(eventName, parameters: parameters)
        
        // Custom backend tracking
        Task {
            do {
                _ = try await mlFunctions.trackUserBehavior(
                    userId: Auth.auth().currentUser?.uid ?? "",
                    eventType: eventName,
                    eventData: parameters,
                    sessionId: currentSession?.id
                )
            } catch {
                print("Analytics tracking error: \(error)")
            }
        }
    }
    
    // MARK: - Feed Analytics
    
    func trackPostView(postId: String, postType: String, authorId: String) {
        logEvent("post_view", parameters: [
            "post_id": postId,
            "post_type": postType,
            "author_id": authorId,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    func trackPostLike(postId: String, isLiked: Bool) {
        logEvent("post_like", parameters: [
            "post_id": postId,
            "action": isLiked ? "like" : "unlike",
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    func trackPostShare(postId: String, shareMethod: String) {
        logEvent("post_share", parameters: [
            "post_id": postId,
            "share_method": shareMethod,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    func trackPostComment(postId: String, commentLength: Int) {
        logEvent("post_comment", parameters: [
            "post_id": postId,
            "comment_length": commentLength,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    func trackFeedScroll(direction: String, postCount: Int) {
        logEvent("feed_scroll", parameters: [
            "direction": direction,
            "post_count": postCount,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    func trackFeedRefresh() {
        logEvent("feed_refresh", parameters: [
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    // MARK: - User Behavior Analytics
    
    func trackUserInteraction(interactionType: String, targetId: String, metadata: [String: Any] = [:]) {
        var parameters: [String: Any] = [
            "interaction_type": interactionType,
            "target_id": targetId,
            "session_id": currentSession?.id ?? ""
        ]
        
        parameters.merge(metadata) { _, new in new }
        
        logEvent("user_interaction", parameters: parameters)
        
        // Backend'e kaydet
        Task {
            do {
                _ = try await mlFunctions.recordUserInteraction(
                    userId: Auth.auth().currentUser?.uid ?? "",
                    postId: targetId,
                    interactionType: interactionType,
                    duration: nil,
                    metadata: metadata
                )
            } catch {
                print("Interaction recording error: \(error)")
            }
        }
    }
    
    func trackUserPreference(preferenceType: String, value: Any) {
        logEvent("user_preference", parameters: [
            "preference_type": preferenceType,
            "value": String(describing: value),
            "session_id": currentSession?.id ?? ""
        ])
        
        // Backend'e kaydet
        Task {
            // updateUserPreferences method doesn't exist in FirebaseMLFunctions
            // This functionality can be implemented later
            print("Preference update: \(preferenceType) = \(value)")
        }
    }
    
    // MARK: - Performance Analytics
    
    func trackAppPerformance(metric: String, value: Double, unit: String = "ms") {
        logEvent("app_performance", parameters: [
            "metric": metric,
            "value": value,
            "unit": unit,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    func trackNetworkRequest(endpoint: String, duration: Double, success: Bool) {
        logEvent("network_request", parameters: [
            "endpoint": endpoint,
            "duration_ms": duration,
            "success": success,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    // MARK: - Error Tracking
    
    func trackError(error: Error, context: String) {
        logEvent("app_error", parameters: [
            "error_message": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "context": context,
            "session_id": currentSession?.id ?? ""
        ])
    }
    
    // MARK: - Analytics Reports
    
    func getAnalyticsReport(dateRange: String = "7d") async throws -> [String: Any] {
        guard Auth.auth().currentUser?.uid != nil else {
            throw NSError(domain: "AnalyticsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // getAnalyticsReport method doesn't exist in FirebaseMLFunctions
        // This functionality can be implemented later
        return [:]
    }
}

// MARK: - Analytics Session Model

struct AnalyticsSession {
    let id: String
    let startTime: Date
    let userId: String?
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
} 