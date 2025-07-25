import SwiftUI
import FirebaseAuth

struct SettingsPage: View {
    @Environment(\.dismiss) private var dismiss
    var onSignOut: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Hesap")) {
                    Button("Çıkış Yap", role: .destructive) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSignOut?()
                        }
                    }
                }
                Section(header: Text("Uygulama")) {
                    Button("Ayarlar (placeholder)") {}
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 
