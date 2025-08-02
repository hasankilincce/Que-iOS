import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import AVKit
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    // Post array'ini mutable yapmak için helper fonksiyon
    private func updatePost(at index: Int, with updatedPost: Post) {
        guard index < posts.count else { return }
        posts[index] = updatedPost
    }
    
    // Kullanıcının beğeni durumlarını güncelle
    private func updateLikeStates(for posts: [Post]) async -> [Post] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return posts }
        
        // Firestore'dan kullanıcının beğeni durumlarını al
        let db = Firestore.firestore()
        var updatedPosts = posts
        
        for (index, post) in updatedPosts.enumerated() {
            do {
                let likeDoc = try await db.collection("likes")
                    .document("\(currentUserId)_\(post.id)")
                    .getDocument()
                
                if likeDoc.exists {
                    // Kullanıcı bu post'u beğenmiş
                    updatedPosts[index].isLiked = true
                } else {
                    // Kullanıcı bu post'u beğenmemiş
                    updatedPosts[index].isLiked = false
                }
            } catch {
                print("❌ Error checking like state for post \(post.id): \(error)")
                // Hata durumunda varsayılan olarak beğenmemiş kabul et
                updatedPosts[index].isLiked = false
            }
        }
        
        return updatedPosts
    }
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasMorePosts: Bool = true
    @Published var showSkeleton: Bool = true
    @Published var isPersonalized: Bool = false
    @Published var currentAlgorithm: RecommendationAlgorithm = .hybrid
    
    // Video prefetch için
    private var prefetchedVideos: Set<String> = []
    
    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private let postsPerPage = 10
    
    // Kişiselleştirme için
    private let recommendationEngine = RecommendationEngine.shared
    private let analyticsService = AnalyticsService.shared
    private let realTimeEngine = RealTimePersonalizationEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Firebase Functions
    let mlFunctions = FirebaseMLFunctions.shared
    
    init() {
        loadFeed()
        setupPersonalization()
    }
    
    private func setupPersonalization() {
        // Recommendation engine'i dinle
        recommendationEngine.$isPersonalized
            .assign(to: &$isPersonalized)
        
        recommendationEngine.$userProfile
            .sink { [weak self] profile in
                if let profile = profile {
                    self?.isPersonalized = profile.hasInterests
                }
            }
            .store(in: &cancellables)
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
        
        // Kişiselleştirme aktifse önerilen post'ları getir
        if isPersonalized {
            loadPersonalizedFeed()
        } else {
            // Standart feed: Kullanıcının takip ettiği kişilerin gönderilerini + kendi gönderilerini getir
            listener = db.collection("posts")
                .order(by: "createdAt", descending: true)
                .limit(to: postsPerPage)
                .addSnapshotListener { [weak self] snapshot, error in
                    Task { @MainActor in
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
                    
                    // Sadece ilk yüklemede beğeni durumlarını kontrol et
                    if self.posts.isEmpty {
                        Task {
                            let postsWithLikeStates = await self.updateLikeStates(for: uniquePosts)
                            
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.posts = postsWithLikeStates
                                    self.isLoading = false
                                    self.showSkeleton = false
                                }
                            }
                        }
                    } else {
                        // Mevcut beğeni durumlarını koru
                        await MainActor.run {
                            self.isLoading = false
                            self.showSkeleton = false
                        }
                    }
                    
                    self.lastDocument = documents.last
                    self.hasMorePosts = documents.count == self.postsPerPage
                    }
                }
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
                
                // Yeni post'ların beğeni durumlarını kontrol et
                Task {
                    let postsWithLikeStates = await self.updateLikeStates(for: uniqueNewPosts)
                    
                    await MainActor.run {
                        // Mevcut beğeni durumlarını koruyarak yeni post'ları ekle
                        for newPost in postsWithLikeStates {
                            if !self.posts.contains(where: { $0.id == newPost.id }) {
                                self.posts.append(newPost)
                            }
                        }
                        
                        // Bellek yönetimi
                        self.trimPosts()
                        
                        self.lastDocument = documents.last
                        self.hasMorePosts = documents.count == self.postsPerPage
                    }
                }
            }
    }
    
    // Post'u beğen/beğenme
    func toggleLike(for post: Post) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Mevcut durumu kaydet
        let currentIndex = posts.firstIndex(where: { $0.id == post.id })
        guard let index = currentIndex else { return }
        
        let wasLiked = posts[index].isLiked
        let oldLikesCount = posts[index].likesCount
        
        // Optimistic update - UI'ı hemen güncelle
        await MainActor.run {
            var updatedPost = self.posts[index]
            updatedPost.toggleLike()
            self.posts[index] = updatedPost
            
            print("🔄 Optimistic update: \(post.id) - Liked: \(updatedPost.isLiked), Count: \(updatedPost.likesCount)")
        }
        
        // Analytics tracking
        analyticsService.trackPostLike(postId: post.id, isLiked: !wasLiked)
        
        // User interaction tracking
        analyticsService.trackUserInteraction(
            interactionType: !wasLiked ? "like" : "unlike",
            targetId: post.id,
            metadata: [
                "post_type": post.mediaType ?? "unknown",
                "author_id": post.userId
            ]
        )
        
        // Etkileşimi kaydet
        let interactionType: UserInteraction.InteractionType = !wasLiked ? .like : .unlike
        recommendationEngine.recordInteraction(postId: post.id, type: interactionType)
        
        // Firebase Functions ile like toggle
        Task {
            do {
                let functions = Functions.functions(region: "us-east1")
                let data: [String: Any] = [
                    "postId": post.id,
                    "userId": currentUserId,
                    "action": !wasLiked ? "like" : "unlike"
                ]
                
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HTTPSCallableResult, Error>) in
                    functions.httpsCallable("toggleLike").call(data) { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let result = result {
                            continuation.resume(returning: result)
                        } else {
                            continuation.resume(throwing: NSError(domain: "ToggleLike", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                        }
                    }
                }
                
                if let response = result.data as? [String: Any] {
                    await MainActor.run {
                        // Backend'den gelen gerçek değerleri kullan
                        var updatedPost = self.posts[index]
                        
                        // Backend'den gelen liked durumunu kontrol et
                        if let liked = response["liked"] as? Bool {
                            updatedPost.isLiked = liked
                        } else {
                            // Backend'den liked durumu gelmezse, action'a göre belirle
                            updatedPost.isLiked = !wasLiked
                        }
                        
                        // Backend'den gelen likes count'u kontrol et
                        if let likesCount = response["likesCount"] as? Int {
                            updatedPost.likesCount = likesCount
                        } else {
                            // Backend'den count gelmezse, optimistic update'i koru
                            // Ama sayıyı doğru hesapla
                            if updatedPost.isLiked != wasLiked {
                                updatedPost.likesCount = wasLiked ? oldLikesCount - 1 : oldLikesCount + 1
                            }
                        }
                        
                        self.posts[index] = updatedPost
                        
                        print("✅ Like toggle successful: \(post.id) - Liked: \(updatedPost.isLiked), Count: \(updatedPost.likesCount)")
                    }
                } else {
                    print("⚠️ Invalid response format from Firebase Functions")
                    // Response formatı geçersizse optimistic update'i geri al
                    await MainActor.run {
                        var updatedPost = self.posts[index]
                        updatedPost.setLikeState(liked: wasLiked, count: oldLikesCount)
                        self.posts[index] = updatedPost
                    }
                }
            } catch {
                print("❌ Like error: \(error)")
                
                // Hata durumunda optimistic update'i geri al
                await MainActor.run {
                    var updatedPost = self.posts[index]
                    updatedPost.setLikeState(liked: wasLiked, count: oldLikesCount)
                    self.posts[index] = updatedPost
                }
                
                // Error tracking
                analyticsService.trackError(error: error, context: "toggle_like")
            }
        }
    }
    
    // MARK: - Personalization Methods
    
    private func loadPersonalizedFeed() {
        Task {
            let personalizedPosts = await recommendationEngine.getPersonalizedPosts()
            
            await MainActor.run {
                // Real-time filtering uygula
                let realTimeFilteredPosts = realTimeEngine.applyRealTimeFilters(to: personalizedPosts)
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.posts = realTimeFilteredPosts
                    self.isLoading = false
                    self.showSkeleton = false
                }
                
                // Preload scores for better performance
                realTimeEngine.preloadScores(for: realTimeFilteredPosts)
            }
        }
    }
    
    func togglePersonalization() {
        isPersonalized.toggle()
        
        if isPersonalized {
            loadPersonalizedFeed()
        } else {
            loadFeed()
        }
    }
    
    func updateUserInterests(_ interests: [String]) {
        recommendationEngine.updateUserInterests(interests)
    }
    
    func recordPostView(postId: String, duration: TimeInterval? = nil) {
        recommendationEngine.recordInteraction(postId: postId, type: .view, duration: duration)
    }
    
    func recordPostSkip(postId: String) {
        recommendationEngine.recordInteraction(postId: postId, type: .skip)
    }
    
    // MARK: - Public Access Methods
    
    func getUserProfile() -> UserProfile? {
        return recommendationEngine.userProfile
    }
    
    func getUserInteractionHistory() -> [UserInteraction] {
        return recommendationEngine.userProfile?.interactionHistory ?? []
    }
} 