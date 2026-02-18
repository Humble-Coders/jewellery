import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class WishlistViewModel: BaseViewModel {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var categories: [Category] = []
    @Published var selectedFilter: String = "All"
    @Published var searchQuery: String = ""
    @Published var showFilterSheet = false
    @Published var selectedMaterialFilter: String = "All"
    @Published var selectedSortOption: SortOption = .defaultSort
    
    private let db = FirebaseService.shared.db
    
    private var categoryNameById: [String: String] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
    }
    private var wishlistProductIds: [String] = []
    
    /// Guard to prevent refetching on every tab switch
    private var hasLoadedOnce = false
    
    var filterOptions: [String] {
        ["All"] + categories.map { $0.name }
    }
    
    /// Called on view appear. Only fetches once unless forced or data is empty.
    func refreshData() {
        guard !hasLoadedOnce || products.isEmpty else { return }
        forceRefreshData()
    }
    
    /// Force a full refresh (e.g. on pull-to-refresh)
    func forceRefreshData() {
        isLoading = true
        clearError()
        
        Task {
            do {
                try await fetchCategories()
                try await fetchWishlistProducts()
                applyFilter()
                isLoading = false
                hasLoadedOnce = true
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    // MARK: - Fetch Categories (for filter pills)
    private func fetchCategories() async throws {
        if let cached = await DataCache.shared.getCategories() {
            categories = cached
            return
        }
        let snapshot = try await db.collection(Constants.Firestore.categories).getDocuments()
        var fetched: [Category] = []
        
        for document in snapshot.documents {
            let data = document.data()
            // Use full URL directly from Firestore (no Storage resolution needed)
            let imageUrl = CategoriesViewModel.extractImageUrl(from: data)
            fetched.append(Category(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                imageUrl: imageUrl,
                description: data["description"] as? String
            ))
        }
        categories = fetched.sorted { $0.name < $1.name }
        await DataCache.shared.setCategories(categories)
    }
    
    // MARK: - Fetch Wishlist (batch fetch to reduce Firestore reads)
    private func fetchWishlistProducts() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            products = []
            wishlistProductIds = []
            return
        }
        
        let wishlistSnapshot = try await db
            .collection(Constants.Firestore.users)
            .document(userId)
            .collection(Constants.Firestore.wishlist)
            .getDocuments()
        
        var productIds: [String] = []
        for doc in wishlistSnapshot.documents {
            if let pid = doc.data()["productId"] as? String {
                productIds.append(pid)
            } else {
                productIds.append(doc.documentID)
            }
        }
        wishlistProductIds = productIds
        
        guard !productIds.isEmpty else {
            products = []
            return
        }
        
        // Batch fetch products using whereField(in:) - max 30 per batch (Firestore limit)
        var fetchedProducts: [Product] = []
        let chunks = stride(from: 0, to: productIds.count, by: 30).map {
            Array(productIds[$0..<min($0 + 30, productIds.count)])
        }
        
        for chunk in chunks {
            do {
                let snapshot = try await db.collection(Constants.Firestore.products)
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                for document in snapshot.documents {
                    let data = document.data()
                    let product = await parseProduct(productId: document.documentID, data: data)
                    fetchedProducts.append(product)
                }
            } catch {
                #if DEBUG
                print("[WishlistViewModel] Batch fetch failed for chunk: \(error.localizedDescription)")
                #endif
            }
        }
        
        // Preserve the original wishlist order
        let productMap = Dictionary(uniqueKeysWithValues: fetchedProducts.map { ($0.id, $0) })
        products = productIds.compactMap { productMap[$0] }
    }
    
    // MARK: - Parse Product from Document Data
    private func parseProduct(productId: String, data: [String: Any]) async -> Product {
        // Use full URLs directly from Firestore (no Storage resolution needed)
        let imageUrls = CategoriesViewModel.extractImageUrls(from: data)
        
        let breakdown = await PriceCalculationService.shared.calculateProductPrice(productData: data)
        
        return Product(
            id: productId,
            name: data["name"] as? String ?? "",
            description: data["description"] as? String,
            price: breakdown.finalAmount,
            imageUrls: imageUrls,
            categoryId: data["categoryId"] as? String ?? data["category_id"] as? String,
            materialId: data["material_id"] as? String ?? data["materialId"] as? String,
            material: data["material"] as? String,
            weight: data["weight"] as? Double,
            inStock: data["inStock"] as? Bool ?? true,
            sku: data["sku"] as? String
        )
    }
    
    /// Unique material names extracted from loaded products
    var availableMaterials: [String] {
        let materials = Set(products.compactMap { $0.material?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        return materials.sorted()
    }
    
    func setMaterialFilter(_ material: String) {
        selectedMaterialFilter = material
        applyFilter()
    }
    
    func setSortOption(_ option: SortOption) {
        selectedSortOption = option
        applyFilter()
    }
    
    // MARK: - Filter
    func selectFilter(_ filter: String) {
        selectedFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        var result: [Product]
        if selectedFilter == "All" {
            result = products
        } else {
            let categoryId = categories.first { $0.name == selectedFilter }?.id
            result = products.filter { $0.categoryId == categoryId }
        }
        
        // Apply material filter from filter sheet
        if selectedMaterialFilter != "All" {
            result = result.filter { ($0.material ?? "").localizedCaseInsensitiveCompare(selectedMaterialFilter) == .orderedSame }
        }
        
        // Apply search filter
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            filteredProducts = result
        } else {
            filteredProducts = ProductSearchFilter.filter(result, query: searchQuery, categoryNameById: categoryNameById)
        }
        
        // Apply sort
        switch selectedSortOption {
        case .defaultSort:
            break
        case .priceLowToHigh:
            filteredProducts.sort { $0.price < $1.price }
        case .priceHighToLow:
            filteredProducts.sort { $0.price > $1.price }
        }
    }
    
    func setSearchQuery(_ query: String) {
        searchQuery = query
        applyFilter()
    }
    
    // MARK: - Remove from Wishlist (via Cloud Function) – optimistic UI
    func removeFromWishlist(productId: String) {
        let removedProducts = products.filter { $0.id == productId }
        products.removeAll { $0.id == productId }
        applyFilter()

        Task {
            do {
                _ = try await WishlistService.shared.toggleWishlist(productId: productId)
            } catch {
                products.append(contentsOf: removedProducts)
                applyFilter()
                handleError(error)
            }
        }
    }
}
