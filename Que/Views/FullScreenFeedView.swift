import SwiftUI
import SDWebImageSwiftUI

struct FullScreenFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isTransitioning = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    // Loading state with better animation
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Yükleniyor...")
                            .foregroundColor(.white)
                            .font(.title3.weight(.medium))
                            .opacity(0.8)
                    }
                    .transition(.opacity.combined(with: .scale))
                } else if viewModel.posts.isEmpty {
                    // Empty state with better design
                    VStack(spacing: 24) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text("Henüz gönderi yok")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("İlk gönderiyi sen paylaş!")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // TikTok-style vertical scroll system
                    ZStack {
                        ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { index, post in
                            TikTokStylePostView(
                                post: post,
                                screenSize: geometry.size,
                                onLike: { viewModel.toggleLike(for: post) },
                                isVisible: index == currentIndex
                            )
                            .offset(y: CGFloat(index - currentIndex) * geometry.size.height + dragOffset)
                            .opacity(opacity(for: index))
                            .scaleEffect(scale(for: index))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentIndex)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.9), value: dragOffset)
                            .onAppear {
                                // Load more when near end
                                if index >= viewModel.posts.count - 3 {
                                    viewModel.loadMorePosts()
                                }
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isTransitioning {
                                    let verticalMovement = value.translation.height
                                    
                                    // Resistance effect at boundaries
                                    if (currentIndex == 0 && verticalMovement > 0) ||
                                       (currentIndex == viewModel.posts.count - 1 && verticalMovement < 0) {
                                        dragOffset = verticalMovement * 0.3 // Reduced movement at boundaries
                                    } else {
                                        dragOffset = verticalMovement
                                    }
                                }
                            }
                            .onEnded { value in
                                handleDragEnd(value: value, screenHeight: geometry.size.height)
                            }
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if viewModel.posts.isEmpty {
                viewModel.loadFeed()
            }
        }
        .onChange(of: currentIndex) { _, newIndex in
            // Load more posts when approaching end
            if newIndex >= viewModel.posts.count - 3 {
                viewModel.loadMorePosts()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func opacity(for index: Int) -> Double {
        let distance = abs(index - currentIndex)
        if distance == 0 { return 1.0 }
        return 0.0 // Sadece aktif post görünsün
    }
    
    private func scale(for index: Int) -> Double {
        let distance = abs(index - currentIndex)
        if distance == 0 { return 1.0 }
        return 1.0 // Diğer postların scale'i normal olsun ama görünmesinler
    }
    
    private func handleDragEnd(value: DragGesture.Value, screenHeight: CGFloat) {
        guard !isTransitioning else { return }
        
        let verticalMovement = value.translation.height
        let velocity = value.velocity.height
        
        // Determine swipe direction and threshold
        let threshold: CGFloat = screenHeight * 0.25 // 25% of screen height
        let velocityThreshold: CGFloat = 1000
        
        isTransitioning = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if (verticalMovement > threshold || velocity > velocityThreshold) && currentIndex > 0 {
                // Swipe down - go to previous post
                currentIndex -= 1
            } else if (verticalMovement < -threshold || velocity < -velocityThreshold) && currentIndex < viewModel.posts.count - 1 {
                // Swipe up - go to next post
                currentIndex += 1
            }
            
            // Reset drag offset
            dragOffset = 0
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset transition flag after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isTransitioning = false
        }
    }
}

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

// MARK: - TikTok Style Gradient Background (Enhanced)
struct TikTokStyleGradientBackground: View {
    let post: Post
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Add subtle pattern overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.black.opacity(0.2)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
    }
    
    private var gradientColors: [Color] {
        if post.postType == .question {
            return [
                Color.blue.opacity(0.9),
                Color.purple.opacity(0.7),
                Color.indigo.opacity(1.0),
                Color.black.opacity(0.8)
            ]
        } else {
            return [
                Color.green.opacity(0.9),
                Color.teal.opacity(0.7),
                Color.mint.opacity(1.0),
                Color.black.opacity(0.8)
            ]
        }
    }
}

// MARK: - TikTok Style Overlay Gradients (Enhanced)
struct TikTokStyleOverlayGradients: View {
    let screenSize: CGSize
    
    var body: some View {
        VStack(spacing: 0) {
            // Top gradient - more sophisticated
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.8), location: 0.0),
                    .init(color: Color.black.opacity(0.4), location: 0.3),
                    .init(color: Color.clear, location: 0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: screenSize.height * 0.4)
            
            Spacer()
            
            // Bottom gradient - enhanced for better control visibility
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color.black.opacity(0.2), location: 0.3),
                    .init(color: Color.black.opacity(0.6), location: 0.7),
                    .init(color: Color.black.opacity(0.9), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: screenSize.height * 0.5)
        }
        .ignoresSafeArea()
    }
}

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
                                /*Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                */
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
                                /*Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 58, height: 58)
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                */
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
                                /*Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 58, height: 58)
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                */
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
                                /*Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 58, height: 58)
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                */
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
                //.padding(.trailing, 8) // Much closer to right edge
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
