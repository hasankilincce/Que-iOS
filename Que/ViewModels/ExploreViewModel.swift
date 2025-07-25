import Foundation
import FirebaseFirestore

struct ExploreUser: Identifiable {
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
    private var lastQuery: String = ""
    
    func searchUsers() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastQuery else { return }
        lastQuery = trimmed
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("searchKeywords", arrayContains: trimmed.lowercased())
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.results = []
                        return
                    }
                    self?.results = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return ExploreUser(
                            id: doc.documentID,
                            displayName: data["displayName"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            photoURL: data["photoURL"] as? String
                        )
                    } ?? []
                }
            }
    }
} 