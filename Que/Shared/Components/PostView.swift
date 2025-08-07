import SwiftUI

struct PostView: View {
    let post: Post
    
    // Post ID'sine göre rastgele renk seçimi
    private var backgroundColor: Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .orange, .red, .green,
            .indigo, .teal, .cyan, .mint, .brown, .yellow
        ]
        let hash = abs(post.id.hashValue)
        let colorIndex = hash % colors.count
        return colors[colorIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arka plan
                backgroundColor
                    .ignoresSafeArea()

                // İçerik
                Group {
                    if let mediaURL = post.mediaURL, let url = URL(string: mediaURL) {
                        if post.mediaType == "video" {
                            // Video post
                            CustomVideoPlayerViewContainer(videoURL: url)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        } else if post.mediaType == "image" {
                            // Image post
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.3))
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                    }
                }

                // Text content overlay
                VStack(spacing: 20) {
                    Spacer()
                    Text(post.content)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Text(post.displayName)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Overlay (like/comment/share vs.)
                VStack {
                    HStack {
                        Spacer()
                        // butonlar burada
                    }
                    .padding()
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.all, edges: .all)
    }
}
