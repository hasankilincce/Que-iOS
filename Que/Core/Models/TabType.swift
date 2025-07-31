import Foundation

// Tab enumu
enum Tab: Int, CaseIterable {
    case home, explore, add, notifications, profile
    
    var title: String {
        switch self {
        case .home: return "Anasayfa"
        case .explore: return "Keşfet"
        case .add: return "Ekle"
        case .notifications: return "Bildirimler"
        case .profile: return "Profilim"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .explore: return "magnifyingglass"
        case .add: return "plus"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .add: return "plus"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
} 