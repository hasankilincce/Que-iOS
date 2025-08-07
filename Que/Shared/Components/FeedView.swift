import SwiftUI

struct FeedView: View {
    @StateObject private var feedManager = FeedManager()
    @State private var visibleID: String?   // aktif sayfa (post.id)

    var body: some View {
        GeometryReader { _ in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(feedManager.posts) { post in
                        PostView(post: post)
                            .id(post.id)
                            // Her öğe görünür alanın tam yüksekliğini kaplasın
                            .containerRelativeFrame(.vertical)
                    }
                    
                    // Loading indicator
                    if feedManager.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Text("Daha fazla gönderi yükleniyor...")
                                .foregroundColor(.gray)
                                .padding(.bottom, 50)
                        }
                        .frame(height: 200)
                        .containerRelativeFrame(.vertical)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)   // dikey sayfalama
            .scrollIndicators(.hidden)
            .scrollPosition(id: $visibleID)  // görünen sayfayı takip et
            .scrollClipDisabled()            // içerik safe area'ya taşabilsin
            .ignoresSafeArea()
        }
        .task { 
            if feedManager.posts.isEmpty {
                feedManager.loadPosts()
            }
        }
        .onChange(of: visibleID) { _, newID in
            // Pagination kontrolü
            if let newID = newID, 
               let currentIndex = feedManager.posts.firstIndex(where: { $0.id == newID }) {
                
                // Aktif post değiştiğinde cache'i güncelle
                feedManager.updateCacheForActivePost(index: currentIndex)
                
                // Son 2 post kala yeni veri yükle
                if currentIndex >= feedManager.posts.count - 2 && 
                   feedManager.hasMorePosts && 
                   !feedManager.isLoading {
                    feedManager.loadMorePosts()
                }
            }
        }
        .refreshable {
            feedManager.refreshPosts()
        }
    }
}
