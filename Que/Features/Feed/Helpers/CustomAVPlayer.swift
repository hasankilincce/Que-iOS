import AVKit
import Foundation
import Combine

class CustomAVPlayer: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isStalled = false
    @Published var isLoading = true
    @Published var isReady = false
    @Published var currentTime: CMTime = .zero
    @Published var duration: CMTime = .zero
    @Published var hasError = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var stallObserver: NSKeyValueObservation?
    private var playbackObserver: NSKeyValueObservation?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    
    // MARK: - Configuration
    private let preferredForwardBufferDuration: TimeInterval = 0.0 // Apple'ın adaptif buffer davranışını kullan
    private let preferredPeakBitRate: Double = 2_000_000 // 2 Mbps
    
    // MARK: - Public Interface
    var playerId: String = ""
    
    // Otomatik oynatma için
    private var shouldAutoPlay = true
    private var wasPlayingBeforeLoad = false
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func prepareVideo(url: URL, playerId: String) {
        print("🎬 CustomAVPlayer: Preparing video for URL: \(url)")
        
        self.playerId = playerId
        isLoading = true
        isStalled = false
        isReady = false
        hasError = false
        errorMessage = nil
        
        // Yükleme öncesi oynatma durumunu kaydet
        wasPlayingBeforeLoad = isPlaying
        
        // Audio session'ı hazırla
        FeedAudioSessionController.shared.prepareAudioSessionForVideo()
        
        // Asset'i yükle
        loadAsset(url: url)
    }
    
    func play() {
        guard let player = player, isReady else {
            print("🎬 CustomAVPlayer: Cannot play - player not ready")
            return
        }
        
        player.play()
        isPlaying = true
        print("🎬 CustomAVPlayer: Playing video with ID: \(playerId)")
    }
    
    func pause() {
        guard let player = player else { return }
        
        player.pause()
        isPlaying = false
        print("🎬 CustomAVPlayer: Paused video with ID: \(playerId)")
    }
    
    func seek(to time: CMTime) {
        guard let player = player else { return }
        
        player.seek(to: time) { [weak self] finished in
            if finished {
                print("🎬 CustomAVPlayer: Seek completed to \(time)")
            }
        }
    }
    
    func restart() {
        seek(to: .zero)
        play()
    }
    
    func getPlayer() -> AVPlayer? {
        return player
    }
    
    func setPlaybackRate(_ rate: Float) {
        guard let player = player else { return }
        
        player.rate = rate
        print("🎬 CustomAVPlayer: Playback rate set to \(rate)x for player ID: \(playerId)")
    }
    
    func cleanup() {
        print("🎬 CustomAVPlayer: Cleaning up player with ID: \(playerId)")
        
        // Observers'ları temizle
        cleanupObservers()
        
        // Player'ı durdur ve temizle
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        
        // Audio session'ı temizle
        FeedAudioSessionController.shared.cleanupAudioSession()
        
        // State'i reset et
        isPlaying = false
        isStalled = false
        isLoading = true
        isReady = false
        hasError = false
        errorMessage = nil
        currentTime = .zero
        duration = .zero
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        FeedAudioSessionController.shared.prepareAudioSessionForVideo()
    }
    
    private func loadAsset(url: URL) {
        // HLS Asset + network cache with custom configuration
        let config = FeedVideoCacheManager.shared.getURLSessionConfiguration()
        
        // URLSession ile cache'i kullan
        let session = URLSession(configuration: config)
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": config.httpAdditionalHeaders ?? [:],
            "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
            "AVURLAssetUsesNoPersistentCacheKey": false
        ])
        
        // Asset loading'i iyileştir
        asset.loadValuesAsynchronously(forKeys: ["playable", "tracks"]) { [weak self] in
            DispatchQueue.main.async {
                self?.handleAssetLoaded(asset)
            }
        }
    }
    
    private func handleAssetLoaded(_ asset: AVURLAsset) {
        var error: NSError?
        let playableStatus = asset.statusOfValue(forKey: "playable", error: &error)
        
        switch playableStatus {
        case .loaded:
            print("🎬 CustomAVPlayer: Asset loaded successfully")
            createPlayerItem(with: asset)
        case .failed:
            print("❌ CustomAVPlayer: Asset failed to load: \(error?.localizedDescription ?? "Unknown error")")
            handleError(error?.localizedDescription ?? "Asset loading failed")
        case .cancelled:
            print("❌ CustomAVPlayer: Asset loading cancelled")
            handleError("Asset loading cancelled")
        case .loading:
            print("🔄 CustomAVPlayer: Asset still loading")
        case .unknown:
            print("❓ CustomAVPlayer: Asset loading unknown status")
            handleError("Asset loading unknown status")
        @unknown default:
            print("❓ CustomAVPlayer: Asset loading unknown status")
            handleError("Asset loading unknown status")
        }
    }
    
    private func createPlayerItem(with asset: AVURLAsset) {
        let item = AVPlayerItem(asset: asset)
        
        // Buffer & bit-rate ayarları
        item.preferredForwardBufferDuration = preferredForwardBufferDuration
        
        // Dinamik bit-rate ayarı - ağ hızına göre
        let networkSpeed = getNetworkSpeed()
        let dynamicBitRate = calculateOptimalBitRate(for: networkSpeed)
        item.preferredPeakBitRate = dynamicBitRate
        
        print("🎬 CustomAVPlayer: Network speed: \(networkSpeed) Mbps, Bit rate: \(dynamicBitRate/1_000_000) Mbps")
        
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        
        // Bildirim çubuğunda video kontrollerini gizle
        newPlayer.allowsExternalPlayback = false
        
        // Observers'ları temizle ve yeniden kur
        cleanupObservers()
        setupObservers(for: item, player: newPlayer)
        
        player = newPlayer
        playerItem = item
        
        // Duration'ı al
        let duration = item.asset.duration
        if duration.isValid && duration.value > 0 {
            self.duration = duration
        }
        
        print("🎬 CustomAVPlayer: Player item created successfully")
    }
    
    private func setupObservers(for item: AVPlayerItem, player: AVPlayer) {
        // Player status monitoring
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                self?.handlePlayerItemStatus(playerItem.status)
            }
        }
        
        // Stall monitoring ve yükleme göstergesi
        stallObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                let isLikelyToKeepUp = playerItem.isPlaybackLikelyToKeepUp
                self?.isStalled = !isLikelyToKeepUp
                
                // Yükleme tamamlandığında loading state'ini güncelle
                if isLikelyToKeepUp && self?.isLoading == true {
                    self?.isLoading = false
                    print("🎬 CustomAVPlayer: Playback likely to keep up, loading complete")
                }
            }
        }
        
        // Playback buffer monitoring
        playbackObserver = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                if playerItem.isPlaybackBufferEmpty {
                    self?.isStalled = true
                }
            }
        }
        
        // Loaded time ranges monitoring
        loadedTimeRangesObserver = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                if let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue {
                    let duration = CMTimeGetSeconds(timeRange.duration)
                    print("🎬 CustomAVPlayer: Loaded time range: \(duration)s")
                }
            }
        }
        
        // Time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time
        }
        
        // Loop için notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }
    
    private func cleanupObservers() {
        statusObserver?.invalidate()
        statusObserver = nil
        
        stallObserver?.invalidate()
        stallObserver = nil
        
        playbackObserver?.invalidate()
        playbackObserver = nil
        
        loadedTimeRangesObserver?.invalidate()
        loadedTimeRangesObserver = nil
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func handlePlayerItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            print("🎬 CustomAVPlayer: Video ready to play")
            isLoading = false
            isReady = true
            hasError = false
            errorMessage = nil
            
            // Otomatik oynatma aktifse hemen başlat
            if shouldAutoPlay {
                DispatchQueue.main.async { [weak self] in
                    self?.play()
                    print("🎬 CustomAVPlayer: Auto-playing video with ID: \(self?.playerId ?? "")")
                }
            } else if wasPlayingBeforeLoad {
                // Yükleme öncesi oynatılıyorsa devam et
                DispatchQueue.main.async { [weak self] in
                    self?.play()
                    print("🎬 CustomAVPlayer: Resuming playback after load for ID: \(self?.playerId ?? "")")
                }
            } else {
                print("🎬 CustomAVPlayer: Player ready, waiting for orchestrator to start playback")
            }
        case .failed:
            print("❌ CustomAVPlayer: Video failed to load")
            isLoading = false
            isReady = false
            hasError = true
            errorMessage = "Video failed to load"
        case .unknown:
            print("❓ CustomAVPlayer: Video status unknown")
            break
        @unknown default:
            break
        }
    }
    
    private func handleError(_ message: String) {
        isLoading = false
        isReady = false
        hasError = true
        errorMessage = message
        print("❌ CustomAVPlayer Error: \(message)")
    }
    
    @objc private func playerItemDidReachEnd() {
        print("🎬 CustomAVPlayer: Video reached end, restarting")
        
        // Video bittiğinde isPlaying false yap
        isPlaying = false
        
        // Mevcut hızı sakla
        let currentRate = player?.rate ?? 1.0
        print("🎬 CustomAVPlayer: Saving current rate: \(currentRate)")
        
        restart()
        
        // Loop sonrası hızı geri yükle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setPlaybackRate(currentRate)
            print("🎬 CustomAVPlayer: Restored rate after loop: \(currentRate)")
        }
    }
    
    // MARK: - Network Optimization
    private func getNetworkSpeed() -> Double {
        // Basit ağ hızı tahmini - gerçek uygulamada daha sofistike olabilir
        // Şimdilik sabit değer kullanıyoruz, ileride gerçek ağ hızı ölçümü eklenebilir
        return 5.0 // 5 Mbps varsayılan
    }
    
    private func calculateOptimalBitRate(for networkSpeed: Double) -> Double {
        // Ağ hızına göre optimal bit-rate hesapla
        // Ağ hızının %80'ini kullan (buffer için %20 bırak)
        let optimalBitRate = networkSpeed * 0.8 * 1_000_000 // Mbps to bps
        
        // Minimum 500kbps, maksimum 2Mbps
        let minBitRate: Double = 500_000
        let maxBitRate: Double = 2_000_000
        
        return max(minBitRate, min(optimalBitRate, maxBitRate))
    }
} 