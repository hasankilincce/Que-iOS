import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = VideoManager.shared
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var hasError = false
    
    // KVO observers için
    @State private var statusObserver: NSKeyValueObservation?
    @State private var playbackObserver: NSKeyValueObservation?
    
    var body: some View {
        ZStack {
            if let currentPlayer = player {
                VideoPlayer(player: currentPlayer)
                    .aspectRatio(9/16, contentMode: .fit) // 9:16 aspect ratio için optimize edilmiş
                    .clipped()
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
                    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
                        // Video bittiğinde başa sar
                        currentPlayer.seek(to: .zero)
                        currentPlayer.play()
                    }
            } else if isLoading {
                Color.black
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Video yükleniyor...")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                    )
            } else if hasError {
                Color.black
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.white)
                                .font(.system(size: 32))
                            Text("Video yüklenemedi")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                    )
            } else {
                Color.black
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupObservers()
            videoManager.removeVideo(id: videoId)
            player = nil
        }
    }
    
    private func setupPlayer() {
        isLoading = true
        hasError = false
        
        // Audio session'ı video oynatma için hazırla
        AudioSessionManager.shared.prepareAudioSessionForVideo()
        
        player = AVPlayer(url: videoURL)
        
        // Bildirim çubuğunda video kontrollerini gizle
        player?.allowsExternalPlayback = false
        
        // KVO observers'ları temizle
        cleanupObservers()
        
        // Player item'ı hazır olduğunda loading'i kapat
        if let playerItem = player?.currentItem {
            statusObserver = playerItem.observe(\.status, options: [.new]) { _, _ in
                self.handlePlayerItemStatus(playerItem.status)
            }
            
            playbackObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { _, _ in
                if playerItem.isPlaybackLikelyToKeepUp {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func handlePlayerItemStatus(_ status: AVPlayerItem.Status) {
        DispatchQueue.main.async {
            switch status {
            case .readyToPlay:
                self.isLoading = false
                print("Video ready to play: \(self.videoURL)")
            case .failed:
                self.isLoading = false
                self.hasError = true
                print("Video failed to load: \(self.videoURL)")
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func cleanupObservers() {
        statusObserver?.invalidate()
        statusObserver = nil
        playbackObserver?.invalidate()
        playbackObserver = nil
    }
} 