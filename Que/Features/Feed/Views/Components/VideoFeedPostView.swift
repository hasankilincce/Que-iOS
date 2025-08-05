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
    @State private var isSpeedUp = false // Video hızlandırıldığında UI'ı gizlemek için
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
                            
                            // Prefetch next video
                            if let feedViewModel = getFeedViewModel() {
                                feedViewModel.prefetchNextVideo(for: post)
                            }
                        }
                        .onDisappear {
                            // Video'yu tamamen kaldır
                            let videoId = "\(post.id)_video"
                            videoWrapper.removeVideo(id: videoId)
                            print("🎬 Video Feed: Video removed on disappear for post: \(post.id)")
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
                
                // Gradients overlay
                FeedPostGradients(screenSize: geometry.size)
                    .zIndex(20000) // UI elementlerinin en üstte görünmesi için
                    .opacity(isSpeedUp ? 0 : 1) // Hızlandırıldığında gizle
                
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
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    }
                )
                .zIndex(20000) // UI elementlerinin en üstte görünmesi için
                .opacity(isSpeedUp ? 0 : 1) // Hızlandırıldığında gizle
                
                // Double-tap like animation
                if showLikeAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                        .opacity(showLikeAnimation ? 1 : 0)
                        .scaleEffect(showLikeAnimation ? 1.2 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showLikeAnimation)
                        .zIndex(20000) // UI elementlerinin en üstte görünmesi için
                }
                
                // Long press areas for video posts
                if post.hasBackgroundVideo {
                    HStack(spacing: 0) {
                        // Left side long press area
                        Rectangle()
                            // .fill(Color.red.opacity(0.3)) // Kırmızı yapıyoruz - YORUM SATIRI
                            .fill(Color.clear) // Görünmez yapıyoruz
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
                                handleTap()
                            }
                            .allowsHitTesting(true) // Long press ve tap için true
                            .zIndex(1000) // UI elementlerinin altında kalması için
                        
                        // Middle clear area (allows tap to pass through to video player's default tap area)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.height)
                            .allowsHitTesting(false) // Taps should pass through to the video player
                            .zIndex(1000) // UI elementlerinin altında kalması için
                        
                        // Right side long press area
                        Rectangle()
                            // .fill(Color.red.opacity(0.3)) // Kırmızı yapıyoruz - YORUM SATIRI
                            .fill(Color.clear) // Görünmez yapıyoruz
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
                                handleTap()
                            }
                            .allowsHitTesting(true) // Long press ve tap için true
                            .zIndex(1000) // UI elementlerinin altında kalması için
                    }
                }
                
                // Heart animation for double tap
                if showLikeAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                        .scaleEffect(isDoubleTapped ? 1.5 : 0)
                        .opacity(isDoubleTapped ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDoubleTapped)
                        .zIndex(20000) // UI elementlerinin en üstte görünmesi için
                }
                
                // Speed indicator animation
                if isSpeedUp {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text("Hız 2x")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                        .scaleEffect(isSpeedUp ? 1.0 : 0.8)
                        .opacity(isSpeedUp ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSpeedUp)
                    }
                    .padding(.bottom, 120) // Navigasyon çubuğunun üstünde kalması için
                    .zIndex(20000) // UI elementlerinin en üstte görünmesi için
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
            
            // Set video speed to 2x only for long press
            setVideoSpeed(2.0)
            
            // Show speed animation only after a short delay to avoid flash on single tap
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if isLongPressing { // Only show if still long pressing
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSpeedUp = true
                    }
                }
            }
            
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
            
            // Reset video speed to 1x only if it was actually changed
            setVideoSpeed(1.0)
            
            // Hide speed animation
            withAnimation(.easeInOut(duration: 0.3)) {
                isSpeedUp = false
            }
        }
    }
    
    private func handleTap() {
        // Single tap - only toggle play/pause, don't change speed
        // Direct access to video player for faster response
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
    
    private func setVideoSpeed(_ speed: Float) {
        let videoId = "\(post.id)_video"
        if let player = CustomVideoOrchestrator.shared.getPlayer(id: videoId) {
            player.setPlaybackRate(speed)
            print("🎬 Video Feed: Video speed set to \(speed)x for post: \(post.id)")
        } else {
            print("🎬 Video Feed: Player not found for video ID: \(videoId)")
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
    
    // FeedViewModel'e erişim için helper fonksiyon
    private func getFeedViewModel() -> FeedViewModel? {
        // Environment'dan FeedViewModel'i al
        // Bu fonksiyon FeedView'da kullanılacak
        return nil // Şimdilik nil, FeedView'da implement edilecek
    }
} 
