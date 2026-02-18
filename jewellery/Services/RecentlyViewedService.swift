import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Service to manage recently viewed products
/// Fetches from users/{userId}/recently_viewed subcollection
class RecentlyViewedService {
    static let shared = RecentlyViewedService()
    
    private let db = Firestore.firestore()
    private let maxRecentlyViewed = 10
    
    private init() {}
    
    // MARK: - Fetch Recently Viewed Product IDs
    
    /// Fetches recently viewed product IDs for the current user
    /// - Returns: Array of product IDs ordered by view timestamp (newest first)
    func fetchRecentlyViewedIds() async throws -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else {
            // User not logged in - return empty array instead of throwing error
            #if DEBUG
            print("📱 [RecentlyViewedService] User not logged in - returning empty recently viewed list")
            #endif
            return []
        }
        
        #if DEBUG
        print("📱 [RecentlyViewedService] Fetching recently viewed for userId: \(userId)")
        #endif
        
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("recently_viewed")
            .order(by: "viewedAt", descending: true)
            .limit(to: maxRecentlyViewed)
            .getDocuments()
        
        // Extract product IDs from document IDs
        let productIds = snapshot.documents.map { $0.documentID }
        
        #if DEBUG
        print("📱 [RecentlyViewedService] Fetched \(productIds.count) recently viewed product IDs: \(productIds)")
        
        // Debug: Print each document's data
        for doc in snapshot.documents {
            print("📱 [RecentlyViewedService] Document: \(doc.documentID), Data: \(doc.data())")
        }
        #endif
        
        return productIds
    }
    
    // MARK: - Add to Recently Viewed
    
    /// Adds a product to recently viewed list
    /// - Parameter productId: The product ID to add
    func addToRecentlyViewed(productId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            // User not logged in - silently skip (don't throw error)
            #if DEBUG
            print("📱 User not logged in - skipping recently viewed tracking")
            #endif
            return
        }
        
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("recently_viewed")
            .document(productId)
        
        // Update or create the document with current timestamp
        try await docRef.setData([
            "viewedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        #if DEBUG
        print("✅ Added product \(productId) to recently viewed")
        #endif
        
        // Clean up old entries if exceeds limit
        await cleanupOldEntries(userId: userId)
    }
    
    // MARK: - Clean Up Old Entries
    
    /// Removes old entries beyond the maximum limit
    private func cleanupOldEntries(userId: String) async {
        do {
            let snapshot = try await db
                .collection("users")
                .document(userId)
                .collection("recently_viewed")
                .order(by: "viewedAt", descending: true)
                .getDocuments()
            
            // Delete documents beyond the limit
            if snapshot.documents.count > maxRecentlyViewed {
                let toDelete = snapshot.documents.dropFirst(maxRecentlyViewed)
                for doc in toDelete {
                    try await doc.reference.delete()
                }
                #if DEBUG
                print("🧹 Cleaned up \(toDelete.count) old recently viewed entries")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to cleanup old entries: \(error.localizedDescription)")
            #endif
        }
    }
    
    // MARK: - Clear Recently Viewed
    
    /// Clears all recently viewed products for the current user
    func clearRecentlyViewed() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            // User not logged in - silently skip
            #if DEBUG
            print("📱 User not logged in - skipping clear recently viewed")
            #endif
            return
        }
        
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("recently_viewed")
            .getDocuments()
        
        // Delete all documents
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
        
        #if DEBUG
        print("🗑️ Cleared all recently viewed products")
        #endif
    }
}
