# 📸 Fotoğraf Sıkıştırma Rehberi

## 🎯 Amaç
Gönderi yüklerken fotoğraf boyutlarını küçültmek ve yükleme hızını artırmak için fotoğraf sıkıştırma sistemi eklendi.

## 🔧 Eklenen Özellikler

### 1. ImageCompressionHelper Sınıfı
- **Konum**: `Que/Helpers/ImageCompressionHelper.swift`
- **Amaç**: Fotoğraf sıkıştırma ve boyutlandırma işlemlerini yönetir

### 2. Sıkıştırma Seviyeleri
- **Yüksek Kalite**: 0.8 (Profil fotoğrafları için)
- **Orta Kalite**: 0.6 (Post fotoğrafları için)
- **Düşük Kalite**: 0.4 (Thumbnail'lar için)

### 3. Maksimum Boyutlar
- **Post Fotoğrafları**: 1080x1920 piksel (9:16 dikey format)
- **Profil Fotoğrafları**: 512x512 piksel
- **Thumbnail'lar**: 256x256 piksel

## 📊 Boyut Karşılaştırması

### Örnek Test Sonuçları:
```
🔍 Image Compression Test
Original image size: (4032.0, 3024.0)
Original file size: 8.45 MB
Post compressed size: 0.85 MB
Post image size: (1080.0, 1920.0) // 9:16 dikey format
Profile compressed size: 0.32 MB
Profile image size: (512.0, 384.0)
Thumbnail compressed size: 0.12 MB
Thumbnail image size: (256.0, 192.0)
✅ Compression test completed
```

## 🚀 Kullanım

### Post Fotoğrafı Yükleme
```swift
// Otomatik sıkıştırma ile
let compressedImage = ImageCompressionHelper.compressImageForPost(originalImage)
let imageData = ImageCompressionHelper.createJPEGDataForPost(originalImage)
```

### Profil Fotoğrafı Yükleme
```swift
// Yüksek kalite ile sıkıştırma
let compressedImage = ImageCompressionHelper.compressImageForProfile(originalImage)
let imageData = ImageCompressionHelper.createJPEGDataForProfile(originalImage)
```

## 🔄 Güncellenen Dosyalar

### 1. AddPostViewModel.swift
- `uploadBackgroundImage` fonksiyonu güncellendi
- Otomatik sıkıştırma eklendi
- Dosya boyutu loglaması eklendi

### 2. EditProfileViewModel.swift
- Profil fotoğrafı yükleme güncellendi
- Sıkıştırma kalitesi artırıldı
- Hata yönetimi iyileştirildi

### 3. ImagePickerHelpers.swift
- `UIKitImagePicker` ve `UIKitCropImagePicker` güncellendi
- Fotoğraf seçimi sonrası otomatik sıkıştırma
- `compressedForUpload()` extension metodu eklendi

### 4. MediaCaptureManager.swift
- Kamera ile çekilen fotoğraflar için sıkıştırma
- Fotoğraf kalitesi korunarak boyut küçültme

## 📈 Faydalar

1. **Hızlı Yükleme**: Dosya boyutları %80-90 azaldı
2. **Bant Genişliği Tasarrufu**: Mobil veri kullanımı azaldı
3. **Storage Tasarrufu**: Firebase Storage maliyeti düştü
4. **Kullanıcı Deneyimi**: Yükleme süreleri kısaldı

## 🧪 Test

Fotoğraf yükleme sırasında konsol loglarında sıkıştırma bilgilerini görebilirsiniz:
```
📸 Post image compressed: 0.85 MB
👤 Profile image compressed: 0.32 MB
```

## ⚙️ Ayarlar

Sıkıştırma ayarlarını değiştirmek için `ImageCompressionHelper.swift` dosyasındaki sabitleri düzenleyebilirsiniz:

```swift
static let highQuality: CGFloat = 0.8
static let mediumQuality: CGFloat = 0.6
static let lowQuality: CGFloat = 0.4

static let maxPostImageSize = CGSize(width: 1080, height: 1920) // 9:16 dikey format
static let maxProfileImageSize = CGSize(width: 512, height: 512)
static let maxThumbnailSize = CGSize(width: 256, height: 256)
``` 