import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import AVKit

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasMorePosts: Bool = true
    @Published var showSkeleton: Bool = true
    
    // Video prefetch için
    private var prefetchedVideos: Set<String> = []
    
    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private let postsPerPage = 10
    
    init() {
        loadFeed()
    }
    
    deinit {
        listener?.remove()
    }
    
    // Ana feed'i yükle (realtime)
    func loadFeed() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // Kullanıcının takip ettiği kişilerin gönderilerini + kendi gönderilerini getir
        listener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: postsPerPage)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    self.isLoading = false
                    return 
                }
                
                let loadedPosts = documents.compactMap { doc in
                    Post(id: doc.documentID, data: doc.data())
                }
                
                // Duplicate post'ları filtrele
                var uniquePosts: [Post] = []
                var seenIds = Set<String>()
                
                for post in loadedPosts {
                    if !seenIds.contains(post.id) {
                        uniquePosts.append(post)
                        seenIds.insert(post.id)
                    }
                }
                
                // Smooth transition için kısa delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.posts = uniquePosts
                        self.isLoading = false
                        self.showSkeleton = false
                    }
                }
                
                self.lastDocument = documents.last
                self.hasMorePosts = documents.count == self.postsPerPage
            }
    }
    
    // Refresh (pull to refresh)
    func refresh() async {
        isRefreshing = true
        listener?.remove()
        
        // Reset pagination
        lastDocument = nil
        hasMorePosts = true
        showSkeleton = true
        
        loadFeed()
        
        // Simulated delay for smooth animation
        try? await Task.sleep(nanoseconds: 800_000_000)
        isRefreshing = false
    }
    
    // Video prefetch - görünen post'tan sonraki video'yu önceden yükle
    func prefetchNextVideo(for currentPost: Post) {
        guard let currentIndex = posts.firstIndex(where: { $0.id == currentPost.id }) else { return }
        let nextIndex = currentIndex + 1
        
        guard nextIndex < posts.count else { return }
        let nextPost = posts[nextIndex]
        
        guard nextPost.hasBackgroundVideo,
            let signedVideoURL = nextPost.backgroundVideoURL else { return }
        
        let publicVideoURL = FeedVideoCacheManager.shared.convertSignedURLToPublic(signedVideoURL)
        guard !prefetchedVideos.contains(publicVideoURL) else { return }
        
        // Video'yu prefetch et
        prefetchedVideos.insert(publicVideoURL)
        
        // AVPlayerItem oluştur (sadece metadata yükle)
        if let url = URL(string: publicVideoURL) {
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            
            // Sadece metadata yükle, video'yu oynatma
            item.preferredForwardBufferDuration = 0
            item.preferredPeakBitRate = 0
            
            print("🎬 Prefetching video: \(publicVideoURL)")
        }
    }
    
    // Bellek yönetimi - eski post'ları temizle
    func trimPosts() {
        guard posts.count > 100 else { return }
        
        // En eski 50 post'u sil
        let postsToRemove = posts.count - 50
        posts.removeFirst(postsToRemove)
        
        // Prefetch cache'ini de temizle
        prefetchedVideos.removeAll()
        
        print("🧹 Trimmed posts: \(postsToRemove) posts removed")
    }
    
    // Load more posts (pagination)
    func loadMorePosts() {
        guard !isLoading, hasMorePosts, let lastDoc = lastDocument else { return }
        
        let db = Firestore.firestore()
        
        db.collection("posts")
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: postsPerPage)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let newPosts = documents.compactMap { doc in
                    Post(id: doc.documentID, data: doc.data())
                }
                
                // Duplicate post'ları filtrele
                let existingIds = Set(self.posts.map { $0.id })
                let uniqueNewPosts = newPosts.filter { !existingIds.contains($0.id) }
                
                self.posts.append(contentsOf: uniqueNewPosts)
                
                // Bellek yönetimi
                self.trimPosts()
                
                self.lastDocument = documents.last
                self.hasMorePosts = documents.count == self.postsPerPage
            }
    }
    
    // Post'u beğen/beğenme
    func toggleLike(for post: Post) {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        
        // Optimistic update
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked.toggle()
            posts[index].likesCount += posts[index].isLiked ? 1 : -1
        }
        
        let functions = Functions.functions(region: "us-east1")
        functions.httpsCallable("toggleLike").call(["postId": post.id]) { [weak self] result, error in
            if let error = error {
                // Revert optimistic update
                if let index = self?.posts.firstIndex(where: { $0.id == post.id }) {
                    self?.posts[index].isLiked.toggle()
                    self?.posts[index].likesCount += self?.posts[index].isLiked == true ? 1 : -1
                }
                print("Like error: \(error)")
            }
        }
    }
} 