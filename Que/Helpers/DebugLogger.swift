import Foundation

class DebugLogger {
    static let shared = DebugLogger()
    
    private init() {}
    
    // Video işlemleri için log
    static func logVideo(_ message: String) {
        #if DEBUG
        print("🎬 Video: \(message)")
        #endif
    }
    
    // Audio işlemleri için log
    static func logAudio(_ message: String) {
        #if DEBUG
        print("🔊 Audio: \(message)")
        #endif
    }
    
    // Hata mesajları için log
    static func logError(_ message: String) {
        #if DEBUG
        print("❌ Error: \(message)")
        #endif
    }
    
    // Uyarı mesajları için log
    static func logWarning(_ message: String) {
        #if DEBUG
        print("⚠️ Warning: \(message)")
        #endif
    }
    
    // Başarı mesajları için log
    static func logSuccess(_ message: String) {
        #if DEBUG
        print("✅ Success: \(message)")
        #endif
    }
    
    // Info mesajları için log
    static func logInfo(_ message: String) {
        #if DEBUG
        print("ℹ️ Info: \(message)")
        #endif
    }
} 