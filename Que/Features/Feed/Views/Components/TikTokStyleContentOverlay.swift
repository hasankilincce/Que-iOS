import SwiftUI
import SDWebImageSwiftUI

// MARK: - TikTok Style Content Overlay (Enhanced UX)
struct TikTokStyleContentOverlay: View {
    let post: Post
    let screenSize: CGSize
    let onLike: () -> Void
    
    var body: some View {
        VStack {
            // Top area - Text content with better positioning
            VStack {
                Spacer()
                    .frame(height: 80) // More space for status bar and notch
                
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        // Post type badge with enhanced design
                        HStack(spacing: 8) {
                            Image(systemName: post.postType.icon)
                                .font(.caption.weight(.semibold))
                            Text(post.postType.displayName)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                        
                        // Enhanced text content with better typography
                        if !post.content.isEmpty {
                            Text(post.content)
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                                .padding(.horizontal, 4)
                        }
                        
                        // Question/Answer specific buttons in text area
                        HStack(spacing: 12) {
                            // Cevapla button for questions
                            if post.postType == .question {
                                Button(action: {}) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.message")
                                            .font(.caption.weight(.bold))
                                        Text("Cevapla")
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(colors: [.green, .teal], 
                                                               startPoint: .leading, endPoint: .trailing))
                                    )
                                    .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            // Cevapları gör button for questions with answers
                            if post.postType == .question && post.commentsCount > 0 {
                                Button(action: {}) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .font(.caption.weight(.bold))
                                        Text("\(post.commentsCount) Cevap")
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 20) // Space for right buttons
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Bottom area - User info and controls with optimal spacing
            HStack(alignment: .bottom) {
                // Left side - User information with enhanced design
                HStack(spacing: 12) {
                    // Enhanced profile image
                    Group {
                        if let photoURL = post.userPhotoURL, let url = URL(string: photoURL) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(colors: [.white, .white.opacity(0.6)], 
                                                         startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 3
                                        )
                                )
                                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.8)], 
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(post.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        
                        HStack(spacing: 8) {
                            Text("@\(post.username)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            // Enhanced timestamp
                            Text(timeAgoString(from: post.createdAt))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    Spacer()
                }
                
                // Right side - Action buttons (moved closer to right edge)
                VStack(spacing: 18) { // Slightly tighter spacing for 4 buttons
                    // Like button
                    VStack(spacing: 2) {
                        Button(action: onLike) {
                            ZStack {
                                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(post.isLiked ? .red : .white)
                                    .scaleEffect(post.isLiked ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: post.isLiked)
                            }
                        }
                        
                        Text("\(post.likesCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                    
                    // Dislike button
                    VStack(spacing: 2) {
                        Button(action: {}) {
                            ZStack {
                                Image(systemName: "hand.thumbsdown")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("—")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                    
                    // Comment button
                    VStack(spacing: 2) {
                        Button(action: {}) {
                            ZStack {
                                Image(systemName: "message")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("\(post.commentsCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                    
                    // Share button
                    VStack(spacing: 2) {
                        Button(action: {}) {
                            ZStack {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("Paylaş")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120) // Optimal spacing for CustomTabBar (62px) + safe area (34px) + extra comfort (24px)
        }
    }
    
    // Enhanced time ago formatting
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "şimdi"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)dk önce"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)sa önce"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)g önce"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
} 