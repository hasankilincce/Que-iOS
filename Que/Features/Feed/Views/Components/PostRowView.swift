import SwiftUI
import SDWebImageSwiftUI

struct PostRowView: View {
    let post: Post
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post type indicator
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: post.postType.icon)
                        .foregroundColor(post.postType == .question ? .blue : .green)
                        .font(.caption)
                    Text(post.postType.displayName)
                        .font(.caption.bold())
                        .foregroundColor(post.postType == .question ? .blue : .green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (post.postType == .question ? Color.blue : Color.green).opacity(0.1)
                )
                .cornerRadius(12)
                
                Spacer()
            }
            
            // User header
            HStack {
                // Profile image
                if let photoURL = post.userPhotoURL, let url = URL(string: photoURL) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .font(.subheadline.bold())
                    Text("@\(post.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .lineLimit(nil)
            
            // Background media (image or video)
            if post.hasBackgroundMedia {
                if post.hasBackgroundVideo, let signedVideoURL = post.backgroundVideoURL {
                    // Signed URL'yi public URL'ye çevir
                    let publicVideoURL = FeedVideoCacheManager.shared.convertSignedURLToPublic(signedVideoURL)
                    
                    if let videoURL = URL(string: publicVideoURL) {
                        CustomVideoPlayerView(
                            videoURL: videoURL,
                            videoId: "\(post.id)_background_video",
                            isVisible: true
                        )
                    }
                } else if post.mediaType == "image", let imageURL = post.mediaURL {
                    // Image post'ları için BackgroundImageView kullan (WebImage ile)
                    BackgroundImageView(imageURL: imageURL)
                } else if post.hasBackgroundImage {
                    BackgroundImageView(imageURL: post.backgroundImageURL!)
                }
            }
            
            // Answer için parent question gösterimi
            if post.isAnswer, let parentId = post.parentQuestionId {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu gönderi bir soruya cevap veriyor:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Soru ID: \(parentId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Soruyu Gör") {
                            // TODO: Navigate to parent question
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            // Action buttons
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likesCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isQuestion ? "message.badge" : "message")
                            .foregroundColor(.gray)
                        Text("\(post.commentsCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Question için "Cevapla" butonu
                if post.isQuestion {
                    Button(action: {
                        // TODO: Open answer creation for this question
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.message")
                                .foregroundColor(.blue)
                            Text("Cevapla")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
} 