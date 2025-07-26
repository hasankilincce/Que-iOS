import SwiftUI

struct GroupHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(.systemBackground).opacity(0.97))
    }
} 