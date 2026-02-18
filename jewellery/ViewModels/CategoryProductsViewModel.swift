import Foundation
import Combine
import FirebaseFirestore

@MainActor
class CategoryProductsViewModel: BaseViewModel {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
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
    private let categoryId: String
    
    init(categoryId: String) {
        self.categoryId = categoryId
        super.init()
        #if DEBUG
        print("🎯 CategoryProductsViewModel initialized with categoryId: '\(categoryId)'")
        if categoryId == "test" {
            print("⚠️ WARNING: Using test/placeholder categoryId 'test'. This is likely from SwiftUI Preview.")
        }
        #endif
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
                if let cached = await DataCache.shared.getProducts(categoryId: categoryId),
                   !cached.isEmpty {
                    products = cached
                    applySearchFilter()
                    isLoading = false
                    hasMorePages = false
                    return
                }
                try await fetchProductsPage(page: 0)
                // Populate cache so subsequent visits are instant
                await DataCache.shared.setProducts(products, categoryId: categoryId)
                applySearchFilter()
                isLoading = false
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    func refreshData() {
        Task {
            await DataCache.shared.invalidateProducts(categoryId: categoryId)
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
    
    // MARK: - Fetch Products Page
    private func fetchProductsPage(page: Int) async throws {
        #if DEBUG
        print("📄 Fetching page \(page) for categoryId: '\(categoryId)'")
        #endif
        
        // Build query with pagination (removed .order(by:) to avoid composite index requirement)
        // We'll sort client-side instead
        let baseQuery: Query = db.collection(Constants.Firestore.products)
            .limit(to: pageSize)
        
        // Primary query: category_id field (matches Firestore structure)
        do {
            var paginatedQuery = baseQuery.whereField("category_id", isEqualTo: categoryId)
            
            // For subsequent pages, start after the last document
            if page > 0, let lastDoc = lastDocument {
                paginatedQuery = paginatedQuery.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await paginatedQuery.getDocuments()
            try await processSnapshot(snapshot, page: page)
            return
        } catch {
            #if DEBUG
            print("❌ Query with 'category_id' failed: \(error.localizedDescription)")
            #endif
        }
        
        // Fallback: Fetch only document IDs and category_id field to filter, then process only matching docs
        // This avoids running price calculation on all 200 products
        do {
            let snapshot = try await db.collection(Constants.Firestore.products).limit(to: 200).getDocuments()
            
            // Filter products that match the categoryId BEFORE parsing (avoids price calc on non-matching)
            var matchingDocs: [QueryDocumentSnapshot] = []
            for doc in snapshot.documents {
                let data = doc.data()
                let docCategoryId = data["category_id"] as? String ?? data["categoryId"] as? String
                
                if docCategoryId == categoryId {
                    matchingDocs.append(doc)
                }
            }
            
            // Only parse (and calculate prices for) matching documents
            try await processSnapshotDocs(matchingDocs, page: page)
        } catch {
            #if DEBUG
            print("❌ Client-side filtering failed: \(error.localizedDescription)")
            #endif
            throw error
        }
    }
    
    private func processSnapshot(_ snapshot: QuerySnapshot, page: Int) async throws {
        try await processSnapshotDocs(snapshot.documents, page: page)
    }
    
    private func processSnapshotDocs(_ documents: [QueryDocumentSnapshot], page: Int) async throws {
        
        
        var fetchedProducts: [Product] = []
        
        for document in documents {
            let product = await parseProduct(from: document)
            fetchedProducts.append(product)
        }
        
        // Sort products by name (client-side sorting to avoid composite index requirement)
        fetchedProducts.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        // Update products array
        if page == 0 {
            products = fetchedProducts
        } else {
            products.append(contentsOf: fetchedProducts)
            // Re-sort the entire products array to maintain order across pages
            products.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        
        // Update pagination state
        lastDocument = documents.last
        hasMorePages = fetchedProducts.count == pageSize
        currentPage = page
        
        
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
            categoryId: data["categoryId"] as? String ?? data["category_id"] as? String ?? categoryId,
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
    
    var itemCount: Int {
        filteredProducts.count
    }
    
    // MARK: - Load Next Page
    func loadNextPage() {
        guard !isLoadingMore && !isLoading && hasMorePages else { return }
        
        isLoadingMore = true
        Task {
            do {
                try await fetchProductsPage(page: currentPage + 1)
                applySearchFilter()
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
        guard let index = filteredProducts.firstIndex(where: { $0.id == product.id }) else {
            return false
        }
        return index >= filteredProducts.count - 2
    }
}
