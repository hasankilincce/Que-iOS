import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@MainActor
class NotificationBadgeViewModel: ObservableObject {
    @Published var unreadCount: Int = 0 {
        didSet {
            // iOS sistem badge'ini güncelle
            Task {
                await setBadgeCount(unreadCount)
            }
        }
    }
    private var listener: ListenerRegistration?
    
    init() {
        listenToNotifications()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func listenToNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        listener = db.collection("users").document(userId)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.unreadCount = snapshot?.documents.count ?? 0
                }
            }
    }
    
    // Modern badge API kullan
    private func setBadgeCount(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            print("Badge count ayarlanamadı: \(error)")
        }
    }
    
    // Manuel olarak badge temizleme
    func clearBadge() {
        Task {
            await setBadgeCount(0)
        }
    }
} 