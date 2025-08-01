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