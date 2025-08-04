import SwiftUI
import AVKit

// MARK: - Video System Wrapper
// Bu sınıf mevcut sistemden custom sisteme geçiş için kullanılır
class VideoSystemWrapper: ObservableObject {
    static let shared = VideoSystemWrapper()
    
    // Custom sistem aktif mi?
    @Published var useCustomSystem = false
    
    private init() {}
    
    // MARK: - Video Player Methods
    
    func createVideoPlayer(url: URL, videoId: String, isVisible: Bool) -> some View {
        return AnyView(
            CustomVideoPlayerView(
                videoURL: url,
                videoId: videoId,
                isVisible: isVisible
            )
        )
    }
    
    func createFullScreenVideoPlayer(videoURL: String, videoId: String, isVisible: Bool) -> some View {
        return AnyView(
            CustomFullScreenVideoPlayerView(
                videoURL: videoURL,
                videoId: videoId,
                isVisible: isVisible
            )
        )
    }
    
    func createBackgroundVideoPlayer(videoURL: String, videoId: String, isVisible: Bool) -> some View {
        return AnyView(
            CustomFullScreenVideoPlayerView(
                videoURL: videoURL,
                videoId: videoId,
                isVisible: isVisible
            )
        )
    }
    
    func createVideoPostCard(url: URL, videoId: String) -> some View {
        return AnyView(
            CustomVideoPlayerView(
                videoURL: url,
                videoId: videoId,
                isVisible: true
            )
        )
    }
    
    func createVideoFeedPostView(post: Post, screenSize: CGSize, onLike: @escaping () -> Void, isVisible: Bool) -> some View {
        return AnyView(
            VideoFeedPostView(
                post: post,
                screenSize: screenSize,
                onLike: onLike,
                isVisible: isVisible
            )
        )
    }
    
    // MARK: - Orchestrator Methods
    
    func getVideoOrchestrator() -> Any {
        return CustomVideoOrchestrator.shared
    }
    
    func playVideo(id: String, player: Any) {
        if let customPlayer = player as? CustomAVPlayer {
            CustomVideoOrchestrator.shared.playVideo(id: id, player: customPlayer)
        }
    }
    
    func pauseVideo(id: String) {
        CustomVideoOrchestrator.shared.pauseVideo(id: id)
    }
    
    func removeVideo(id: String) {
        CustomVideoOrchestrator.shared.removeVideo(id: id)
    }
    
    func isVideoPlaying(id: String) -> Bool {
        return CustomVideoOrchestrator.shared.isVideoPlaying(id: id)
    }
    
    // MARK: - System Toggle
    
    func toggleSystem() {
        useCustomSystem.toggle()
        print("🎬 VideoSystemWrapper: Switched to \(useCustomSystem ? "Custom" : "Original") system")
    }
    
    func enableCustomSystem() {
        useCustomSystem = true
        print("🎬 VideoSystemWrapper: Enabled Custom system")
    }
    
    func enableOriginalSystem() {
        useCustomSystem = false
        print("🎬 VideoSystemWrapper: Enabled Original system")
    }
} 