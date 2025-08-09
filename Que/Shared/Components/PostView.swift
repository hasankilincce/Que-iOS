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
    
    // PostCreationView'deki rozetin feed'e uyarlanmış hali
    private var postTypeBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: post.postType.icon)
                .font(.caption.weight(.semibold))
            Text(post.postType.displayName)
                .font(.caption.weight(.bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
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
                                isVisible: isVisible,
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
                
                // Üst-sol: Post türü rozeti + metin (PostCreationView stilinde)
                VStack(alignment: .leading, spacing: 12) {
                    // Güvenli alan + ekstra boşluk (biraz daha aşağıda başlasın)
                    Spacer().frame(height: max(geometry.safeAreaInsets.top + 40, 60))
                    
                    postTypeBadge
                    
                    Text(post.content)
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1...6)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.trailing, 40)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)

                // Overlay (like/comment/share vs.)
                VStack {
                    HStack {
                        Spacer()
                        // butonlar burada
                    }
                    .padding()
                    Spacer()
                }

                // Alt bilgi çubuğu: kullanıcı fotoğrafı, görünen ad, kullanıcı adı ve paylaşılma zamanı
                VStack {
                    Spacer()
                    HStack(alignment: .center, spacing: 12) {
                        if let photo = post.userPhotoURL, let url = URL(string: photo) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 40, height: 40)
                            }
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 40, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text("@\(post.username)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Text("·")
                                    .foregroundColor(.white.opacity(0.6))
                                Text(post.timeAgo)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 120) // CustomTabBar üstünde konumla
                    .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 2)
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
