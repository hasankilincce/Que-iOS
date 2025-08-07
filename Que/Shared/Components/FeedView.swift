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
            // aktif sayfa değiştiğinde video play/pause gibi işlemler
            // let index = posts.firstIndex { $0.id == newID }
        }
    }
}
