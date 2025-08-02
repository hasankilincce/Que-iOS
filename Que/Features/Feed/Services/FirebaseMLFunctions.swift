import Foundation
import FirebaseFunctions
import FirebaseAuth

class FirebaseMLFunctions: ObservableObject {
    static let shared = FirebaseMLFunctions()
    
    private let functions = Functions.functions(region: "us-east1")
    
    private init() {}
    
    // MARK: - Test Functions
    
    func testConnection() async throws -> Bool {
        let data: [String: Any] = [
            "test": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let result = try await functions.httpsCallable("testConnection").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return success
    }
    
    // MARK: - ML Recommendation Functions
    
    func getPersonalizedRecommendations(userId: String, limit: Int = 20) async throws -> [String] {
        let data: [String: Any] = [
            "userId": userId,
            "limit": limit,
            "algorithm": "hybrid"
        ]
        
        let result = try await functions.httpsCallable("getPersonalizedRecommendations").call(data)
        
        guard let response = result.data as? [String: Any],
              let postIds = response["postIds"] as? [String] else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return postIds
    }
    
    func getUserPreferences(userId: String) async throws -> [String: Any] {
        let data: [String: Any] = [
            "userId": userId
        ]
        
        let result = try await functions.httpsCallable("getUserPreferences").call(data)
        
        guard let response = result.data as? [String: Any] else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return response
    }
    
    func recordUserInteraction(userId: String, postId: String, interactionType: String, duration: TimeInterval? = nil, metadata: [String: Any] = [:]) async throws -> Bool {
        let data: [String: Any] = [
            "userId": userId,
            "postId": postId,
            "interactionType": interactionType,
                                                "duration": duration as Any,
            "metadata": metadata
        ]
        
        let result = try await functions.httpsCallable("recordUserInteraction").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return success
    }
    
    func trackUserBehavior(userId: String, eventType: String, eventData: [String: Any] = [:], sessionId: String? = nil) async throws -> Bool {
        let data: [String: Any] = [
            "userId": userId,
            "eventType": eventType,
            "eventData": eventData,
                                                "sessionId": sessionId as Any
        ]
        
        let result = try await functions.httpsCallable("trackUserBehavior").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return success
    }
    
    func getExperimentVariant(userId: String, experimentId: String) async throws -> [String: Any] {
        let data: [String: Any] = [
            "userId": userId,
            "experimentId": experimentId
        ]
        
        let result = try await functions.httpsCallable("getExperimentVariant").call(data)
        
        guard let response = result.data as? [String: Any],
              let variant = response["variant"] as? [String: Any] else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return variant
    }
    
    func getMLRecommendations(userId: String, limit: Int = 10) async throws -> [String] {
        let data: [String: Any] = [
            "userId": userId,
            "limit": limit
        ]
        
        let result = try await functions.httpsCallable("getMLRecommendations").call(data)
        
        guard let response = result.data as? [String: Any],
              let postIds = response["postIds"] as? [String] else {
            throw NSError(domain: "MLFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return postIds
    }
} 