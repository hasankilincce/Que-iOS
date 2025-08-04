import SwiftUI

struct FeedShimmerLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header shimmer
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .shimmer(isAnimating: isAnimating)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(width: 120)
                        .shimmer(isAnimating: isAnimating)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 10)
                        .frame(width: 80)
                        .shimmer(isAnimating: isAnimating)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Content shimmer
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .shimmer(isAnimating: isAnimating)
                .padding(.horizontal)
            
            // Action buttons shimmer
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 20)
                        .shimmer(isAnimating: isAnimating)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.black)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: isAnimating ? 400 : -400)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            )
            .clipped()
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

