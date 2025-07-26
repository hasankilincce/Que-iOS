import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(.systemBackground).opacity(0.4),
                        Color(.systemBackground).opacity(0.7),
                        Color(.systemBackground).opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(-12))
                .offset(x: isAnimating ? 350 : -350)
                .animation(
                    Animation
                        .linear(duration: 2.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
} 