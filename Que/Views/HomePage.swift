import SwiftUI

struct HomePage: View {
    @State private var selectedTab: Tab = .home
    @State private var isProfileRoot: Bool = true
    @StateObject private var exploreVM = ExploreViewModel()
    @State private var selectedUserId: String? = nil
    @State private var isExploreSearching: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    FeedView()
                case .explore:
                    ExploreView(viewModel: exploreVM, selectedUserId: $selectedUserId, isSearching: $isExploreSearching)
                case .add:
                    AddPostView()
                case .notifications:
                    NotificationsView()
                case .profile:
                    ProfileTabNavigation(isProfileRoot: $isProfileRoot)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Sadece ana sekmelerde ve profile root'ta tab bar göster
            if (selectedTab != .add) && (selectedTab != .profile || isProfileRoot) {
                CustomTabBar(selectedTab: $selectedTab, onTabTapped: { tab in
                    if tab == .explore {
                        selectedUserId = nil // Keşfet sekmesine tekrar tıklanınca ana sayfaya dön
                        isExploreSearching = false
                        exploreVM.query = ""
                    }
                })
                }
            }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(.systemBackground))
            }
        }

