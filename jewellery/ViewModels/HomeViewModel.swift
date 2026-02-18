import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage

@MainActor
class HomeViewModel: BaseViewModel {
    @Published var categories: [Category] = []
    @Published var carouselItems: [CarouselItem] = []
    @Published var collections: [ThemedCollection] = []
    @Published var testimonials: [CustomerTestimonial] = []
    @Published var editorialImages: [EditorialImage] = []
    @Published var videoHeader: VideoHeader?
    @Published var bannerImageUrl: String?
    @Published var homeTopImageUrl: String?
    @Published var recentlyViewedProducts: [Product] = []
    @Published var searchQuery: String = ""
    
    // MARK: - Filtered Results for Inline Search
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
    
    var filteredCarouselItems: [CarouselItem] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return carouselItems }
        let q = searchQuery.lowercased()
        return carouselItems.filter {
            $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
        }
    }
    
    var filteredTestimonials: [CustomerTestimonial] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return testimonials }
        let q = searchQuery.lowercased()
        return testimonials.filter {
            $0.name.lowercased().contains(q) || $0.testimonial.lowercased().contains(q)
        }
    }
    
    var isSearchActive: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Loading States
    @Published var imageLoadingStates: [String: LoadingState] = [:]
    @Published var isLoadingRecentlyViewed = false
    
    // MARK: - Cache Timestamps
    private var lastRecentlyViewedFetch: Date?
    private let recentlyViewedCacheInterval: TimeInterval = 30 // 30 seconds
    
    enum LoadingState {
        case notStarted
        case loading
        case loaded
        case failed(Error)
    }
    
    private let db = FirebaseService.shared.db
    
    /// Sections that failed to load (for retry)
    private var failedSections: Set<String> = []
    
    /// Loaded flags for lazy sections (only fetch when section appears)
    private var editorialLoaded = false
    private var testimonialsLoaded = false
    private var collectionsLoaded = false
    private var videoHeaderLoaded = false
    private var homeTopLoaded = false
    private var recentlyViewedLoaded = false
    
    override init() {
        super.init()
        observeNetworkChanges()
    }
    
    // MARK: - Network Monitoring
    private func observeNetworkChanges() {
        NetworkMonitor.shared.$isConnected
            .dropFirst() // Ignore initial value
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    #if DEBUG
                    print("[HomeViewModel] Network reconnected - retrying failed sections")
                    #endif
                    self.retryFailedSections()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Retry sections that failed to load
    func retryFailedSections() {
        guard !failedSections.isEmpty else { return }
        
        #if DEBUG
        print("[HomeViewModel] Retrying \(failedSections.count) failed sections")
        #endif
        
        for section in failedSections {
            switch section {
            case "categories":
                Task { try? await fetchCategories() }
            case "carousel":
                Task { try? await fetchCarouselItems() }
            case "collections":
                loadCollectionsIfNeeded()
            case "testimonials":
                loadTestimonialsIfNeeded()
            case "editorial":
                loadEditorialIfNeeded()
            case "recentlyViewed":
                loadRecentlyViewedIfNeeded()
            default:
                break
            }
        }
    }
    
    /// App launch: Load cached data immediately, then refresh in background
    /// "Stale-while-revalidate" strategy for instant UX with fresh data
    func loadPriorityData() {
        isLoading = true
        clearError()
        
        Task {
            // Phase 1: Load from cache immediately (instant display)
            if let cached = await DataCache.shared.getCategories() {
                categories = cached
                imageLoadingStates["categories"] = .loaded
                #if DEBUG
                print("[HomeViewModel] Loaded \(cached.count) categories from cache")
                #endif
            }
            
            if let cached = await DataCache.shared.getCarouselItems() {
                carouselItems = cached
                imageLoadingStates["carousel"] = .loaded
                #if DEBUG
                print("[HomeViewModel] Loaded \(cached.count) carousel items from cache")
                #endif
            }
            
            isLoading = false
            
            // Phase 2: Refresh from Firestore in background (fresh data)
            Task {
                await refreshPriorityDataInBackground()
            }
            
            // Phase 3: Load home top image
            Task { await loadHomeTopIfNeeded() }
        }
    }
    
    /// Background refresh to get latest data without blocking UI
    private func refreshPriorityDataInBackground() async {
        #if DEBUG
        print("[HomeViewModel] Background refresh started")
        #endif
        
        // Refresh categories
        do {
            imageLoadingStates["categories"] = .loading
            try await fetchCategories()
            await DataCache.shared.setCategories(categories)
            imageLoadingStates["categories"] = .loaded
            failedSections.remove("categories")
            #if DEBUG
            print("[HomeViewModel] Background refresh: categories updated")
            #endif
        } catch {
            imageLoadingStates["categories"] = .failed(error)
            failedSections.insert("categories")
            #if DEBUG
            print("[HomeViewModel] Background refresh: categories failed - \(error)")
            #endif
        }
        
        // Refresh carousel
        do {
            imageLoadingStates["carousel"] = .loading
            try await fetchCarouselItems()
            await DataCache.shared.setCarouselItems(carouselItems)
            imageLoadingStates["carousel"] = .loaded
            failedSections.remove("carousel")
            #if DEBUG
            print("[HomeViewModel] Background refresh: carousel updated")
            #endif
        } catch {
            imageLoadingStates["carousel"] = .failed(error)
            failedSections.insert("carousel")
            #if DEBUG
            print("[HomeViewModel] Background refresh: carousel failed - \(error)")
            #endif
        }
    }
    
    /// Pull-to-refresh: invalidate memory cache and force fresh fetch
    func refreshData() {
        editorialLoaded = false
        testimonialsLoaded = false
        collectionsLoaded = false
        videoHeaderLoaded = false
        homeTopLoaded = false
        recentlyViewedLoaded = false
        
        // Invalidate recently viewed cache to force refresh
        lastRecentlyViewedFetch = nil
        
        Task {
            // Clear memory cache only (keep disk cache for offline support)
            await DataCache.shared.invalidateMemoryOnly()
            
            // Clear stale material rates so prices are recalculated from fresh data
            await PriceCalculationService.shared.clearCache()
            
            // Force fresh fetch
            isLoading = true
            do {
                try await fetchCategories()
                await DataCache.shared.setCategories(categories)
                
                try await fetchCarouselItems()
                await DataCache.shared.setCarouselItems(carouselItems)
                
                // Force refresh recently viewed
                await loadRecentlyViewedProducts(forceRefresh: true)
                
                isLoading = false
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    func loadEditorialIfNeeded() {
        guard !editorialLoaded else { return }
        editorialLoaded = true
        Task {
            do {
                try await fetchEditorialImages()
            } catch {
                editorialLoaded = false
                handleError(error)
            }
        }
    }
    
    func loadTestimonialsIfNeeded() {
        guard !testimonialsLoaded else { return }
        testimonialsLoaded = true
        Task {
            do {
                try await fetchTestimonials()
            } catch {
                testimonialsLoaded = false
                handleError(error)
            }
        }
    }
    
    func loadCollectionsIfNeeded() {
        guard !collectionsLoaded else { return }
        collectionsLoaded = true
        Task {
            do {
                if let cached = await DataCache.shared.getCollections() {
                    collections = cached
                } else {
                    try await fetchCollections()
                    await DataCache.shared.setCollections(collections)
                }
            } catch {
                collectionsLoaded = false
                handleError(error)
            }
        }
    }
    
    func loadVideoHeaderIfNeeded() {
        guard !videoHeaderLoaded else { return }
        videoHeaderLoaded = true
        Task {
            do {
                try await fetchVideoHeader()
            } catch {
                videoHeaderLoaded = false
                handleError(error)
            }
        }
    }
    
    func loadHomeTopIfNeeded() async {
        guard !homeTopLoaded else { return }
        homeTopLoaded = true
        await fetchHomeTopImage()
    }
    
    // MARK: - Fetch Categories
    private func fetchCategories() async throws {
        let snapshot = try await db.collection(Constants.Firestore.categories).getDocuments()
        var fetchedCategories: [Category] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            // Use full URL directly from Firestore (no Storage resolution needed)
            let imageUrl = extractImageUrl(from: data)
            
            fetchedCategories.append(Category(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                imageUrl: imageUrl,
                description: data["description"] as? String
            ))
        }
        
        categories = fetchedCategories.sorted { $0.name < $1.name }
    }
    
    // MARK: - Fetch Carousel Items
    private func fetchCarouselItems() async throws {
        let snapshot = try await db.collection(Constants.Firestore.carouselItems).getDocuments()
        var fetchedItems: [CarouselItem] = []
        
        for (index, document) in snapshot.documents.enumerated() {
            let data = document.data()
            
            // Use full URL directly from Firestore (no Storage resolution needed)
            let imageUrl = extractImageUrl(from: data)
            
            fetchedItems.append(CarouselItem(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                subtitle: data["subtitle"] as? String ?? "",
                buttonText: data["buttonText"] as? String ?? "Shop Now",
                imageUrl: imageUrl,
                productIds: data["productIds"] as? [String] ?? [],
                order: data["order"] as? Int ?? index
            ))
        }
        
        carouselItems = fetchedItems.sorted { $0.order < $1.order }
    }
    
    // MARK: - Fetch Collections
    private func fetchCollections() async throws {
        let snapshot = try await db.collection(Constants.Firestore.themedCollections).getDocuments()
        var fetchedCollections: [ThemedCollection] = []
        
        for (index, document) in snapshot.documents.enumerated() {
            let data = document.data()
            
            // Extract full URLs directly from Firestore (no Storage resolution needed)
            let imageUrls = extractImageUrls(from: data)
            
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
    
    // MARK: - Fetch Testimonials
    private func fetchTestimonials() async throws {
        let snapshot = try await db.collection(Constants.Firestore.customerTestomonials).getDocuments()
        var fetchedTestimonials: [CustomerTestimonial] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            // Get imageUrl directly from Firestore document
            let imageUrl = data["image_url"] as? String ?? data["imageUrl"] as? String ?? ""
            
            let testimonial = CustomerTestimonial(
                id: document.documentID,
                name: data["customer_name"] as? String ?? data["name"] as? String ?? "",
                age: data["age"] as? Int,
                testimonial: data["testomonial"] as? String ?? data["testimonial"] as? String ?? "",
                imageUrl: imageUrl,
                productId: data["productId"] as? String ?? data["product_id"] as? String
            )
            fetchedTestimonials.append(testimonial)
        }
        
        testimonials = fetchedTestimonials
    }
    
    // MARK: - Fetch Editorial Images
    private func fetchEditorialImages() async throws {
        let snapshot = try await db.collection(Constants.Firestore.editorial).getDocuments()
        var fetchedImages: [EditorialImage] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            // Use full URL directly from Firestore (no Storage resolution needed)
            let imageUrl = extractImageUrl(from: data)
            
            fetchedImages.append(EditorialImage(
                id: document.documentID,
                imageUrl: imageUrl,
                productId: data["productId"] as? String,
                title: data["title"] as? String,
                description: data["description"] as? String
            ))
        }
        
        editorialImages = fetchedImages
    }
    
    // MARK: - Fetch Video Header
    private func fetchVideoHeader() async throws {
        // Try Firestore document first for metadata + URL
        let snapshot = try await db.collection(Constants.Firestore.header)
            .document(Constants.Firestore.video)
            .getDocument()
        
        let data = snapshot.data()
        
        // If Firestore has is_active = false, skip video entirely
        if let data = data, let isActive = data["is_active"] as? Bool, !isActive {
            return
        }
        
        // Try to get video URL from Firestore document
        var resolvedUrl: String?
        if let data = data {
            let candidateUrl = data["link"] as? String ?? data["url"] as? String ?? ""
            if !candidateUrl.isEmpty {
                resolvedUrl = try? await resolveStorageUrlIfNeeded(candidateUrl)
            }
        }
        
        // Fallback: resolve directly from known Storage path
        if resolvedUrl == nil || resolvedUrl?.isEmpty == true {
            let storageRef = Storage.storage().reference().child("Header/VID-20250902-WA0009.mp4")
            resolvedUrl = try? await storageRef.downloadURL().absoluteString
        }
        
        if let url = resolvedUrl, !url.isEmpty {
            videoHeader = VideoHeader(
                id: snapshot.documentID,
                link: url,
                title: data?["title"] as? String,
                description: data?["description"] as? String,
                thumbnailUrl: data?["thumbnail_url"] as? String,
                duration: data?["duration"] as? Int,
                isActive: true
            )
        }
    }
    
    // MARK: - Fetch Banner Image
    private func fetchBannerImage() async {
        do {
            let snapshot = try await db.collection(Constants.Firestore.header)
                .document("banner")
                .getDocument()
            if let data = snapshot.data() {
                let candidateUrl = data["imageUrl"] as? String ?? data["image_url"] as? String ?? data["url"] as? String ?? ""
                if !candidateUrl.isEmpty {
                    let resolved = try? await resolveStorageUrlIfNeeded(candidateUrl)
                    bannerImageUrl = (resolved?.isEmpty == false) ? resolved : nil
                }
            }
        } catch {
            #if DEBUG
            print("[HomeViewModel] Failed to fetch banner: \(error.localizedDescription)")
            #endif
        }
    }
    
    // MARK: - Fetch Home Top Image
    private func fetchHomeTopImage() async {
        do {
            // Try Firestore document first
            var resolvedUrl: String?
            let snapshot = try await db.collection(Constants.Firestore.header)
                .document("home_top")
                .getDocument()
            if let data = snapshot.data() {
                let candidateUrl = data["imageUrl"] as? String ?? data["image_url"] as? String ?? data["url"] as? String ?? ""
                if !candidateUrl.isEmpty {
                    resolvedUrl = try? await resolveStorageUrlIfNeeded(candidateUrl)
                }
            }
            
            // Fallback: resolve directly from known Storage path
            if resolvedUrl == nil || resolvedUrl?.isEmpty == true {
                let storageRef = Storage.storage().reference().child("Header/Group 787.png")
                resolvedUrl = try? await storageRef.downloadURL().absoluteString
            }
            
            homeTopImageUrl = (resolvedUrl?.isEmpty == false) ? resolvedUrl : nil
        } catch {
            // Firestore failed, try Storage directly as fallback
            do {
                let storageRef = Storage.storage().reference().child("Header/Group 787.png")
                let url = try await storageRef.downloadURL().absoluteString
                homeTopImageUrl = url.isEmpty ? nil : url
            } catch {
                #if DEBUG
                print("[HomeViewModel] Failed to fetch home top image: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Storage URL Resolution
    
    /// If the URL is a gs:// Firebase Storage path, resolve it to an HTTPS download URL.
    /// If it's already an HTTPS URL, return it as-is.
    private func resolveStorageUrlIfNeeded(_ urlString: String) async throws -> String {
        if urlString.hasPrefix("gs://") {
            let ref = Storage.storage().reference(forURL: urlString)
            return try await ref.downloadURL().absoluteString
        }
        return urlString
    }
    
    // MARK: - Recently Viewed Section
    
    /// Loads recently viewed products if not already loaded
    /// Shows loading indicator ONLY if list is empty
    /// Uses cached data if available, no forced refresh
    /// Does NOT clear existing data on error
    func loadRecentlyViewedIfNeeded() {
        guard !recentlyViewedLoaded else {
            #if DEBUG
            print("[HomeViewModel] Recently viewed already loaded, skipping")
            #endif
            return
        }
        recentlyViewedLoaded = true
        
        #if DEBUG
        print("[HomeViewModel] Starting to load recently viewed products...")
        #endif
        
        Task {
            await loadRecentlyViewedProducts()
        }
    }
    
    /// Force refresh recently viewed products (called when returning to home screen)
    /// Uses smart caching - only refetches if cache is stale (older than 30 seconds)
    func refreshRecentlyViewed() {
        // Check if we have a recent fetch (within cache interval)
        if let lastFetch = lastRecentlyViewedFetch {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            
            if timeSinceLastFetch < recentlyViewedCacheInterval {
                #if DEBUG
                print("[HomeViewModel] Recently viewed cache is fresh (\(Int(timeSinceLastFetch))s old), skipping fetch")
                #endif
                return
            }
        }
        
        Task {
            await loadRecentlyViewedProducts(forceRefresh: false)
        }
    }
    
    /// Internal method to load recently viewed products
    /// - Parameter forceRefresh: If true, ignores cache timestamp and always fetches
    private func loadRecentlyViewedProducts(forceRefresh: Bool = false) async {
        // Show loading indicator ONLY if list is empty
        if recentlyViewedProducts.isEmpty {
            isLoadingRecentlyViewed = true
        }
        
        do {
            // Fetch recently viewed product IDs
            let productIds = try await RecentlyViewedService.shared.fetchRecentlyViewedIds()
            
            guard !productIds.isEmpty else {
                isLoadingRecentlyViewed = false
                failedSections.remove("recentlyViewed")
                lastRecentlyViewedFetch = Date() // Update timestamp even if empty
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
                        let product = await parseProduct(from: document, data: data)
                        fetchedProductMap[document.documentID] = product
                    }
                    
                } catch {
                    #if DEBUG
                    print("[HomeViewModel] ❌ Batch fetch failed: \(error.localizedDescription)")
                    #endif
                }
            }
            
            // Preserve the original recently-viewed order
            let fetchedProducts = productIds.compactMap { fetchedProductMap[$0] }
            
            // Update UI reactively - DO NOT clear on error
            recentlyViewedProducts = fetchedProducts
            isLoadingRecentlyViewed = false
            failedSections.remove("recentlyViewed")
            
            // Update cache timestamp
            lastRecentlyViewedFetch = Date()
            
        } catch {
            // DO NOT clear existing data on error
            isLoadingRecentlyViewed = false
            recentlyViewedLoaded = false
            failedSections.insert("recentlyViewed")
            
            #if DEBUG
            print("[HomeViewModel] ❌ Failed to load recently viewed: \(error)")
            #endif
        }
    }
    
    // MARK: - Image URL Extraction Helpers
    
    /// Extracts the first valid image URL from Firestore document data.
    /// Firestore documents store complete URLs, so no Storage resolution is needed.
    private func extractImageUrl(from data: [String: Any]) -> String {
        // Priority 1: imageUrls array (first valid http URL)
        if let urls = data["imageUrls"] as? [String],
           let first = urls.first(where: { $0.hasPrefix("http") }) {
            return first
        }
        // Priority 2: images array
        if let urls = data["images"] as? [String],
           let first = urls.first(where: { $0.hasPrefix("http") }) {
            return first
        }
        // Priority 3: single imageUrl / image_url field
        if let url = data["imageUrl"] as? String, url.hasPrefix("http") { return url }
        if let url = data["image_url"] as? String, url.hasPrefix("http") { return url }
        if let url = data["url"] as? String, url.hasPrefix("http") { return url }
        return ""
    }
    
    /// Extracts all valid image URLs from Firestore document data.
    /// Firestore documents store complete URLs, so no Storage resolution is needed.
    private func extractImageUrls(from data: [String: Any]) -> [String] {
        // Priority 1: imageUrls array
        if let urls = data["imageUrls"] as? [String] {
            let valid = urls.filter { $0.hasPrefix("http") }
            if !valid.isEmpty { return valid }
        }
        // Priority 2: images array
        if let urls = data["images"] as? [String] {
            let valid = urls.filter { $0.hasPrefix("http") }
            if !valid.isEmpty { return valid }
        }
        // Priority 3: single URL fields
        if let url = data["imageUrl"] as? String, url.hasPrefix("http") { return [url] }
        if let url = data["image_url"] as? String, url.hasPrefix("http") { return [url] }
        return []
    }
    
    /// Helper method to parse product from Firestore document
    private func parseProduct(from document: DocumentSnapshot, data: [String: Any]) async -> Product {
        let productId = document.documentID
        
        // Use full URLs directly from Firestore (no Storage resolution needed)
        let imageUrls = extractImageUrls(from: data)
        
        // Calculate price
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
    
    /// Load all data needed for home search (categories, collections, testimonials - NO products)
    func loadSearchData() {
        Task {
            loadCollectionsIfNeeded()
            loadTestimonialsIfNeeded()
            // Categories are already loaded in loadPriorityData()
            // No need to fetch products for search
        }
    }
}
