import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    init() {
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        // Kullanıcı silinmiş veya geçersiz, çıkış yap
                        try? Auth.auth().signOut()
                        self?.isLoggedIn = false
                    } else {
                        self?.isLoggedIn = true
                    }
                }
            }
        } else {
            self.isLoggedIn = false
        }
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
        }
    }
}

@main
struct QueApp: App {
    @StateObject private var appState = AppState()
    init() {
        // 1️⃣ App Check provider'ını *FirebaseApp.configure()* çağrısından ÖNCE ayarlayın
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        // 2️⃣ Firebase modüllerini başlatın
        FirebaseApp.configure()
    }
    // SwiftData kalıcı konteyneri
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
            if appState.isLoggedIn {
                HomePage()
            } else {
                LoginPage()
            }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(appState)
    }
}
