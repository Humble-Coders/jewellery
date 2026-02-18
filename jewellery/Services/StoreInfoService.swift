import Foundation
import FirebaseFirestore

actor StoreInfoService {
    static let shared = StoreInfoService()
    
    private let db = Firestore.firestore()
    
    /// Cached store info to avoid redundant Firestore reads
    private var cachedStoreInfo: StoreInfo?
    private var lastFetchTime: Date?
    private let cacheTTL: TimeInterval = 600 // 10 minutes
    
    private init() {}
    
    // MARK: - Fetch Store Info (cached)
    
    func fetchStoreInfo() async throws -> StoreInfo {
        // Return cached data if fresh
        if let cached = cachedStoreInfo,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTTL {
            return cached
        }
        
        let snapshot = try await db
            .collection("store_info")
            .document("main_store")
            .getDocument()
        
        guard snapshot.data() != nil else {
            throw NSError(domain: "StoreInfoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Store information not found"])
        }
        
        let storeInfo = try snapshot.data(as: StoreInfo.self)
        
        // Update cache
        cachedStoreInfo = storeInfo
        lastFetchTime = Date()
        
        #if DEBUG
        print("📍 Fetched and cached store info")
        #endif
        return storeInfo
    }
    
    /// Invalidate cache (e.g. on pull-to-refresh)
    func clearCache() {
        cachedStoreInfo = nil
        lastFetchTime = nil
    }
}
