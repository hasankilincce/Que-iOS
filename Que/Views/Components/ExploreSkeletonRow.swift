import SwiftUI

struct ExploreSkeletonRow: View {
    let variant: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile foto skeleton
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 44, height: 44)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                // Display name skeleton (farklı uzunluklar)
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private func getDisplayNameWidth() -> CGFloat {
        switch variant {
        case 0: return 140
        case 1: return 110
        case 2: return 125
        case 3: return 95
        case 4: return 160
        default: return 120
        }
    }
    
    private func getUsernameWidth() -> CGFloat {
        switch variant {
        case 0: return 85
        case 1: return 70
        case 2: return 90
        case 3: return 65
        case 4: return 95
        default: return 75
        }
    }
} 