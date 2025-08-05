import SwiftUI
import AVKit

struct SharedVideoPlayerView: View {
    let videoId: String
    let videoURL: URL
    
    @StateObject private var sharedPlayer = SharedVideoPlayer.shared
    @StateObject private var visibilityTracker = VideoVisibilityTracker.shared
    @State private var showPlayIcon = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player Layer
                VideoPlayerLayerView(videoId: videoId)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Play Icon (when paused)
                if showPlayIcon {
                    ZStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(showPlayIcon ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.3), value: showPlayIcon)
                    }
                    .opacity(showPlayIcon ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: showPlayIcon)
                    .allowsHitTesting(false)
                }
                
                // Tap area for play/pause
                Color.clear
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayback()
                    }
                    .zIndex(1000)
            }
        }
        .onAppear {
            setupVideo()
        }
        .onDisappear {
            cleanupVideo()
        }
        .onReceive(sharedPlayer.$isPlaying) { isPlaying in
            showPlayIcon = !isPlaying
        }
        .modifier(VideoVisibilityModifier(videoId: videoId))
    }
    
    // MARK: - Private Methods
    
    private func setupVideo() {
        print("🎬 SharedVideoPlayerView: Setting up video for ID: \(videoId)")
        
        // Video URL'ini VideoVisibilityTracker'a kaydet
        visibilityTracker.registerVideoURL(videoURL, for: videoId)
        
        // Video'yu önbelleğe al
        sharedPlayer.prefetchVideo(url: videoURL, videoId: videoId)
    }
    
    private func cleanupVideo() {
        print("🎬 SharedVideoPlayerView: Cleaning up video for ID: \(videoId)")
        
        // Eğer bu video oynatılıyorsa durdur
        if visibilityTracker.currentVisibleVideoId == videoId {
            visibilityTracker.pauseCurrentVideo()
        }
    }
    
    private func togglePlayback() {
        if sharedPlayer.isPlaying {
            sharedPlayer.pause()
        } else {
            // Video'yu oynat
            sharedPlayer.play(url: videoURL, videoId: videoId)
            visibilityTracker.switchToVideo(videoId)
        }
    }
}

// MARK: - Video Player Layer View
struct VideoPlayerLayerView: UIViewRepresentable {
    let videoId: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // SharedPlayer'ı bu view'a bağla
        SharedVideoPlayer.shared.attach(to: view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // View güncellemeleri burada yapılabilir
    }
}

// MARK: - Full Screen Video Player View
struct SharedFullScreenVideoPlayerView: View {
    let videoId: String
    let videoURL: URL
    
    @StateObject private var sharedPlayer = SharedVideoPlayer.shared
    @StateObject private var visibilityTracker = VideoVisibilityTracker.shared
    @State private var showPlayIcon = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player Layer
                VideoPlayerLayerView(videoId: videoId)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Play Icon (when paused)
                if showPlayIcon {
                    ZStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(showPlayIcon ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.3), value: showPlayIcon)
                    }
                    .opacity(showPlayIcon ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: showPlayIcon)
                    .allowsHitTesting(false)
                }
                
                // Tap area for play/pause
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayback()
                    }
                    .zIndex(9999)
            }
        }
        .onAppear {
            setupVideo()
        }
        .onDisappear {
            cleanupVideo()
        }
        .onReceive(sharedPlayer.$isPlaying) { isPlaying in
            showPlayIcon = !isPlaying
        }
        .modifier(VideoVisibilityModifier(videoId: videoId))
    }
    
    // MARK: - Private Methods
    
    private func setupVideo() {
        print("🎬 SharedFullScreenVideoPlayerView: Setting up video for ID: \(videoId)")
        
        // Video URL'ini VideoVisibilityTracker'a kaydet
        visibilityTracker.registerVideoURL(videoURL, for: videoId)
        
        // Video'yu önbelleğe al
        sharedPlayer.prefetchVideo(url: videoURL, videoId: videoId)
    }
    
    private func cleanupVideo() {
        print("🎬 SharedFullScreenVideoPlayerView: Cleaning up video for ID: \(videoId)")
        
        // Eğer bu video oynatılıyorsa durdur
        if visibilityTracker.currentVisibleVideoId == videoId {
            visibilityTracker.pauseCurrentVideo()
        }
    }
    
    private func togglePlayback() {
        if sharedPlayer.isPlaying {
            sharedPlayer.pause()
        } else {
            // Video'yu oynat
            sharedPlayer.play(url: videoURL, videoId: videoId)
            visibilityTracker.switchToVideo(videoId)
        }
    }
} 