import Foundation
import FirebaseFirestore
import FirebaseAuth

class ABTestingService: ObservableObject {
    static let shared = ABTestingService()
    
    @Published var currentExperiment: ABExperiment?
    @Published var userVariant: String = "A"
    
    private let db = Firestore.firestore()
    private var experiments: [String: ABExperiment] = [:]
    
    private init() {
        loadExperiments()
    }
    
    // MARK: - Experiment Management
    
    func loadExperiments() {
        db.collection("experiments")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let experiment = ABExperiment(id: document.documentID, data: document.data())
                    self?.experiments[experiment.id] = experiment
                }
                
                self?.assignUserToExperiment()
            }
    }
    
    private func assignUserToExperiment() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Kullanıcıyı rastgele bir deneye ata
        for (experimentId, experiment) in experiments {
            let userHash = hashUserId(userId, experimentId: experimentId)
            let variant = assignVariant(hash: userHash, experiment: experiment)
            
            // Kullanıcının variant'ını kaydet
            db.collection("users").document(userId)
                .collection("experiments").document(experimentId)
                .setData([
                    "variant": variant,
                    "assignedAt": Timestamp(date: Date())
                ])
            
            // Aktif deneyi belirle
            if experiment.isActive {
                currentExperiment = experiment
                userVariant = variant
            }
        }
    }
    
    private func hashUserId(_ userId: String, experimentId: String) -> Int {
        let combined = userId + experimentId
        return abs(combined.hashValue)
    }
    
    private func assignVariant(hash: Int, experiment: ABExperiment) -> String {
        let normalizedHash = hash % 100
        
        var cumulativeWeight = 0
        for variant in experiment.variants {
            cumulativeWeight += variant.weight
            if normalizedHash < cumulativeWeight {
                return variant.name
            }
        }
        
        return experiment.variants.first?.name ?? "A"
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ eventName: String, parameters: [String: Any] = [:]) {
        guard let userId = Auth.auth().currentUser?.uid,
              let experiment = currentExperiment else { return }
        
        let eventData: [String: Any] = [
            "userId": userId,
            "experimentId": experiment.id,
            "variant": userVariant,
            "eventName": eventName,
            "parameters": parameters,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("experiment_events").addDocument(data: eventData)
    }
    
    // MARK: - Feature Flags
    
    func isFeatureEnabled(_ featureName: String) -> Bool {
        guard let experiment = currentExperiment,
              let variant = experiment.variants.first(where: { $0.name == userVariant }) else {
            return false
        }
        
        return variant.features.contains(featureName)
    }
    
    func getFeatureValue<T>(_ featureName: String, defaultValue: T) -> T {
        guard let experiment = currentExperiment,
              let variant = experiment.variants.first(where: { $0.name == userVariant }),
              let value = variant.featureValues[featureName] as? T else {
            return defaultValue
        }
        
        return value
    }
}

// MARK: - Supporting Types

struct ABExperiment {
    let id: String
    let name: String
    let description: String
    let isActive: Bool
    let variants: [ABVariant]
    let startDate: Date
    let endDate: Date?
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.isActive = data["isActive"] as? Bool ?? false
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue()
        
        if let variantsData = data["variants"] as? [[String: Any]] {
            self.variants = variantsData.compactMap { ABVariant(data: $0) }
        } else {
            self.variants = []
        }
    }
}

struct ABVariant {
    let name: String
    let weight: Int // 0-100 arası
    let features: [String]
    let featureValues: [String: Any]
    
    init(data: [String: Any]) {
        self.name = data["name"] as? String ?? "A"
        self.weight = data["weight"] as? Int ?? 50
        self.features = data["features"] as? [String] ?? []
        self.featureValues = data["featureValues"] as? [String: Any] ?? [:]
    }
} 