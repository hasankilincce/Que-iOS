import Foundation
import FirebaseFirestore

struct ExploreUser: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let username: String
    let photoURL: String?
    
    var _id: String { id } // For ForEach compatibility
}

class ExploreViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [ExploreUser] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var recentSearches: [ExploreUser] = []
    private var lastQuery: String = ""
    private let recentKey = "recentSearches"
    
    init() {
        loadRecentSearches()
    }
    
    func searchUsers() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastQuery else { return }
        lastQuery = trimmed
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("searchKeywords", arrayContains: trimmed.lowercased())
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.results = []
                        return
                    }
                    let users: [ExploreUser] = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return ExploreUser(
                            id: doc.documentID,
                            displayName: data["displayName"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            photoURL: data["photoURL"] as? String
                        )
                    } ?? []
                    self?.results = self?.rankAndSort(users: users, query: trimmed) ?? []
                }
            }
    }
    
    // Skorla ve sırala: tam eşleşme > prefix > contains
    private func rankAndSort(users: [ExploreUser], query: String) -> [ExploreUser] {
        let q = query.lowercased()
        let qParts = q.split(separator: " ").map { String($0) }
        return users.map { user in
            let uname = user.username.lowercased()
            let dname = user.displayName.lowercased()
            var score = 0
            // Tam eşleşme
            if uname == q || dname == q { score += 100 }
            // Prefix eşleşme
            if uname.hasPrefix(q) || dname.hasPrefix(q) { score += 50 }
            // Contains eşleşme
            if uname.contains(q) || dname.contains(q) { score += 20 }
            // Çoklu kelime desteği
            for part in qParts {
                if uname == part || dname == part { score += 30 }
                else if uname.hasPrefix(part) || dname.hasPrefix(part) { score += 15 }
                else if uname.contains(part) || dname.contains(part) { score += 5 }
            }
            return (user, score)
        }
        .sorted { $0.1 > $1.1 }
        .map { $0.0 }
    }
    
    func addRecentSearch(user: ExploreUser) {
        var recents = recentSearches.filter { $0.id != user.id }
        recents.insert(user, at: 0)
        if recents.count > 10 { recents = Array(recents.prefix(10)) }
        recentSearches = recents
        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentKey)
        }
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: recentKey),
           let recents = try? JSONDecoder().decode([ExploreUser].self, from: data) {
            recentSearches = recents
        }
    }
} 