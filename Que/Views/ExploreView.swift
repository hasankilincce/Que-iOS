import SwiftUI
import SDWebImageSwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Binding var selectedUserId: String?
    @Binding var isSearching: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sabit SearchBar (her zaman en üstte)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Kullanıcı ara...", text: $viewModel.query, onEditingChanged: { editing in
                        if editing { isSearching = true }
                    })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.query) { _ in
                        viewModel.searchUsers()
                    }
                    if isSearching {
                        Button(action: {
                            isSearching = false
                            viewModel.query = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title3)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 12)
                ZStack(alignment: .top) {
                    // Keşfet alanı (şimdilik boş)
                    if !isSearching {
                        VStack {
                            Spacer()
                            // Buraya keşfet grid veya içerik gelecek
                            Spacer()
                        }
                    }
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
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .shimmer()
                                            VStack(alignment: .leading, spacing: 6) {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(width: 120, height: 16)
                                                    .shimmer()
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.white.opacity(0.15))
                                                    .frame(width: 80, height: 12)
                                                    .shimmer()
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
                                    .foregroundColor(.white)
                                    .padding(.top, 32)
                            } else if viewModel.query.isEmpty {
                                if viewModel.recentSearches.isEmpty {
                                    Text("Son arama yok.")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 32)
                                } else {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Son Aramalar")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white.opacity(0.7))
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
                                                            .foregroundColor(.white)
                                                        Text("@" + user.username)
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.7))
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
                                    .foregroundColor(.white)
                                    .padding(.top, 32)
                            } else {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(viewModel.results, id: \.id) { user in
                                            Button(action: {
                                                viewModel.addRecentSearch(user: user)
                                                selectedUserId = user.id; isSearching = false }) {
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
                                                            .foregroundColor(.white)
                                                        Text("@" + user.username)
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.7))
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
                    }
                }
            }
            .navigationDestination(item: $selectedUserId) { userId in
                ProfilePage(userId: userId)
            }
        }
    }
}


