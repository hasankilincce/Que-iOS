import SwiftUI

struct FeedView: View {
    @ObservedObject var feedManager: FeedManager
    @Binding var visibleID: String?
    
    var body: some View {
        GeometryReader { _ in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(feedManager.posts) { post in
                        PostView(post: post)
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
        }
        .task {
            if feedManager.posts.isEmpty {
                feedManager.loadPosts()
            }
        }
        .onChange(of: visibleID) { _, newID in
            if let newID = newID,
               let currentIndex = feedManager.posts.firstIndex(where: { $0.id == newID }) {
                feedManager.updateCacheForActivePost(index: currentIndex)
                // feedStartIndex HomeViewModel'da tutuluyor, oradan güncelleniyor
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
