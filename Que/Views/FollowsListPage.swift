import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

struct FollowsListPage: View {
    let userId: String
    var onUserTap: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var users: [ProfileListUser] = []
    @State private var isLoading = false
    @State private var allLoaded = false
    @State private var lastDoc: DocumentSnapshot? = nil
    private let pageSize = 20
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(8)
                }
                Spacer()
                Text("Takip")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .overlay(
                EmptyView().navigationBarBackButtonHidden(true)
            )
            List {
                ForEach(users, id: \.id) { user in
                    FollowerRow(user: user, onUserTap: onUserTap, onFollowChanged: { isNowFollowing in
                        if let idx = users.firstIndex(where: { $0.id == user.id }) {
                            users[idx].isFollowing = isNowFollowing
                        }
                    })
                    .onAppear {
                        if user == users.last, !isLoading, !allLoaded {
                            loadMore()
                        }
                    }
                }
                if isLoading && users.count > 0 {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
            .listStyle(.plain)
        }
        .onAppear { if users.isEmpty { loadMore() } }
    }
    private func loadMore() {
        isLoading = true
        let db = Firestore.firestore()
        var query: Query = db.collection("users").document(userId).collection("following").limit(to: pageSize)
        if let lastDoc = lastDoc { query = query.start(afterDocument: lastDoc) }
        query.getDocuments { snapshot, _ in
            let ids = snapshot?.documents.map { $0.documentID } ?? []
            self.lastDoc = snapshot?.documents.last
            if ids.isEmpty { self.isLoading = false; self.allLoaded = true; return }
            db.collection("users").whereField(FieldPath.documentID(), in: Array(ids)).getDocuments { userSnap, _ in
                let newUsers = userSnap?.documents.compactMap { doc -> ProfileListUser? in
                    let data = doc.data()
                    return ProfileListUser(
                        id: doc.documentID,
                        displayName: data["displayName"] as? String ?? "",
                        username: data["username"] as? String ?? "",
                        photoURL: data["photoURL"] as? String,
                        isFollowing: nil // Takip durumu aşağıda yüklenecek
                    )
                } ?? []
                DispatchQueue.main.async {
                    self.users += newUsers
                    self.isLoading = false
                    if newUsers.count < pageSize { self.allLoaded = true }
                    // Takip durumlarını yükle
                    loadFollowStates(for: newUsers)
                }
            }
        }
    }
    private func loadFollowStates(for users: [ProfileListUser]) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        for user in users {
            if user.id == currentUserId { continue }
            db.collection("users").document(currentUserId).collection("following").document(user.id).getDocument { snapshot, _ in
                if let idx = self.users.firstIndex(where: { $0.id == user.id }) {
                    self.users[idx].isFollowing = snapshot?.exists ?? false
                }
            }
        }
    }
} 
