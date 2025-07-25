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

// Profile sekmesi için navigation stack
struct ProfileTabNavigation: View {
    @Binding var isProfileRoot: Bool
    var body: some View {
        NavigationStack {
            ProfilePage(isProfileRoot: $isProfileRoot)
        }
    }
}

// Placeholder views for each tab
struct FeedView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Anasayfa")
                    .font(.largeTitle.bold())
                Spacer()
            }
        }
    }
}

/*struct ExploreView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Keşfet")
                    .font(.largeTitle.bold())
                Spacer()
            }
        }
    }
}*/

struct AddPostView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Gönderi Ekle")
                    .font(.largeTitle.bold())
                Spacer()
            }
        }
    }
}

struct NotificationsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Bildirimler")
                    .font(.largeTitle.bold())
                Spacer()
            }
        }
    }
}
