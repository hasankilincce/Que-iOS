import AVKit
import Foundation

class VideoPlayerManager: NSObject, ObservableObject {
    @Published var isStalled = false
    @Published var isLoading = true
    @Published var isReady = false
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    func prepareVideo(url: URL) {
        print("🎬 VideoPostView: Preparing video for URL: \(url)")
        
        isLoading = true
        isStalled = false
        isReady = false
        
        // 0. Audio session'ı hazırla
        AudioSessionManager.shared.prepareAudioSessionForVideo()
        
        // 1. HLS Asset + network cache with custom configuration
        let config = URLCacheManager.shared.getURLSessionConfiguration()
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": config.httpAdditionalHeaders ?? [:]
        ])
        
        // Asset loading'i iyileştir
        asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
            DispatchQueue.main.async {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                switch status {
                case .loaded:
                    print("🎬 VideoPostView: Asset loaded successfully")
                    self?.createPlayerItem(with: asset)
                case .failed:
                    print("❌ VideoPostView: Asset failed to load: \(error?.localizedDescription ?? "Unknown error")")
                    self?.isLoading = false
                case .cancelled:
                    print("❌ VideoPostView: Asset loading cancelled")
                    self?.isLoading = false
                case .loading:
                    print("🔄 VideoPostView: Asset still loading")
                case .unknown:
                    print("❓ VideoPostView: Asset loading unknown status")
                    self?.isLoading = false
                @unknown default:
                    print("❓ VideoPostView: Asset loading unknown status")
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func createPlayerItem(with asset: AVURLAsset) {
        let item = AVPlayerItem(asset: asset)
        
        // 2. Buffer & bit-rate ayarları
        item.preferredForwardBufferDuration = 6        // 6 sn ön buffer
        item.preferredPeakBitRate = 2_000_000         // 2 Mbps tavan
        
        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = false
        
        // 3. Stall monitoring
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new], context: nil)
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)
        
        // 4. Player status monitoring
        item.observe(\.status, options: [.new]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                switch playerItem.status {
                case .readyToPlay:
                    print("🎬 VideoPostView: Video ready to play")
                    self?.isLoading = false
                    self?.isReady = true
                    // 5. Oynat
                    p.play()
                case .failed:
                    print("❌ VideoPostView: Video failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    if let error = playerItem.error {
                        print("❌ VideoPostView: Error details: \(error)")
                    }
                    self?.isLoading = false
                case .unknown:
                    print("❓ VideoPostView: Video status unknown")
                    break
                @unknown default:
                    break
                }
            }
        }
        
        // 6. Loop için
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            p.seek(to: CMTime.zero)
            p.play()
        }
        
        player = p
        playerItem = item
    }
    
    func release() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
        playerItem = nil
        
        NotificationCenter.default.removeObserver(self)
        
        // Audio session'ı temizle
        AudioSessionManager.shared.cleanupAudioSession()
    }
    
    func getPlayer() -> AVPlayer? {
        return player
    }
    
    // Stall monitoring
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            if keyPath == "playbackBufferEmpty" {
                self.isStalled = true
            } else if keyPath == "playbackLikelyToKeepUp" {
                self.isStalled = false
            }
        }
    }
} 