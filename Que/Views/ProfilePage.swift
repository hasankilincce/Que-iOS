import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfilePage: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var showEdit = false
    @State private var showSettings = false
    @Binding var isProfileRoot: Bool
    @State private var showFollowersPage = false
    @State private var showFollowsPage = false
    @State private var selectedUserId: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    init(userId: String? = nil, isProfileRoot: Binding<Bool> = .constant(true)) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
        self._isProfileRoot = isProfileRoot
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom üst bar
            HStack {
                if !viewModel.isCurrentUser {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(8)
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                    Spacer()
                }
                
                //viewModel.isCurrentUser ? "Profilim" : 
                Text(viewModel.username.isEmpty ? "" : viewModel.username)
                    .font(.title3)
                    //.foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                if viewModel.isCurrentUser {
                    NavigationLink(destination: SettingsPage(onSignOut: signOut)) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .overlay(
                EmptyView().navigationBarBackButtonHidden(true)
            )
            ScrollView {
                if viewModel.isLoading {
                    ProfileSkeletonView()
                } else {
                    VStack(spacing: 12) {
                        // Profil Fotoğrafı
                        if let urlString = viewModel.photoURL, let url = URL(string: urlString), !urlString.isEmpty {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                                .shadow(radius: 4)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 96, height: 96)
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        // Display Name
                        Text(viewModel.displayName.isEmpty ? "Kullanıcı" : viewModel.displayName)
                            .font(.title2.bold())
                            .padding(.top, 2)
                        // Takipçi ve Takip edilen sayıları
                        HStack(spacing: 32) {
                            Button(action: { showFollowersPage = true }) {
                                VStack {
                                    Text("\(viewModel.followersCount)")
                                        .foregroundColor(.primary)
                                        .font(.title3)
                                    Text("Takipçi")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Button(action: { showFollowsPage = true }) {
                                VStack {
                                    Text("\(viewModel.followsCount)")
                                        .foregroundColor(.primary)
                                        .font(.title3)
                                    Text("Takip")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        // Butonlar
                        if viewModel.isCurrentUser {
                            Button {
                                showEdit = true
                            } label: {
                                Text("Profili Düzenle")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                        } else {
                            Button {
                                if viewModel.isFollowing {
                                    viewModel.unfollow()
                                } else {
                                    viewModel.follow()
                                }
                            } label: {
                                Text(viewModel.isFollowing ? "Takipten Çık" : "Takip Et")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(viewModel.isFollowing ? Color.gray.opacity(0.15) : Color.purple)
                                    .foregroundColor(viewModel.isFollowing ? .primary : .white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                        }
                        // Bio
                        if !viewModel.bio.isEmpty {
                            Text(viewModel.bio)
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .refreshable {
                viewModel.fetchUser()
                if !viewModel.isCurrentUser {
                    viewModel.checkIfFollowing()
                }
            }
            .background(Color(.systemBackground))
        }
        .onAppear { isProfileRoot = true }
        .navigationDestination(isPresented: $showEdit) {
            EditProfilePage(userId: viewModel.userId)
                .onAppear { isProfileRoot = false }
        }
        .navigationDestination(isPresented: $showFollowersPage) {
            FollowersListPage(userId: viewModel.userId, onUserTap: { userId in selectedUserId = userId })
        }
        .navigationDestination(isPresented: $showFollowsPage) {
            FollowsListPage(userId: viewModel.userId, onUserTap: { userId in selectedUserId = userId })
        }
        .navigationDestination(item: $selectedUserId) { userId in
            ProfilePage(userId: userId)
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Uygulama state'inizi güncelleyin (ör: ana ekrana yönlendirme)
        } catch {
            // Hata yönetimi
        }
    }
}

struct ProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Profil fotoğrafı skeleton - exactly matching real size
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 96, height: 96)
                .shimmer()
                .padding(.top, 20)
            
            // Display name skeleton - matching font size
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 150, height: 24)
                .shimmer()
                .padding(.top, 2)
            
            // Takipçi ve takip skeleton - matching real layout
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 35, height: 20)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 12)
                        .shimmer()
                }
                
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 35, height: 20)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 12)
                        .shimmer()
                }
            }
            
            // Follow/Edit button skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(width: 100, height: 32)
                .shimmer()
                .padding(.top, 8)
            
            // Bio skeleton - multiple lines
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(width: 280, height: 16)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(width: 200, height: 16)
                    .shimmer()
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
}


