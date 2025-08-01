import SwiftUI

// MARK: - TikTok Style Overlay Gradients (Enhanced)
struct TikTokStyleOverlayGradients: View {
    let screenSize: CGSize
    
    var body: some View {
        VStack(spacing: 0) {
            // Top gradient - more sophisticated
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.8), location: 0.0),
                    .init(color: Color.black.opacity(0.4), location: 0.3),
                    .init(color: Color.clear, location: 0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: screenSize.height * 0.4)
            
            Spacer()
            
            // Bottom gradient - enhanced for better control visibility
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color.black.opacity(0.2), location: 0.3),
                    .init(color: Color.black.opacity(0.6), location: 0.7),
                    .init(color: Color.black.opacity(0.9), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: screenSize.height * 0.5)
        }
        .ignoresSafeArea()
    }
} 