import SwiftUI
import AVKit

struct CustomVideoTestView: View {
    @State private var isVisible = true
    @State private var showCustomPlayer = true
    
    // Test video URL'leri
    private let testVideoURL = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    private let testVideoURL2 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Custom Video Player Test")
                    .font(.title)
                    .padding()
                
                // Toggle for visibility
                Toggle("Video Visible", isOn: $isVisible)
                    .padding()
                
                // Toggle for custom player
                Toggle("Use Custom Player", isOn: $showCustomPlayer)
                    .padding()
                
                if showCustomPlayer {
                    // Custom Video Player Test
                    CustomVideoPlayerView(
                        videoURL: URL(string: testVideoURL)!,
                        videoId: "test_video_1",
                        isVisible: isVisible
                    )
                    .frame(height: 400)
                    .cornerRadius(12)
                    .padding()
                    
                    // Custom Full Screen Video Player Test
                    CustomFullScreenVideoPlayerView(
                        videoURL: testVideoURL2,
                        videoId: "test_video_2",
                        isVisible: isVisible
                    )
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                    
                    // Custom Background Video Test
                    CustomBackgroundVideoView(
                        videoURL: testVideoURL,
                        videoId: "test_video_3",
                        isVisible: isVisible
                    )
                    .padding()
                    
                    // Custom Video Post Card Test
                    CustomVideoPostView(
                        url: URL(string: testVideoURL2)!,
                        videoId: "test_video_4"
                    )
                    .frame(height: 400)
                    .padding()
                    
                } else {
                    // Original Video Player Test
                    VideoPlayerView(
                        videoURL: URL(string: testVideoURL)!,
                        videoId: "original_test_video",
                        isVisible: isVisible
                    )
                    .frame(height: 400)
                    .cornerRadius(12)
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Video Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CustomVideoTestView()
} 