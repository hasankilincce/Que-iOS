import SwiftUI
import Combine

final class VideoVisibilityTracker: ObservableObject {
    static let shared = VideoVisibilityTracker()
    
    // MARK: - Published Properties
    @Published var currentVisibleVideoId: String?
    @Published var visibleVideoPercentage: Double = 0.0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let sharedPlayer = SharedVideoPlayer.shared
    
    // MARK: - Video URL Storage
    private var videoURLs: [String: URL] = [:]
    
    // MARK: - Configuration
    private let visibilityThreshold: Double = 0.5 // %50 görünürlük eşiği
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Video URL'ini kaydet
    func registerVideoURL(_ url: URL, for videoId: String) {
        videoURLs[videoId] = url
        print("🎬 VideoVisibilityTracker: Registered URL for video ID: \(videoId)")
    }
    
    /// Video görünürlüğünü güncelle
    func updateVisibility(for videoId: String, percentage: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Eğer bu video zaten görünürse ve yeterli yüzde varsa
            if self.currentVisibleVideoId == videoId && percentage >= self.visibilityThreshold {
                self.visibleVideoPercentage = percentage
                return
            }
            
            // Eğer yeni bir video yeterli yüzde ile görünürse
            if percentage >= self.visibilityThreshold {
                self.switchToVideo(videoId)
            } else if self.currentVisibleVideoId == videoId {
                // Mevcut video artık yeterli görünür değilse durdur
                self.pauseCurrentVideo()
            }
        }
    }
    
    /// Video'ya geç
    func switchToVideo(_ videoId: String) {
        guard currentVisibleVideoId != videoId else { return }
        
        print("🎬 VideoVisibilityTracker: Switching to video ID: \(videoId)")
        
        // Önceki videoyu durdur
        pauseCurrentVideo()
        
        // Yeni videoyu oynat
        currentVisibleVideoId = videoId
        visibleVideoPercentage = 1.0
        
        // SharedPlayer'ı kullanarak video oynat
        if let url = getVideoURL(for: videoId) {
            sharedPlayer.play(url: url, videoId: videoId)
        }
    }
    
    /// Mevcut videoyu duraklat
    func pauseCurrentVideo() {
        guard let currentId = currentVisibleVideoId else { return }
        
        print("🎬 VideoVisibilityTracker: Pausing video ID: \(currentId)")
        
        sharedPlayer.pause()
        currentVisibleVideoId = nil
        visibleVideoPercentage = 0.0
    }
    
    /// Tüm videoları durdur
    func pauseAllVideos() {
        print("🎬 VideoVisibilityTracker: Pausing all videos")
        
        sharedPlayer.stop()
        currentVisibleVideoId = nil
        visibleVideoPercentage = 0.0
    }
    
    /// Video URL'ini al
    private func getVideoURL(for videoId: String) -> URL? {
        return videoURLs[videoId]
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // SharedPlayer'dan gelen değişiklikleri dinle
        sharedPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                if !isPlaying {
                    self?.currentVisibleVideoId = nil
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - GeometryReader Helper
struct VideoVisibilityModifier: ViewModifier {
    let videoId: String
    @ObservedObject private var tracker = VideoVisibilityTracker.shared
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: VideoVisibilityPreferenceKey.self, value: [
                            VideoVisibilityData(
                                videoId: videoId,
                                frame: geometry.frame(in: .named("ScrollView")),
                                screenSize: UIScreen.main.bounds.size
                            )
                        ])
                }
            )
    }
}

// MARK: - Preference Key
struct VideoVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [VideoVisibilityData] = []
    
    static func reduce(value: inout [VideoVisibilityData], nextValue: () -> [VideoVisibilityData]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Visibility Data
struct VideoVisibilityData {
    let videoId: String
    let frame: CGRect
    let screenSize: CGSize
    
    var visibilityPercentage: Double {
        let screenHeight = screenSize.height
        let videoTop = frame.minY
        let videoBottom = frame.maxY
        
        let visibleTop = max(0, videoTop)
        let visibleBottom = min(screenHeight, videoBottom)
        let visibleHeight = max(0, visibleBottom - visibleTop)
        
        return visibleHeight / frame.height
    }
} 