import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class WishlistService {
    static let shared = WishlistService()
    
    private let db = FirebaseService.shared.db
    private lazy var functions: Functions = {
        Functions.functions(region: "us-central1")
    }()
    
    /// In-memory cache of wishlist product IDs to avoid per-card Firestore reads
    private var wishlistIds: Set<String>?
    private var wishlistLoaded = false
    
    private init() {}
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isLoggedIn: Bool {
        currentUserId != nil
    }
    
    // MARK: - Load Wishlist IDs (call once on app launch / login)
    
    /// Fetches all wishlist product IDs into memory. Call this early (e.g. on home screen appear).
    func loadWishlistIds() async {
        guard let userId = currentUserId else {
            wishlistIds = []
            wishlistLoaded = true
            return
        }
        
        // Skip if already loaded
        guard !wishlistLoaded else { return }
        
        do {
            let snapshot = try await db
                .collection(Constants.Firestore.users)
                .document(userId)
                .collection(Constants.Firestore.wishlist)
                .getDocuments()
            
            wishlistIds = Set(snapshot.documents.map { $0.documentID })
            wishlistLoaded = true
            #if DEBUG
            print("[WishlistService] Loaded \(wishlistIds?.count ?? 0) wishlist IDs into memory")
            #endif
        } catch {
            #if DEBUG
            print("[WishlistService] Failed to load wishlist IDs: \(error.localizedDescription)")
            #endif
            wishlistIds = nil
            wishlistLoaded = false
        }
    }
    
    /// Force reload wishlist IDs (e.g. after login or pull-to-refresh)
    func reloadWishlistIds() async {
        wishlistLoaded = false
        await loadWishlistIds()
    }
    
    /// Clear cached wishlist IDs (e.g. on logout)
    func clearCache() {
        wishlistIds = nil
        wishlistLoaded = false
    }
    
    // MARK: - Check if in wishlist (uses in-memory cache - NO Firestore read)
    
    func isInWishlist(productId: String) -> Bool {
        return wishlistIds?.contains(productId) ?? false
    }
    
    /// Async version for backward compatibility - preloads cache if needed, then checks locally
    func isInWishlistAsync(productId: String) async -> Bool {
        if !wishlistLoaded {
            await loadWishlistIds()
        }
        return isInWishlist(productId: productId)
    }
    
    // MARK: - Add to wishlist
    func addToWishlist(productId: String) async throws {
        guard let userId = currentUserId else {
            throw WishlistError.notLoggedIn
        }
        
        try await db
            .collection(Constants.Firestore.users)
            .document(userId)
            .collection(Constants.Firestore.wishlist)
            .document(productId)
            .setData(["productId": productId])
        
        // Update local cache (initialize if nil so the update isn't a no-op)
        if wishlistIds == nil { wishlistIds = Set<String>() }
        wishlistIds?.insert(productId)
    }
    
    // MARK: - Remove from wishlist
    func removeFromWishlist(productId: String) async throws {
        guard let userId = currentUserId else {
            throw WishlistError.notLoggedIn
        }
        
        try await db
            .collection(Constants.Firestore.users)
            .document(userId)
            .collection(Constants.Firestore.wishlist)
            .document(productId)
            .delete()
        
        // Update local cache (initialize if nil so the update isn't a no-op)
        if wishlistIds == nil { wishlistIds = Set<String>() }
        wishlistIds?.remove(productId)
    }
    
    func toggleWishlistViaCloudFunction(productId: String) async throws -> Bool {
        guard let userId = currentUserId else {
            #if DEBUG
            print("[Wishlist] Cloud Function: Not called – user not logged in")
            #endif
            throw WishlistError.notLoggedIn
        }
        #if DEBUG
        print("[Wishlist] Cloud Function: Calling toggleWishlist for productId=\(productId), userId=\(userId)")
        #endif
        let params: [String: Any] = ["productId": productId]
        let result = try await functions.httpsCallable("toggleWishlist").call(params)
        let data = result.data as? [String: Any]
        let inWishlist = (data?["inWishlist"] as? Bool) ?? false
        #if DEBUG
        print("[Wishlist] Cloud Function: Success – inWishlist=\(inWishlist)")
        #endif
        
        // Update local cache based on Cloud Function result (initialize if nil)
        if wishlistIds == nil { wishlistIds = Set<String>() }
        if inWishlist {
            wishlistIds?.insert(productId)
        } else {
            wishlistIds?.remove(productId)
        }
        
        return inWishlist
    }
    
    // MARK: - Toggle wishlist (convenience) – Cloud Function with Firestore fallback
    func toggleWishlist(productId: String) async throws -> Bool {
        #if DEBUG
        print("[Wishlist] toggleWishlist called for productId=\(productId)")
        #endif
        do {
            let result = try await toggleWishlistViaCloudFunction(productId: productId)
            #if DEBUG
            print("[Wishlist] Completed via Cloud Function, inWishlist=\(result)")
            #endif
            return result
        } catch {
            #if DEBUG
            print("[Wishlist] Cloud Function failed: \(error.localizedDescription) – falling back to Firestore")
            #endif
            // Use local cache instead of Firestore read for fallback check
            let isIn = isInWishlist(productId: productId)
            if isIn {
                try await removeFromWishlist(productId: productId)
                #if DEBUG
                print("[Wishlist] Fallback: Removed from wishlist via Firestore")
                #endif
                return false
            } else {
                try await addToWishlist(productId: productId)
                #if DEBUG
                print("[Wishlist] Fallback: Added to wishlist via Firestore")
                #endif
                return true
            }
        }
    }
}

enum WishlistError: LocalizedError {
    case notLoggedIn
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Please log in to add items to your wishlist"
        }
    }
}
