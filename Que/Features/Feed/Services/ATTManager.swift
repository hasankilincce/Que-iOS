import Foundation
import AppTrackingTransparency
import AdSupport
import FirebaseAnalytics

class ATTManager: ObservableObject {
    static let shared = ATTManager()
    
    @Published var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var isRequestingPermission = false
    
    private init() {
        // Mevcut durumu kontrol et
        if #available(iOS 14, *) {
            trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
        }
    }
    
    // ATT izin durumunu kontrol et
    func checkTrackingAuthorization() {
        if #available(iOS 14, *) {
            trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
        }
    }
    
    // ATT izin isteği gönder
    func requestTrackingAuthorization() {
        guard #available(iOS 14, *) else { return }
        
        // IDFA'ya erişim için izin iste
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.trackingAuthorizationStatus = status
                self?.isRequestingPermission = false
                
                // Firebase Analytics'e IDFA durumunu bildir
                self?.updateAnalyticsForTrackingStatus(status)
                
                let statusText = self?.getStatusText(status) ?? "Unknown"
                print("ATT Status: \(status.rawValue) - \(statusText)")
            }
        }
    }
    
    // Firebase Analytics'e IDFA durumunu bildir
    private func updateAnalyticsForTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) {
        var parameters: [String: Any] = [:]
        
        switch status {
        case .authorized:
            // IDFA'ya erişim var
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            parameters["idfa"] = idfa.uuidString
            parameters["tracking_authorized"] = true
            
        case .denied, .restricted:
            // IDFA'ya erişim yok
            parameters["tracking_authorized"] = false
            parameters["tracking_denied"] = true
            
        case .notDetermined:
            // Henüz karar verilmemiş
            parameters["tracking_not_determined"] = true
            
        @unknown default:
            parameters["tracking_unknown"] = true
        }
        
        // Firebase Analytics'e gönder
        Analytics.logEvent("tracking_permission_status", parameters: parameters)
    }
    
    // IDFA'ya erişim var mı kontrol et
    var hasIDFAAccess: Bool {
        guard #available(iOS 14, *) else { return false }
        return trackingAuthorizationStatus == .authorized
    }
    
    // IDFA değerini al (izin varsa)
    var advertisingIdentifier: String? {
        guard hasIDFAAccess else { return nil }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    // ATT durumunu metin olarak al
    private func getStatusText(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
} 