import SwiftUI
import AVKit
import Combine

struct CustomVideoPlayerView: View {
    let videoURL: URL
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoManager = CustomVideoOrchestrator.shared
    @StateObject private var customPlayer = CustomAVPlayer()
    @State private var isLoading = true
    @State private var hasError = false
    @State private var cancellables = Set<AnyCancellable>()
    
    init(videoURL: URL, videoId: String, isVisible: Bool) {
        self.videoURL = videoURL
        self.videoId = videoId
        self.isVisible = isVisible
    }
    
    var body: some View {
        ZStack {
            if let currentPlayer = customPlayer.getPlayer() {
                // Custom Video Player with minimal controls
                CustomVideoPlayerControls(player: currentPlayer, customPlayer: customPlayer)
                    .aspectRatio(9/16, contentMode: .fit) // 9:16 aspect ratio için optimize edilmiş
                    .clipped()
                    .onAppear {
                        if isVisible {
                            videoManager.playVideo(id: videoId, player: customPlayer)
                        }
                    }
                    .onDisappear {
                        videoManager.pauseVideo(id: videoId)
                    }
                    .onChange(of: isVisible) { _, newIsVisible in
                        if newIsVisible {
                            videoManager.playVideo(id: videoId, player: customPlayer)
                        } else {
                            videoManager.pauseVideo(id: videoId)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
                        // Video bittiğinde başa sar
                        customPlayer.restart()
                    }
            } else if isLoading {
                Color.black
                    .aspectRatio(9/16, contentMode: .fit)
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
            } else if hasError {
                Color.black
                    .aspectRatio(9/16, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.red)
                            
                            Text("Video yüklenemedi")
                                .foregroundColor(.white)
                                .font(.body)
                            
                            Button("Tekrar Dene") {
                                setupPlayer()
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
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
        isLoading = true
        hasError = false
        
        // Custom player'ı hazırla
        customPlayer.prepareVideo(url: videoURL, playerId: videoId)
        
        // Video manager'a kaydet
        videoManager.registerPlayer(id: videoId, player: customPlayer)
        
        // Player durumunu takip et
        customPlayer.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { loading in
                self.isLoading = loading
            }
            .store(in: &cancellables)
        
        customPlayer.$hasError
            .receive(on: DispatchQueue.main)
            .sink { error in
                self.hasError = error
            }
            .store(in: &cancellables)
    }
}

// MARK: - Custom Video Player Controls
struct CustomVideoPlayerControls: View {
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
                if showPlayIcon {
                    ZStack {
                        // Play icon - sadece icon, circle yok
                        Image(systemName: "play.fill")
                            .font(.system(size: 30, weight: .medium))
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
            
            // Show play icon only when video is paused
            showPlayIcon = !playing
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