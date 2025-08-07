import SwiftUI
import AVFoundation

struct CustomVideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    
    @Binding var isPlaying: Bool
    @Binding var showIcon: Bool
    @Binding var iconType: PlayPauseIconType

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        view.configure(url: videoURL)
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
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.updateLayerFrame()
        uiView.setPlaying(isPlaying)
    }
    
    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.cleanupPlayer()
    }
}

enum PlayPauseIconType {
    case play, pause
}

class PlayerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var isConfigured = false
    var onPlayPauseToggle: ((Bool) -> Void)?
    private var isPlaying = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(url: URL) {
        if isConfigured { return }
        cleanupPlayer()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        let playerItem = AVPlayerItem(url: url)
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
        player.play()
        isPlaying = true
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        isConfigured = true
    }
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        // SwiftUI tarafında showIcon ve iconType yönetilecek, burada state yok
    }
    @objc private func handleTap() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        onPlayPauseToggle?(isPlaying)
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

struct CustomVideoPlayerViewContainer: View {
    let videoURL: URL
    @State private var isPlaying = true
    @State private var showIcon = false
    @State private var iconType: PlayPauseIconType = .pause
    var body: some View {
        ZStack {
            CustomVideoPlayerView(videoURL: videoURL, isPlaying: $isPlaying, showIcon: $showIcon, iconType: $iconType)
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
