import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

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

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedUserId: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    // Loading state
                    VStack(spacing: 16) {
                        ForEach(0..<8, id: \.self) { _ in
                            NotificationSkeletonRow()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                } else if viewModel.notifications.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Henüz bildirim yok")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Takipçilerin ve etkileşimlerle ilgili bildirimler burada görünecek")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupedNotifications.keys.sorted(by: groupSortOrder), id: \.self) { group in
                                if let notifs = groupedNotifications[group] {
                                    Group {
                                        GroupHeader(title: group)
                                        ForEach(notifs) { notif in
                                            NotificationRow(
                                                notification: notif,
                                                onTap: {
                                                    viewModel.markAsRead(notif)
                                                    if notif.type == "follow" || notif.type == "like" || notif.type == "mention" {
                                                        selectedUserId = notif.fromUserId
                                                    }
                                                }
                                            )
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedUserId) { userId in
                ProfilePage(userId: userId)
            }
            .onAppear {
                // iOS sistem badge'ini hemen temizle
                Task {
                    do {
                        try await UNUserNotificationCenter.current().setBadgeCount(0)
                    } catch {
                        print("Badge temizlenemedi: \(error)")
                    }
                }
                
                // Sayfa açılınca görünen tüm bildirimleri okundu olarak işaretle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.markAllVisibleAsRead()
                }
            }
        }
    }
}

// Bildirimleri gruplandırmak için yardımcı fonksiyonlar
extension NotificationsView {
    var groupedNotifications: [String: [NotificationItem]] {
        Dictionary(grouping: viewModel.notifications) { notif in
            groupTitle(for: notif.createdAt)
        }
    }
    
    func groupTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else if let days = calendar.dateComponents([.day], from: date, to: Date()).day {
            if days < 7 {
                return "Son 7 Gün"
            } else if days < 30 {
                return "Son 30 Gün"
            } else {
                return "Daha Eski"
            }
        }
        return "Daha Eski"
    }
    
    func groupSortOrder(_ a: String, _ b: String) -> Bool {
        let order = ["Bugün", "Dün", "Son 7 Gün", "Son 30 Gün", "Daha Eski"]
        return (order.firstIndex(of: a) ?? 99) < (order.firstIndex(of: b) ?? 99)
    }
}

struct GroupHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(.systemBackground).opacity(0.97))
    }
}

struct NotificationRow: View {
    let notification: NotificationItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile foto
                if let url = URL(string: notification.fromPhotoURL ?? ""), !(notification.fromPhotoURL ?? "").isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(notification.isRead ? Color.clear : Color.purple, lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(6)
                        )
                        .overlay(
                            Circle()
                                .stroke(notification.isRead ? Color.clear : Color.purple, lineWidth: 2)
                        )
                }
                
                // İçerik
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Ana mesaj
                            Text(getNotificationText())
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                            
                            // Username ve zaman
                            HStack(spacing: 8) {
                                Text("@\(notification.fromUsername)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(timeAgo(notification.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Bildirim tipi ikonu
                        getNotificationIcon()
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .background(
                notification.isRead ? 
                Color(.systemBackground) : 
                Color.purple.opacity(0.03)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func getNotificationIcon() -> some View {
        switch notification.type {
        case "follow":
            Image(systemName: "person.badge.plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
        case "like":
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
        case "comment":
            Image(systemName: "message.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
        case "mention":
            Image(systemName: "at")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
        default:
            Image(systemName: "bell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
    
    private func getNotificationText() -> String {
        switch notification.type {
        case "follow":
            return "\(notification.fromDisplayName) seni takip etmeye başladı"
        case "like":
            return "\(notification.fromDisplayName) gönderini beğendi"
        case "comment":
            if let comment = notification.commentText, !comment.isEmpty {
                return "\(notification.fromDisplayName) gönderine yorum yaptı: \"\(comment)\""
            } else {
                return "\(notification.fromDisplayName) gönderine yorum yaptı"
            }
        case "mention":
            return "\(notification.fromDisplayName) bir gönderide seni etiketledi"
        default:
            return "Bilinmeyen bildirim"
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NotificationSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Profile foto skeleton
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 52, height: 52)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                // Ana mesaj skeleton
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                // Alt bilgi skeleton
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 12)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 12)
                        .shimmer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
}
