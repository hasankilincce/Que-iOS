import AVKit
import SwiftUI

struct VideoPostView: View {
    let url: URL
    let videoId: String
    @StateObject private var videoManager = VideoPlayerManager()
    
    var body: some View {
        ZStack {
            if let player = videoManager.getPlayer() {
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fill)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        // Stall indicator
                        Group {
                            if videoManager.isStalled {
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
                // Loading state
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(9/16, contentMode: .fit)
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
            print("🎬 VideoPostView: onAppear for videoId: \(videoId)")
            print("🎬 VideoPostView: URL: \(url)")
            videoManager.prepareVideo(url: url)
        }
        .onDisappear { 
            videoManager.release()
        }
    }
} 