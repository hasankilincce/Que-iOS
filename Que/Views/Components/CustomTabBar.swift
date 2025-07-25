import SwiftUI

// Tab enumu
enum Tab: Int, CaseIterable {
    case home, explore, add, notifications, profile
}

// CustomTabBar component
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onTabTapped: ((Tab) -> Void)? = nil
    
    private let tabBarHeight: CGFloat = 62
    private let tabBarCornerRadius: CGFloat = 24
    private let tabIconSize: CGFloat = 22
    private let tabFont: Font = .caption
    private let plusButtonSize: CGFloat = 54
    private let plusButtonOffset: CGFloat = -18
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Arka planı ZStack'e taşı ve kenarlardan boşluk bırak
            RoundedRectangle(cornerRadius: tabBarCornerRadius, style: .continuous)
                .fill(Color.clear)
                .background(
                    BlurView(style: .systemMaterial)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(.systemBackground).opacity(0.97), Color(.systemBackground).opacity(0.85)]), startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: tabBarCornerRadius, style: .continuous))
                )
                .frame(height: tabBarHeight)
                .padding(.horizontal, 12)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: -2)
            HStack(spacing: 0) {
                tabButton(tab: .home, icon: "house", selectedIcon: "house.fill", label: "Anasayfa")
                tabButton(tab: .explore, icon: "magnifyingglass", selectedIcon: "magnifyingglass", label: "Keşfet")
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: plusButtonSize, height: plusButtonSize)
                        .shadow(color: Color.pink.opacity(0.25), radius: 8, y: 4)
                    Button(action: { selectedTab = .add; onTabTapped?(.add) }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 26, weight: .bold))
                    }
                }
                .offset(y: plusButtonOffset)
                .frame(width: plusButtonSize + 12)
                tabButton(tab: .notifications, icon: "bell", selectedIcon: "bell.fill", label: "Bildirim")
                tabButton(tab: .profile, icon: "person", selectedIcon: "person.fill", label: "Profilim")
            }
            .padding(.horizontal, 24)
            .frame(height: tabBarHeight)
            .padding(.bottom, 0)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    @ViewBuilder
    private func tabButton(tab: Tab, icon: String, selectedIcon: String, label: String) -> some View {
        Button(action: {
            if selectedTab == tab {
                onTabTapped?(tab)
            }
            selectedTab = tab
        }) {
            VStack(spacing: 0) {
                Image(systemName: selectedTab == tab ? selectedIcon : icon)
                    .font(.system(size: tabIconSize, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? Color.purple : Color.gray.opacity(0.7))
                Text(label)
                    .font(tabFont)
                    .foregroundColor(selectedTab == tab ? Color.purple : Color.gray.opacity(0.7))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

// iOS için BlurView helper
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 
