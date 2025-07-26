import SwiftUI

struct FollowerSkeletonRow: View {
    let variant: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile foto skeleton
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 50, height: 50)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                // Display name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: getDisplayNameWidth(), height: 16)
                    .shimmer()
                
                // Username skeleton
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: getUsernameWidth(), height: 12)
                    .shimmer()
            }
            
            Spacer()
            
            // Follow button skeleton
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: getButtonWidth(), height: 28)
                .shimmer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func getDisplayNameWidth() -> CGFloat {
        switch variant {
        case 0: return 120
        case 1: return 100
        case 2: return 140
        case 3: return 85
        case 4: return 130
        default: return 110
        }
    }
    
    private func getUsernameWidth() -> CGFloat {
        switch variant {
        case 0: return 80
        case 1: return 65
        case 2: return 90
        case 3: return 70
        case 4: return 85
        default: return 75
        }
    }
    
    private func getButtonWidth() -> CGFloat {
        switch variant {
        case 0, 2, 4: return 75 // "Takip Et"
        case 1, 3: return 85 // "Takipten Çık"
        default: return 80
        }
    }
} 