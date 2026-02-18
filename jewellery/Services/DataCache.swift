import Foundation

/// Hybrid memory + disk cache for screen data
/// - Shows disk-cached data immediately (instant load)
/// - Refreshes from Firestore in background (fresh data)
/// - "Stale-while-revalidate" strategy for best UX
actor DataCache {
    static let shared = DataCache()
    
    // MARK: - In-Memory Cache
    private var categories: Cached<[Category]>?
    private var collections: Cached<[ThemedCollection]>?
    private var carouselItems: Cached<[CarouselItem]>?
    private var productsByCategory: [String: Cached<[Product]>] = [:]
    private var productsByCollection: [String: Cached<[Product]>] = [:]
    private var allProducts: Cached<[Product]>?
    
    /// TTL: 10 minutes for memory cache
    private let ttl: TimeInterval = 10 * 60
    
    // MARK: - Disk Cache
    private let fileManager = FileManager.default
    private lazy var diskCacheURL: URL? = {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dataCacheDir = cacheDir.appendingPathComponent("DataCache", isDirectory: true)
        try? fileManager.createDirectory(at: dataCacheDir, withIntermediateDirectories: true)
        return dataCacheDir
    }()
    
    private struct Cached<T> {
        let value: T
        let expiresAt: Date
    }
    
    private struct DiskCached<T: Codable>: Codable {
        let value: T
        let cachedAt: Date
    }
    
    private init() {
        #if DEBUG
        print("[DataCache] Initialized with disk cache at: \(diskCacheURL?.path ?? "nil")")
        #endif
    }
    
    // MARK: - Disk Cache Helpers
    private func saveToDisk<T: Codable>(_ value: T, key: String) {
        guard let diskCacheURL = diskCacheURL else { return }
        
        let fileURL = diskCacheURL.appendingPathComponent("\(key).json")
        let diskCached = DiskCached(value: value, cachedAt: Date())
        
        do {
            let data = try JSONEncoder().encode(diskCached)
            try data.write(to: fileURL)
            #if DEBUG
            print("[DataCache] Saved \(key) to disk")
            #endif
        } catch {
            #if DEBUG
            print("❌ [DataCache] Failed to save \(key) to disk: \(error)")
            #endif
        }
    }
    
    private func loadFromDisk<T: Codable>(key: String) -> T? {
        guard let diskCacheURL = diskCacheURL else { return nil }
        
        let fileURL = diskCacheURL.appendingPathComponent("\(key).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let diskCached = try JSONDecoder().decode(DiskCached<T>.self, from: data)
            #if DEBUG
            print("[DataCache] Loaded \(key) from disk (cached at: \(diskCached.cachedAt))")
            #endif
            return diskCached.value
        } catch {
            // File doesn't exist or decode failed - not an error, just cache miss
            return nil
        }
    }
    
    private func removeFromDisk(key: String) {
        guard let diskCacheURL = diskCacheURL else { return }
        let fileURL = diskCacheURL.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Categories
    func getCategories() -> [Category]? {
        // Check memory cache first
        if let c = categories, c.expiresAt > Date() {
            return c.value
        }
        
        // Memory cache expired, try disk cache
        categories = nil
        return loadFromDisk(key: "categories")
    }
    
    func setCategories(_ value: [Category]) {
        // Save to both memory and disk
        categories = Cached(value: value, expiresAt: Date().addingTimeInterval(ttl))
        saveToDisk(value, key: "categories")
    }
    
    // MARK: - Collections
    func getCollections() -> [ThemedCollection]? {
        // Check memory cache first
        if let c = collections, c.expiresAt > Date() {
            return c.value
        }
        
        // Memory cache expired, try disk cache
        collections = nil
        return loadFromDisk(key: "collections")
    }
    
    func setCollections(_ value: [ThemedCollection]) {
        // Save to both memory and disk
        collections = Cached(value: value, expiresAt: Date().addingTimeInterval(ttl))
        saveToDisk(value, key: "collections")
    }
    
    // MARK: - Carousel
    func getCarouselItems() -> [CarouselItem]? {
        // Check memory cache first
        if let c = carouselItems, c.expiresAt > Date() {
            return c.value
        }
        
        // Memory cache expired, try disk cache
        carouselItems = nil
        return loadFromDisk(key: "carousel_items")
    }
    
    func setCarouselItems(_ value: [CarouselItem]) {
        // Save to both memory and disk
        carouselItems = Cached(value: value, expiresAt: Date().addingTimeInterval(ttl))
        saveToDisk(value, key: "carousel_items")
    }
    
    // MARK: - Products by Category
    func getProducts(categoryId: String) -> [Product]? {
        // Check memory cache first
        if let c = productsByCategory[categoryId], c.expiresAt > Date() {
            return c.value
        }
        
        // Memory cache expired, try disk cache
        productsByCategory.removeValue(forKey: categoryId)
        return loadFromDisk(key: "products_category_\(categoryId)")
    }
    
    func setProducts(_ value: [Product], categoryId: String) {
        // Save to both memory and disk
        productsByCategory[categoryId] = Cached(value: value, expiresAt: Date().addingTimeInterval(ttl))
        saveToDisk(value, key: "products_category_\(categoryId)")
    }
    
    // MARK: - Invalidation
    func invalidateAll() {
        // Clear memory cache
        categories = nil
        collections = nil
        carouselItems = nil
        productsByCategory.removeAll()
        productsByCollection.removeAll()
        allProducts = nil
        
        // Clear disk cache
        guard let diskCacheURL = diskCacheURL else { return }
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        #if DEBUG
        print("[DataCache] Cleared all memory and disk cache")
        #endif
    }
    
    func invalidateProducts(categoryId: String) {
        productsByCategory.removeValue(forKey: categoryId)
        removeFromDisk(key: "products_category_\(categoryId)")
    }
    
    func invalidateMemoryOnly() {
        // Clear only memory cache, keep disk cache intact
        categories = nil
        collections = nil
        carouselItems = nil
        productsByCategory.removeAll()
        productsByCollection.removeAll()
        allProducts = nil
        
        #if DEBUG
        print("[DataCache] Cleared memory cache only")
        #endif
    }
    
    // MARK: - Products by Collection (for collection/carousel "See All Products")
    func getCollectionProducts(collectionKey: String) -> [Product]? {
        // Check memory cache first
        if let c = productsByCollection[collectionKey], c.expiresAt > Date() {
            return c.value
        }
        
        // Memory cache expired, try disk cache
        productsByCollection.removeValue(forKey: collectionKey)
        return loadFromDisk(key: "products_collection_\(collectionKey)")
    }
    
    func setCollectionProducts(_ value: [Product], collectionKey: String) {
        // Save to both memory and disk
        productsByCollection[collectionKey] = Cached(value: value, expiresAt: Date().addingTimeInterval(ttl))
        saveToDisk(value, key: "products_collection_\(collectionKey)")
    }
    
    func invalidateCollectionProducts(collectionKey: String) {
        productsByCollection.removeValue(forKey: collectionKey)
        removeFromDisk(key: "products_collection_\(collectionKey)")
    }
    
    // MARK: - All Products
    func getAllProducts() -> [Product]? {
        // Check memory cache first
        if let c = allProducts, c.expiresAt > Date() {
            return c.value
        }
        
        // Memory cache expired, try disk cache
        allProducts = nil
        return loadFromDisk(key: "all_products")
    }
    
    func setAllProducts(_ value: [Product]) {
        // Save to both memory and disk
        allProducts = Cached(value: value, expiresAt: Date().addingTimeInterval(ttl))
        saveToDisk(value, key: "all_products")
    }
    
    func invalidateAllProducts() {
        allProducts = nil
        removeFromDisk(key: "all_products")
    }
}

