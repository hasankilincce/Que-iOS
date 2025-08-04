import SwiftUI

struct PostSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Post type indicator skeleton
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 12, height: 12)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 16)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6).opacity(0.3))
                .cornerRadius(12)
                
                Spacer()
            }
            
            // User header skeleton
            HStack(spacing: 12) {
                // Profile image skeleton
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Display name skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 120, height: 16)
                    
                    // Username skeleton
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 12)
                }
                
                Spacer()
                
                // Time ago skeleton
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 12)
            }
            
            // Content skeleton - multiple lines with varying lengths
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 280)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 200)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(height: 16)
                    .frame(width: 150)
            }
            
            // Media skeleton (70% chance to show for variety)
            if Bool.random() {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 240)
                    .overlay(
                        // Media type indicator
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(width: 16, height: 16)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(width: 40, height: 12)
                            
                            Spacer()
                        }
                        .padding(8),
                        alignment: .topLeading
                    )
            }
            
            // Action buttons skeleton
            HStack(spacing: 24) {
                // Like button skeleton
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 18, height: 16)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 25, height: 12)
                }
                
                // Comment button skeleton
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 18, height: 16)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 20, height: 12)
                }
                
                // Share button skeleton
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 18, height: 16)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 30, height: 12)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Compact skeleton for list view
struct CompactPostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header
            HStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 14)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 70, height: 10)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray6))
                    .frame(width: 35, height: 10)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray6))
                    .frame(height: 14)
                    .frame(width: 200)
            }
            
            // Actions
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 14, height: 14)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 20, height: 10)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 14, height: 14)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: 15, height: 10)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}
