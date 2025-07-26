import SwiftUI
import SDWebImageSwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    // Loading skeleton
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                PostSkeletonView()
                            }
                        }
                        .padding()
                    }
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
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
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

struct PostRowView: View {
    let post: Post
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header
            HStack {
                // Profile image
                if let photoURL = post.userPhotoURL, let url = URL(string: photoURL) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .font(.subheadline.bold())
                    Text("@\(post.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .lineLimit(nil)
            
            // Images (if any)
            if post.hasImages {
                PostImagesView(imageURLs: post.imageURLs)
            }
            
            // Action buttons
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likesCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .foregroundColor(.gray)
                        Text("\(post.commentsCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

struct PostImagesView: View {
    let imageURLs: [String]
    
    var body: some View {
        if imageURLs.count == 1 {
            // Single image
            if let url = URL(string: imageURLs[0]) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            }
        } else {
            // Multiple images grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 2), spacing: 4) {
                ForEach(Array(imageURLs.prefix(4).enumerated()), id: \.offset) { index, imageURL in
                    if let url = URL(string: imageURL) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(8)
                            .overlay {
                                if index == 3 && imageURLs.count > 4 {
                                    ZStack {
                                        Color.black.opacity(0.6)
                                        Text("+\(imageURLs.count - 4)")
                                            .foregroundColor(.white)
                                            .font(.headline.bold())
                                    }
                                    .cornerRadius(8)
                                }
                            }
                    }
                }
            }
        }
    }
}

struct PostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header skeleton - exactly matching real structure
            HStack {
                // Profile image skeleton
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 2) {
                    // Display name skeleton
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 130, height: 16)
                        .shimmer()
                    
                    // Username skeleton
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 85, height: 12)
                        .shimmer()
                }
                
                Spacer()
                
                // Time ago skeleton
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(width: 35, height: 12)
                    .shimmer()
            }
            
            // Content skeleton - multiple lines like real posts
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 280)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 180)
                    .shimmer()
            }
            
            // Sometimes show image skeleton (50% chance for variety)
            if Bool.random() {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .shimmer()
            }
            
            // Action buttons skeleton - matching real buttons layout
            HStack(spacing: 24) {
                // Like button skeleton
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 16, height: 16)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 20, height: 12)
                        .shimmer()
                }
                
                // Comment button skeleton
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 16, height: 16)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 15, height: 12)
                        .shimmer()
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
} 