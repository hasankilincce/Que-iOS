import SwiftUI
import SDWebImageSwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Binding var selectedUserId: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Kullanıcı ara...", text: $viewModel.query)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.query) { _ in
                            viewModel.searchUsers()
                        }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 12)
                // Sonuçlar
                List {
                    ForEach(viewModel.results, id: \._id) { user in
                        Button(action: { selectedUserId = user.id }) {
                            HStack(spacing: 12) {
                                if let url = URL(string: user.photoURL ?? ""), !(user.photoURL ?? "").isEmpty {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .background(
                                            Circle()
                                                .fill(Color(.systemGray5))
                                                .frame(width: 40, height: 40)
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
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text("@" + user.username)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
<<<<<<< Updated upstream
                    if viewModel.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
=======
                    
                    // Overlay: Arama aktifse
                    if isSearching {
                        Color(.systemBackground)
                            .opacity(0.98)
                            .ignoresSafeArea()
                            .onTapGesture { }
                            .transition(.opacity)
                            .zIndex(1)
                        
                        VStack(spacing: 0) {
                            Spacer().frame(height: 0)
                            // Arama sonuçları
                            if viewModel.isLoading {
                                VStack(spacing: 0) {
                                    ForEach(0..<6) { _ in
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 40, height: 40)
                                                .modernShimmer()
                                            VStack(alignment: .leading, spacing: 6) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray6))
                                                    .frame(width: 120, height: 16)
                                                    .subtleShimmer()
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 80, height: 12)
                                                    .subtleShimmer()
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.top, 8)
                            } else if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.primary)
                                    .padding(.top, 32)
                            } else if viewModel.query.isEmpty {
                                if viewModel.recentSearches.isEmpty {
                                    Text("Son arama yok.")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 32)
                                } else {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Son Aramalar")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 12)
                                        ForEach(viewModel.recentSearches, id: \.id) { user in
                                            Button(action: {
                                                viewModel.addRecentSearch(user: user)
                                                selectedUserId = user.id
                                                isSearching = false
                                            }) {
                                                HStack(spacing: 12) {
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
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(user.displayName)
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Text("@" + user.username)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                            }
                                            .background(Color.purple.opacity(0.01))
                                        }
                                    }
                                }
                            } else if viewModel.results.isEmpty {
                                Text("Sonuç bulunamadı.")
                                    .foregroundColor(.primary)
                                    .padding(.top, 32)
                            } else {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(viewModel.results, id: \.id) { user in
                                            Button(action: {
                                                viewModel.addRecentSearch(user: user)
                                                selectedUserId = user.id
                                                isSearching = false
                                            }) {
                                                HStack(spacing: 12) {
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
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(user.displayName)
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Text("@" + user.username)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                            }
                                            .background(Color.purple.opacity(0.01))
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .zIndex(2)
>>>>>>> Stashed changes
                    }
                }
                .listStyle(.plain)
                .padding(.top, 8)
            }
            .navigationDestination(item: $selectedUserId) { userId in
                ProfilePage(userId: userId)
            }
        }
    }
} 
