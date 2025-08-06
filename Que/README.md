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
│   ├── Explore/                   # Keşfet
│   │   ├── ExploreView.swift
│   │   └── ExploreViewModel.swift
│   ├── Notifications/             # Bildirimler
│   │   ├── NotificationsView.swift
│   │   └── NotificationBadgeViewModel.swift
│   ├── Post/                      # Post oluşturma
│   │   ├── AddPostView.swift
│   │   └── AddPostViewModel.swift
│   ├── Profile/                   # Profil
│   │   ├── ProfilePage.swift
│   │   ├── ProfileViewModel.swift
│   │   ├── EditProfilePage.swift
│   │   ├── EditProfileViewModel.swift
│   │   ├── OnboardingProfilePage.swift
│   │   ├── OnboardingProfileViewModel.swift
│   │   ├── FollowersListPage.swift
│   │   └── FollowsListPage.swift
│   └── Settings/                  # Ayarlar
│       ├── SettingsPage.swift
│       └── SettingsViewModel.swift
│
├── Shared/                        # Paylaşılan bileşenler
│   ├── Components/                # Yeniden kullanılabilir bileşenler
│   │   ├── CameraOverlayView.swift
│   │   ├── CustomTabBar.swift
│   │   ├── CustomVideoPlayerView.swift
│   │   ├── LiveCameraView.swift
│   │   ├── NotificationSkeletonRow.swift
│   │   └── PostCreationView.swift
│   ├── Services/                  # Servisler
│   │   ├── Media/                 # Medya servisleri
│   │   ├── Network/               # Ağ servisleri
│   │   └── Storage/               # Depolama servisleri
│   ├── Utils/                     # Yardımcı araçlar
│   │   ├── Constants/             # Sabitler
│   │   ├── Extensions/            # Uzantılar
│   │   ├── Helpers/               # Yardımcı fonksiyonlar
│   │   ├── ImageProcessing/       # Görüntü işleme
│   │   ├── Logging/               # Loglama
│   │   └── MediaCapture/          # Medya yakalama
│   └── UI/                        # UI bileşenleri
│       ├── Components/            # UI bileşenleri
│       ├── Modifiers/             # UI değiştiricileri
│       └── Views/                 # UI görünümleri
│
└── Resources/                     # Kaynaklar
    ├── Assets.xcassets/           # Görsel kaynaklar
    └── GoogleService-Info.plist   # Firebase yapılandırması
```

## 🎬 Video Player Geliştirmeleri

### ✅ Son Güncellemeler (2024-08-06)

#### 1. **Echo Sorunu Çözümü**
- **Problem**: PostCreationView'da video sesi echo yapıyordu
- **Kök Neden**: AddPostView'da 2 adet video player aynı anda çalışıyordu
- **Çözüm**: AddPostView'da `showingPostCreation = true` olduğunda background video player'ı kaldırıldı

#### 2. **Teknik Detaylar**
```swift
// ÖNCE (Echo sorunu)
if showingPostCreation {
    if let videoURL = mediaCaptureManager.capturedVideoURL {
        CustomVideoPlayerView(videoURL: videoURL) // 1. PLAYER
    }
}
// PostCreationView içinde de video player var
// Toplam: 2 video player aynı anda çalışıyor

// SONRA (Echo çözüldü)
if showingPostCreation {
    if let videoURL = mediaCaptureManager.capturedVideoURL {
        Color.black // Sadece siyah background
    }
}
// Sadece PostCreationView içindeki video player çalışıyor
```

#### 3. **AVKit Kontrolleri Keşfi**
- **Keşfedilen Durum**: AVKit'in VideoPlayer'ı varsayılan kontroller gösteriyor
- **Kontroller**: Play/Pause, 10s ileri/geri, progress bar, hız ayarı, ses ayarı, ekran paylaşma
- **Çözüm**: UIViewRepresentable ile AVPlayerLayer kullanarak kontrolleri tamamen gizledik

#### 4. **Video Player Özellikleri**
- ✅ **Otomatik video oynatma**
- ✅ **Video loop**
- ✅ **9:16 aspect ratio**
- ✅ **Loading state**
- ✅ **Dosya varlık kontrolü**
- ✅ **Ses ayarları optimizasyonu**
- ✅ **Memory management**
- ✅ **Observer pattern düzgün implementasyonu**

#### 5. **Build Kontrolü**
- ✅ **Başarılı build**: `xcodebuild -project Que.xcodeproj -scheme Que -destination 'platform=iOS Simulator,name=iPhone 16' build`
- ✅ **Hata yok**: Tüm syntax ve logic hataları düzeltildi
- ✅ **Performans**: Video player optimize edildi

### 📋 Önceki Güncellemeler

#### 1. **CustomVideoPlayerView.swift** - Özel Video Player
- **Oluşturulma Tarihi**: 2024-08-06
- **Özellikler**:
  - Sadece Play/Pause butonu (kaldırıldı)
  - Video loop özelliği
  - 9:16 aspect ratio desteği
  - Loading state gösterimi
  - Auto-hide buton animasyonu

#### 2. **Observer Pattern** implementasyonu
- **VideoPlayerObserver**: Video durumu takibi
- **VideoPlayerManager**: ObservableObject yönetimi
- **VideoPlayerManagerObserver**: Duration tracking

#### 3. **Entegrasyon** tamamlandı
- **AddPostView.swift**: Video preview
- **PostCreationView.swift**: Video player

#### 4. **Hata Düzeltmeleri**
- Weak reference hataları çözüldü
- UIViewRepresentable syntax hataları düzeltildi
- AVAudioSession import sorunları çözüldü

### 🎯 Sonuç
- ✅ **Echo sorunu tamamen çözüldü**
- ✅ **Video player stabil çalışıyor**
- ✅ **Ses kalitesi optimize edildi**
- ✅ **Memory leak'ler önlendi**
- ✅ **Build başarılı**

---

## 📝 Notlar

Bu klasör yapısı, uygulamanın modüler ve ölçeklenebilir olmasını sağlar. Her özellik kendi klasöründe organize edilmiştir ve paylaşılan bileşenler `Shared` klasöründe bulunmaktadır. 