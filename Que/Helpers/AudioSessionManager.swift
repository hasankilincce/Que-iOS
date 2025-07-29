import AVFoundation
import UIKit

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {}
    
    // Audio session'ı video oynatma için optimize et
    func configureAudioSessionForVideoPlayback() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Audio session kategorisini video oynatma için ayarla
            // .playback kategorisi sessiz modda da ses çalar
            // .mixWithOthers ile Control Center'da görünmesini engellemeye çalış
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            
            // Audio session'ı aktif et
            try audioSession.setActive(true)
            
            DebugLogger.logSuccess("Audio session configured for video playback (playback mode)")
            
        } catch {
            // Error -50 normal bir durum, audio session zaten aktif
            if (error as NSError).code == -50 {
                DebugLogger.logInfo("Audio session already active (normal)")
            } else {
                DebugLogger.logWarning("Audio session warning: \(error.localizedDescription)")
            }
        }
    }
    
    // Audio session'ı reset et
    func resetAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            DebugLogger.logInfo("Audio session reset")
        } catch {
            // Error -50 normal bir durum
            if (error as NSError).code == -50 {
                DebugLogger.logInfo("Audio session already inactive (normal)")
            } else {
                DebugLogger.logWarning("Audio session reset warning: \(error.localizedDescription)")
            }
        }
    }
    
    // Video oynatma için audio session'ı hazırla
    func prepareAudioSessionForVideo() {
        configureAudioSessionForVideoPlayback()
    }
    
    // Video durdurma için audio session'ı temizle
    func cleanupAudioSession() {
        // Video durduğunda audio session'ı reset etme
        // Çünkü diğer videolar hala oynatılıyor olabilir
    }
    
    // Mevcut ses seviyesini al
    func getCurrentVolume() -> Float {
        return AVAudioSession.sharedInstance().outputVolume
    }
    
    // Ses seviyesinin değişimini dinle
    func observeVolumeChanges(completion: @escaping (Float) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil,
            queue: .main
        ) { _ in
            completion(self.getCurrentVolume())
        }
    }
} 