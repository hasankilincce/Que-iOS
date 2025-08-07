import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirestoreDataManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let postsPerPage = 10 // Firestore'dan daha fazla veri çek
    
    // MARK: - Public Methods
    
    /// Firestore'dan gönderileri çek ve FeedManager'a ilet
    func fetchPostsForFeed(completion: @escaping ([Post]) -> Void) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        var query: Query = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: postsPerPage)
        
        // Eğer pagination varsa
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { [weak self] (snapshot, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = "Veri çekme hatası: \(error.localizedDescription)"
                    completion([])
                    return
                }
                
                guard let snapshot = snapshot else {
                    self?.error = "Veri bulunamadı"
                    completion([])
                    return
                }
                
                let posts = snapshot.documents.compactMap { document -> Post? in
                    // Manuel parsing kullan
                    let data = document.data()
                    return Post(id: document.documentID, data: data)
                }
                
                // lastDocument'ı güncelle (pagination için)
                self?.lastDocument = snapshot.documents.last
                completion(posts)
            }
        }
    }
    
    /// Belirli kriterlere göre gönderileri çek
    func fetchPostsWithCriteria(
        category: String? = nil,
        mediaType: String? = nil,
        userId: String? = nil,
        completion: @escaping ([Post]) -> Void
    ) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        var query: Query = db.collection("posts")
        
        // Kategori filtresi (eğer category alanı varsa)
        if let category = category {
            query = query.whereField("category", isEqualTo: category)
        }
        
        // Medya türü filtresi
        if let mediaType = mediaType {
            query = query.whereField("mediaType", isEqualTo: mediaType)
        }
        
        // Kullanıcı filtresi
        if let userId = userId {
            query = query.whereField("userId", isEqualTo: userId)
        }
        
        query = query.order(by: "createdAt", descending: true)
            .limit(to: postsPerPage)
        
        query.getDocuments { [weak self] (snapshot, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = "Filtreleme hatası: \(error.localizedDescription)"
                    completion([])
                    return
                }
                
                guard let snapshot = snapshot else {
                    self?.error = "Filtrelenmiş veri bulunamadı"
                    completion([])
                    return
                }
                
                let posts = snapshot.documents.compactMap { document -> Post? in
                    // Manuel parsing kullan
                    let data = document.data()
                    return Post(id: document.documentID, data: data)
                }
                
                completion(posts)
            }
        }
    }
    
    /// Popüler gönderileri çek (beğeni sayısına göre)
    func fetchPopularPosts(completion: @escaping ([Post]) -> Void) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        let query: Query = db.collection("posts")
            .order(by: "likesCount", descending: true)
            .order(by: "createdAt", descending: true)
            .limit(to: postsPerPage)
        
        query.getDocuments { [weak self] (snapshot, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = "Popüler gönderiler çekme hatası: \(error.localizedDescription)"
                    completion([])
                    return
                }
                
                guard let snapshot = snapshot else {
                    self?.error = "Popüler gönderiler bulunamadı"
                    completion([])
                    return
                }
                
                let posts = snapshot.documents.compactMap { document -> Post? in
                    // Manuel parsing kullan
                    let data = document.data()
                    return Post(id: document.documentID, data: data)
                }
                
                completion(posts)
            }
        }
    }
    
    /// Yeni gönderileri çek (son 24 saat)
    func fetchRecentPosts(completion: @escaping ([Post]) -> Void) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        let oneDayAgo = Date().addingTimeInterval(-86400) // 24 saat önce
        
        let query: Query = db.collection("posts")
            .whereField("createdAt", isGreaterThan: oneDayAgo)
            .order(by: "createdAt", descending: true)
            .limit(to: postsPerPage)
        
        query.getDocuments { [weak self] (snapshot, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = "Yeni gönderiler çekme hatası: \(error.localizedDescription)"
                    completion([])
                    return
                }
                
                guard let snapshot = snapshot else {
                    self?.error = "Yeni gönderiler bulunamadı"
                    completion([])
                    return
                }
                
                let posts = snapshot.documents.compactMap { document -> Post? in
                    // Manuel parsing kullan
                    let data = document.data()
                    return Post(id: document.documentID, data: data)
                }
                
                completion(posts)
            }
        }
    }
    
    /// Daha fazla gönderi çek (pagination)
    func fetchMorePosts(completion: @escaping ([Post]) -> Void) {
        guard !isLoading, let lastDoc = lastDocument else {
            completion([])
            return
        }
        
        isLoading = true
        error = nil
        
        let query: Query = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: postsPerPage)
        
        query.getDocuments { [weak self] (snapshot, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = "Daha fazla gönderi çekme hatası: \(error.localizedDescription)"
                    completion([])
                    return
                }
                
                guard let snapshot = snapshot else {
                    self?.error = "Daha fazla gönderi bulunamadı"
                    completion([])
                    return
                }
                
                let posts = snapshot.documents.compactMap { document -> Post? in
                    // Manuel parsing kullan
                    let data = document.data()
                    return Post(id: document.documentID, data: data)
                }
                
                self?.lastDocument = snapshot.documents.last
                completion(posts)
            }
        }
    }
    
    /// Pagination'ı sıfırla
    func resetPagination() {
        lastDocument = nil
    }
    
    /// Hata mesajını temizle
    func clearError() {
        error = nil
    }
    
    // MARK: - Helper Methods
    
    /// Firestore'da gönderi var mı kontrol et
    func checkIfPostsExist(completion: @escaping (Bool) -> Void) {
        let query: Query = db.collection("posts")
            .limit(to: 1)
        
        query.getDocuments { (snapshot, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Gönderi kontrol hatası: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let exists = snapshot?.documents.isEmpty == false
                completion(exists)
            }
        }
    }
    
    /// Gönderi sayısını al
    func getPostCount(completion: @escaping (Int) -> Void) {
        let query: Query = db.collection("posts")
        
        query.getDocuments { (snapshot, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Gönderi sayısı alma hatası: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
        }
    }
} 
