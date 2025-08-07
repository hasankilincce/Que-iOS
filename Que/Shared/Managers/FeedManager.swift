import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FeedManager: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMorePosts = true
    @Published var currentIndex = 0
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let postsPerPage = 10
    
    init() {
        loadPosts()
    }
    
    // MARK: - Public Methods
    
    /// İlk gönderileri yükle
    func loadPosts() {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Gerçek Firebase sorgusu yerine örnek veriler yükle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.posts = self.createSamplePosts()
            self.hasMorePosts = false // Örnek veriler için false
        }
    }
    
    /// Daha fazla gönderi yükle (pagination)
    func loadMorePosts() {
        guard !isLoading && hasMorePosts else { return }
        
        isLoading = true
        
        // Örnek veriler için pagination yok
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    /// Gönderileri yenile
    func refreshPosts() {
        lastDocument = nil
        hasMorePosts = true
        posts = []
        loadPosts()
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
    
    // MARK: - Sample Data
    
    /// Örnek gönderiler oluştur
    private func createSamplePosts() -> [Post] {
        return [
            Post(
                id: "1",
                userId: "user1",
                username: "alice_smith",
                displayName: "Alice Smith",
                userPhotoURL: "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
                content: "Bugün harika bir gün! 🌞 Yeni projeler üzerinde çalışıyorum ve çok heyecanlıyım. #motivation #coding #swift",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Post(
                id: "2",
                userId: "user2",
                username: "john_doe",
                displayName: "John Doe",
                userPhotoURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
                content: "Yeni bir video çektim! 🎬 Bu sefer farklı bir açıdan bakmaya çalıştım. Nasıl olmuş?",
                postType: .answer,
                backgroundImageURL: nil,
                backgroundVideoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                mediaType: "video",
                mediaURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                parentQuestionId: "1",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            Post(
                id: "3",
                userId: "user3",
                username: "sarah_wilson",
                displayName: "Sarah Wilson",
                userPhotoURL: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
                content: "Doğanın güzelliği karşısında nefesim kesildi! 🌿 Bu anı sizlerle paylaşmak istedim.",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-10800)
            ),
            Post(
                id: "4",
                userId: "user4",
                username: "mike_johnson",
                displayName: "Mike Johnson",
                userPhotoURL: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
                content: "Müzik ruhun gıdasıdır! 🎵 Bugün yeni bir şarkı yazdım. Dinlemek ister misiniz?",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                mediaType: "video",
                mediaURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-14400)
            ),
            Post(
                id: "5",
                userId: "user5",
                username: "emma_davis",
                displayName: "Emma Davis",
                userPhotoURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
                content: "Kahve ve kitap - mükemmel bir kombinasyon! ☕📚 Bugün hangi kitabı okuyorsunuz?",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-18000)
            ),
            Post(
                id: "6",
                userId: "user6",
                username: "david_brown",
                displayName: "David Brown",
                userPhotoURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face",
                content: "Teknoloji dünyasındaki son gelişmeler hakkında ne düşünüyorsunuz? 🤖 #tech #innovation",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-21600)
            ),
            Post(
                id: "7",
                userId: "user7",
                username: "lisa_garcia",
                displayName: "Lisa Garcia",
                userPhotoURL: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face",
                content: "Yemek yapmak benim için bir terapi! 🍳 Bugün özel bir tarif denedim.",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-25200)
            ),
            Post(
                id: "8",
                userId: "user8",
                username: "alex_wilson",
                displayName: "Alex Wilson",
                userPhotoURL: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face",
                content: "Spor yapmak hayatımın vazgeçilmez bir parçası! 💪 Bugünkü antrenmanım harikaydı.",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                mediaType: "video",
                mediaURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-28800)
            ),
            Post(
                id: "9",
                userId: "user9",
                username: "sophia_martinez",
                displayName: "Sophia Martinez",
                userPhotoURL: "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150&h=150&fit=crop&crop=face",
                content: "Sanat ruhu besler! 🎨 Bugün yeni bir resim yaptım. Nasıl olmuş?",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-32400)
            ),
            Post(
                id: "10",
                userId: "user10",
                username: "james_lee",
                displayName: "James Lee",
                userPhotoURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
                content: "Seyahat etmek dünyayı anlamanın en iyi yolu! ✈️ Bugün nereye gitmek istersiniz?",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-36000)
            ),
            Post(
                id: "11",
                userId: "user11",
                username: "olivia_taylor",
                displayName: "Olivia Taylor",
                userPhotoURL: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
                content: "Müzik benim için her şey! 🎼 Bugün yeni bir şarkı öğrendim.",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
                mediaType: "video",
                mediaURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-39600)
            ),
            Post(
                id: "12",
                userId: "user12",
                username: "daniel_clark",
                displayName: "Daniel Clark",
                userPhotoURL: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
                content: "Fotoğraf çekmek anı ölümsüzleştirir! 📸 Bugün harika bir kare yakaladım.",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-43200)
            ),
            Post(
                id: "13",
                userId: "user13",
                username: "ava_rodriguez",
                displayName: "Ava Rodriguez",
                userPhotoURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
                content: "Yoga ruhu ve bedeni birleştirir! 🧘‍♀️ Bugünkü pratiğim çok huzur vericiydi.",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: "image",
                mediaURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=1080&h=1920&fit=crop",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-46800)
            ),
            Post(
                id: "14",
                userId: "user14",
                username: "william_white",
                displayName: "William White",
                userPhotoURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face",
                content: "Kod yazmak benim için bir tutku! 💻 Bugün yeni bir proje başlattım.",
                postType: .question,
                backgroundImageURL: "https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=1080&h=1920&fit=crop",
                backgroundVideoURL: nil,
                mediaType: nil,
                mediaURL: nil,
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-50400)
            ),
            Post(
                id: "15",
                userId: "user15",
                username: "mia_anderson",
                displayName: "Mia Anderson",
                userPhotoURL: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face",
                content: "Dans etmek özgürlüktür! 💃 Bugün yeni bir koreografi öğrendim.",
                postType: .question,
                backgroundImageURL: nil,
                backgroundVideoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
                mediaType: "video",
                mediaURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
                parentQuestionId: nil,
                createdAt: Date().addingTimeInterval(-54000)
            )
        ]
    }
} 