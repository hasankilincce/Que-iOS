import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore


class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var needsOnboarding: Bool = false
    
    init() {
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
            } else {
                self?.needsOnboarding = false
            }
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
    }
}
