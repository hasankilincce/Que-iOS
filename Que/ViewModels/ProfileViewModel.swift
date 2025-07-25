import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var email: String = ""
    @Published var photoURL: String? = nil
    @Published var isCurrentUser: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var followsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var isFollowing: Bool = false
    let userId: String
    private var currentUserId: String? { Auth.auth().currentUser?.uid }
    private lazy var functions = Functions.functions(region: "us-east1")
    
    init(userId: String? = nil) {
        let currentUser = Auth.auth().currentUser
        self.userId = userId ?? currentUser?.uid ?? ""
        self.isCurrentUser = (userId == nil) || (userId == currentUser?.uid)
        fetchUser()
        if !isCurrentUser { checkIfFollowing() }
    }
    
    func fetchUser(showLoading: Bool = true) {
        if showLoading { self.isLoading = true }
        self.errorMessage = nil
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if showLoading { self?.isLoading = false }
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let data = snapshot?.data() else {
                    self?.errorMessage = "Kullanıcı bulunamadı."
                    return
                }
                self?.displayName = data["displayName"] as? String ?? ""
                self?.username = data["username"] as? String ?? ""
                self?.bio = data["bio"] as? String ?? ""
                self?.email = data["email"] as? String ?? ""
                self?.photoURL = data["photoURL"] as? String
                self?.followsCount = data["followsCount"] as? Int ?? 0
                self?.followersCount = data["followersCount"] as? Int ?? 0
            }
        }
    }
    
    func checkIfFollowing() {
        guard let currentUserId else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId)
            .collection("following").document(userId)
            .getDocument { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    self?.isFollowing = snapshot?.exists ?? false
                }
            }
    }
    
    func follow() {
        isFollowing = true
        followersCount += 1
        functions.httpsCallable("followUser").call(["targetUserId": userId]) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.fetchUser(showLoading: false) // Sadece alanları güncelle, skeleton gösterme
            }
        }
    }
    
    func unfollow() {
        isFollowing = false
        followersCount = max(0, followersCount - 1)
        functions.httpsCallable("unfollowUser").call(["targetUserId": userId]) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.fetchUser(showLoading: false) // Sadece alanları güncelle, skeleton gösterme
            }
        }
    }
    
    // Takipçi/takip edilen listesi için örnek fonksiyonlar:
    func fetchFollowersList(completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("followers").getDocuments { snapshot, _ in
            let ids = snapshot?.documents.map { $0.documentID } ?? []
            completion(ids)
        }
    }
    func fetchFollowsList(completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("following").getDocuments { snapshot, _ in
            let ids = snapshot?.documents.map { $0.documentID } ?? []
            completion(ids)
        }
    }
} 