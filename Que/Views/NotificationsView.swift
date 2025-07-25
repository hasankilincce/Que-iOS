import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NotificationItem: Identifiable {
    let id: String
    let type: String
    let fromUserId: String
    let fromDisplayName: String
    let fromUsername: String
    let fromPhotoURL: String?
    let createdAt: Date
    let isRead: Bool
    // Ekstra alanlar (like, comment, mention için)
    let postId: String?
    let commentText: String?
}

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    private var listener: ListenerRegistration?
    
    init() {
        listenNotifications()
    }
    
    deinit {
        listener?.remove()
    }
    
    func listenNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        listener = db.collection("users").document(userId)
            .collection("notifications")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
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
}

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedUserId: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notifications) { notif in
                    Button(action: {
                        viewModel.markAsRead(notif)
                        if notif.type == "follow" || notif.type == "like" || notif.type == "mention" {
                            selectedUserId = notif.fromUserId
                        }
                        // Yorum bildirimi için postId ile post detayına gidebilirsin
                    }) {
                        HStack(spacing: 12) {
                            if let url = URL(string: notif.fromPhotoURL ?? ""), !(notif.fromPhotoURL ?? "").isEmpty {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.gray.opacity(0.3))
                                            .padding(4)
                                    )
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                if notif.type == "follow" {
                                    Text("\(notif.fromDisplayName) seni takip etmeye başladı")
                                        .font(.body)
                                } else if notif.type == "like" {
                                    Text("\(notif.fromDisplayName) gönderini beğendi")
                                        .font(.body)
                                } else if notif.type == "comment" {
                                    Text("\(notif.fromDisplayName) gönderine yorum yaptı: \(notif.commentText ?? "")")
                                        .font(.body)
                                } else if notif.type == "mention" {
                                    Text("\(notif.fromDisplayName) bir gönderide seni etiketledi")
                                        .font(.body)
                                } else {
                                    Text("Bilinmeyen bildirim")
                                        .font(.body)
                                }
                                Text("@\(notif.fromUsername)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(timeAgo(notif.createdAt))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                        .background(notif.isRead ? Color(.systemBackground) : Color.purple.opacity(0.07))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.plain)
            .navigationTitle("Bildirimler")
            .navigationDestination(item: $selectedUserId) { userId in
                ProfilePage(userId: userId)
            }
            .onAppear {
                // Sayfa açılınca görünen tüm bildirimleri okundu olarak işaretle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.markAllVisibleAsRead()
                }
            }
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 