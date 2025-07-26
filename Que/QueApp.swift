import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore
import UIKit
import UserNotifications

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Push notification setup
        Task {
            await NotificationManager.shared.checkPermissionStatus()
        }
        
        // Uygulama açıldığında badge'i temizle
        NotificationManager.shared.clearBadge()
        
        return true
    }
    
    // APNs token başarıyla alındığında
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.setAPNSToken(deviceToken)
    }
    
    // APNs token alınamadığında
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs kayıt hatası: \(error)")
    }
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var needsOnboarding: Bool = false
    @Published var navigationPath: [String] = []
    @Published var selectedUserId: String? = nil
    @Published var selectedPostId: String? = nil
    @Published var shouldNavigateToNotifications: Bool = false
    
    init() {
        setupNotificationObservers()
        
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        try? Auth.auth().signOut()
                        self?.isLoggedIn = false
                        self?.needsOnboarding = false
                    } else {
                        self?.isLoggedIn = true
                        self?.checkOnboarding(for: user.uid)
                        self?.requestNotificationPermissionIfNeeded()
                    }
                }
            }
        } else {
            self.isLoggedIn = false
            self.needsOnboarding = false
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
            if let user = user {
                self?.checkOnboarding(for: user.uid)
                self?.requestNotificationPermissionIfNeeded()
            } else {
                self?.needsOnboarding = false
                // Logout olduğunda token'ı sil
                NotificationManager.shared.removeTokenFromFirestore()
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .navigateToProfile,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userId = notification.object as? String {
                self?.selectedUserId = userId
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .navigateToPost,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let postId = notification.object as? String {
                self?.selectedPostId = postId
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .navigateToNotifications,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.shouldNavigateToNotifications = true
        }
    }
    
    private func requestNotificationPermissionIfNeeded() {
        Task {
            if !NotificationManager.shared.hasPermission {
                await NotificationManager.shared.requestPermission()
            } else {
                // Permission varsa token'ı yenile
                await NotificationManager.shared.refreshToken()
            }
        }
    }
    
    func checkOnboarding(for uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data(),
                   let username = data["username"] as? String,
                   !username.trimmingCharacters(in: .whitespaces).isEmpty {
                    self?.needsOnboarding = false
                } else {
                    self?.needsOnboarding = true
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@main
struct QueApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    init() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        FirebaseApp.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if !appState.isLoggedIn {
                LoginPage()
            } else if appState.needsOnboarding {
                OnboardingProfilePage()
            } else {
                HomePage()
            }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(appState)
        .environmentObject(NotificationManager.shared)
    }
}
