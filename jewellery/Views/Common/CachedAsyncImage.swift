import SwiftUI
import SDWebImageSwiftUI

/// Type alias for WebImage - provides automatic disk caching and retry
/// Just use WebImage directly from SDWebImageSwiftUI
typealias CachedAsyncImage = WebImage

/// Configure SDWebImage global settings
enum ImageCacheConfiguration {
    static func configure() {
        let imageCache = SDImageCache.shared
        
        // Memory cache configuration
        imageCache.config.maxMemoryCost = 50 * 1024 * 1024 // 50MB memory cache
        imageCache.config.maxMemoryCount = 100 // Max 100 images in memory
        
        // Disk cache configuration
        imageCache.config.maxDiskSize = 200 * 1024 * 1024 // 200MB disk cache
        imageCache.config.maxDiskAge = 7 * 24 * 60 * 60 // 7 days
        imageCache.config.diskCacheExpireType = .accessDate // Based on last access
        
        // Download configuration
        SDWebImageDownloader.shared.config.downloadTimeout = 30 // 30 seconds timeout
        SDWebImageDownloader.shared.config.maxConcurrentDownloads = 6 // Max 6 parallel downloads
        
        #if DEBUG
        print("[ImageCache] Configured - Memory: 50MB, Disk: 200MB, Expiry: 7 days")
        #endif
    }
    
    /// Clear all image caches (memory + disk)
    static func clearAll() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        #if DEBUG
        print("[ImageCache] Cleared all caches")
        #endif
    }
    
    /// Clear only memory cache (keep disk cache)
    static func clearMemory() {
        SDImageCache.shared.clearMemory()
        #if DEBUG
        print("[ImageCache] Cleared memory cache")
        #endif
    }
}
