import Foundation

class URLCacheManager {
    static let shared = URLCacheManager()
    
    private let cache: URLCache
    
    private init() {
        // 20MB memory, 200MB disk cache
        cache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "hlsCache"
        )
    }
    
    func getURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        // Network timeout'ları artır
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        // Custom headers for video requests
        config.httpAdditionalHeaders = [
            "User-Agent": "QueApp/1.0"
        ]
        
        return config
    }
    
    // Signed URL'yi public URL'ye çevir
    func convertSignedURLToPublic(_ signedURL: String) -> String {
        // Firebase Storage signed URL'den public URL'ye çevir
        // Örnek: https://firebasestorage.googleapis.com/v0/b/queapp-fb.appspot.com/o/post_videos%2F...?alt=media&token=...
        // Public: https://storage.googleapis.com/queapp-fb.firebasestorage.app/post_videos/...
        
        guard let url = URL(string: signedURL) else { return signedURL }
        
        // Firebase Storage URL'sini kontrol et
        if url.host?.contains("firebasestorage.googleapis.com") == true {
            // URL'den path'i çıkar
            let pathComponents = url.pathComponents
            
            // post_videos/... kısmını bul
            if let postVideosIndex = pathComponents.firstIndex(of: "o"),
               postVideosIndex + 1 < pathComponents.count {
                let encodedPath = pathComponents[postVideosIndex + 1]
                
                // URL decode
                let decodedPath = encodedPath.removingPercentEncoding ?? encodedPath
                
                // Public URL oluştur
                let publicURL = "https://storage.googleapis.com/queapp-fb.firebasestorage.app/\(decodedPath)"
                
                print("🔄 Converting signed URL to public: \(publicURL)")
                return publicURL
            }
        }
        
        return signedURL
    }
    
    func clearCache() {
        cache.removeAllCachedResponses()
    }
    
    func getCacheSize() -> Int {
        return cache.memoryCapacity + cache.diskCapacity
    }
} 