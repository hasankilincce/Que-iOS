import SwiftUI

// CustomTabBar component
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onTabTapped: ((Tab) -> Void)? = nil
    @ObservedObject var badgeViewModel: NotificationBadgeViewModel
    
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
                tabButton(tab: .home, icon: Tab.home.iconName, selectedIcon: Tab.home.selectedIconName, label: Tab.home.title)
                tabButton(tab: .explore, icon: Tab.explore.iconName, selectedIcon: Tab.explore.selectedIconName, label: Tab.explore.title)
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
                tabButtonWithBadge(tab: .notifications, icon: Tab.notifications.iconName, selectedIcon: Tab.notifications.selectedIconName, label: Tab.notifications.title, badgeCount: badgeViewModel.unreadCount)
                tabButton(tab: .profile, icon: Tab.profile.iconName, selectedIcon: Tab.profile.selectedIconName, label: Tab.profile.title)
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
    
    @ViewBuilder
    private func tabButtonWithBadge(tab: Tab, icon: String, selectedIcon: String, label: String, badgeCount: Int) -> some View {
        Button(action: {
            if selectedTab == tab {
                onTabTapped?(tab)
            }
            selectedTab = tab
        }) {
            VStack(spacing: 0) {
                ZStack {
                    Image(systemName: selectedTab == tab ? selectedIcon : icon)
                        .font(.system(size: tabIconSize, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? Color.purple : Color.gray.opacity(0.7))
                    
                    // Badge
                    if badgeCount > 0 {
                        Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, badgeCount > 9 ? 4 : 0)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(
                                Circle()
                                    .fill(Color.red)
                            )
                            .offset(x: 10, y: -8)
                    }
                }
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
