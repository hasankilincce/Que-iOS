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
        LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4), Color(.systemGray5)]), startPoint: .leading, endPoint: .trailing)
            .rotationEffect(.degrees(30))
            .offset(x: phase * 350)
            .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
            .onAppear { phase = 1 }
    }
}
