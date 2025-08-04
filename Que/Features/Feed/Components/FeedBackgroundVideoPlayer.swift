import SwiftUI
import AVKit

struct BackgroundVideoView: View {
    let videoURL: String
    let videoId: String
    let isVisible: Bool
    @StateObject private var videoWrapper = VideoSystemWrapper.shared
    
    var body: some View {
        ZStack {
            // Custom background video player kullan
            videoWrapper.createBackgroundVideoPlayer(
                videoURL: videoURL,
                videoId: videoId,
                isVisible: isVisible
            )
            .frame(height: 320) // Fixed height for 9:16 viewing (vertical)
            .clipped()
            .cornerRadius(12)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
            )
        }
        .onAppear {
            // Custom video system'i aktif et
            videoWrapper.useCustomSystem = true
        }
    }
} 