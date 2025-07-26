import SwiftUI


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

