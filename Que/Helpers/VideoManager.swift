import SwiftUI
import AVKit
import Combine

class VideoManager: ObservableObject {
    static let shared = VideoManager()
    
    @Published var currentPlayingVideoId: String?
    private var players: [String: AVPlayer] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let audioSessionManager = AudioSessionManager.shared
    private let mediaSessionManager = MediaSessionManager.shared
    
    private init() {}
    
    // Video oynatmayı başlat
    func playVideo(id: String, player: AVPlayer) {
        // Önceki videoyu durdur
        if let currentId = currentPlayingVideoId, currentId != id {
            pauseVideo(id: currentId)
        }
        
        // Media session'ı video oynatma için hazırla (Control Center'da görünmesini engelle)
        mediaSessionManager.prepareForVideoPlayback()
        
        // External playback'i devre dışı bırak (Control Center'da görünmesini engelle)
        player.allowsExternalPlayback = false
        
        // Yeni videoyu oynat
        currentPlayingVideoId = id
        players[id] = player
        player.play()
        
        // Video oynatma sırasında Now Playing'i sürekli temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mediaSessionManager.clearNowPlayingInfo()
        }
        
        DebugLogger.logVideo("Playing video with ID: \(id)")
        DebugLogger.logAudio("Video should play with sound even in silent mode")
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
        
        // Eğer hiç video oynatılmıyorsa session'ları temizle
        if players.isEmpty {
            audioSessionManager.cleanupAudioSession()
            mediaSessionManager.cleanupMediaSession()
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
        
        // Session'ları temizle
        audioSessionManager.cleanupAudioSession()
        mediaSessionManager.cleanupMediaSession()
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