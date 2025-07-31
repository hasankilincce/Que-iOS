import SwiftUI

extension View {
    func shimmer() -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(20))
                        .offset(x: shimmerOffset(for: geometry.size.width))
                        .animation(
                            Animation.easeInOut(duration: 1.8)
                                .repeatForever(autoreverses: false),
                            value: shimmerOffset(for: geometry.size.width)
                        )
                }
            )
            .clipped()
    }
    
    private func shimmerOffset(for width: CGFloat) -> CGFloat {
        return -width - 60
    }
}

// Alternatif shimmer için StateObject kullanımı
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(.systemGray6).opacity(0.3),
                        Color(.systemGray5).opacity(0.5),
                        Color(.systemGray6).opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(12))
                .scaleEffect(x: isAnimating ? 3 : 0.5, y: 1)
                .offset(x: isAnimating ? 300 : -300)
                .animation(
                    Animation.easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            )
            .clipped()
    }
}

// Kullanım kolaylığı için ek extension
extension View {
    func modernShimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
    
    func subtleShimmer() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(.systemGray6).opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .animation(
                        Animation.easeInOut(duration: 2.2)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            )
            .clipped()
    }
    
    func pulseShimmer() -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(x: 1.2, y: 1)
                        .offset(x: -geometry.size.width)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: UUID()
                        )
                }
            )
            .clipped()
    }
} 