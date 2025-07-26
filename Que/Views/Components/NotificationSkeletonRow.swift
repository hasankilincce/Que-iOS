import SwiftUI

struct NotificationSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Profile foto skeleton (gerçek boyutlarda)
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 52, height: 52)
                .shimmer()
            
            // İçerik alanı
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Ana mesaj skeleton (3 farklı uzunlukta rastgele)
                        VStack(alignment: .leading, spacing: 3) {
                            // İlk satır (uzun)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(height: 14)
                                .frame(maxWidth: .infinity)
                                .shimmer()
                            
                            // İkinci satır (orta)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 14)
                                .frame(width: UIScreen.main.bounds.width * 0.6)
                                .shimmer()
                        }
                        
                        Spacer().frame(height: 4)
                        
                        // Username ve zaman skeleton
                        HStack(spacing: 8) {
                            // Username skeleton (@kullaniciadi)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(width: 85, height: 10)
                                .shimmer()
                            
                            // Nokta
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 2, height: 2)
                            
                            // Zaman skeleton
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(width: 45, height: 10)
                                .shimmer()
                        }
                    }
                    
                    Spacer()
                    
                    // Bildirim ikonu skeleton
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 20, height: 20)
                        .shimmer()
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// Farklı skeleton varyasyonları için
struct NotificationSkeletonVariant: View {
    let variant: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile foto skeleton
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 52, height: 52)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Farklı uzunluklarda mesaj skeleton'ları
                        VStack(alignment: .leading, spacing: 3) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(height: 14)
                                .frame(width: getFirstLineWidth())
                                .shimmer()
                            
                            if variant != 2 { // Kısa mesajlar için ikinci satır yok
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 14)
                                    .frame(width: getSecondLineWidth())
                                    .shimmer()
                            }
                        }
                        
                        Spacer().frame(height: 4)
                        
                        // Username ve zaman
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(width: getUsernameWidth(), height: 10)
                                .shimmer()
                            
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 2, height: 2)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(width: 45, height: 10)
                                .shimmer()
                        }
                    }
                    
                    Spacer()
                    
                    // Farklı icon skeleton'ları
                    getIconSkeleton()
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private func getFirstLineWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        switch variant {
        case 0: return screenWidth * 0.75
        case 1: return screenWidth * 0.65
        case 2: return screenWidth * 0.55
        default: return screenWidth * 0.7
        }
    }
    
    private func getSecondLineWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        switch variant {
        case 0: return screenWidth * 0.6
        case 1: return screenWidth * 0.4
        default: return screenWidth * 0.5
        }
    }
    
    private func getUsernameWidth() -> CGFloat {
        switch variant {
        case 0: return 95
        case 1: return 75
        case 2: return 85
        default: return 80
        }
    }
    
    @ViewBuilder
    private func getIconSkeleton() -> some View {
        switch variant {
        case 0:
            // Yuvarlak icon (follow, like)
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 18, height: 18)
                .shimmer()
        case 1:
            // Kare icon (comment, mention)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray6))
                .frame(width: 16, height: 16)
                .shimmer()
        default:
            // Oval icon
            Capsule()
                .fill(Color(.systemGray6))
                .frame(width: 20, height: 14)
                .shimmer()
        }
    }
} 