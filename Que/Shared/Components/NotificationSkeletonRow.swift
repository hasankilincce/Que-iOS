import SwiftUI

struct NotificationSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Profile foto skeleton
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 52, height: 52)
            
            VStack(alignment: .leading, spacing: 8) {
                // Ana mesaj skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                // Alt bilgi skeleton
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 12)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
} 