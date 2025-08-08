import SwiftUI
import AVFoundation

struct FeedVideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    let postID: String
    
    @Binding var isPlaying: Bool
    @Binding var showIcon: Bool
    @Binding var iconType: PlayPauseIconType
    
    // Feed'e özel özellikler
    var onDoubleTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressStateChanged: ((Bool) -> Void)? // Uzun basma durumu değişikliği için callback
    var isVisible: Bool = true // Post görünür mü?

    func makeUIView(context: Context) -> FeedPlayerView {
        let view = FeedPlayerView()
        view.backgroundColor = .black
        view.configure(url: videoURL, postID: postID)
        view.onPlayPauseToggle = { playing in
            DispatchQueue.main.async {
                isPlaying = playing
                showIcon = true
                iconType = playing ? .pause : .play
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    showIcon = false
                }
            }
        }
        view.onDoubleTap = onDoubleTap
        view.onLongPress = onLongPress
        view.onLongPressStateChanged = onLongPressStateChanged
        return view
    }

    func updateUIView(_ uiView: FeedPlayerView, context: Context) {
        uiView.updateLayerFrame()
        
        // Player henüz configure edilmemişse configure et
        if !uiView.isConfigured {
            print("FeedVideoPlayer: Player henüz configure edilmemiş, configure ediliyor - Post ID: \(postID)")
            uiView.configure(url: videoURL, postID: postID)
        }
        
        uiView.setPlaying(isPlaying)
        uiView.setVisibility(isVisible)
    }
    
    static func dismantleUIView(_ uiView: FeedPlayerView, coordinator: ()) {
        uiView.cleanupPlayer()
    }
}

class FeedPlayerView: UIView {
    // MARK: - Global registry to stop any stray audio
    private static let activeViews = NSHashTable<FeedPlayerView>.weakObjects()
    private static var hasInstalledGlobalCleanupObserver: Bool = false
    private static func installGlobalCleanupObserverIfNeeded() {
        guard !hasInstalledGlobalCleanupObserver else { return }
        hasInstalledGlobalCleanupObserver = true
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CleanupAllVideoPlayers"),
            object: nil,
            queue: .main
        ) { _ in
            // Clean up any registered players
            for view in activeViews.allObjects { view.forceCleanupPlayer() }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PauseAllVideoPlayers"),
            object: nil,
            queue: .main
        ) { _ in
            for view in activeViews.allObjects { view.pauseAndNotify() }
        }
    }

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    var isConfigured = false // Public yapıldı
    var isConfiguring = false // Yeni: eşzamanlı configure'ları engellemek için
    private var configureToken: Int = 0 // Yeni: asenkron asset yüklemelerini tekilleştirmek için
    private var postID: String = ""
    private var isVisible = true
    
    var onPlayPauseToggle: ((Bool) -> Void)?
    var onDoubleTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressStateChanged: ((Bool) -> Void)? // Uzun basma durumu değişikliği için callback
    
    private var isPlaying = true
    private var isLongPressing = false // Uzun basma durumu
    private let normalPlaybackRate: Float = 1.0 // Normal hız
    private let fastPlaybackRate: Float = 2.0 // Hızlı oynatma hızı
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        FeedPlayerView.installGlobalCleanupObserverIfNeeded()
        setupGestures()
        setupAppLifecycleObservers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        FeedPlayerView.installGlobalCleanupObserverIfNeeded()
        setupGestures()
        setupAppLifecycleObservers()
    }
    
    // MARK: - Playback helpers (DRY)
    private func applyPlaybackRate() {
        if isLongPressing {
            player?.rate = fastPlaybackRate
        } else {
            player?.rate = normalPlaybackRate
        }
    }

    private func playFromStartAndNotify() {
        guard let player else { return }
        player.seek(to: .zero)
        player.play()
        isPlaying = true
        onPlayPauseToggle?(true)
        applyPlaybackRate()
    }

    private func ensurePlayIfVisible() {
        guard isVisible, let player else { return }
        player.play()
        isPlaying = true
        applyPlaybackRate()
    }

    private func pauseAndNotify() {
        player?.pause()
        isPlaying = false
        onPlayPauseToggle?(false)
    }

    private func setupAppLifecycleObservers() {
        // Uygulama arka plana geçtiğinde video'yu durdur
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseVideoOnBackground()
        }
        
        // Uygulama ön plana geldiğinde video'yu kontrol et
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeVideoOnForeground()
        }
        
    }
    
    private func pauseVideoOnBackground() {
        print("FeedVideoPlayer: Uygulama arka plana geçti - Video durduruluyor - Post ID: \(postID)")
        pauseAndNotify()
    }
    
    private func resumeVideoOnForeground() {
        print("FeedVideoPlayer: Uygulama ön plana geldi - Video oynatılıyor - Post ID: \(postID)")
        // Uygulama ön plana geldiğinde video'yu otomatik olarak oynat
        ensurePlayIfVisible()
    }
    
    private func setupGestures() {
        // Tek tık gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
        
        // Çift tık gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        // Uzun basma gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.5
        self.addGestureRecognizer(longPress)
        
        // Gesture'ların birbirini etkilememesi için
        tap.require(toFail: doubleTap)
    }

    // MARK: - Hard stop helpers
    private func hardStopAudio() {
        // Tam durdurma: pause + item'ı kaldır + rate=0
        player?.pause()
        player?.rate = 0
        player?.replaceCurrentItem(with: nil)
    }

    private func cancelPendingLoads() {
        if let item = playerItem {
            item.cancelPendingSeeks()
            item.asset.cancelLoading()
        }
    }

    private static func deactivateAudioSessionIfNoActivePlayers() {
        // Kalan aktif view yoksa ses oturumunu pasifleştirmeyi dene
        if activeViews.allObjects.isEmpty {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            } catch {
                print("FeedVideoPlayer: AVAudioSession deactivate error: \(error)")
            }
        }
    }

    func configure(url: URL, postID: String) {
        // Zaten configure edilmiş veya edilmekteyse tekrarlama
        if isConfigured || isConfiguring { return }
        self.postID = postID

        // Önce mevcut player'ı temizle (gerekirse)
        // Not: cleanupPlayer configureToken'ı artırır, bu yüzden cleanup'tan
        // sonra yeni bir token ile devam edeceğiz
        cleanupPlayer()

        // Yeni bir configure denemesi başlat
        isConfiguring = true
        let nextToken = configureToken + 1
        configureToken = nextToken
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup error: \(error)")
        }
        
        // AVURLAsset ile ön ısıtma ve buffer optimizasyonu
        let asset = AVURLAsset(url: url)
        
        // Video'yu önceden hazırla
        let keys = ["playable", "tracks", "duration"]
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Yalnızca en güncel configure isteği sonuçlandığında ilerle
                guard self.configureToken == nextToken else {
                    // Eski bir configure tamamlandı, yok say
                    return
                }
                self.setupPlayerWithAsset(asset)
                // setup tamamlandıktan sonra artık configuring değiliz
                self.isConfiguring = false
            }
        }
    }
    
    private func setupPlayerWithAsset(_ asset: AVURLAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        
        // PlayerItem buffer ayarları
        playerItem.preferredForwardBufferDuration = 4.0
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        self.playerItem = playerItem
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        player.volume = 1.0
        self.player = player
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        // Video'yu önceden hazırla ve ilk frame'i göster
        player.seek(to: .zero)
        
        // Video görünürse oynat, değilse sadece hazırla
        if isVisible {
            player.play()
            isPlaying = true
        } else {
            // Görünür değilse sadece hazırla, oynatma
            isPlaying = false
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            if self?.isVisible == true {
                self?.player?.play()
                // Video yeniden başladığında mevcut hız durumunu koru
                if self?.isLongPressing == true {
                    self?.player?.rate = self?.fastPlaybackRate ?? 2.0
                } else {
                    self?.player?.rate = self?.normalPlaybackRate ?? 1.0
                }
            }
        }
        
        isConfigured = true
        // Register to global registry
        FeedPlayerView.activeViews.add(self)
    }
    
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        if playing && isVisible { ensurePlayIfVisible() } else { player?.pause() }
    }
    
    func setVisibility(_ visible: Bool) {
        let wasVisible = isVisible
        isVisible = visible
        
        if visible && !wasVisible {
            // Görünür hale geldiğinde video'yu anında baştan başlat
            print("FeedVideoPlayer: Video görünür hale geldi - Post ID: \(postID)")
            startVideoWithRetry()
        } else if visible && isPlaying {
            ensurePlayIfVisible()
        } else {
            player?.pause()
        }
    }
    
    private func startVideoWithRetry() {
        print("FeedVideoPlayer: startVideoWithRetry çağrıldı - Post ID: \(postID), player: \(player != nil), isConfigured: \(isConfigured)")
        
        guard let player = player else {
            // Player henüz hazır değilse 1 saniye sonra tekrar dene
            print("FeedVideoPlayer: Player henüz hazır değil, 1 saniye sonra tekrar deneniyor - Post ID: \(postID)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startVideoWithRetry()
            }
            return
        }
        
        // Video'yu baştan başlat ve anında oynat
        playFromStartAndNotify()
        
        print("FeedVideoPlayer: Video başlatıldı - Post ID: \(postID)")
    }
    
    func restartVideo() {
        guard let player = player else { return }
        
        // Video'yu baştan başlat ve anında oynat (görünürse)
        if isVisible { playFromStartAndNotify() } else { player.seek(to: .zero) }
    }
    
    @objc private func handleTap() {
        guard let player = player else { return }
        
        if isPlaying { pauseAndNotify() } else { ensurePlayIfVisible(); onPlayPauseToggle?(isPlaying) }
    }
    
    @objc private func handleDoubleTap() {
        print("FeedVideoPlayer çift tıklandı - Post ID: \(postID)")
        onDoubleTap?()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        print("FeedVideoPlayer uzun basıldı - Post ID: \(postID), State: \(gesture.state.rawValue)")
        
        switch gesture.state {
        case .began:
            // Uzun basma başladı - hızı artır
            isLongPressing = true
            player?.rate = fastPlaybackRate
            print("Video hızı 2x'e çıkarıldı")
            onLongPressStateChanged?(isLongPressing)
            
        case .ended, .cancelled, .failed:
            // Uzun basma bitti - hızı normale döndür
            isLongPressing = false
            player?.rate = normalPlaybackRate
            print("Video hızı normale döndü")
            onLongPressStateChanged?(isLongPressing)
            
        default:
            break
        }
        
        onLongPress?()
    }
    
    func cleanupPlayer() {
        if let playerItem = self.playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        // App lifecycle observer'larını temizle
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Tüm ses/oynatma durumunu kesin olarak durdur
        hardStopAudio()
        cancelPendingLoads()
        player = nil
        playerItem = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        isConfigured = false
        isConfiguring = false
        // Mevcut ve bekleyen asenkron configure'ları geçersiz kıl
        configureToken += 1
        // Remove from global registry
        FeedPlayerView.activeViews.remove(self)
        FeedPlayerView.deactivateAudioSessionIfNoActivePlayers()
    }
    
    private func forceCleanupPlayer() {
        print("FeedVideoPlayer: Feed yenilendi, player temizleniyor - Post ID: \(postID)")
        
        // Video'yu hemen durdur
        hardStopAudio()
        cancelPendingLoads()
        isPlaying = false
        isLongPressing = false
        
        // Player'ı tamamen temizle
        if let playerItem = self.playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        player = nil
        playerItem = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        isConfigured = false
        isConfiguring = false
        // Bekleyen yüklemeleri geçersiz kıl
        configureToken += 1
        // Remove from global registry
        FeedPlayerView.activeViews.remove(self)
        FeedPlayerView.deactivateAudioSessionIfNoActivePlayers()
        
        // UI güncelle
        onPlayPauseToggle?(false)
        onLongPressStateChanged?(false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrame()
    }
    
    func updateLayerFrame() {
        playerLayer?.frame = bounds
    }
    
    deinit {
        cleanupPlayer()
    }
}

struct FeedVideoPlayerViewContainer: View {
    let videoURL: URL
    let postID: String
    let isVisible: Bool
    
    @State private var isPlaying = true
    @State private var showIcon = false
    @State private var iconType: PlayPauseIconType = .pause
    @State private var isLongPressing = false // Uzun basma durumu
    
    var body: some View {
        ZStack {
            FeedVideoPlayerView(
                videoURL: videoURL,
                postID: postID,
                isPlaying: $isPlaying,
                showIcon: $showIcon,
                iconType: $iconType,
                onDoubleTap: {
                    print("FeedVideoPlayerContainer çift tıklandı - Post ID: \(postID)")
                },
                onLongPress: {
                    print("FeedVideoPlayerContainer uzun basıldı - Post ID: \(postID)")
                },
                onLongPressStateChanged: { isLongPressing in
                    self.isLongPressing = isLongPressing
                },
                isVisible: isVisible
            )
            .aspectRatio(9/16, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
            if showIcon || !isPlaying {
                Group {
                    if iconType == .play {
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .opacity(0.5)
                    } else {
                        /*Image(systemName: "pause.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .opacity(0.5)*/
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showIcon || !isPlaying)
            }
            
            // Hız göstergesi
            if isLongPressing {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Hız 2x")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            //.background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(.bottom, 120)
                            //.padding(.center)
                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: isLongPressing)
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                showIcon = false
            } else {
                showIcon = true
            }
        }
    }
} 
