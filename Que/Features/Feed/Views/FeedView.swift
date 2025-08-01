import SwiftUI
import SDWebImageSwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.showSkeleton || (viewModel.isLoading && viewModel.posts.isEmpty) {
                    // Loading skeleton with improved UI
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(0..<6, id: \.self) { index in
                                PostSkeletonView()
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: viewModel.showSkeleton)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .background(Color(.systemGroupedBackground))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if viewModel.posts.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "house")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Henüz gönderi yok")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Takip ettiğin kişilerin gönderileri burada görünecek")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Posts list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.posts) { post in
                                PostRowView(post: post) {
                                    viewModel.toggleLike(for: post)
                                }
                                .onAppear {
                                    // Load more when near end
                                    if post.id == viewModel.posts.last?.id {
                                        viewModel.loadMorePosts()
                                    }
                                    
                                    // Prefetch next video
                                    viewModel.prefetchNextVideo(for: post)
                                }
                                .transition(.opacity.combined(with: .scale))
                                .animation(.easeInOut(duration: 0.3), value: viewModel.posts.count)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Error overlay
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Text(error)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Anasayfa")
            .navigationBarTitleDisplayMode(.large)
        }
    }
} 