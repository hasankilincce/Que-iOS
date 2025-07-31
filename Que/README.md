# Que iOS App - Klasör Yapısı

Bu dosya, Que iOS uygulamasının yeni organize edilmiş klasör yapısını açıklar.

## 📁 Yeni Klasör Yapısı

```
Que/
├── Core/                           # Uygulama çekirdek bileşenleri
│   ├── Models/                     # Veri modelleri
│   │   ├── Item.swift
│   │   ├── NotificationItem.swift
│   │   ├── Post.swift
│   │   ├── ProfileListUser.swift
│   │   └── TabType.swift
│   ├── ViewModels/                 # Ana ViewModels
│   │   └── HomeViewModel.swift
│   ├── Views/                      # Ana görünümler
│   │   └── HomePage.swift
│   └── QueApp.swift               # Uygulama giriş noktası
│
├── Features/                       # Özellik bazlı modüller
│   ├── Auth/                      # Kimlik doğrulama
│   │   ├── LoginPage.swift
│   │   ├── LoginViewModel.swift
│   │   ├── RegisterPage.swift
│   │   ├── RegisterViewModel.swift
│   │   ├── ResetPasswordPage.swift
│   │   └── ResetPasswordViewModel.swift
│   │
│   ├── Feed/                      # Ana akış
│   │   ├── FeedView.swift
│   │   ├── FeedViewModel.swift
│   │   └── FullScreenFeedView.swift
│   │
│   ├── Profile/                   # Profil yönetimi
│   │   ├── ProfilePage.swift
│   │   ├── ProfileViewModel.swift
│   │   ├── EditProfilePage.swift
│   │   ├── EditProfileViewModel.swift
│   │   ├── OnboardingProfilePage.swift
│   │   ├── OnboardingProfileViewModel.swift
│   │   ├── FollowersListPage.swift
│   │   └── FollowsListPage.swift
│   │
│   ├── Explore/                   # Keşfet özelliği
│   │   ├── ExploreView.swift
│   │   └── ExploreViewModel.swift
│   │
│   ├── Notifications/             # Bildirimler
│   │   ├── NotificationsView.swift
│   │   └── NotificationBadgeViewModel.swift
│   │
│   ├── Post/                      # Gönderi oluşturma
│   │   ├── AddPostView.swift
│   │   └── AddPostViewModel.swift
│   │
│   └── Settings/                  # Ayarlar
│       ├── SettingsPage.swift
│       └── SettingsViewModel.swift
│
└── Shared/                        # Paylaşılan bileşenler
    ├── Components/                # Yeniden kullanılabilir UI bileşenleri
    │   ├── BackgroundVideoView.swift
    │   ├── CameraOverlayView.swift
    │   ├── CustomTabBar.swift
    │   ├── FullScreenVideoPlayerView.swift
    │   ├── LiveCameraView.swift
    │   ├── NotificationSkeletonRow.swift
    │   ├── PostCreationView.swift
    │   ├── PostSkeletonView.swift
    │   ├── ShimmerModifier.swift
    │   ├── ShimmerView.swift
    │   ├── VideoPlayerView.swift
    │   └── VideoPostView.swift
    │
    ├── Helpers/                   # Yardımcı sınıflar
    │   ├── AudioSessionManager.swift
    │   ├── CameraManager.swift
    │   ├── DebugLogger.swift
    │   ├── ImageCompressionHelper.swift
    │   ├── ImageCompressionTest.swift
    │   ├── ImagePickerHelpers.swift
    │   ├── MediaCaptureManager.swift
    │   ├── MediaControlManager.swift
    │   ├── URLCacheManager.swift
    │   ├── VideoManager.swift
    │   └── VideoPlayerManager.swift
    │
    └── Utilities/                 # Yardımcı araçlar (boş)
```

## 🎯 Organizasyon Prensipleri

### **Core/** 
- Uygulamanın temel bileşenleri
- Ana giriş noktası ve modeller
- Tüm özellikler tarafından kullanılan ortak ViewModels

### **Features/**
- Her özellik kendi klasöründe
- Her özellik kendi Views ve ViewModels'ini içerir
- Modüler yapı sayesinde kolay bakım

### **Shared/**
- Tüm özellikler tarafından kullanılan bileşenler
- Yeniden kullanılabilir UI bileşenleri
- Yardımcı sınıflar ve araçlar

## 🔄 Değişiklik Özeti

✅ **Taşınan Dosyalar:**
- Models → Core/Models
- Ana ViewModels → Core/ViewModels  
- HomePage → Core/Views
- Auth ile ilgili dosyalar → Features/Auth
- Feed ile ilgili dosyalar → Features/Feed
- Profile ile ilgili dosyalar → Features/Profile
- Explore ile ilgili dosyalar → Features/Explore
- Notifications ile ilgili dosyalar → Features/Notifications
- Post ile ilgili dosyalar → Features/Post
- Settings ile ilgili dosyalar → Features/Settings
- Components → Shared/Components
- Helpers → Shared/Helpers

✅ **Temizlenen Klasörler:**
- Eski Models, Views, ViewModels, Helpers klasörleri kaldırıldı

## 📈 Faydalar

1. **Modüler Yapı**: Her özellik kendi klasöründe
2. **Kolay Navigasyon**: Dosyaları bulmak daha kolay
3. **Ölçeklenebilirlik**: Yeni özellikler kolayca eklenebilir
4. **Bakım Kolaylığı**: İlgili dosyalar bir arada
5. **Takım Çalışması**: Farklı geliştiriciler farklı özellikler üzerinde çalışabilir

## 🚀 Kullanım

Bu yapı sayesinde:
- Yeni bir özellik eklemek için sadece Features/ altında yeni klasör oluşturun
- Ortak bileşenler Shared/ altına ekleyin
- Core/ altındaki dosyalar tüm uygulama için ortak 