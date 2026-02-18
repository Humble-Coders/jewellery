import Foundation
import Combine
import FirebaseFirestore

@MainActor
class AllJewelleryViewModel: BaseViewModel {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var categories: [Category] = []
    @Published var selectedFilter: String = "All"
    @Published var selectedMetalFilter: (id: String, name: String)?  // When set, filters by material
    @Published var showFilterSheet = false
    @Published var searchQuery: String = ""
    @Published var selectedMaterialFilter: String = "All"
    @Published var selectedSortOption: SortOption = .defaultSort
    
    // Pagination properties
    @Published var isLoadingMore = false
    @Published var hasMorePages = true
    private var currentPage = 0
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    
    private let db = FirebaseService.shared.db
    
    private var categoryNameById: [String: String] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
    }
    private let initialMetalId: String?
    private let initialMetalName: String?
    
    init(initialMetalId: String? = nil, initialMetalName: String? = nil) {
        self.initialMetalId = initialMetalId
        self.initialMetalName = initialMetalName
        super.init()
        if let id = initialMetalId, let name = initialMetalName, !id.isEmpty, !name.isEmpty {
            selectedMetalFilter = (id, name)
        }
    }
    
    var filterOptions: [String] {
        ["All"] + categories.map { $0.name }
    }
    
    func loadData() {
        isLoading = true
        clearError()
        
        // Reset pagination state
        currentPage = 0
        lastDocument = nil
        hasMorePages = true
        products = []
        
        Task {
            do {
                // For initial load, check cache
                if let cachedProducts = await DataCache.shared.getAllProducts(),
                   let cachedCategories = await DataCache.shared.getCategories(),
                   !cachedProducts.isEmpty {
                    products = cachedProducts
                    categories = cachedCategories
                    applyFilter()
                    isLoading = false
                    // Assume no more pages if loading from cache
                    hasMorePages = false
                    return
                }
                
                try await fetchCategories()
                try await fetchProductsPage(page: 0)
                // Populate the all-products cache so subsequent visits are instant
                await DataCache.shared.setAllProducts(products)
                applyFilter()
                isLoading = false
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    func refreshData() {
        Task {
            await DataCache.shared.invalidateAllProducts()
            // Clear stale material rates so prices are recalculated from fresh data
            await PriceCalculationService.shared.clearCache()
        }
        // Reset pagination and reload
        currentPage = 0
        lastDocument = nil
        hasMorePages = true
        products = []
        loadData()
    }
    
    func selectFilter(_ filter: String) {
        selectedFilter = filter
        applyFilter()
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
    
    private func applyFilter() {
        var result = products
        
        // Apply metal filter from navigation (e.g. from home screen metal section)
        if let metal = selectedMetalFilter {
            result = result.filter { $0.materialId == metal.id }
        }
        
        // Apply material filter from filter sheet
        if selectedMaterialFilter != "All" {
            result = result.filter { ($0.material ?? "").localizedCaseInsensitiveCompare(selectedMaterialFilter) == .orderedSame }
        }
        
        // Apply category filter
        if selectedFilter != "All" {
            let categoryId = categories.first { $0.name == selectedFilter }?.id
            result = result.filter { $0.categoryId == categoryId }
        }
        
        // Apply search filter
        if searchQuery.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
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
    
    func clearMetalFilter() {
        selectedMetalFilter = nil
        applyFilter()
    }
    
    // MARK: - Fetch Categories
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
    }
    
    // MARK: - Fetch Products Page
    private func fetchProductsPage(page: Int) async throws {
        var query = db.collection(Constants.Firestore.products)
            .order(by: "name")
            .limit(to: pageSize)
        
        // For subsequent pages, start after the last document
        if page > 0, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        var fetchedProducts: [Product] = []
        
        for document in snapshot.documents {
            let product = await parseProduct(from: document)
            fetchedProducts.append(product)
        }
        
        // Update pagination state
        if page == 0 {
            products = fetchedProducts
        } else {
            products.append(contentsOf: fetchedProducts)
        }
        
        // Update last document for next page
        lastDocument = snapshot.documents.last
        
        // Check if there are more pages
        hasMorePages = fetchedProducts.count == pageSize
        currentPage = page
        
        #if DEBUG
        print("📄 Loaded page \(page): \(fetchedProducts.count) products. Total: \(products.count). Has more: \(hasMorePages)")
        #endif
    }
    
    // MARK: - Parse Product from Document
    private func parseProduct(from document: DocumentSnapshot) async -> Product {
        let productId = document.documentID
        let data = document.data() ?? [:]
        
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
    
    // MARK: - Load Next Page
    func loadNextPage() {
        // Don't load if already loading or no more pages
        guard !isLoadingMore && !isLoading && hasMorePages else { return }
        
        isLoadingMore = true
        Task {
            do {
                try await fetchProductsPage(page: currentPage + 1)
                // Update cache with all loaded products so far
                await DataCache.shared.setAllProducts(products)
                applyFilter()
                isLoadingMore = false
            } catch {
                isLoadingMore = false
                #if DEBUG
                print("Error loading next page: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    // MARK: - Check if should load more
    func shouldLoadMore(currentProduct product: Product) -> Bool {
        // Load more when we're at the second-to-last product
        guard let index = filteredProducts.firstIndex(where: { $0.id == product.id }) else {
            return false
        }
        return index >= filteredProducts.count - 2
    }
}
