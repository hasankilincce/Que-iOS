import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = VideoManager.shared
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let currentPlayer = player {
                VideoPlayer(player: currentPlayer)
                    .onAppear {
                        if isVisible {
                            videoManager.playVideo(id: videoId, player: currentPlayer)
                        }
                    }
                    .onDisappear {
                        videoManager.pauseVideo(id: videoId)
                    }
                    .onChange(of: isVisible) { _, newIsVisible in
                        if newIsVisible {
                            if let currentPlayer = player {
                                videoManager.playVideo(id: videoId, player: currentPlayer)
                            }
                        } else {
                            videoManager.pauseVideo(id: videoId)
                        }
                    }
            } else {
                Color.black
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            videoManager.removeVideo(id: videoId)
            player = nil
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        
        // Video loop için
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
} 