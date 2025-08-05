import SwiftUI
import FirebaseAuth

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var isProfileRoot: Bool = true
    @Published var selectedUserId: String? = nil
    @Published var isExploreSearching: Bool = false
    
    // Sub-ViewModels
    @Published var exploreViewModel = ExploreViewModel()
    @Published var addPostViewModel = AddPostViewModel()
    @Published var notificationBadgeViewModel = NotificationBadgeViewModel()
    
    init() {
        setupNotificationHandling()
    }
    
    // Tab değişimi
    func selectTab(_ tab: Tab) {
        let previousTab = selectedTab
        selectedTab = tab
        
        // Tab'e özel aksiyonlar
        switch tab {
        case .explore:
            // Explore'a tekrar tıklanınca reset
            if previousTab == .explore {
                resetExplore()
            }
        case .home:
            // Home tab functionality removed
            break
        case .add:
            // Add post modalını aç
            break
        case .notifications:
            // Badge'i temizle
            notificationBadgeViewModel.clearBadge()
        case .profile:
            isProfileRoot = true
        }
    }
    
    // Explore reset
    private func resetExplore() {
        selectedUserId = nil
        isExploreSearching = false
        exploreViewModel.query = ""
    }
    
    // Bildirim setup
    private func setupNotificationHandling() {
        // Notification badge handling is managed by notificationBadgeViewModel
    }
    
    // Profile navigation
    func navigateToProfile(userId: String) {
        selectedUserId = userId
        isProfileRoot = false
        selectedTab = .profile
    }
    
    // Tab bar visibility
    var shouldShowTabBar: Bool {
        switch selectedTab {
        case .add:
            return false
        case .profile:
            return isProfileRoot
        default:
            return true
        }
    }
    
    // Tab specific actions
    func handleTabTap(_ tab: Tab) {
        selectTab(tab)
    }
} 