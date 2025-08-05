import AVKit
import Foundation
import Combine

final class SharedVideoPlayer: ObservableObject {
    static let shared = SharedVideoPlayer()
    
    // MARK: - Published Properties
    @Published var isPlaying: Bool = false
    @Published var currentVideoId: String?
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var playbackObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let preferredForwardBufferDuration: TimeInterval = 1.0 // Hızlı önbellek
    private let preferredPeakBitRate: Double = 2_000_000 // 2 Mbps
    
    // MARK: - Cache
    private let videoURLs = NSCache<NSString, NSURL>()
    private let prefetchQueue = DispatchQueue(label: "com.que.prefetch", qos: .background)
    
    private init() {
        setupPlayer()
        setupObservers()
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Video katmanını view'a ekle
    func attach(to view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Önceki katmanı kaldır
            self.playerLayer.removeFromSuperlayer()
            
            // Yeni katmanı ekle
            self.playerLayer.player = self.player
            self.playerLayer.frame = view.bounds
            self.playerLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(self.playerLayer)
            
            print("🎬 SharedVideoPlayer: Attached player layer to view")
        }
    }
    
    /// Video oynat
    func play(url: URL, videoId: String) {
        print("🎬 SharedVideoPlayer: Playing video with ID: \(videoId)")
        
        // Önceki videoyu durdur
        pause()
        
        // URL'yi cache'e kaydet
        videoURLs.setObject(url as NSURL, forKey: videoId as NSString)
        
        // Video'yu oynat
        playFromURL(url: url, videoId: videoId)
        
        currentVideoId = videoId
        isLoading = true
        hasError = false
        errorMessage = nil
    }
    
    /// Video duraklat
    func pause() {
        player.pause()
        isPlaying = false
        print("🎬 SharedVideoPlayer: Paused video")
    }
    
    /// Video'yu durdur ve temizle
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        currentVideoId = nil
        print("🎬 SharedVideoPlayer: Stopped video")
    }
    
    /// Video'yu önbelleğe al
    func prefetchVideo(url: URL, videoId: String) {
        prefetchQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("🎬 SharedVideoPlayer: Prefetching video with ID: \(videoId)")
            
            // URL'yi cache'e kaydet
            self.videoURLs.setObject(url as NSURL, forKey: videoId as NSString)
            print("🎬 SharedVideoPlayer: Cached video URL for ID: \(videoId)")
        }
    }
    
    /// URL'den video oynat
    private func playFromURL(url: URL, videoId: String) {
        print("🎬 SharedVideoPlayer: Playing from URL for ID: \(videoId)")
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        configurePlayerItem(playerItem)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        isPlaying = true
    }
    
    /// PlayerItem'ı yapılandır
    private func configurePlayerItem(_ playerItem: AVPlayerItem) {
        playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration
        playerItem.preferredPeakBitRate = preferredPeakBitRate
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = false
    }
    
    /// Player'ı yapılandır
    private func setupPlayer() {
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = false
    }
    
    /// Observer'ları ayarla
    private func setupObservers() {
        // Status observer
        statusObserver = player.observe(\.currentItem?.status, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.handlePlayerItemStatus()
            }
        }
        
        // Playback observer
        playbackObserver = player.observe(\.rate, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isPlaying = self?.player.rate != 0
            }
        }
        
        // Time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            // Time updates if needed
        }
    }
    
    /// Audio session'ı ayarla
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("🎬 SharedVideoPlayer: Audio session configured")
        } catch {
            print("❌ SharedVideoPlayer: Failed to configure audio session: \(error)")
        }
    }
    
    /// PlayerItem status'unu işle
    private func handlePlayerItemStatus() {
        guard let playerItem = player.currentItem else { return }
        
        switch playerItem.status {
        case .readyToPlay:
            isLoading = false
            hasError = false
            print("🎬 SharedVideoPlayer: Video ready to play")
        case .failed:
            isLoading = false
            hasError = true
            errorMessage = playerItem.error?.localizedDescription ?? "Video failed to load"
            print("❌ SharedVideoPlayer: Video failed to load")
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    /// Temizlik
    private func cleanup() {
        statusObserver?.invalidate()
        playbackObserver?.invalidate()
        
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("❌ SharedVideoPlayer: Failed to deactivate audio session: \(error)")
        }
    }
}

 