import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var token: String?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                hasPermission = granted
            }
            
            if granted {
                await registerForPushNotifications()
            }
        } catch {
            print("Push notification permission error: \(error)")
        }
    }
    
    @MainActor
    func registerForPushNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func setAPNSToken(_ tokenData: Data) {
        // APNs token'ını Firebase Messaging'e set et
        Messaging.messaging().setAPNSToken(tokenData, type: .unknown)
        
        // FCM token'ını al
        Task {
            do {
                let fcmToken = try await Messaging.messaging().token()
                await MainActor.run {
                    self.token = fcmToken
                    self.saveTokenToFirestore(fcmToken)
                }
            } catch {
                print("FCM token alma hatası: \(error)")
            }
        }
    }
    
    private func saveTokenToFirestore(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "tokenUpdatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Token kaydetme hatası: \(error)")
            } else {
                print("FCM token başarıyla kaydedildi: \(token)")
            }
        }
    }
    
    func removeTokenFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "fcmToken": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("Token silme hatası: \(error)")
            }
        }
    }
    
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        await MainActor.run {
            hasPermission = settings.authorizationStatus == .authorized
        }
    }
    
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func refreshToken() async {
        do {
            let fcmToken = try await Messaging.messaging().token()
            await MainActor.run {
                self.token = fcmToken
                self.saveTokenToFirestore(fcmToken)
            }
        } catch {
            print("Token yenileme hatası: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Uygulama açıkken notification geldiğinde
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Foreground'da notification gösterme (sessizce al)
        completionHandler([])
    }
    
    // Notification'a tıklandığında
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Badge sayısını sıfırla
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        // Notification payload'ından gerekli bilgileri al
        if let notificationType = userInfo["type"] as? String {
            handleNotificationTap(type: notificationType, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) {
        DispatchQueue.main.async {
            switch type {
            case "follow":
                if let userId = userInfo["fromUserId"] as? String {
                    // Profile sayfasına yönlendir
                    NotificationCenter.default.post(
                        name: .navigateToProfile,
                        object: userId
                    )
                }
            case "like", "comment", "mention":
                if let postId = userInfo["postId"] as? String {
                    // Post detay sayfasına yönlendir
                    NotificationCenter.default.post(
                        name: .navigateToPost,
                        object: postId
                    )
                }
            default:
                // Genel bildirimler sayfasına yönlendir
                NotificationCenter.default.post(
                    name: .navigateToNotifications,
                    object: nil
                )
            }
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    
    // FCM token yenilendiğinde
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        DispatchQueue.main.async {
            self.token = fcmToken
            self.saveTokenToFirestore(fcmToken)
        }
    }
}

// MARK: - Navigation Helper Extensions
extension Notification.Name {
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToNotifications = Notification.Name("navigateToNotifications")
} 