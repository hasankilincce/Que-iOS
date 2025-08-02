import SwiftUI

// MARK: - Feed Post Gradient Background (Enhanced)
struct FeedPostBackground: View {
    let post: Post
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Add subtle pattern overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.black.opacity(0.2)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
    }
    
    private var gradientColors: [Color] {
        if post.postType == .question {
            return [
                Color.blue.opacity(0.9),
                Color.purple.opacity(0.7),
                Color.indigo.opacity(1.0),
                Color.black.opacity(0.8)
            ]
        } else {
            return [
                Color.green.opacity(0.9),
                Color.teal.opacity(0.7),
                Color.mint.opacity(1.0),
                Color.black.opacity(0.8)
            ]
        }
    }
} 