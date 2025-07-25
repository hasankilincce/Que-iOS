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
                    if viewModel.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
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
