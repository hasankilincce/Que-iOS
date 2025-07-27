import SwiftUI

struct HomePage: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch viewModel.selectedTab {
                case .home:
                    FullScreenFeedView(viewModel: viewModel.feedViewModel)
                case .explore:
                    ExploreView(viewModel: viewModel.exploreViewModel, selectedUserId: $viewModel.selectedUserId, isSearching: $viewModel.isExploreSearching)
                case .add:
                    AddPostView(viewModel: viewModel.addPostViewModel)
                case .notifications:
                    NotificationsView()
                case .profile:
                    ProfileTabNavigation(isProfileRoot: $viewModel.isProfileRoot)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Sadece ana sekmelerde ve profile root'ta tab bar göster
            if viewModel.shouldShowTabBar {
                CustomTabBar(
                    selectedTab: $viewModel.selectedTab, 
                    onTabTapped: viewModel.handleTabTap,
                    badgeViewModel: viewModel.notificationBadgeViewModel
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(.systemBackground))
    }
}

// Profile sekmesi için navigation stack
struct ProfileTabNavigation: View {
    @Binding var isProfileRoot: Bool
    var body: some View {
        NavigationStack {
            ProfilePage(isProfileRoot: $isProfileRoot)
        }
    }
}



