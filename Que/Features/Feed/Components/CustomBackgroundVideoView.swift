import SwiftUI
import AVKit
import Combine

struct CustomBackgroundVideoView: View {
    let videoURL: String
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = CustomVideoOrchestrator.shared
    @StateObject private var customPlayer = CustomAVPlayer()
    @State private var isPlaying = false
    @State private var cancellables = Set<AnyCancellable>()
    
    init(videoURL: String, videoId: String, isVisible: Bool) {
        self.videoURL = videoURL
        self.videoId = videoId
        self.isVisible = isVisible
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let currentPlayer = customPlayer.getPlayer() {
                    // Custom Background Video Player with minimal controls
                    CustomBackgroundVideoPlayerControls(
                        player: currentPlayer,
                        customPlayer: customPlayer
                    )
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
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            videoManager.removeVideo(id: videoId)
            customPlayer.cleanup()
        }
        .onChange(of: isVisible) { _, newIsVisible in
            if newIsVisible {
                videoManager.playVideo(id: videoId, player: customPlayer)
            } else {
                videoManager.pauseVideo(id: videoId)
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return
        }
        
        // Custom player'ı hazırla
        customPlayer.prepareVideo(url: url, playerId: videoId)
        
        // Video manager'a kaydet
        videoManager.registerPlayer(id: videoId, player: customPlayer)
        
        // Player durumunu takip et
        customPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { playing in
                self.isPlaying = playing
            }
            .store(in: &cancellables)
    }
}

// MARK: - Custom Background Video Player Controls
struct CustomBackgroundVideoPlayerControls: View {
    let player: AVPlayer
    let customPlayer: CustomAVPlayer
    @State private var isPlaying = false
    @State private var showControls = false
    @State private var showPlayIcon = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player (no controls)
                VideoPlayer(player: player)
                    .allowsHitTesting(false) // Disable default controls but allow tap gesture
                
                // Play Icon Animation when video is paused
                if !isPlaying && showPlayIcon {
                    ZStack {
                        // Play icon - sadece icon, circle yok
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(showPlayIcon ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.3), value: showPlayIcon)
                    }
                    .opacity(showPlayIcon ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: showPlayIcon)
                    .allowsHitTesting(false) // Allow tap to pass through to the background
                }
                
                // Tap area for pause/play - covers entire screen and is on top
                Color.clear
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayback()
                    }
                    .zIndex(1000) // Ensure it's on top of other elements
            }
        }
        .onReceive(customPlayer.$isPlaying) { playing in
            isPlaying = playing
            
            // Show play icon animation when video is paused
            if !playing {
                showPlayIcon = true
            } else {
                showPlayIcon = false
            }
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            customPlayer.pause()
        } else {
            customPlayer.play()
        }
    }
} 
