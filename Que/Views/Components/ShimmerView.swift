import SwiftUI


// Shimmer effect modifier
extension View {
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .overlay(
                ShimmerView()
                    .mask(self)
            )
    }
}

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray6).opacity(0.3),
                Color(.systemGray5).opacity(0.6),
                Color(.systemGray6).opacity(0.3)
            ]), 
            startPoint: .leading, 
            endPoint: .trailing
        )
        .rotationEffect(.degrees(20))
        .offset(x: phase * 350)
        .animation(Animation.linear(duration: 1.8).repeatForever(autoreverses: false), value: phase)
        .onAppear { phase = 1 }
    }
}
