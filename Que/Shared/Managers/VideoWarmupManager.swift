import Foundation
import AVFoundation

final class VideoWarmupManager {
    static let shared = VideoWarmupManager()

    private let queue = DispatchQueue(label: "video.warmup.queue", qos: .utility)
    private var store: [URL: AVURLAsset] = [:]
    private var order: [URL] = []                // LRU sırası
    private let maxCount = 6                     // elde tutulacak en fazla asset

    private init() {}

    func warm(urls: [URL]) {
        guard !urls.isEmpty else { return }
        queue.async { [weak self] in
            guard let self else { return }
            for url in urls {
                self.warmOne(url)
            }
            self.trimIfNeeded()
        }
    }

    func asset(for url: URL) -> AVURLAsset? {
        var asset: AVURLAsset?
        queue.sync {
            asset = store[url]
            if asset != nil { self.touch(url) }
        }
        return asset
    }

    func clear() {
        queue.async { [weak self] in
            guard let self else { return }
            self.store.values.forEach { $0.cancelLoading() }
            self.store.removeAll()
            self.order.removeAll()
        }
    }

    // MARK: - Private

    private func warmOne(_ url: URL) {
        if let _ = store[url] {
            touch(url)
            return
        }
        let asset = AVURLAsset(url: url)
        store[url] = asset
        order.append(url)

        let keys = ["playable", "tracks", "duration"]
        asset.loadValuesAsynchronously(forKeys: keys) {
            // İstersen status kontrol/log ekleyebilirsin
            _ = try? asset.statusOfValue(forKey: "playable", error: nil)
        }
    }

    private func touch(_ url: URL) {
        if let i = order.firstIndex(of: url) {
            order.remove(at: i)
            order.append(url)
        }
    }

    private func trimIfNeeded() {
        while order.count > maxCount {
            let evicted = order.removeFirst()
            if let a = store.removeValue(forKey: evicted) {
                a.cancelLoading()
            }
        }
    }
}


