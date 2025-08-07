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
        uiView.setPlaying(isPlaying)
        uiView.setVisibility(isVisible)
    }
    
    static func dismantleUIView(_ uiView: FeedPlayerView, coordinator: ()) {
        uiView.cleanupPlayer()
    }
}

class FeedPlayerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var isConfigured = false
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
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func configure(url: URL, postID: String) {
        if isConfigured { return }
        self.postID = postID
        cleanupPlayer()
        
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
                self?.setupPlayerWithAsset(asset)
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
    }
    
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        if playing && isVisible {
            player?.play()
            // Mevcut hız durumunu koru
            if isLongPressing {
                player?.rate = fastPlaybackRate
            } else {
                player?.rate = normalPlaybackRate
            }
        } else {
            player?.pause()
        }
    }
    
    func setVisibility(_ visible: Bool) {
        let wasVisible = isVisible
        isVisible = visible
        
        if visible && !wasVisible {
            // Görünür hale geldiğinde video'yu anında baştan başlat
            restartVideo()
            isPlaying = true
        } else if visible && isPlaying {
            player?.play()
            // Mevcut hız durumunu koru
            if isLongPressing {
                player?.rate = fastPlaybackRate
            } else {
                player?.rate = normalPlaybackRate
            }
        } else {
            player?.pause()
        }
    }
    
    func restartVideo() {
        guard let player = player else { return }
        
        // Video'yu baştan başlat ve anında oynat
        player.seek(to: .zero)
        if isVisible {
            player.play()
            isPlaying = true
            // Mevcut hız durumunu koru
            if isLongPressing {
                player.rate = fastPlaybackRate
            } else {
                player.rate = normalPlaybackRate
            }
        }
    }
    
    @objc private func handleTap() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
            // Mevcut hız durumunu koru
            if isLongPressing {
                player.rate = fastPlaybackRate
            } else {
                player.rate = normalPlaybackRate
            }
        }
        
        onPlayPauseToggle?(isPlaying)
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
        player?.pause()
        player = nil
        playerItem = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        isConfigured = false
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
                        Image(systemName: "pause.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .opacity(0.5)
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
