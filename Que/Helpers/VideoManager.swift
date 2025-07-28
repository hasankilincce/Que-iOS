import SwiftUI
import AVKit
import Combine

class VideoManager: ObservableObject {
    static let shared = VideoManager()
    
    @Published var currentPlayingVideoId: String?
    private var players: [String: AVPlayer] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // Video oynatmayı başlat
    func playVideo(id: String, player: AVPlayer) {
        // Önceki videoyu durdur
        if let currentId = currentPlayingVideoId, currentId != id {
            pauseVideo(id: currentId)
        }
        
        // Yeni videoyu oynat
        currentPlayingVideoId = id
        players[id] = player
        player.play()
        
        print("🎬 VideoManager: Playing video with ID: \(id)")
    }
    
    // Video oynatmayı durdur
    func pauseVideo(id: String) {
        if let player = players[id] {
            player.pause()
            print("⏸️ VideoManager: Paused video with ID: \(id)")
        }
        
        if currentPlayingVideoId == id {
            currentPlayingVideoId = nil
        }
    }
    
    // Video'yu kaldır (cleanup)
    func removeVideo(id: String) {
        pauseVideo(id: id)
        players.removeValue(forKey: id)
        print("🗑️ VideoManager: Removed video with ID: \(id)")
    }
    
    // Tüm videoları durdur
    func pauseAllVideos() {
        for (id, player) in players {
            player.pause()
            print("⏸️ VideoManager: Paused all videos, including: \(id)")
        }
        currentPlayingVideoId = nil
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