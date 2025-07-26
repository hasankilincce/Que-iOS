import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.5), Color.white.opacity(0.2)]), startPoint: .leading, endPoint: .trailing)
            .rotationEffect(.degrees(30))
            .offset(x: phase * 350)
            .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
            .onAppear { phase = 1 }
    }
} 
