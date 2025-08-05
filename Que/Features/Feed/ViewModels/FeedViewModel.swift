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
    
    // Kullanıcının beğeni durumlarını toplu olarak güncelle
    private func updateLikeStatesBatch(for posts: [Post]) async -> [Post] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return posts }
        
        let db = Firestore.firestore()
        var updatedPosts = posts
        
        // Tüm post'lar için like document ID'lerini hazırla
        let likeDocumentIds = posts.map { "\(currentUserId)_\($0.id)" }
        
        do {
            // Toplu sorgu ile beğeni durumlarını al
            let likeDocs = try await db.collection("likes")
                .whereField(FieldPath.documentID(), in: likeDocumentIds)
                .getDocuments()
            
            // Mevcut like document'larını Set'e çevir
            let existingLikeIds = Set(likeDocs.documents.map { $0.documentID })
            
            // Her post için beğeni durumunu kontrol et
            for (index, post) in updatedPosts.enumerated() {
                let likeDocId = "\(currentUserId)_\(post.id)"
                updatedPosts[index].isLiked = existingLikeIds.contains(likeDocId)
            }
            
            print("✅ Batch like states updated for \(posts.count) posts")
            
        } catch {
            print("❌ Error checking batch like states: \(error)")
            // Hata durumunda varsayılan olarak beğenmemiş kabul et
            for index in updatedPosts.indices {
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
        setupPersonalization()
        loadFeed()
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
    
    // Ana feed'i yükle (one-time)
    func loadFeed() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Mevcut listener'ı temizle
        listener?.remove()
        
        let db = Firestore.firestore()
        
        // Kişiselleştirme aktifse önerilen post'ları getir
        if isPersonalized {
            loadPersonalizedFeed()
        } else {
            // Standart feed: Kullanıcının takip ettiği kişilerin gönderilerini + kendi gönderilerini getir
            Task {
                do {
                    let query = db.collection("posts")
                        .order(by: "createdAt", descending: true)
                        .limit(to: postsPerPage)
                    
                    let snapshot = try await query.getDocuments()
                    
                    await MainActor.run {
                        let loadedPosts = snapshot.documents.compactMap { doc in
                            Post(id: doc.documentID, data: doc.data())
                        }
                        
                        // Duplicate post'ları filtrele
                        let uniquePosts = self.removeDuplicates(from: loadedPosts)
                        
                        // Beğeni durumlarını toplu olarak güncelle
                        Task {
                            let postsWithLikeStates = await self.updateLikeStatesBatch(for: uniquePosts)
                            
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.posts = postsWithLikeStates
                                    self.isLoading = false
                                    self.showSkeleton = false
                                }
                                
                                self.lastDocument = snapshot.documents.last
                                self.hasMorePosts = snapshot.documents.count == self.postsPerPage
                                
                                print("✅ Feed loaded: \(postsWithLikeStates.count) posts")
                            }
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                        print("❌ Error loading feed: \(error)")
                    }
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
    
    // Duplicate post'ları filtrele
    private func removeDuplicates(from posts: [Post]) -> [Post] {
        var uniquePosts: [Post] = []
        var seenIds = Set<String>()
        
        for post in posts {
            if !seenIds.contains(post.id) {
                uniquePosts.append(post)
                seenIds.insert(post.id)
            }
        }
        
        return uniquePosts
    }
    
    // Video prefetch - görünen post'tan sonraki video'yu önceden yükle
    func prefetchNextVideo(for currentPost: Post) {
        guard let currentIndex = posts.firstIndex(where: { $0.id == currentPost.id }),
              currentIndex + 1 < posts.count else { return }
        
        let nextPost = posts[currentIndex + 1]
        guard let videoURL = nextPost.backgroundVideoURL,
              let url = URL(string: videoURL) else { return }
        
        print("🎬 Prefetching next video: \(nextPost.id)")
        
        // URLSession ile prefetch
        let config = FeedVideoCacheManager.shared.getURLSessionConfiguration()
        let session = URLSession(configuration: config)
        
        // Video'nun ilk 10 saniyesini indir
        let prefetchRequest = URLRequest(url: url)
        
        let task = session.dataTask(with: prefetchRequest) { [weak self] data, response, error in
            if let error = error {
                print("❌ Prefetch error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("✅ Prefetch successful for video: \(nextPost.id)")
                
                // AVPlayerItem cache'ine ekle
                DispatchQueue.main.async {
                    self?.addToPlayerCache(videoURL: url, data: data)
                }
            } else {
                print("❌ Prefetch failed for video: \(nextPost.id)")
            }
        }
        
        task.resume()
    }
    
    // AVPlayerItem cache'ine video ekle
    private func addToPlayerCache(videoURL: URL, data: Data?) {
        guard let data = data else { return }
        
        // Temporary file oluştur
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("\(videoURL.lastPathComponent)_prefetch")
        
        do {
            try data.write(to: tempFile)
            print("✅ Prefetch data written to cache: \(tempFile)")
        } catch {
            print("❌ Failed to write prefetch data: \(error)")
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
        
        isLoading = true
        
        let db = Firestore.firestore()
        
        Task {
            do {
                let query = db.collection("posts")
                    .order(by: "createdAt", descending: true)
                    .start(afterDocument: lastDoc)
                    .limit(to: postsPerPage)
                
                let snapshot = try await query.getDocuments()
                
                await MainActor.run {
                    let newPosts = snapshot.documents.compactMap { doc in
                        Post(id: doc.documentID, data: doc.data())
                    }
                    
                    // Duplicate post'ları filtrele
                    let existingIds = Set(self.posts.map { $0.id })
                    let uniqueNewPosts = newPosts.filter { !existingIds.contains($0.id) }
                    
                    // Yeni post'ların beğeni durumlarını toplu olarak kontrol et
                    Task {
                        let postsWithLikeStates = await self.updateLikeStatesBatch(for: uniqueNewPosts)
                        
                        await MainActor.run {
                            // Mevcut beğeni durumlarını koruyarak yeni post'ları ekle
                            for newPost in postsWithLikeStates {
                                if !self.posts.contains(where: { $0.id == newPost.id }) {
                                    self.posts.append(newPost)
                                }
                            }
                            
                            // Bellek yönetimi
                            self.trimPosts()
                            
                            self.lastDocument = snapshot.documents.last
                            self.hasMorePosts = snapshot.documents.count == self.postsPerPage
                            self.isLoading = false
                            
                            print("✅ More posts loaded: \(postsWithLikeStates.count) new posts")
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("❌ Error loading more posts: \(error)")
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
            // 1. RecommendationEngine'den kişiselleştirilmiş post'ları al
            let personalizedPosts = await recommendationEngine.getPersonalizedPosts()
            
            await MainActor.run {
                // 2. RealTimePersonalizationEngine ile filtrele
                let realTimeFilteredPosts = realTimeEngine.applyRealTimeFilters(to: personalizedPosts)
                
                // 3. Duplicate post'ları filtrele
                let uniquePosts = self.removeDuplicates(from: realTimeFilteredPosts)
                
                // 4. Beğeni durumlarını toplu olarak güncelle
                Task {
                    let postsWithLikeStates = await self.updateLikeStatesBatch(for: uniquePosts)
                    
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.posts = postsWithLikeStates
                            self.isLoading = false
                            self.showSkeleton = false
                        }
                        
                        // 5. Performance için skorları önceden yükle
                        realTimeEngine.preloadScores(for: postsWithLikeStates)
                        
                        print("✅ Personalized feed loaded: \(postsWithLikeStates.count) posts")
                    }
                }
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