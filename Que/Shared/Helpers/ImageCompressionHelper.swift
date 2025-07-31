import UIKit

class ImageCompressionHelper {
    
    // MARK: - Compression Quality Constants
    static let highQuality: CGFloat = 0.8
    static let mediumQuality: CGFloat = 0.6
    static let lowQuality: CGFloat = 0.4
    
    // MARK: - Size Constants
    static let maxPostImageSize = CGSize(width: 1080, height: 1920) // 9:16 dikey format
    static let maxProfileImageSize = CGSize(width: 512, height: 512)
    static let maxThumbnailSize = CGSize(width: 256, height: 256)
    
    // MARK: - Public Methods
    
    /// Post için fotoğraf sıkıştırma ve boyutlandırma
    static func compressImageForPost(_ image: UIImage) -> UIImage? {
        return compressAndResizeImage(image, 
                                   maxSize: maxPostImageSize, 
                                   quality: mediumQuality)
    }
    
    /// 9:16 format için özel sıkıştırma
    static func compressImageForPostWithAspectRatio(_ image: UIImage) -> UIImage? {
        // Önce fotoğrafı 9:16 oranında kırp
        let croppedImage = cropToAspectRatio(image, targetRatio: 9.0/16.0)
        return compressAndResizeImage(croppedImage, 
                                   maxSize: maxPostImageSize, 
                                   quality: mediumQuality)
    }
    
    /// Profil fotoğrafı için sıkıştırma ve boyutlandırma
    static func compressImageForProfile(_ image: UIImage) -> UIImage? {
        return compressAndResizeImage(image, 
                                   maxSize: maxProfileImageSize, 
                                   quality: highQuality)
    }
    
    /// Thumbnail için sıkıştırma ve boyutlandırma
    static func compressImageForThumbnail(_ image: UIImage) -> UIImage? {
        return compressAndResizeImage(image, 
                                   maxSize: maxThumbnailSize, 
                                   quality: lowQuality)
    }
    
    /// JPEG data'ya çevirme
    static func convertToJPEGData(_ image: UIImage, quality: CGFloat = mediumQuality) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    /// Post için JPEG data oluşturma
    static func createJPEGDataForPost(_ image: UIImage) -> Data? {
        let compressedImage = compressImageForPost(image)
        return compressedImage?.jpegData(compressionQuality: mediumQuality)
    }
    
    /// Profil için JPEG data oluşturma
    static func createJPEGDataForProfile(_ image: UIImage) -> Data? {
        let compressedImage = compressImageForProfile(image)
        return compressedImage?.jpegData(compressionQuality: highQuality)
    }
    
    // MARK: - Private Methods
    
    private static func compressAndResizeImage(_ image: UIImage, 
                                             maxSize: CGSize, 
                                             quality: CGFloat) -> UIImage? {
        
        // Önce boyutlandır
        let resizedImage = resizeImage(image, to: maxSize)
        
        // Sonra sıkıştır
        guard let imageData = resizedImage.jpegData(compressionQuality: quality),
              let compressedImage = UIImage(data: imageData) else {
            return nil
        }
        
        return compressedImage
    }
    
    private static func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let originalSize = image.size
        
        // Aspect ratio'yu koru
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        // Eğer resim zaten küçükse, boyutlandırma yapma
        if ratio >= 1.0 {
            return image
        }
        
        let newSize = CGSize(width: originalSize.width * ratio, 
                           height: originalSize.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Utility Methods
    
    /// Fotoğrafı belirli bir aspect ratio'ya kırp
    private static func cropToAspectRatio(_ image: UIImage, targetRatio: CGFloat) -> UIImage {
        let imageSize = image.size
        let imageRatio = imageSize.width / imageSize.height
        
        var cropRect: CGRect
        
        if imageRatio > targetRatio {
            // Fotoğraf daha geniş, yüksekliği koru
            let newWidth = imageSize.height * targetRatio
            let x = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Fotoğraf daha yüksek, genişliği koru
            let newHeight = imageSize.width / targetRatio
            let y = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: imageSize.width, height: newHeight)
        }
        
        // Core Graphics ile kırpma
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Dosya boyutunu MB cinsinden hesapla
    static func getImageFileSize(_ imageData: Data) -> Double {
        return Double(imageData.count) / (1024 * 1024)
    }
    
    /// Dosya boyutunu string olarak formatla
    static func formatFileSize(_ data: Data) -> String {
        let sizeInMB = getImageFileSize(data)
        return String(format: "%.2f MB", sizeInMB)
    }
} 