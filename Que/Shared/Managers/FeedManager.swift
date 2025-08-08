import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FeedManager: ObservableObject {
    @Published private(set) var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMorePosts = true
    @Published var currentIndex = 0
    @Published var activePostIndex = 0
    @Published var error: String?

    private let firestoreManager = FirestoreDataManager()
    private let mediaCacheManager = MediaCacheManager.shared
    private let db = Firestore.firestore()

    private let postsPerPage = 10

    // duplicate ve preload takibi
    private var idSet = Set<String>()
    private var lastPreloadedCount = 0

    // pagination spam’ini önlemek için basit debounce
    private var lastLoadMoreTime: TimeInterval = 0
    private let loadMoreCooldown: TimeInterval = 0.6

    init(startIndex: Int = 0) {
        self.currentIndex = startIndex
        loadPosts()
    }

    // MARK: - İlk yükleme
    func loadPosts() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        firestoreManager.fetchPostsForFeed { [weak self] fetched in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if !fetched.isEmpty {
                    self.applyNewSnapshotReplacing(fetched)
                    self.hasMorePosts = fetched.count >= self.postsPerPage

                    if let first = fetched.first {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SetFirstPostVisible"),
                            object: first.id
                        )
                    }
                }
                self.preloadImagesForNewPosts()
            }
        }
    }

    // MARK: - Pagination
    func loadMorePosts() {
        guard !isLoading && hasMorePosts else { return }
        isLoading = true
        error = nil

        firestoreManager.fetchMorePosts { [weak self] fetched in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if fetched.isEmpty {
                    self.hasMorePosts = false
                } else {
                    self.appendUnique(fetched)
                    self.hasMorePosts = fetched.count >= self.postsPerPage
                    self.preloadImagesForNewPosts()
                }
            }
        }
    }

    /// Görünür indeks değişiminde “end reached” kontrolü (+ küçük debounce)
    func maybeLoadMore(afterIndex index: Int) {
        let now = Date().timeIntervalSince1970
        guard now - lastLoadMoreTime > loadMoreCooldown else { return }

        if index >= posts.count - 2, hasMorePosts, !isLoading {
            lastLoadMoreTime = now
            loadMorePosts()
        }
    }

    // MARK: - Refresh
    func refreshPosts() {
        NotificationCenter.default.post(name: NSNotification.Name("CleanupAllVideoPlayers"), object: nil)

        firestoreManager.resetPagination()
        hasMorePosts = true
        posts.removeAll()
        idSet.removeAll()
        lastPreloadedCount = 0

        mediaCacheManager.clearCache()
        loadPosts()
    }

    // MARK: - Cache / Preload
    private func preloadImagesForNewPosts() {
        // Yalnızca yeni gelen aralığı preload et
        let start = lastPreloadedCount
        let end = posts.count
        guard start < end else { return }

        let slice = Array(posts[start..<end])
        lastPreloadedCount = end

        DispatchQueue.global(qos: .background).async { [slice, mediaCacheManager] in
            mediaCacheManager.preloadImages(from: slice)
        }
    }

    func updateCacheForActivePost(index: Int) {
        activePostIndex = index
        let snapshot = posts
        DispatchQueue.global(qos: .background).async {
            MediaCacheManager.shared.preloadImagesForActivePost(
                posts: snapshot,
                activePostIndex: index
            )
        }
    }

    // MARK: - Alternatif feedler
    func loadPopularPosts() {
        guard !isLoading else { return }
        isLoading = true; error = nil
        firestoreManager.fetchPopularPosts { [weak self] fetched in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if fetched.isEmpty { self.loadPosts(); return }
                self.applyNewSnapshotReplacing(fetched)
                self.hasMorePosts = fetched.count >= self.postsPerPage
                self.preloadImagesForNewPosts()
            }
        }
    }

    func loadRecentPosts() {
        guard !isLoading else { return }
        isLoading = true; error = nil
        firestoreManager.fetchRecentPosts { [weak self] fetched in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if fetched.isEmpty { self.loadPosts(); return }
                self.applyNewSnapshotReplacing(fetched)
                self.hasMorePosts = fetched.count >= self.postsPerPage
                self.preloadImagesForNewPosts()
            }
        }
    }

    func loadPostsWithCriteria(category: String? = nil, mediaType: String? = nil, userId: String? = nil) {
        guard !isLoading else { return }
        isLoading = true; error = nil

        firestoreManager.fetchPostsWithCriteria(category: category, mediaType: mediaType, userId: userId) { [weak self] fetched in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if fetched.isEmpty { self.loadPosts(); return }
                self.applyNewSnapshotReplacing(fetched)
                self.hasMorePosts = fetched.count >= self.postsPerPage
                self.preloadImagesForNewPosts()
            }
        }
    }

    // MARK: - Like (optimistic)
    func toggleLike(for postId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }

        let likeRef = db.collection("posts").document(postId)
            .collection("likes").document(currentUser.uid)

        likeRef.getDocument { [weak self] snap, _ in
            guard let self else { return }

            if let doc = snap, doc.exists {
                // optimistic UI
                self.updateLocalLikeCount(postId: postId, delta: -1)
                likeRef.delete()
                self.updatePostLikeCount(postId: postId, increment: -1)
            } else {
                self.updateLocalLikeCount(postId: postId, delta: +1)
                likeRef.setData([
                    "userId": currentUser.uid,
                    "timestamp": FieldValue.serverTimestamp()
                ])
                self.updatePostLikeCount(postId: postId, increment: +1)
            }
        }
    }

    private func updateLocalLikeCount(postId: String, delta: Int) {
        if let idx = posts.firstIndex(where: { $0.id == postId }) {
            var p = posts[idx]
            p.likesCount = max(0, (p.likesCount ?? 0) + delta)
            posts[idx] = p
        }
    }

    private func updatePostLikeCount(postId: String, increment: Int) {
        let postRef = db.collection("posts").document(postId)
        postRef.updateData(["likeCount": FieldValue.increment(Int64(increment))]) { err in
            if let err { print("Beğeni sayısı güncelleme hatası: \(err.localizedDescription)") }
        }
    }

    // MARK: - Helpers
    var postCount: Int { posts.count }
    var currentPost: Post? { (0..<posts.count).contains(currentIndex) ? posts[currentIndex] : nil }

    func nextPost() {
        if currentIndex < posts.count - 1 {
            currentIndex += 1
        } else if hasMorePosts {
            loadMorePosts()
        }
    }

    func previousPost() {
        if currentIndex > 0 { currentIndex -= 1 }
    }

    func goToPost(at index: Int) {
        guard posts.indices.contains(index) else { return }
        currentIndex = index
    }

    func clearError() { error = nil }

    // Yeni snapshot geldiğinde tüm state’i temiz tak kur
    private func applyNewSnapshotReplacing(_ newPosts: [Post]) {
        posts = []
        idSet.removeAll()
        lastPreloadedCount = 0
        appendUnique(newPosts)
    }

    private func appendUnique(_ newPosts: [Post]) {
        var appended: [Post] = []
        for p in newPosts where !idSet.contains(p.id) {
            idSet.insert(p.id)
            appended.append(p)
        }
        if !appended.isEmpty { posts.append(contentsOf: appended) }
    }
}
