import SwiftUI
import AVKit
import Combine

class CustomVideoOrchestrator: ObservableObject {
    static let shared = CustomVideoOrchestrator()
    
    @Published var currentPlayingVideoId: String?
    private var customPlayers: [String: CustomAVPlayer] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let audioSessionManager = FeedAudioSessionController.shared
    private let mediaControlManager = FeedMediaControlHandler.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    // Video oynatmayı başlat
    func playVideo(id: String, player: CustomAVPlayer) {
        // Önceki videoyu durdur
        if let currentId = currentPlayingVideoId, currentId != id {
            pauseVideo(id: currentId)
        }
        
        // Media kontrollerini yapılandır (bildirim çubuğunda görünmeyi engelle)
        mediaControlManager.configureForVideoPlayback()
        
        // Yeni videoyu oynat
        currentPlayingVideoId = id
        customPlayers[id] = player
        player.play()
        
        DebugLogger.logVideo("CustomVideoOrchestrator: Playing video with ID: \(id)")
        DebugLogger.logAudio("Video should play with sound even in silent mode")
        DebugLogger.logInfo("External playback controls and media controls disabled")
    }
    
    // Video oynatmayı durdur
    func pauseVideo(id: String) {
        if let player = customPlayers[id] {
            player.pause()
            DebugLogger.logVideo("CustomVideoOrchestrator: Paused video with ID: \(id)")
        }
        
        if currentPlayingVideoId == id {
            currentPlayingVideoId = nil
        }
    }
    
    // Video'yu kaldır (cleanup)
    func removeVideo(id: String) {
        pauseVideo(id: id)
        customPlayers.removeValue(forKey: id)
        
        // Eğer hiç video oynatılmıyorsa audio session'ı temizle
        if customPlayers.isEmpty {
            audioSessionManager.cleanupAudioSession()
            mediaControlManager.cleanupForVideoStop()
        }
        
        DebugLogger.logVideo("CustomVideoOrchestrator: Removed video with ID: \(id)")
    }
    
    // Alias for removeVideo (for consistency)
    func removePlayer(id: String) {
        removeVideo(id: id)
    }
    
    // Tüm videoları durdur
    func pauseAllVideos() {
        for (id, player) in customPlayers {
            player.pause()
            DebugLogger.logVideo("CustomVideoOrchestrator: Paused all videos, including: \(id)")
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
    
    // Custom player'ı kaydet
    func registerPlayer(id: String, player: CustomAVPlayer) {
        customPlayers[id] = player
        DebugLogger.logVideo("CustomVideoOrchestrator: Registered player with ID: \(id)")
    }
    
    // Custom player'ı al
    func getPlayer(id: String) -> CustomAVPlayer? {
        return customPlayers[id]
    }
    
    // Tüm player'ları temizle
    func cleanupAllPlayers() {
        for (id, player) in customPlayers {
            player.cleanup()
            DebugLogger.logVideo("CustomVideoOrchestrator: Cleaned up player with ID: \(id)")
        }
        customPlayers.removeAll()
        currentPlayingVideoId = nil
    }
    
    // MARK: - Cleanup
    deinit {
        pauseAllVideos()
        cleanupAllPlayers()
        cancellables.removeAll()
    }
} 