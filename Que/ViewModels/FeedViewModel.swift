import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasMorePosts: Bool = true
    
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // Kullanıcının takip ettiği kişilerin gönderilerini + kendi gönderilerini getir
        listener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: postsPerPage)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.posts = documents.compactMap { doc in
                    Post(id: doc.documentID, data: doc.data())
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
        
        loadFeed()
        
        // Simulated delay for smooth animation
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
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
                
                self.posts.append(contentsOf: newPosts)
                self.lastDocument = documents.last
                self.hasMorePosts = documents.count == self.postsPerPage
            }
    }
    
    // Post'u beğen/beğenme
    func toggleLike(for post: Post) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
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

 