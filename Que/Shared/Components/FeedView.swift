import SwiftUI

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var visibleID: String?   // aktif sayfa (post.id)

    var body: some View {
        GeometryReader { _ in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
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
        .task { loadPosts() }
        .onChange(of: visibleID) { _, newID in
            // aktif sayfa değiştiğinde video play/pause gibi işlemler
            // let index = posts.firstIndex { $0.id == newID }
        }
    }

    private func loadPosts() {
        // TODO: Gerçek post verilerini yükle
        // Şimdilik örnek veriler (sende zaten var olan Post init’iyle aynı)
        posts = [
            Post(
                id: "1",
                userId: "user1",
                username: "user1",
                displayName: "Kullanıcı 1",
                userPhotoURL: nil,
                content: "İlk post içeriği",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date()
            ),
            Post(
                id: "2",
                userId: "user2",
                username: "user2",
                displayName: "Kullanıcı 2",
                userPhotoURL: nil,
                content: "İkinci post içeriği",
                postType: .answer,
                backgroundImageURL: nil,
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date()
            ),
            Post(
                id: "3",
                userId: "user3",
                username: "user3",
                displayName: "Kullanıcı 3",
                userPhotoURL: nil,
                content: "Üçüncü post içeriği",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date()
            ),
            Post(
                id: "4",
                userId: "user4",
                username: "user4",
                displayName: "Kullanıcı 4",
                userPhotoURL: nil,
                content: "Dört post içeriği",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date()
            )
        ]
    }
}
