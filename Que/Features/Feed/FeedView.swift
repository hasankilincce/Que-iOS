import SwiftUI
import SDWebImageSwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.showSkeleton || (viewModel.isLoading && viewModel.posts.isEmpty) {
                    // Loading skeleton with improved UI
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(0..<6, id: \.self) { index in
                                PostSkeletonView()
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: viewModel.showSkeleton)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .background(Color(.systemGroupedBackground))
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                                .transition(.opacity.combined(with: .scale))
                                .animation(.easeInOut(duration: 0.3), value: viewModel.posts.count)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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

 