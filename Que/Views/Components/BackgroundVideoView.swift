import SwiftUI
import AVKit

struct BackgroundVideoView: View {
    let videoURL: String
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = VideoManager.shared
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if let currentPlayer = player {
                VideoPlayer(player: currentPlayer)
                    .frame(height: 320) // Fixed height for 9:16 viewing (vertical)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .cornerRadius(12)
                    )
                    .onTapGesture {
                        togglePlayback()
                    }
                    .overlay(
                        // Play/Pause button overlay
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: togglePlayback) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, 16)
                            }
                        }
                    )
            } else {
                // Loading state
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 320)
                    .overlay(
                        VStack {
                            Image(systemName: "video")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            Text("Video yükleniyor...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
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
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return
        }
        
        // Audio session'ı video oynatma için hazırla
        AudioSessionManager.shared.prepareAudioSessionForVideo()
        
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
            isPlaying = videoManager.isVideoPlaying(id: videoId)
        }
        
        // Player status monitoring
        playerItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    break
                case .failed:
                    print("Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            videoManager.pauseVideo(id: videoId)
        } else {
            if let currentPlayer = player {
                videoManager.playVideo(id: videoId, player: currentPlayer)
            }
        }
    }
} 