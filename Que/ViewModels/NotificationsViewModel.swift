import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading: Bool = false
    private var listener: ListenerRegistration?
    
    init() {
        listenNotifications()
    }
    
    deinit {
        listener?.remove()
    }
    
    func listenNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        let db = Firestore.firestore()
        listener = db.collection("users").document(userId)
            .collection("notifications")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    guard let docs = snapshot?.documents else { return }
                    self?.notifications = docs.compactMap { doc in
                        let data = doc.data()
                        guard let type = data["type"] as? String,
                              let fromUserId = data["fromUserId"] as? String,
                              let fromDisplayName = data["fromDisplayName"] as? String,
                              let fromUsername = data["fromUsername"] as? String,
                              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
                              let isRead = data["isRead"] as? Bool else { return nil }
                        return NotificationItem(
                            id: doc.documentID,
                            type: type,
                            fromUserId: fromUserId,
                            fromDisplayName: fromDisplayName,
                            fromUsername: fromUsername,
                            fromPhotoURL: data["fromPhotoURL"] as? String,
                            createdAt: createdAt,
                            isRead: isRead,
                            postId: data["postId"] as? String,
                            commentText: data["commentText"] as? String
                        )
                    }
                }
            }
    }
    
    func markAsRead(_ notif: NotificationItem) {
        guard !notif.isRead, let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .collection("notifications").document(notif.id)
            .updateData(["isRead": true])
    }
    
    func markAllVisibleAsRead() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Görünen ve okunmamış tüm bildirimleri işaretle
        let unreadNotifications = notifications.filter { !$0.isRead }
        for notif in unreadNotifications {
            let notifRef = db.collection("users").document(userId)
                .collection("notifications").document(notif.id)
            batch.updateData(["isRead": true], forDocument: notifRef)
        }
        
        // Batch commit
        batch.commit { error in
            if let error = error {
                print("Bildirimler okundu olarak işaretlenirken hata: \(error)")
            }
        }
    }
    
    func refresh() {
        // Refresh için listener'ı yeniden başlat
        listener?.remove()
        listenNotifications()
    }
} 