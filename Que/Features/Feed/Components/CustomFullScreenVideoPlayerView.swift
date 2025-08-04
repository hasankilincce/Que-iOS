import SwiftUI
import AVKit
import Combine

struct CustomFullScreenVideoPlayerView: View {
    let videoURL: String
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = CustomVideoOrchestrator.shared
    @StateObject private var customPlayer = CustomAVPlayer()
    @State private var isPlaying = false
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    init(videoURL: String, videoId: String, isVisible: Bool) {
        self.videoURL = videoURL
        self.videoId = videoId
        self.isVisible = isVisible
    }
    
    var body: some View {
        ZStack {
            if let currentPlayer = customPlayer.getPlayer() {
                // Custom Full Screen Video Player with minimal controls
                CustomFullScreenVideoPlayerControls(
                    player: currentPlayer, 
                    customPlayer: customPlayer
                )
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .onTapGesture {
                    // Video pause/play için tap gesture
                    if customPlayer.isPlaying {
                        customPlayer.pause()
                    } else {
                        customPlayer.play()
                    }
                }
                .onAppear {
                    // Auto-play video when it appears and is visible
                    if isVisible {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            videoManager.playVideo(id: videoId, player: customPlayer)
                        }
                    }
                }
                .onDisappear {
                    videoManager.pauseVideo(id: videoId)
                }
                .onChange(of: isVisible) { _, newIsVisible in
                    if newIsVisible {
                        // Video görünür olduğunda oynat
                        videoManager.playVideo(id: videoId, player: customPlayer)
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
            customPlayer.cleanup()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return
        }
        
        isLoading = true
        
        // Custom player'ı hazırla
        customPlayer.prepareVideo(url: url, playerId: videoId)
        
        // Video manager'a kaydet
        videoManager.registerPlayer(id: videoId, player: customPlayer)
        
        // Player durumunu takip et
        customPlayer.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { loading in
                self.isLoading = loading
            }
            .store(in: &cancellables)
        
        customPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { playing in
                self.isPlaying = playing
            }
            .store(in: &cancellables)
        
        // Player durumunu takip et
        customPlayer.$isReady
            .receive(on: DispatchQueue.main)
            .sink { isReady in
                if isReady {
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Custom Full Screen Video Player Controls
struct CustomFullScreenVideoPlayerControls: View {
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
                            .font(.system(size: 40, weight: .medium))
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayback()
                    }
                    .zIndex(9999) // En yüksek z-index - diğer tüm elementlerin üzerinde
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
