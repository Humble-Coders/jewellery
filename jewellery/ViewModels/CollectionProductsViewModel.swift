import Foundation
import Combine
import FirebaseFirestore

@MainActor
class CollectionProductsViewModel: BaseViewModel {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var showFilterSheet = false
    @Published var searchQuery: String = ""
    @Published var selectedMaterialFilter: String = "All"
    @Published var selectedSortOption: SortOption = .defaultSort
    
    private let db = FirebaseService.shared.db
    private let productIds: [String]
    private let collectionTitle: String
    
    /// Cache key for this collection's products
    private var collectionKey: String {
        "collection_\(collectionTitle)"
    }
    
    init(productIds: [String], collectionTitle: String) {
        self.productIds = productIds
        self.collectionTitle = collectionTitle
        super.init()
    }
    
    func loadData() {
        isLoading = true
        clearError()
        Task {
            do {
                if let cached = await DataCache.shared.getCollectionProducts(collectionKey: collectionKey) {
                    products = cached
                    applySearchFilter()
                    isLoading = false
                    return
                }
                try await fetchProducts()
                await DataCache.shared.setCollectionProducts(products, collectionKey: collectionKey)
                isLoading = false
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    func refreshData() {
        Task {
            await DataCache.shared.invalidateCollectionProducts(collectionKey: collectionKey)
        }
        loadData()
    }
    
    // MARK: - Fetch Products by IDs (batch fetch to reduce Firestore reads)
    private func fetchProducts() async throws {
        guard !productIds.isEmpty else {
            products = []
            filteredProducts = []
            return
        }
        
        // Batch fetch products using whereField(in:) - max 30 per batch (Firestore limit)
        var fetchedProductMap: [String: Product] = [:]
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
                    fetchedProductMap[document.documentID] = product
                }
            } catch {
                #if DEBUG
                print("[CollectionProducts] Batch fetch failed: \(error.localizedDescription)")
                #endif
            }
        }
        
        // Preserve the original product order from the collection
        products = productIds.compactMap { fetchedProductMap[$0] }
        applySearchFilter()
    }
    
    /// Unique material names extracted from loaded products
    var availableMaterials: [String] {
        let materials = Set(products.compactMap { $0.material?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        return materials.sorted()
    }
    
    func setMaterialFilter(_ material: String) {
        selectedMaterialFilter = material
        applySearchFilter()
    }
    
    func setSortOption(_ option: SortOption) {
        selectedSortOption = option
        applySearchFilter()
    }
    
    func applySearchFilter() {
        var base = products
        
        // Apply material filter
        if selectedMaterialFilter != "All" {
            base = base.filter { ($0.material ?? "").localizedCaseInsensitiveCompare(selectedMaterialFilter) == .orderedSame }
        }
        
        // Apply search filter
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            filteredProducts = base
        } else {
            filteredProducts = ProductSearchFilter.filter(base, query: searchQuery, categoryNameById: [:])
        }
        
        // Apply sort
        switch selectedSortOption {
        case .defaultSort:
            break // Keep the original order
        case .priceLowToHigh:
            filteredProducts.sort { $0.price < $1.price }
        case .priceHighToLow:
            filteredProducts.sort { $0.price > $1.price }
        }
    }
    
    func setSearchQuery(_ query: String) {
        searchQuery = query
        applySearchFilter()
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
    
    var itemCount: Int {
        filteredProducts.count
    }
}
