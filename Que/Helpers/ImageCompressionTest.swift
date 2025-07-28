import UIKit

class ImageCompressionTest {
    
    static func testCompression(_ originalImage: UIImage) {
        print("🔍 Image Compression Test")
        print("Original image size: \(originalImage.size)")
        
        // Orijinal boyutu hesapla
        if let originalData = originalImage.jpegData(compressionQuality: 1.0) {
            let originalSize = ImageCompressionHelper.formatFileSize(originalData)
            print("Original file size: \(originalSize)")
        }
        
        // Post için sıkıştırma testi
        if let postImage = ImageCompressionHelper.compressImageForPostWithAspectRatio(originalImage),
           let postData = postImage.jpegData(compressionQuality: ImageCompressionHelper.mediumQuality) {
            let postSize = ImageCompressionHelper.formatFileSize(postData)
            print("Post compressed size (9:16): \(postSize)")
            print("Post image size: \(postImage.size)")
        }
        
        // Profil için sıkıştırma testi
        if let profileImage = ImageCompressionHelper.compressImageForProfile(originalImage),
           let profileData = ImageCompressionHelper.createJPEGDataForProfile(originalImage) {
            let profileSize = ImageCompressionHelper.formatFileSize(profileData)
            print("Profile compressed size: \(profileSize)")
            print("Profile image size: \(profileImage.size)")
        }
        
        // Thumbnail için sıkıştırma testi
        if let thumbnailImage = ImageCompressionHelper.compressImageForThumbnail(originalImage),
           let thumbnailData = thumbnailImage.jpegData(compressionQuality: ImageCompressionHelper.lowQuality) {
            let thumbnailSize = ImageCompressionHelper.formatFileSize(thumbnailData)
            print("Thumbnail compressed size: \(thumbnailSize)")
            print("Thumbnail image size: \(thumbnailImage.size)")
        }
        
        print("✅ Compression test completed")
    }
} 