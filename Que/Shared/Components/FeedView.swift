import SwiftUI

struct FeedView: View {
    @ObservedObject var feedManager: FeedManager
    @Binding var visibleID: String?
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(feedManager.posts) { post in
                    PostView(
                        post: post,
                        isVisible: visibleID == post.id
                    )
                    .id(post.id)
                    .containerRelativeFrame(.vertical)
                }

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
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $visibleID)
        .scrollClipDisabled()
        .ignoresSafeArea()
        .task {
            if feedManager.posts.isEmpty {
                feedManager.loadPosts()
            }
        }
        .onChange(of: visibleID) { _, newID in
            guard
                let newID,
                let currentIndex = feedManager.posts.firstIndex(where: { $0.id == newID })
            else { return }

            feedManager.updateCacheForActivePost(index: currentIndex)

            // Daha güvenli pagination tetiklemesi (debounce içeride)
            feedManager.maybeLoadMore(afterIndex: currentIndex)

            // Görsel post görünürse tüm videoları durdur
            let currentPost = feedManager.posts[currentIndex]
            if (currentPost.mediaType ?? "").lowercased() != "video" {
                NotificationCenter.default.post(name: NSNotification.Name("PauseAllVideoPlayers"), object: nil)
            }
        }
        .refreshable {
            feedManager.refreshPosts()
        }
    }
}
