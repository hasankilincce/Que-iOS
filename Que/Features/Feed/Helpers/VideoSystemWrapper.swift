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
        if useCustomSystem {
            return AnyView(
                CustomVideoPlayerView(
                    videoURL: url,
                    videoId: videoId,
                    isVisible: isVisible
                )
            )
        } else {
            return AnyView(
                VideoPlayerView(
                    videoURL: url,
                    videoId: videoId,
                    isVisible: isVisible
                )
            )
        }
    }
    
    func createFullScreenVideoPlayer(videoURL: String, videoId: String, isVisible: Bool) -> some View {
        if useCustomSystem {
            return AnyView(
                CustomFullScreenVideoPlayerView(
                    videoURL: videoURL,
                    videoId: videoId,
                    isVisible: isVisible
                )
            )
        } else {
            return AnyView(
                FullScreenVideoPlayerView(
                    videoURL: videoURL,
                    videoId: videoId,
                    isVisible: isVisible
                )
            )
        }
    }
    
    func createBackgroundVideoPlayer(videoURL: String, videoId: String, isVisible: Bool) -> some View {
        if useCustomSystem {
            return AnyView(
                // CustomBackgroundVideoView artık kullanılmıyor, FullScreenVideoPlayerView kullan
                CustomFullScreenVideoPlayerView(
                    videoURL: videoURL,
                    videoId: videoId,
                    isVisible: isVisible
                )
            )
        } else {
            return AnyView(
                FullScreenVideoPlayerView(
                    videoURL: videoURL,
                    videoId: videoId,
                    isVisible: isVisible
                )
            )
        }
    }
    
    func createVideoPostCard(url: URL, videoId: String) -> some View {
        if useCustomSystem {
            return AnyView(
                CustomVideoPostView(
                    url: url,
                    videoId: videoId
                )
            )
        } else {
            return AnyView(
                VideoPostView(
                    url: url,
                    videoId: videoId
                )
            )
        }
    }
    
    func createVideoFeedPostView(post: Post, screenSize: CGSize, onLike: @escaping () -> Void, isVisible: Bool) -> some View {
        if useCustomSystem {
            return AnyView(
                CustomVideoFeedPostView(
                    post: post,
                    screenSize: screenSize,
                    onLike: onLike,
                    isVisible: isVisible
                )
            )
        } else {
            return AnyView(
                VideoFeedPostView(
                    post: post,
                    screenSize: screenSize,
                    onLike: onLike,
                    isVisible: isVisible
                )
            )
        }
    }
    
    // MARK: - Orchestrator Methods
    
    func getVideoOrchestrator() -> Any {
        if useCustomSystem {
            return CustomVideoOrchestrator.shared
        } else {
            return FeedVideoOrchestrator.shared
        }
    }
    
    func playVideo(id: String, player: Any) {
        if useCustomSystem {
            if let customPlayer = player as? CustomAVPlayer {
                CustomVideoOrchestrator.shared.playVideo(id: id, player: customPlayer)
            }
        } else {
            if let avPlayer = player as? AVPlayer {
                FeedVideoOrchestrator.shared.playVideo(id: id, player: avPlayer)
            }
        }
    }
    
    func pauseVideo(id: String) {
        if useCustomSystem {
            CustomVideoOrchestrator.shared.pauseVideo(id: id)
        } else {
            FeedVideoOrchestrator.shared.pauseVideo(id: id)
        }
    }
    
    func removeVideo(id: String) {
        if useCustomSystem {
            CustomVideoOrchestrator.shared.removeVideo(id: id)
        } else {
            FeedVideoOrchestrator.shared.removeVideo(id: id)
        }
    }
    
    func isVideoPlaying(id: String) -> Bool {
        if useCustomSystem {
            return CustomVideoOrchestrator.shared.isVideoPlaying(id: id)
        } else {
            return FeedVideoOrchestrator.shared.isVideoPlaying(id: id)
        }
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