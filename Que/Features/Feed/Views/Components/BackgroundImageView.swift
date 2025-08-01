import SwiftUI
import SDWebImageSwiftUI

// Background image view for 9:16 aspect ratio images (vertical)
struct BackgroundImageView: View {
    let imageURL: String
    
    var body: some View {
        if let url = URL(string: imageURL) {
            WebImage(url: url)
                //.resizable()
                .aspectRatio(9/16, contentMode: .fit) // Fit mode: tüm içerik görünür
                .frame(maxWidth: .infinity)
                .background(Color.black) // Siyah arka plan letterbox effect için
                .cornerRadius(12)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(12)
                )
                .onAppear {
                    print("📸 BackgroundImageView: onAppear for imageURL: \(imageURL)")
                    
                    // Resim boyutlarını kontrol et
                    if let imageData = try? Data(contentsOf: url),
                       let image = UIImage(data: imageData) {
                        let size = image.size
                        let ratio = size.width / size.height
                        print("📸 Image dimensions: \(size.width) x \(size.height)")
                        print("📸 Image aspect ratio: \(ratio)")
                        print("📸 Target aspect ratio: \(9.0/16.0)")
                        print("📸 Difference: \(abs(ratio - 9.0/16.0))")
                    }
                }
        }
    }
} 