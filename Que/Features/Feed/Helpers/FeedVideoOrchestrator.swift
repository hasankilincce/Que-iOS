import SwiftUI
import AVKit
import Combine

class FeedVideoOrchestrator: ObservableObject {
    static let shared = FeedVideoOrchestrator()
    
    @Published var currentPlayingVideoId: String?
    private var players: [String: AVPlayer] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let audioSessionManager = FeedAudioSessionController.shared
    private let mediaControlManager = FeedMediaControlHandler.shared
    
    private init() {}
    
    // Video oynatmayı başlat
    func playVideo(id: String, player: AVPlayer) {
        // Önceki videoyu durdur
        if let currentId = currentPlayingVideoId, currentId != id {
            pauseVideo(id: currentId)
        }
        
        // Media kontrollerini yapılandır (bildirim çubuğunda görünmeyi engelle)
        mediaControlManager.configureForVideoPlayback()
        
        // Bildirim çubuğunda video kontrollerini gizle
        player.allowsExternalPlayback = false
        
        // Yeni videoyu oynat
        currentPlayingVideoId = id
        players[id] = player
        player.play()
        
        DebugLogger.logVideo("Playing video with ID: \(id)")
        DebugLogger.logAudio("Video should play with sound even in silent mode")
        DebugLogger.logInfo("External playback controls and media controls disabled")
    }
    
    // Video oynatmayı durdur
    func pauseVideo(id: String) {
        if let player = players[id] {
            player.pause()
            DebugLogger.logVideo("Paused video with ID: \(id)")
        }
        
        if currentPlayingVideoId == id {
            currentPlayingVideoId = nil
        }
    }
    
    // Video'yu kaldır (cleanup)
    func removeVideo(id: String) {
        pauseVideo(id: id)
        players.removeValue(forKey: id)
        
        // Eğer hiç video oynatılmıyorsa audio session'ı temizle
        if players.isEmpty {
            audioSessionManager.cleanupAudioSession()
            mediaControlManager.cleanupForVideoStop()
        }
        
        DebugLogger.logVideo("Removed video with ID: \(id)")
    }
    
    // Tüm videoları durdur
    func pauseAllVideos() {
        for (id, player) in players {
            player.pause()
            DebugLogger.logVideo("Paused all videos, including: \(id)")
        }
        currentPlayingVideoId = nil
        
        // Audio session'ı temizle
        audioSessionManager.cleanupAudioSession()
        mediaControlManager.cleanupForVideoStop()
    }
    
    // Video'nun oynatılıp oynatılmadığını kontrol et
    func isVideoPlaying(id: String) -> Bool {
        return currentPlayingVideoId == id
    }
    
    // Cleanup
    deinit {
        pauseAllVideos()
        cancellables.removeAll()
    }
} 