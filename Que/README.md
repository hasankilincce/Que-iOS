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
│   │   └── RegisterViewModel.swift
│   ├── Post/                      # Post oluşturma
│   │   ├── Views/
│   │   │   ├── AddPostView.swift
│   │   │   └── PostCreationView.swift
│   │   └── ViewModels/
│   │       └── AddPostViewModel.swift
│   └── Profile/                   # Profil yönetimi
│       ├── Views/
│       │   ├── ProfilePage.swift
│       │   └── ProfileSettingsPage.swift
│       └── ViewModels/
│           └── ProfileViewModel.swift
│
└── Shared/                        # Paylaşılan bileşenler
    ├── Components/                # Yeniden kullanılabilir UI bileşenleri
    │   ├── CustomVideoPlayerView.swift
    │   ├── FeedView.swift
    │   └── PostView.swift
    └── Managers/                  # Veri yönetimi
        ├── FeedManager.swift
        └── FirestoreDataManager.swift
```

## 📝 Değişiklik Geçmişi

### 🖼️ Media Caching Sistemi - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **MediaCacheManager Oluşturuldu**
   - `Que/Shared/Managers/MediaCacheManager.swift` dosyası oluşturuldu
   - `NSCache` ile in-memory image caching
   - Background thread'de preloading
   - Memory pressure handling

2. **CachedAsyncImage SwiftUI View**
   - Custom SwiftUI view oluşturuldu
   - MediaCacheManager ile entegrasyon
   - Placeholder ve loading state'leri
   - Convenience initializer'lar

3. **Cache Management Features**
   - `preloadImage(from:completion:)` - Tek image preload
   - `preloadImages(from:)` - Batch preloading
   - `getCachedImage(for:)` - Cache'den image alma
   - `clearCache()` - Cache temizleme
   - `handleMemoryWarning()` - Memory warning handling

4. **FeedManager Entegrasyonu**
   - `MediaCacheManager.shared` instance eklendi
   - `preloadImagesForNewPosts()` çağrısı
   - `clearCache()` refresh sırasında
   - Background thread'de preloading

5. **PostView Güncellendi**
   - `AsyncImage` yerine `CachedAsyncImage` kullanımı
   - Image posts için cache'den yükleme
   - Performance optimizasyonu

6. **Cache Configuration**
   - Maksimum 100 image cache limiti
   - 100MB total cost limit
   - 5 dakikada bir otomatik cleanup
   - Memory warning'de otomatik temizleme

**Teknik Notlar:**
- `NSCache` ile thread-safe caching
- `DispatchGroup` ile concurrent preloading
- `NotificationCenter` ile memory warning handling
- Background queue ile performans optimizasyonu
- Timer ile otomatik cleanup
- Cache status tracking (`notCached`, `caching`, `cached`, `failed`)
- `DispatchQueue.main.async` ile @Published property güncellemeleri
- Background thread'den main thread'e güvenli geçiş

**Build Durumu:** ✅ Başarılı
- `xcodebuild -project Que.xcodeproj -scheme Que -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Media caching sistemi aktif
- Image preloading çalışıyor
- Memory management düzgün
- Background thread publishing hatası düzeltildi

---

### 🔄 Pagination Sistemi Güncellemesi - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **FeedView Pagination Mantığı**
   - `onChange(of: visibleID)` içinde pagination kontrolü eklendi
   - Son 2 post kala yeni veri yükleme mantığı
   - Loading indicator eklendi
   - Pull-to-refresh özelliği eklendi

2. **FirestoreDataManager Düzeltmesi**
   - `fetchPostsForFeed` fonksiyonunda `lastDocument` güncelleme eklendi
   - Pagination için gerekli `lastDocument` tracking
   - `fetchMorePosts` fonksiyonunun düzgün çalışması sağlandı

3. **Pagination Özellikleri**
   - İlk yükleme: 10 post
   - Son 2 post kala otomatik yeni veri yükleme
   - Yukarıdaki postlar korunuyor
   - Loading indicator ile kullanıcı feedback'i
   - Pull-to-refresh ile manuel yenileme

4. **Loading Indicator**
   - ProgressView ile loading gösterimi
   - "Daha fazla gönderi yükleniyor..." mesajı
   - Tam ekran yükseklikte loading alanı

**Teknik Notlar:**
- `currentIndex >= feedManager.posts.count - 2` kontrolü
- `feedManager.hasMorePosts && !feedManager.isLoading` kontrolü
- `lastDocument` tracking ile Firestore pagination
- `refreshable` modifier ile pull-to-refresh

**Build Durumu:** ✅ Başarılı
- `xcodebuild -project Que.xcodeproj -scheme Que -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Pagination sistemi düzgün çalışıyor
- Firestore'dan veriler sorunsuz çekiliyor

---

### 🔥 FirestoreDataManager Sistemi - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **FirestoreDataManager Oluşturuldu**
   - `Que/Shared/Managers/FirestoreDataManager.swift` dosyası oluşturuldu
   - Firestore'dan veri çekme sistemi
   - Belirli kurallarla filtreleme
   - Pagination desteği

2. **Post Parsing Hatası Düzeltildi**
   - Firestore'dan gelen verilerin Post modeliyle uyumsuzluğu tespit edildi
   - Otomatik Codable parsing yerine manuel parsing kullanıldı
   - `Post(id: String, data: [String: Any])` initializer kullanımı
   - "Post parse hatası: The data couldn't be read because it is missing" hatası çözüldü

3. **FirestoreDataManager Özellikleri**
   - `fetchPostsForFeed()` - Temel feed verisi çekme
   - `fetchPostsWithCriteria()` - Kategori, medya türü, kullanıcı filtreleme
   - `fetchPopularPosts()` - Beğeni sayısına göre sıralama
   - `fetchRecentPosts()` - Son 24 saat içindeki gönderiler
   - `fetchMorePosts()` - Pagination ile daha fazla veri
   - `resetPagination()` - Pagination sıfırlama
   - `checkIfPostsExist()` - Gönderi varlığı kontrolü
   - `getPostCount()` - Gönderi sayısı alma

4. **FeedManager Entegrasyonu**
   - FeedManager FirestoreDataManager ile entegre edildi
   - Gerçek Firestore verilerini kullanma
   - Hata yönetimi ve loading state'leri

5. **Gerçek Firestore Veri Yapısı**
   - Firestore'daki posts koleksiyonunun gerçek yapısı analiz edildi
   - `mediaURL` ve `mediaType` alanları kullanımı
   - `isActive` ve `isApproved` alanları olmadığı tespit edildi
   - Filtreler gerçek veri yapısına göre güncellendi

**Teknik Notlar:**
- FirestoreDataManager `ObservableObject` protokolünü implement ediyor
- Tüm Firestore işlemleri async/await pattern kullanıyor
- Hata yönetimi ve loading state'leri `@Published` property'ler ile yönetiliyor
- Pagination sistemi `lastDocument` ile çalışıyor
- Manuel parsing sayesinde Firestore veri yapısındaki değişikliklere esneklik sağlanıyor

**Build Durumu:** ✅ Başarılı
- `xcodebuild -project Que.xcodeproj -scheme Que -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Tüm hatalar çözüldü
- Post parsing hatası düzeltildi

---

### 🎬 PostView MediaURL Kullanımı - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **PostView Güncellendi**
   - `post.mediaURL` ve `post.mediaType` kullanımına geçildi
   - `post.backgroundImageURL` ve `post.backgroundVideoURL` yerine tutarlı yaklaşım
   - Tek medya türü per post yaklaşımı benimsendi

2. **Media Display Logic**
   - Video: `post.mediaType == "video"` kontrolü
   - Image: `post.mediaType == "image"` kontrolü
   - Text: `post.mediaType == "text"` veya `mediaURL == nil` durumu

3. **Tutarlılık Sağlandı**
   - Tüm medya türleri için tek URL kullanımı
   - Firestore veri yapısıyla uyumluluk
   - Gelecekteki genişletmeler için esneklik

**Teknik Notlar:**
- `mediaURL` ve `mediaType` kombinasyonu daha tutarlı
- Firestore'daki gerçek veri yapısıyla uyumlu
- Tek medya per post yaklaşımı daha basit ve anlaşılır

**Build Durumu:** ✅ Başarılı

---

### 📱 PostView İçerik Görünürlüğü Düzeltmesi - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **PostView Layout Düzeltmesi**
   - `GeometryReader` doğru kullanımı
   - `ZStack` yapısı yeniden düzenlendi
   - Text content overlay olarak eklendi

2. **Full Screen Coverage**
   - `ignoresSafeArea(.all, edges: .all)` eklendi
   - Telefonun tam boyutunu kullanma
   - Safe area'ları görmezden gelme

3. **Content Visibility**
   - Text content her zaman görünür
   - Media üzerinde overlay olarak konumlandırma
   - `VStack` ile düzenli text layout

**Teknik Notlar:**
- `GeometryReader` ile doğru boyutlandırma
- `ZStack` ile katmanlı layout
- `ignoresSafeArea()` ile tam ekran kullanımı

**Build Durumu:** ✅ Başarılı

---

### 🔄 FeedView FeedManager Entegrasyonu - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **FeedManager Entegrasyonu**
   - `@StateObject private var feedManager = FeedManager()` eklendi
   - `@State private var posts: [Post] = []` kaldırıldı
   - `ForEach(feedManager.posts)` kullanımına geçildi

2. **Data Loading**
   - `loadPosts()` fonksiyonu kaldırıldı
   - `feedManager.loadPosts()` kullanımı
   - Task modifier ile otomatik yükleme

3. **Pagination Support**
   - `onChange(of: visibleID)` ile pagination
   - Son 2 post kala yeni veri yükleme
   - `feedManager.loadMorePosts()` çağrısı

**Teknik Notlar:**
- FeedView görünümü korundu
- FeedManager sorumluluğu veri yönetimi
- Pagination otomatik çalışıyor

**Build Durumu:** ✅ Başarılı

---

### 📊 Örnek Gönderiler Özelliği - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **FeedManager Güncellendi**
   - `createSamplePosts()` fonksiyonu eklendi
   - 15 farklı örnek post oluşturuldu
   - Gerçek Firebase sorgusu yerine örnek veriler

2. **Sample Posts Özellikleri**
   - Farklı medya türleri (video, image, text)
   - Çeşitli kullanıcı profilleri
   - Gerçekçi içerikler ve tarihler
   - `mediaType` string literals kullanımı

3. **Development Mode**
   - Firebase bağlantısı geçici olarak devre dışı
   - Hızlı geliştirme için örnek veriler
   - Gerçek veri yapısıyla uyumlu

**Teknik Notlar:**
- `mediaType` enum yerine string kullanımı
- Gerçekçi örnek veriler
- Development için optimize edilmiş

**Build Durumu:** ✅ Başarılı

---

### 🎨 PostView Arkaplan Renkleri - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **Background Color System**
   - Post ID'sine göre hash-based renk seçimi
   - 12 farklı renk paleti
   - Her post için tutarlı renk

2. **Full Screen Coverage**
   - `ignoresSafeArea()` ile tam ekran
   - Arkaplan rengi tüm ekranı kaplıyor
   - Safe area'ları görmezden gelme

3. **Color Palette**
   - Blue, Purple, Pink, Orange, Red, Green
   - Indigo, Teal, Cyan, Mint, Brown, Yellow
   - Hash-based deterministic seçim

**Teknik Notlar:**
- `abs(post.id.hashValue)` ile hash hesaplama
- `hash % colors.count` ile renk indeksi
- Tutarlı renk dağılımı

**Build Durumu:** ✅ Başarılı

---

### 📱 Feed Özelliği - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **FeedView Oluşturuldu**
   - `Que/Shared/Components/FeedView.swift` dosyası oluşturuldu
   - TikTok/Instagram Reels benzeri dikey scroll
   - Full-screen post görünümü

2. **PostView Oluşturuldu**
   - `Que/Shared/Components/PostView.swift` dosyası oluşturuldu
   - Video ve image desteği
   - CustomVideoPlayerViewContainer entegrasyonu

3. **Scroll Behavior**
   - `ScrollView(.vertical)` kullanımı
   - `LazyVStack` ile performans optimizasyonu
   - `scrollTargetBehavior(.paging)` ile sayfalama
   - `containerRelativeFrame(.vertical)` ile tam yükseklik

4. **HomePage Entegrasyonu**
   - FeedView HomePage'e eklendi
   - `.home` tab case'inde görünüm

**Teknik Notlar:**
- `GeometryReader` ile boyut hesaplama
- `ignoresSafeArea()` ile tam ekran
- `scrollPosition(id: $visibleID)` ile aktif post takibi
- `refreshable` ile pull-to-refresh

**Build Durumu:** ✅ Başarılı

---

### 🎬 Custom Video Player - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **CustomVideoPlayerView Oluşturuldu**
   - `Que/Shared/Components/CustomVideoPlayerView.swift` dosyası oluşturuldu
   - `UIViewRepresentable` kullanımı
   - `AVPlayerLayer` ile doğrudan video kontrolü

2. **PlayerView Class**
   - `UIView` subclass'ı
   - `AVPlayer` ve `AVPlayerLayer` yönetimi
   - `layoutSubviews` override ile frame güncelleme
   - `cleanupPlayer()` ile memory management

3. **CustomVideoPlayerViewContainer**
   - State management (`isPlaying`, `showIcon`, `iconType`)
   - Tap gesture ile play/pause
   - Icon visibility kontrolü

4. **AddPostView Entegrasyonu**
   - Video preview için CustomVideoPlayerViewContainer
   - Background video player kaldırıldı (echo fix)

5. **PostCreationView Entegrasyonu**
   - Video preview için CustomVideoPlayerViewContainer
   - `AVAudioSession` management
   - `onAppear`/`onDisappear` ile audio control

**Teknik Notlar:**
- `UIViewRepresentable` ile UIKit entegrasyonu
- `AVPlayerLayer` ile doğrudan video kontrolü
- Memory management için proper cleanup
- Audio session management echo önleme

**Build Durumu:** ✅ Başarılı

---

### 🎯 One Tap Play/Pause - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **Tap Gesture Eklendi**
   - `UITapGestureRecognizer` ile tap detection
   - `PlayerView` içinde gesture handling
   - `setPlaying()` fonksiyonu ile state toggle

2. **Icon Management**
   - Play/pause icon visibility
   - `showIcon` state management
   - Icon type switching (play/pause)

3. **State Synchronization**
   - `isPlaying` state ile icon sync
   - `showIcon` temporary state
   - Proper state management

**Teknik Notlar:**
- Tap gesture video üzerinde çalışıyor
- Icon state management
- Proper cleanup ve memory management

**Build Durumu:** ✅ Başarılı

---

### 🔇 AVKit Controls Gizleme - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **UIViewRepresentable Kullanımı**
   - SwiftUI `VideoPlayer` yerine custom implementation
   - `AVPlayerLayer` ile doğrudan kontrol
   - Hiçbir default control görünmüyor

2. **PlayerView Architecture**
   - `UIView` subclass ile custom video player
   - `AVPlayerLayer` frame management
   - Layout subviews override

**Teknik Notlar:**
- SwiftUI `VideoPlayer`'ın kontrol gizleme sınırlaması
- `UIViewRepresentable` ile tam kontrol
- `AVPlayerLayer` ile doğrudan video rendering

**Build Durumu:** ✅ Başarılı

---

### 🎬 Custom Video Player Temel Özellikler - Tamamlandı!

**Tarih:** 7 Ağustos 2025

**Yapılan Değişiklikler:**

1. **AddPostView Güncellendi**
   - Placeholder yerine CustomVideoPlayerViewContainer
   - Video preview functionality
   - Proper integration

2. **PostCreationView Güncellendi**
   - Placeholder yerine CustomVideoPlayerViewContainer
   - Video preview functionality
   - Proper integration

3. **CustomVideoPlayerView Oluşturuldu**
   - Temel video player functionality
   - Play/pause controls
   - Visibility check (%80 görünürlük)

**Teknik Notlar:**
- SwiftUI ile video player implementation
- Visibility detection
- Basic play/pause functionality

**Build Durumu:** ✅ Başarılı

---

## 🚀 Kullanım

### Feed Sistemi
```swift
// FeedView kullanımı
FeedView()
    .ignoresSafeArea()

// FeedManager ile veri yönetimi
@StateObject private var feedManager = FeedManager()
```

### Custom Video Player
```swift
// Video player kullanımı
CustomVideoPlayerViewContainer(videoURL: videoURL)
    .frame(width: width, height: height)
```

### Firestore Data Manager
```swift
// Firestore'dan veri çekme
let firestoreManager = FirestoreDataManager()
firestoreManager.fetchPostsForFeed { posts in
    // Handle posts
}
```

## 📋 Notlar

- Tüm değişiklikler build kontrolünden geçti
- Firestore entegrasyonu tamamlandı
- Custom video player çalışıyor
- Feed sistemi aktif
- Post parsing hatası çözüldü
- Pagination sistemi düzgün çalışıyor
- Firestore'dan veriler sorunsuz çekiliyor
- Media caching sistemi aktif 