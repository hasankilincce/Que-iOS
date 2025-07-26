import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFunctions

struct FollowerRow: View {
    var user: ProfileListUser
    @Binding var isFollowing: Bool?
    var onUserTap: (String) -> Void
    var onFollowChanged: (Bool) -> Void
    
    @State private var isLoading = false
    private let functions = Functions.functions(region: "us-east1")
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onUserTap(user.id) }) {
                if let url = URL(string: user.photoURL ?? ""), !(user.photoURL ?? "").isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .background(
                            Circle().fill(Color(.systemGray5)).frame(width: 40, height: 40)
                        )
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray.opacity(0.3))
                                .padding(4)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                Text("@" + user.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let following = isFollowing, user.id != Auth.auth().currentUser?.uid {
                Button(action: {
                    isLoading = true
                    let fn = following ? "unfollowUser" : "followUser"
                    functions.httpsCallable(fn).call(["targetUserId": user.id]) { _, error in
                        self.isLoading = false
                        if error == nil {
                            self.isFollowing?.toggle()
                            onFollowChanged(self.isFollowing ?? false)
                        }
                    }
                }) {
                    Text(following ? "Takipten Çık" : "Takip Et")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(following ? Color.gray.opacity(0.15) : Color.purple)
                        .foregroundColor(following ? .primary : .white)
                        .cornerRadius(10)
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            if isFollowing == nil, let val = user.isFollowing {
                isFollowing = val
            }
        }
    }
} 