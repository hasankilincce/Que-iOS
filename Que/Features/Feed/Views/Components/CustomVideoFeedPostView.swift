import SwiftUI
import SDWebImageSwiftUI

// MARK: - Custom Video Feed Post View (Enhanced UX)
struct CustomVideoFeedPostView: View {
    let post: Post
    let screenSize: CGSize
    let onLike: () -> Void
    let isVisible: Bool
    @State private var showLikeAnimation = false
    @State private var isDoubleTapped = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layer - always fills entire screen
                Color.black
                    .ignoresSafeArea(.all)
                
                // Content layer - perfect aspect ratio handling
                if post.hasBackgroundVideo, let signedVideoURL = post.backgroundVideoURL {
                    // Signed URL'yi public URL'ye çevir
                    let publicVideoURL = FeedVideoCacheManager.shared.convertSignedURLToPublic(signedVideoURL)
                    
                    if let videoURL = URL(string: publicVideoURL) {
                        // Video background for full screen
                        CustomFullScreenVideoPlayerView(
                            videoURL: publicVideoURL,
                            videoId: "\(post.id)_video",
                            isVisible: isVisible
                        )
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .ignoresSafeArea(.all)
                        .onAppear {
                            // Önce mevcut player'ı kontrol et - yeniden kullan
                            let videoId = "\(post.id)_video"
                            if let existingPlayer = CustomVideoOrchestrator.shared.getPlayer(id: videoId) {
                                print("🎬 CustomVideoFeedPostView: Reusing existing player for post: \(post.id)")
                            }
                            
                            // Prefetch next video
                            if let feedViewModel = getFeedViewModel() {
                                feedViewModel.prefetchNextVideo(for: post)
                            }
                        }
                        .onDisappear {
                            // Video'yu tamamen kaldır
                            let videoId = "\(post.id)_video"
                            CustomVideoOrchestrator.shared.removePlayer(id: videoId)
                            print("🎬 CustomVideoFeedPostView: Video removed on disappear for post: \(post.id)")
                        }
                    }
                } else if post.mediaType == "image", let imageURL = post.mediaURL, let url = URL(string: imageURL) {
                    WebImage(url: url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .ignoresSafeArea(.all)
                } else if post.hasBackgroundImage, let imageURL = post.backgroundImageURL, let url = URL(string: imageURL) {
                    WebImage(url: url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .ignoresSafeArea(.all)
                } else {
                    // Text-only posts with enhanced gradient background
                    FeedPostBackground(post: post)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .ignoresSafeArea(.all)
                }
                
                // Enhanced overlay gradients
                FeedPostGradients(screenSize: geometry.size)
                
                // Content overlay with improved animations
                FeedPostOverlay(
                    post: post,
                    screenSize: geometry.size,
                    onLike: {
                        // Beğeni butonuna tıklandığında her zaman çalışır (beğenme/geri çekme)
                        let wasLiked = post.isLiked
                        onLike()
                        
                        // Sadece beğenme durumunda animasyon tetikle
                        if !wasLiked {
                            triggerLikeAnimation()
                        }
                    }
                )
                
                // Double-tap like animation
                if showLikeAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                        .opacity(showLikeAnimation ? 1 : 0)
                        .scaleEffect(showLikeAnimation ? 1.2 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showLikeAnimation)
                }
            }
        }
        .frame(
            width: screenSize.width,
            height: screenSize.height
        )
        .clipped()
        .ignoresSafeArea(.all)
        .onTapGesture(count: 2) {
            // Double tap to like - sadece beğenme durumunda çalışır
            let wasLiked = post.isLiked
            
            // Sadece beğenilmemiş durumda beğen
            if !wasLiked {
                onLike()
                triggerLikeAnimation()
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
        .allowsHitTesting(false) // Ana view'ın tap gesture'ı video player'ı engellemesin
    }
    
    private func triggerLikeAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showLikeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showLikeAnimation = false
            }
        }
    }
    
    // FeedViewModel'e erişim için helper fonksiyon
    private func getFeedViewModel() -> FeedViewModel? {
        // Environment'dan FeedViewModel'i al
        // Bu fonksiyon FeedView'da kullanılacak
        return nil // Şimdilik nil, FeedView'da implement edilecek
    }
} 