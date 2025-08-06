import SwiftUI
import AVFoundation

struct CustomVideoPlayerView: UIViewRepresentable {
    let videoURL: URL

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        view.configure(url: videoURL)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.updateLayerFrame()
    }
    
    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.cleanupPlayer()
    }
}

class PlayerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var isConfigured = false

    func configure(url: URL) {
        // Eğer zaten configure edilmişse, tekrar yapma
        if isConfigured {
            return
        }
        
        // Önceki player'ı temizle
        cleanupPlayer()
        
        // Video dosyasının varlığını kontrol et
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Video dosyası bulunamadı: \(url.path)")
            return
        }
        
        // Ses ayarlarını kontrol et - sadece bir kez
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ses ayarları hatası: \(error)")
        }
        
        // Yeni player item oluştur
        let playerItem = AVPlayerItem(url: url)
        self.playerItem = playerItem
        
        // Player oluştur
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        
        // Ses seviyesini kontrol et
        player.volume = 1.0
        
        self.player = player
        
        // Player layer oluştur
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        // Video oynatmayı başlat
        player.play()
        
        // Loop video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        isConfigured = true
    }
    
    func cleanupPlayer() {
        // Önceki observer'ları kaldır
        if let playerItem = self.playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        // Player'ı durdur ve temizle
        player?.pause()
        player = nil
        playerItem = nil
        
        // Player layer'ı kaldır
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