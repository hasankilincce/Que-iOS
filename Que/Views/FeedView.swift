import SwiftUI
import SDWebImageSwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    // Loading skeleton
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                PostSkeletonView()
                            }
                        }
                        .padding()
                    }
                } else if viewModel.posts.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "house")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Henüz gönderi yok")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Takip ettiğin kişilerin gönderileri burada görünecek")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Posts list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.posts) { post in
                                PostRowView(post: post) {
                                    viewModel.toggleLike(for: post)
                                }
                                .onAppear {
                                    // Load more when near end
                                    if post.id == viewModel.posts.last?.id {
                                        viewModel.loadMorePosts()
                                    }
                                    
                                    // Prefetch next video
                                    viewModel.prefetchNextVideo(for: post)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                // Error overlay
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Text(error)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Anasayfa")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

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
                    let publicVideoURL = URLCacheManager.shared.convertSignedURLToPublic(signedVideoURL)
                    
                    if let videoURL = URL(string: publicVideoURL) {
                        VideoPostView(
                            url: videoURL,
                            videoId: "\(post.id)_background_video"
                        )
                    }
                } else if post.mediaType == "image", let imageURL = post.mediaURL {
                    // Image post'ları için AsyncImage kullan
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fill)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(9/16, contentMode: .fill)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
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

// Background image view for 9:16 aspect ratio images (vertical)
struct BackgroundImageView: View {
    let imageURL: String
    
    var body: some View {
                    if let url = URL(string: imageURL) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                .frame(height: 320) // Fixed height for 9:16 viewing (vertical)
                            .clipped()
                .cornerRadius(12)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(12)
                )
        }
    }
}

struct PostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header skeleton - exactly matching real structure
            HStack {
                // Profile image skeleton
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 2) {
                    // Display name skeleton
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 130, height: 16)
                        .shimmer()
                    
                    // Username skeleton
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 85, height: 12)
                        .shimmer()
                }
                
                Spacer()
                
                // Time ago skeleton
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(width: 35, height: 12)
                    .shimmer()
            }
            
            // Content skeleton - multiple lines like real posts
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 280)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 180)
                    .shimmer()
            }
            
            // Sometimes show image skeleton (50% chance for variety)
            if Bool.random() {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .shimmer()
            }
            
            // Action buttons skeleton - matching real buttons layout
            HStack(spacing: 24) {
                // Like button skeleton
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 16, height: 16)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 20, height: 12)
                        .shimmer()
                }
                
                // Comment button skeleton
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 16, height: 16)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 15, height: 12)
                        .shimmer()
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