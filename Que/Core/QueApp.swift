import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import AppTrackingTransparency


class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var needsOnboarding: Bool = false
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                DispatchQueue.main.async {
                    if error != nil {
                        try? Auth.auth().signOut()
                        self?.isLoggedIn = false
                        self?.needsOnboarding = false
                    } else {
                        self?.isLoggedIn = true
                        self?.checkOnboarding(for: user.uid)
                    }
                }
            }
        } else {
            self.isLoggedIn = false
            self.needsOnboarding = false
        }
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
            if let user = user {
                self?.checkOnboarding(for: user.uid)
            } else {
                self?.needsOnboarding = false
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func checkOnboarding(for uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
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

@main
struct QueApp: App {
    @StateObject private var appState = AppState()
    init() {
        #if DEBUG
        // Development ortamında App Check'i devre dışı bırak
        // AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        FirebaseApp.configure()
        
        // Audio session'ı uygulama başlangıcında yapılandır
        FeedAudioSessionController.shared.configureAudioSessionForVideoPlayback()
        
        // ATT izin akışını başlat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTManager.shared.requestTrackingAuthorization()
        }
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
            Group {
                if !appState.isLoggedIn {
                    LoginPage()
                } else if appState.needsOnboarding {
                    OnboardingProfilePage()
                } else {
                    HomePage()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Uygulama ön plana geldiğinde badge'i temizle
                if appState.isLoggedIn {
                    Task {
                        do {
                            try await UNUserNotificationCenter.current().setBadgeCount(0)
                        } catch {
                            print("Badge temizlenemedi: \(error)")
                        }
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(appState)
    }
}
