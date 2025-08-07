import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FeedManager: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMorePosts = true
    @Published var currentIndex = 0
    @Published var activePostIndex = 0 // Aktif post index'ini takip et
    @Published var error: String?
    
    private let firestoreManager = FirestoreDataManager()
    private let mediaCacheManager = MediaCacheManager.shared
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let postsPerPage = 10
    private var startIndex: Int = 0
    
    init(startIndex: Int = 0) {
        self.startIndex = startIndex
        loadPosts()
    }
    
    // MARK: - Public Methods
    
    /// İlk gönderileri yükle
    func loadPosts() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // Firestore'dan veri çek
        firestoreManager.fetchPostsForFeed { [weak self] fetchedPosts in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if !fetchedPosts.isEmpty {
                    // Firestore'dan gelen verileri kullan
                    self?.posts = fetchedPosts
                    self?.hasMorePosts = fetchedPosts.count >= self?.postsPerPage ?? 10
                }
                
                // Yeni postlar için image'ları preload et
                self?.preloadImagesForNewPosts()
            }
        }
    }
    
    /// Daha fazla gönderi yükle (pagination)
    func loadMorePosts() {
        guard !isLoading && hasMorePosts else { return }
        
        isLoading = true
        error = nil
        
        firestoreManager.fetchMorePosts { [weak self] fetchedPosts in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if fetchedPosts.isEmpty {
                    self?.hasMorePosts = false
                } else {
                    self?.posts.append(contentsOf: fetchedPosts)
                    self?.hasMorePosts = fetchedPosts.count >= self?.postsPerPage ?? 10
                    
                    // Yeni postlar için image'ları preload et
                    self?.preloadImagesForNewPosts()
                }
            }
        }
    }
    
    /// Gönderileri yenile
    func refreshPosts() {
        firestoreManager.resetPagination()
        lastDocument = nil
        hasMorePosts = true
        posts = []
        
        // Cache'i temizle
        mediaCacheManager.clearCache()
        
        loadPosts()
    }
    
    /// Yeni postlar için image'ları preload et
    private func preloadImagesForNewPosts() {
        // Background thread'de preload et
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.mediaCacheManager.preloadImages(from: self?.posts ?? [])
        }
    }
    
    /// Aktif post değiştiğinde cache'i güncelle
    func updateCacheForActivePost(index: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.activePostIndex = index
        }
        
        // Background thread'de cache güncelle
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.mediaCacheManager.preloadImagesForActivePost(
                posts: self.posts,
                activePostIndex: index
            )
        }
    }
    
    /// Popüler gönderileri yükle
    func loadPopularPosts() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        firestoreManager.fetchPopularPosts { [weak self] fetchedPosts in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if fetchedPosts.isEmpty {
                    // Popüler gönderiler yoksa normal gönderileri kullan
                    self?.loadPosts()
                } else {
                    self?.posts = fetchedPosts
                    self?.hasMorePosts = fetchedPosts.count >= self?.postsPerPage ?? 10
                    
                    // Yeni postlar için image'ları preload et
                    self?.preloadImagesForNewPosts()
                }
            }
        }
    }
    
    /// Yeni gönderileri yükle (son 24 saat)
    func loadRecentPosts() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        firestoreManager.fetchRecentPosts { [weak self] fetchedPosts in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if fetchedPosts.isEmpty {
                    // Yeni gönderiler yoksa normal gönderileri kullan
                    self?.loadPosts()
                } else {
                    self?.posts = fetchedPosts
                    self?.hasMorePosts = fetchedPosts.count >= self?.postsPerPage ?? 10
                    
                    // Yeni postlar için image'ları preload et
                    self?.preloadImagesForNewPosts()
                }
            }
        }
    }
    
    /// Belirli kriterlere göre gönderileri yükle
    func loadPostsWithCriteria(
        category: String? = nil,
        mediaType: String? = nil,
        userId: String? = nil
    ) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        firestoreManager.fetchPostsWithCriteria(
            category: category,
            mediaType: mediaType,
            userId: userId
        ) { [weak self] fetchedPosts in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if fetchedPosts.isEmpty {
                    // Filtrelenmiş gönderiler yoksa normal gönderileri kullan
                    self?.loadPosts()
                } else {
                    self?.posts = fetchedPosts
                    self?.hasMorePosts = fetchedPosts.count >= self?.postsPerPage ?? 10
                    
                    // Yeni postlar için image'ları preload et
                    self?.preloadImagesForNewPosts()
                }
            }
        }
    }
    
    /// Belirli bir gönderiyi beğen/beğenme
    func toggleLike(for postId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let likeRef = db.collection("posts").document(postId)
            .collection("likes").document(currentUser.uid)
        
        likeRef.getDocument { [weak self] snapshot, error in
            if let document = snapshot, document.exists {
                // Beğeniyi kaldır
                likeRef.delete()
                self?.updatePostLikeCount(postId: postId, increment: -1)
            } else {
                // Beğeniyi ekle
                likeRef.setData([
                    "userId": currentUser.uid,
                    "timestamp": FieldValue.serverTimestamp()
                ])
                self?.updatePostLikeCount(postId: postId, increment: 1)
            }
        }
    }
    
    /// Gönderi beğeni sayısını güncelle
    private func updatePostLikeCount(postId: String, increment: Int) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData([
            "likeCount": FieldValue.increment(Int64(increment))
        ]) { error in
            if let error = error {
                print("Beğeni sayısı güncelleme hatası: \(error.localizedDescription)")
            }
        }
    }
    
    /// Gönderi paylaş
    func sharePost(_ post: Post) {
        // Paylaşım işlemi (gelecekte implement edilecek)
        print("Gönderi paylaşılıyor: \(post.id)")
    }
    
    /// Gönderi raporla
    func reportPost(_ post: Post, reason: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let reportData: [String: Any] = [
            "postId": post.id,
            "reporterId": currentUser.uid,
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Gönderi raporlama hatası: \(error.localizedDescription)")
            } else {
                print("Gönderi başarıyla raporlandı")
            }
        }
    }
    
    /// Kullanıcının gönderiyi beğenip beğenmediğini kontrol et
    func isPostLiked(_ postId: String) -> Bool {
        // Bu özellik gelecekte implement edilecek
        // Şimdilik false döndürüyor
        return false
    }
    
    // MARK: - Helper Methods
    
    /// Gönderi sayısını döndür
    var postCount: Int {
        return posts.count
    }
    
    /// Mevcut gönderiyi döndür
    var currentPost: Post? {
        guard currentIndex < posts.count else { return nil }
        return posts[currentIndex]
    }
    
    /// Bir sonraki gönderiye geç
    func nextPost() {
        if currentIndex < posts.count - 1 {
            currentIndex += 1
        } else if hasMorePosts {
            loadMorePosts()
        }
    }
    
    /// Bir önceki gönderiye geç
    func previousPost() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    /// Belirli bir indekse git
    func goToPost(at index: Int) {
        guard index >= 0 && index < posts.count else { return }
        currentIndex = index
    }
    
    /// Hata mesajını temizle
    func clearError() {
        error = nil
    }
}
