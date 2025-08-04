import AVKit
import SwiftUI

struct CustomVideoPostView: View {
    let url: URL
    let videoId: String
    @StateObject private var customPlayer = CustomAVPlayer()
    
    var body: some View {
        ZStack {
            if let player = customPlayer.getPlayer() {
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fill) // FILL MODE: tam ekran, letterbox yok
                    .frame(maxWidth: .infinity)
                    .background(Color.black) // Siyah arka plan letterbox effect için
                    .cornerRadius(12)
                    .overlay(
                        // Stall indicator
                        Group {
                            if customPlayer.isStalled {
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                    Text("Video yükleniyor...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                }
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                            }
                        }
                    )
            } else {
                // Loading state - BackgroundImageView ile aynı boyut
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(9/16, contentMode: .fit) // BackgroundImageView ile aynı: fit mode
                    .frame(maxWidth: .infinity)
                    .background(Color.black) // BackgroundImageView ile aynı: siyah arka plan
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .scaleEffect(1.2)
                            Text("Video hazırlanıyor...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                    )
            }
        }
        .onAppear { 
            print("🎬 CustomVideoPostView: onAppear for videoId: \(videoId)")
            print("🎬 CustomVideoPostView: URL: \(url)")
            
            // Video boyutlarını kontrol et
            let asset = AVURLAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                DispatchQueue.main.async {
                    if let track = try? asset.tracks(withMediaType: .video).first {
                        let size = track.naturalSize
                        let ratio = size.width / size.height
                        print("🎬 CustomVideoPostView dimensions: \(size.width) x \(size.height)")
                        print("🎬 CustomVideoPostView aspect ratio: \(ratio)")
                        print("🎬 CustomVideoPostView target aspect ratio: \(9.0/16.0)")
                        print("🎬 CustomVideoPostView difference: \(abs(ratio - 9.0/16.0))")
                    }
                }
            }
            
            customPlayer.prepareVideo(url: url, playerId: videoId)
        }
        .onDisappear { 
            customPlayer.cleanup()
        }
    }
} 