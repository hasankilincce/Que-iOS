import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

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
            // Badge sayısını temizle
            NotificationManager.shared.clearBadge()
            
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


