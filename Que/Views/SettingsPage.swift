import SwiftUI
import FirebaseAuth

struct SettingsPage: View {
    var onSignOut: () -> Void
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Bildirimleri")
                                .font(.body)
                            if notificationManager.hasPermission {
                                Text("Etkin")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Kapalı")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        if !notificationManager.hasPermission {
                            Button("Aç") {
                                Task {
                                    await notificationManager.requestPermission()
                                }
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        } else {
                            Button("Ayarlar") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                    
                } header: {
                    Text("Bildirimler")
                }
                
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Çıkış Yap")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Hesap")
                }
            }
            .navigationTitle("Ayarlar")
            .alert("Çıkış Yap", isPresented: $showingSignOutAlert) {
                Button("İptal", role: .cancel) { }
                Button("Çıkış Yap", role: .destructive) {
                    onSignOut()
                }
            } message: {
                Text("Hesabınızdan çıkış yapmak istediğinizden emin misiniz?")
            }
        }
        .onAppear {
            Task {
                await notificationManager.checkPermissionStatus()
            }
        }
    }
} 
 