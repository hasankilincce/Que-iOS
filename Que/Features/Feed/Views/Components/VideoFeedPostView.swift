import SwiftUI
import SDWebImageSwiftUI

// MARK: - Video Feed Post View (Enhanced UX)
struct VideoFeedPostView: View {
    let post: Post
    let screenSize: CGSize
    let onLike: () -> Void
    let isVisible: Bool
    @State private var showLikeAnimation = false
    @State private var isDoubleTapped = false
    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?
    @StateObject private var videoWrapper = VideoSystemWrapper.shared
    @State private var videoPlayerRef: CustomAVPlayer?
    
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
                        // Video background for full screen - Custom system kullan
                        videoWrapper.createFullScreenVideoPlayer(
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
                            // Video player referansını al
                            if let orchestrator = CustomVideoOrchestrator.shared.getPlayer(id: "\(post.id)_video") {
                                videoPlayerRef = orchestrator
                            }
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
                        // Sadece beğenme durumunda animasyon göster
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
                
                // Long press areas for video posts
                if post.hasBackgroundVideo {
                    HStack(spacing: 0) {
                        // Left side long press area
                        Rectangle()
                            .fill(Color.red.opacity(0.3)) // Kırmızı yapıyoruz
                            .frame(width: geometry.size.width * 0.3, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                                // Long press completed
                                print("🎬 Video Feed: Left side long press completed for post: \(post.id)")
                            } onPressingChanged: { isPressing in
                                handleLongPress(isPressing: isPressing, side: "left")
                            }
                            .onTapGesture {
                                // Tap to play/pause for left side - Video player'ı tetikle
                                print("🎬 Video Feed: Left side tap for play/pause for post: \(post.id)")
                                toggleVideoPlayback()
                            }
                            .allowsHitTesting(true) // Long press için true
                            .zIndex(10000) // En üstte görünmesi için
                        
                        // Middle area (no long press)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.height)
                            .allowsHitTesting(false)
                        
                        // Right side long press area
                        Rectangle()
                            .fill(Color.red.opacity(0.3)) // Kırmızı yapıyoruz
                            .frame(width: geometry.size.width * 0.3, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                                // Long press completed
                                print("🎬 Video Feed: Right side long press completed for post: \(post.id)")
                            } onPressingChanged: { isPressing in
                                handleLongPress(isPressing: isPressing, side: "right")
                            }
                            .onTapGesture {
                                // Tap to play/pause for right side - Video player'ı tetikle
                                print("🎬 Video Feed: Right side tap for play/pause for post: \(post.id)")
                                toggleVideoPlayback()
                            }
                            .allowsHitTesting(true) // Long press için true
                            .zIndex(10000) // En üstte görünmesi için
                    }
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
            // Double tap to like - sadece beğenme durumunda animasyon
            let wasLiked = post.isLiked
            onLike()
            
            // Sadece beğenme durumunda animasyon ve haptic feedback
            if !wasLiked {
                triggerLikeAnimation()
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
        .onAppear {
            // Custom video system'i aktif et
            videoWrapper.useCustomSystem = true
        }
    }
    
    private func toggleVideoPlayback() {
        // Video player'ın play/pause durumunu değiştir
        let videoId = "\(post.id)_video"
        if let player = CustomVideoOrchestrator.shared.getPlayer(id: videoId) {
            if player.isPlaying {
                player.pause()
                print("🎬 Video Feed: Video paused via tap for post: \(post.id)")
            } else {
                player.play()
                print("🎬 Video Feed: Video played via tap for post: \(post.id)")
            }
        } else {
            print("🎬 Video Feed: Player not found for video ID: \(videoId)")
        }
    }
    
    private func handleLongPress(isPressing: Bool, side: String) {
        if isPressing {
            // Long press started
            print("🎬 Video Feed: \(side) side long press started for post: \(post.id)")
            isLongPressing = true
            
            // Start timer for continuous logging
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                print("🎬 Video Feed: \(side) side long press continuing for post: \(post.id)")
            }
        } else {
            // Long press ended
            print("🎬 Video Feed: \(side) side long press ended for post: \(post.id)")
            isLongPressing = false
            longPressTimer?.invalidate()
            longPressTimer = nil
        }
    }
    
    private func triggerLikeAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showLikeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showLikeAnimation = false
            }
        }
    }
} 