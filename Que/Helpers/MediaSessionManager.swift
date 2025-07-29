import AVFoundation
import MediaPlayer
import UIKit

class MediaSessionManager {
    static let shared = MediaSessionManager()
    
    private init() {}
    
    // Media session'ı yapılandır ve Control Center'da görünmesini engelle
    func configureMediaSession() {
        // MPRemoteCommandCenter'ı devre dışı bırak
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Tüm remote command'ları devre dışı bırak
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.ratingCommand.isEnabled = false
        commandCenter.likeCommand.isEnabled = false
        commandCenter.dislikeCommand.isEnabled = false
        commandCenter.bookmarkCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        
        // Now Playing bilgilerini temizle ve minimal bilgi ayarla
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        DebugLogger.logInfo("Media session configured - Control Center controls disabled")
    }
    
    // Video oynatma için media session'ı hazırla
    func prepareForVideoPlayback() {
        configureMediaSession()
        
        // Audio session'ı playback modda yapılandır (sessiz modda ses çalar)
        AudioSessionManager.shared.configureAudioSessionForVideoPlayback()
        
        // Ek olarak Now Playing'i sürekli temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.clearNowPlayingInfo()
        }
    }
    
    // Now Playing bilgilerini temizle
    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        DebugLogger.logInfo("Now Playing info cleared")
    }
    
    // Media session'ı temizle
    func cleanupMediaSession() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Remote command'ları tekrar etkinleştir (isteğe bağlı)
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true
        
        // Now Playing bilgilerini temizle
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        DebugLogger.logInfo("Media session cleaned up")
    }
    
    // Now Playing bilgilerini güncelle (eğer gerekirse)
    func updateNowPlayingInfo(title: String? = nil, artist: String? = nil) {
        var nowPlayingInfo = [String: Any]()
        
        if let title = title {
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
        }
        
        if let artist = artist {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        // Control Center'da görünmesini engellemek için minimal bilgi
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
} 