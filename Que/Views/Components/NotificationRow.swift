import SwiftUI
import SDWebImageSwiftUI

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