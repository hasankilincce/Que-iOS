import SwiftUI
import SDWebImageSwiftUI

// MARK: - TikTok Style Post View (Enhanced UX)
struct TikTokStylePostView: View {
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
                    let publicVideoURL = URLCacheManager.shared.convertSignedURLToPublic(signedVideoURL)
                    
                    if let videoURL = URL(string: publicVideoURL) {
                        // Video background for full screen
                        FullScreenVideoPlayerView(
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
                    TikTokStyleGradientBackground(post: post)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .ignoresSafeArea(.all)
                }
                
                // Enhanced overlay gradients
                TikTokStyleOverlayGradients(screenSize: geometry.size)
                
                // Content overlay with improved animations
                TikTokStyleContentOverlay(
                    post: post,
                    screenSize: geometry.size,
                    onLike: {
                        onLike()
                        triggerLikeAnimation()
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
            // Double tap to like
            onLike()
            triggerLikeAnimation()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
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
} 