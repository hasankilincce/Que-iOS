import AVKit
import SwiftUI

struct VideoPostView: View {
    let url: URL
    let videoId: String
    @StateObject private var videoWrapper = VideoSystemWrapper.shared
    
    var body: some View {
        ZStack {
            // Custom video player kullan
            videoWrapper.createVideoPlayer(
                url: url,
                videoId: videoId,
                isVisible: true
            )
            .aspectRatio(9/16, contentMode: .fill) // FILL MODE: tam ekran, letterbox yok
            .frame(maxWidth: .infinity)
            .background(Color.black) // Siyah arka plan letterbox effect için
            .cornerRadius(12)
        }
        .onAppear { 
            print("🎬 VideoPostView: onAppear for videoId: \(videoId)")
            print("🎬 VideoPostView: URL: \(url)")
            
            // Custom video system'i aktif et
            videoWrapper.useCustomSystem = true
            
            // Video boyutlarını kontrol et
            let asset = AVURLAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                DispatchQueue.main.async {
                    if let track = try? asset.tracks(withMediaType: .video).first {
                        let size = track.naturalSize
                        let ratio = size.width / size.height
                        print("🎬 Video dimensions: \(size.width) x \(size.height)")
                        print("🎬 Video aspect ratio: \(ratio)")
                        print("🎬 Target aspect ratio: \(9.0/16.0)")
                        print("🎬 Difference: \(abs(ratio - 9.0/16.0))")
                    }
                }
            }
        }
    }
} 