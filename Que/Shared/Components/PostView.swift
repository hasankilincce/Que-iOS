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
        ZStack {
            // Arka plan
            backgroundColor
                .ignoresSafeArea()

            // İçerik
            Group {
                if let v = post.backgroundVideoURL, let url = URL(string: v) {
                    // Video post
                    CustomVideoPlayerViewContainer(videoURL: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                } else if let i = post.backgroundImageURL, let url = URL(string: i) {
                    // Image post
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                } else {
                    // Text only post
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                }
            }

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
        .contentShape(Rectangle())
    }
}
