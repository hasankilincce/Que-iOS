import Foundation
import UIKit
import SwiftUI

class MediaCacheManager: ObservableObject {
    static let shared = MediaCacheManager()
    
    @Published var cacheStatus: [String: CacheStatus] = [:]
    @Published var isLoading = false
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let backgroundQueue = DispatchQueue(label: "com.que.mediacache", qos: .background)
                    private var cleanupTimer: Timer?
    
    enum CacheStatus {
        case notCached
        case caching
        case cached
        case failed
    }
    
                    private init() {
                    // Cache ayarları
                    imageCache.countLimit = 100 // Maksimum 100 image
                    imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB limit
                    
                    // Memory pressure handling
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(handleMemoryWarning),
                        name: UIApplication.didReceiveMemoryWarningNotification,
                        object: nil
                    )
                    
                    // Otomatik cleanup timer (5 dakikada bir)
                    cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
                        self?.cleanupCache()
                    }
                }
    
                    deinit {
                    NotificationCenter.default.removeObserver(self)
                    cleanupTimer?.invalidate()
                }
    
    // MARK: - Public Methods
    
    /// Image'ı cache'e yükle
    func preloadImage(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        // Eğer zaten cache'de varsa
        if imageCache.object(forKey: urlString as NSString) != nil {
            DispatchQueue.main.async { [weak self] in
                self?.cacheStatus[urlString] = .cached
            }
            completion(true)
            return
        }
        
        // Cache status'u güncelle
        DispatchQueue.main.async { [weak self] in
            self?.cacheStatus[urlString] = .caching
        }
        
        backgroundQueue.async { [weak self] in
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    guard let self = self,
                          let data = data,
                          let image = UIImage(data: data) else {
                        self?.cacheStatus[urlString] = .failed
                        completion(false)
                        return
                    }
                    
                    // Image'ı cache'e ekle
                    self.imageCache.setObject(image, forKey: urlString as NSString)
                    self.cacheStatus[urlString] = .cached
                    completion(true)
                }
            }.resume()
        }
    }
    
    /// Cache'den image al
    func getCachedImage(for urlString: String) -> UIImage? {
        return imageCache.object(forKey: urlString as NSString)
    }
    
    /// Birden fazla image'ı preload et
    func preloadImages(from posts: [Post]) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        let imagePosts = posts.filter { post in
            post.mediaType == "image" && 
            post.mediaURL != nil &&
            cacheStatus[post.mediaURL!] != .cached
        }
        
        let group = DispatchGroup()
        
        for post in imagePosts {
            guard let mediaURL = post.mediaURL else { continue }
            
            group.enter()
            preloadImage(from: mediaURL) { success in
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    /// Aktif gönderi ve etrafındaki 2'şer gönderiyi cache'le
    func preloadImagesForActivePost(posts: [Post], activePostIndex: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        // Aktif gönderi ve etrafındaki 2'şer gönderiyi seç
        let startIndex = max(0, activePostIndex - 2)
        let endIndex = min(posts.count - 1, activePostIndex + 2)
        
        let postsToCache = Array(posts[startIndex...endIndex])
        
        let imagePosts = postsToCache.filter { post in
            post.mediaType == "image" && 
            post.mediaURL != nil
        }
        
        // Önce cache'i temizle (sadece image cache'i)
        clearImageCache()
        
        let group = DispatchGroup()
        
        for post in imagePosts {
            guard let mediaURL = post.mediaURL else { continue }
            
            group.enter()
            preloadImage(from: mediaURL) { success in
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    /// Sadece image cache'ini temizle
    private func clearImageCache() {
        DispatchQueue.main.async { [weak self] in
            self?.imageCache.removeAllObjects()
            self?.cacheStatus.removeAll()
        }
    }
    
    /// Cache'i temizle
    func clearCache() {
        DispatchQueue.main.async { [weak self] in
            self?.imageCache.removeAllObjects()
            self?.cacheStatus.removeAll()
        }
    }
    
    /// Cache durumunu kontrol et
    func isImageCached(for urlString: String) -> Bool {
        return imageCache.object(forKey: urlString as NSString) != nil
    }
    
    /// Cache istatistikleri
    var cacheStats: (count: Int, totalCost: Int) {
        return (imageCache.totalCostLimit, imageCache.totalCostLimit)
    }
    
    // MARK: - Private Methods
    
    @objc private func handleMemoryWarning() {
        // Memory warning geldiğinde cache'i temizle
        DispatchQueue.main.async { [weak self] in
            self?.imageCache.removeAllObjects()
            self?.cacheStatus.removeAll()
        }
    }
    
    private func cleanupCache() {
        // Eski cache'leri temizle
        // Burada daha gelişmiş cleanup logic eklenebilir
    }
}

// MARK: - CachedAsyncImage SwiftUI View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var cacheManager = MediaCacheManager.shared
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        let urlString = url.absoluteString
        
        // Önce cache'den kontrol et
        if let cachedImage = cacheManager.getCachedImage(for: urlString) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        // Cache'de yoksa yükle
        cacheManager.preloadImage(from: urlString) { success in
            DispatchQueue.main.async {
                if success {
                    self.image = self.cacheManager.getCachedImage(for: urlString)
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Convenience Initializers

            extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
                init(url: URL?) {
                    self.init(
                        url: url,
                        content: { image in
                            image
                        },
                        placeholder: { 
                            AnyView(Color.gray.opacity(0.3)) 
                        }
                    )
                }
            } 