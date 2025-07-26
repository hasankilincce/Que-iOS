import SwiftUI

// Profile sekmesi için navigation stack
struct ProfileTabNavigation: View {
    @Binding var isProfileRoot: Bool
    
    var body: some View {
        NavigationStack {
            ProfilePage(isProfileRoot: $isProfileRoot)
        }
    }
} 