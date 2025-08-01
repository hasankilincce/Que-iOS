import SwiftUI
import AVKit

struct FullScreenVideoPlayerView: View {
    let videoURL: String
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = FeedVideoOrchestrator.shared
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let currentPlayer = player {
                VideoPlayer(player: currentPlayer)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .onTapGesture {
                        togglePlayback()
                    }
                    .onAppear {
                        // Auto-play video when it appears and is visible
                        if isVisible {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                videoManager.playVideo(id: videoId, player: currentPlayer)
                            }
                        }
                    }
                    .onDisappear {
                        videoManager.pauseVideo(id: videoId)
                    }
                    .onChange(of: isVisible) { _, newIsVisible in
                        if newIsVisible {
                            // Video görünür olduğunda oynat
                            if let currentPlayer = player {
                                videoManager.playVideo(id: videoId, player: currentPlayer)
                            }
                        } else {
                            // Video görünmez olduğunda durdur
                            videoManager.pauseVideo(id: videoId)
                        }
                    }
            } else {
                // Loading state
                Color.black
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Video yükleniyor...")
                                .foregroundColor(.white)
                                .font(.body)
                        }
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
        guard let url = URL(string: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return
        }
        
        isLoading = true
        
        // Audio session'ı video oynatma için hazırla
        FeedAudioSessionController.shared.prepareAudioSessionForVideo()
        
        // Create player with the video URL
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Bildirim çubuğunda video kontrollerini gizle
        player?.allowsExternalPlayback = false
        
        // Video loop için
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        // Player durumunu takip et
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { _ in
            isPlaying = videoManager.isVideoPlaying(id: videoId)
        }
        
        // Monitor player status
        monitorPlayerStatus()
        
        // Fallback: Video yüklendiğinde loading'i kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            videoManager.pauseVideo(id: videoId)
        } else {
            if let player = player {
                videoManager.playVideo(id: videoId, player: player)
            }
        }
    }
    
    // Player status monitoring
    private func monitorPlayerStatus() {
        guard let playerItem = player?.currentItem else { return }
        
        // Monitor player item status
        let statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self.isLoading = false
                case .failed:
                    print("Full screen video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        // Store observer reference (in a real app, you'd want to manage this properly)
        // For now, we'll rely on the automatic cleanup
    }
} 