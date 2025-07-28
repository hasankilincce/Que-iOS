import SwiftUI
import AVKit

struct FullScreenVideoPlayerView: View {
    let videoURL: String
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .onTapGesture {
                        togglePlayback()
                    }
                    .onAppear {
                        // Auto-play video when it appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
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
            
            // Play/Pause button overlay (only show when not playing)
            if !isPlaying && player != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: togglePlayback) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 32)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return
        }
        
        isLoading = true
        
        // Create player with the video URL
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
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
            isPlaying = player?.timeControlStatus == .playing
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
            player?.pause()
        } else {
            player?.play()
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