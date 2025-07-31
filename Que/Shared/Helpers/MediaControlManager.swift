import MediaPlayer
import AVFoundation

class MediaControlManager {
    static let shared = MediaControlManager()
    
    private init() {}
    
    // Media kontrollerini devre dışı bırak
    func disableMediaControls() {
        // MPNowPlayingInfoCenter'ı temizle
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Media kontrollerini gizle
        MPRemoteCommandCenter.shared().playCommand.isEnabled = false
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = false
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = false
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = false
        
        DebugLogger.logInfo("Media controls disabled")
    }
    
    // Media kontrollerini etkinleştir (gerekirse)
    func enableMediaControls() {
        // Media kontrollerini etkinleştir
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        
        DebugLogger.logInfo("Media controls enabled")
    }
    
    // Video oynatma için media kontrollerini yapılandır
    func configureForVideoPlayback() {
        // Media kontrollerini devre dışı bırak
        disableMediaControls()
        
        // Audio session'ı da yapılandır
        AudioSessionManager.shared.prepareAudioSessionForVideo()
    }
    
    // Video durdurma için media kontrollerini temizle
    func cleanupForVideoStop() {
        // Media kontrollerini temizle
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        DebugLogger.logInfo("Media controls cleaned up")
    }
} 