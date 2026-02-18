import Foundation
import Combine
import FirebaseFirestore

@MainActor
class CategoriesViewModel: BaseViewModel {
    @Published var categories: [Category] = []
    @Published var collections: [ThemedCollection] = []
    @Published var searchQuery: String = ""
    
    private let db = FirebaseService.shared.db
    
    var filteredCategories: [Category] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return categories }
        let q = searchQuery.lowercased()
        return categories.filter {
            $0.name.lowercased().contains(q) || ($0.description?.lowercased().contains(q) ?? false)
        }
    }
    
    var filteredCollections: [ThemedCollection] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return collections }
        let q = searchQuery.lowercased()
        return collections.filter {
            $0.name.lowercased().contains(q) || $0.description.lowercased().contains(q)
        }
    }
    
    func refreshData(forceRefresh: Bool = false) {
        isLoading = true
        clearError()
        Task {
            do {
                if forceRefresh { await DataCache.shared.invalidateAll() }
                if let cached = await DataCache.shared.getCategories(), !forceRefresh {
                    categories = cached
                } else {
                    try await fetchCategories()
                    await DataCache.shared.setCategories(categories)
                }
                if let cached = await DataCache.shared.getCollections(), !forceRefresh {
                    collections = cached
                } else {
                    try await fetchCollections()
                    await DataCache.shared.setCollections(collections)
                }
                isLoading = false
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    // MARK: - Fetch Categories
    private func fetchCategories() async throws {
        let snapshot = try await db.collection(Constants.Firestore.categories).getDocuments()
        var fetchedCategories: [Category] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            // Use full URL directly from Firestore (no Storage resolution needed)
            let imageUrl = Self.extractImageUrl(from: data)
            
            fetchedCategories.append(Category(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                imageUrl: imageUrl,
                description: data["description"] as? String
            ))
        }
        
        categories = fetchedCategories.sorted { $0.name < $1.name }
    }
    
    // MARK: - Fetch Collections
    private func fetchCollections() async throws {
        let snapshot = try await db.collection(Constants.Firestore.themedCollections).getDocuments()
        var fetchedCollections: [ThemedCollection] = []
        
        for (index, document) in snapshot.documents.enumerated() {
            let data = document.data()
            
            // Use full URLs directly from Firestore (no Storage resolution needed)
            let imageUrls = Self.extractImageUrls(from: data)
            
            fetchedCollections.append(ThemedCollection(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                imageUrls: imageUrls,
                productIds: data["productIds"] as? [String] ?? [],
                order: data["order"] as? Int ?? index
            ))
        }
        
        collections = fetchedCollections.filter { !$0.id.isEmpty }.sorted { $0.order < $1.order }
    }
    
    // MARK: - Image URL Extraction Helpers
    
    /// Extracts the first valid image URL from Firestore document data.
    static func extractImageUrl(from data: [String: Any]) -> String {
        if let urls = data["imageUrls"] as? [String],
           let first = urls.first(where: { $0.hasPrefix("http") }) { return first }
        if let urls = data["images"] as? [String],
           let first = urls.first(where: { $0.hasPrefix("http") }) { return first }
        if let url = data["imageUrl"] as? String, url.hasPrefix("http") { return url }
        if let url = data["image_url"] as? String, url.hasPrefix("http") { return url }
        return ""
    }
    
    /// Extracts all valid image URLs from Firestore document data.
    static func extractImageUrls(from data: [String: Any]) -> [String] {
        if let urls = data["imageUrls"] as? [String] {
            let valid = urls.filter { $0.hasPrefix("http") }
            if !valid.isEmpty { return valid }
        }
        if let urls = data["images"] as? [String] {
            let valid = urls.filter { $0.hasPrefix("http") }
            if !valid.isEmpty { return valid }
        }
        if let url = data["imageUrl"] as? String, url.hasPrefix("http") { return [url] }
        if let url = data["image_url"] as? String, url.hasPrefix("http") { return [url] }
        return []
    }
}
