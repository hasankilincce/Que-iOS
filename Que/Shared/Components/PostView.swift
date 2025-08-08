import SwiftUI

struct PostView: View {
    let post: Post
    let isVisible: Bool
    
    // Post süre takibi için değişkenler
    @State private var viewStartTime: Date?
    @State private var totalViewDuration: TimeInterval = 0
    
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
                            // Video post - FeedVideoPlayerViewContainer kullan
                            FeedVideoPlayerViewContainer(
                                videoURL: url,
                                postID: post.id,
                                isVisible: isVisible
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        } else if post.mediaType == "image" {
                            // Image post - CachedAsyncImage kullan
                            CachedAsyncImage(url: url) { image in
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
            .onTapGesture(count: 2) {
                print("PostView çift tıklandı - Post ID: \(post.id)")
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                // Post görünür hale geldi - süre takibini başlat
                startViewTracking()
            } else {
                // Post görünmez hale geldi - süre takibini bitir
                endViewTracking()
            }
        }
        .onAppear {
            // İlk açılışta post görünürse süre takibini başlat
            if isVisible {
                startViewTracking()
            }
        }
        .onDisappear {
            // PostView tamamen ekrandan çıktığında süre takibini bitir
            endViewTracking()
        }
    }
    
    // MARK: - View Tracking Methods
    
    private func startViewTracking() {
        guard viewStartTime == nil else { return } // Zaten başlatılmışsa tekrar başlatma
        
        viewStartTime = Date()
        print("📊 Post görüntüleme başladı - Post ID: \(post.id) - Başlangıç: \(Date())")
    }
    
    private func endViewTracking() {
        guard let startTime = viewStartTime else { return } // Başlangıç zamanı yoksa işlem yapma
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        totalViewDuration += duration
        
        print("📊 Post görüntüleme bitti - Post ID: \(post.id)")
        print("📊 Bu oturum süresi: \(String(format: "%.2f", duration)) saniye")
        print("📊 Toplam görüntüleme süresi: \(String(format: "%.2f", totalViewDuration)) saniye")
        print("📊 Post Tipi: \(post.mediaType ?? "metin")")
        print("📊 ---")
        
        // Başlangıç zamanını sıfırla
        viewStartTime = nil
    }
}
