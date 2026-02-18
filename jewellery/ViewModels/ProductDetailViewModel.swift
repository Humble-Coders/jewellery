import Foundation
import Combine
import FirebaseFirestore

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var productName = ""
    @Published var productDescription = ""
    @Published var imageUrls: [String] = []
    @Published var formattedPrice = "₹0.00"
    @Published var materialDisplay = ""
    @Published var availabilityDisplay = ""
    @Published var materialWeight = ""
    @Published var metalWeight = ""
    @Published var totalWeight = ""
    @Published var stoneDisplay = ""
    @Published var stoneWeightDisplay = ""
    @Published var labourChargesDisplay = ""
    @Published var stoneAmountDisplay = ""
    @Published var gstDisplay = "5%"
    @Published var stoneDetails: [StoneDetail] = []
    @Published var isPremiumCollection = false
    @Published var showMap = ShowMap()
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let productId: String
    private let db = Firestore.firestore()
    
    init(productId: String) {
        self.productId = productId
    }
    
    func refreshData() {
        Task {
            await fetchProductDetails()
        }
    }
    
    private func fetchProductDetails() async {
        isLoading = true
        showError = false
        
        do {
            let document = try await db.collection("products").document(productId).getDocument()
            
            guard document.exists else {
                showError = true
                errorMessage = "Product not found"
                isLoading = false
                return
            }
            
            let data = document.data() ?? [:]
            
            // Parse show map
            if let showData = data["show"] as? [String: Bool] {
                showMap = ShowMap(
                    available: showData["available"] ?? false,
                    category_id: showData["category_id"] ?? false,
                    collection_id: showData["collection_id"] ?? false,
                    custom_price: showData["custom_price"] ?? false,
                    description: showData["description"] ?? false,
                    effective_metal_weight: showData["effective_metal_weight"] ?? false,
                    effective_weight: showData["effective_weight"] ?? false,
                    featured: showData["featured"] ?? false,
                    has_stones: showData["has_stones"] ?? false,
                    images: showData["images"] ?? false,
                    is_collection_product: showData["is_collection_product"] ?? false,
                    labour_charges: showData["labour_charges"] ?? false,
                    labour_rate: showData["labour_rate"] ?? false,
                    making_percent: showData["making_percent"] ?? false,
                    material_id: showData["material_id"] ?? false,
                    material_type: showData["material_type"] ?? false,
                    material_weight: showData["material_weight"] ?? false,
                    name: showData["name"] ?? false,
                    price: showData["price"] ?? false,
                    quantity: showData["quantity"] ?? false,
                    stone_amount: showData["stone_amount"] ?? false,
                    stone_weight: showData["stone_weight"] ?? false,
                    stones: showData["stones"] ?? false,
                    total_weight: showData["total_weight"] ?? false
                )
            }
            
            // For silver products, ensure Single details card fields are shown (Firestore show map may be incomplete)
            let materialIdForCheck = data["material_id"] as? String ?? ""
            let materialNameForCheck = await PriceCalculationService.shared.getMaterialName(materialId: materialIdForCheck)
            let materialTypeForCheck = (data["material_type"] as? String ?? "").lowercased()
            if materialNameForCheck.lowercased().contains("silver") || materialTypeForCheck.contains("silver") {
                showMap.material_id = true
                showMap.material_type = true
                showMap.material_weight = true
                showMap.name = true
                showMap.quantity = true
                showMap.price = true
            }
            
            // Product name
            if showMap.name {
                productName = data["name"] as? String ?? ""
            }
            
            // Images - use full URLs directly from Firestore (no Storage resolution needed)
            if showMap.images {
                imageUrls = CategoriesViewModel.extractImageUrls(from: data)
            }
            
            // Premium collection
            isPremiumCollection = data["is_collection_product"] as? Bool ?? false
            
            // Description
            if showMap.description {
                productDescription = data["description"] as? String ?? ""
            }
            
            // Calculate price using separate calculator (mirrors Kotlin logic)
            // Calculate price using separate calculator (mirrors Kotlin logic)
            // Calculate price using shared service
            if showMap.price {
                let breakdown = await PriceCalculationService.shared.calculateProductPrice(productData: data)
                formattedPrice = "₹\(String(format: "%.2f", breakdown.finalAmount))"
                
                #if DEBUG
                print("Final Price: \(formattedPrice)")
                print("===============================================================")
                #endif
            }
            
            // Material display (uses cached material name from PriceCalculationService - no extra Firestore read)
            if showMap.material_id || showMap.material_type {
                let materialId = data["material_id"] as? String ?? ""
                let materialType = data["material_type"] as? String ?? ""
                let materialName = await PriceCalculationService.shared.getMaterialName(materialId: materialId)
                materialDisplay = "\(materialName) \(materialType)"
            }
            
            // Availability
            if showMap.quantity {
                let quantity = parseDouble(data["quantity"])
                let available = data["available"] as? Bool ?? false
                if available && quantity > 0 {
                    availabilityDisplay = "In Stock (\(Int(quantity)))"
                } else {
                    availabilityDisplay = "Out of Stock"
                }
            }
            
            // Material weight
            if showMap.material_weight {
                let weight = parseDouble(data["material_weight"])
                if weight > 0 {
                    materialWeight = "\(String(format: "%.2f", weight))g"
                }
            }
            
            // Effective metal weight
            if showMap.effective_metal_weight {
                let weight = parseDouble(data["effective_metal_weight"])
                if weight > 0 {
                    metalWeight = "\(String(format: "%.2f", weight))g"
                }
            }
            
            // Total weight
            if showMap.total_weight || showMap.effective_weight {
                let weight = parseDouble(data["total_weight"] ?? data["effective_weight"])
                if weight > 0 {
                    totalWeight = "\(String(format: "%.2f", weight))g"
                }
            }
            
            // Stone display
            if showMap.has_stones || showMap.stones {
                if let stones = data["stones"] as? [[String: Any]], !stones.isEmpty {
                    let stoneNames = stones.compactMap { $0["name"] as? String }
                    stoneDisplay = stoneNames.joined(separator: ", ")
                    
                    // Parse stone details
                    stoneDetails = stones.map { stoneData in
                        StoneDetail(
                            id: UUID().uuidString,
                            name: stoneData["name"] as? String ?? "",
                            weight: String(format: "%.2f", parseDouble(stoneData["weight"])),
                            amount: parseDouble(stoneData["amount"])
                        )
                    }
                }
            }
            
            // Stone weight
            if showMap.stone_weight {
                let weight = parseDouble(data["stone_weight"])
                if weight > 0 {
                    stoneWeightDisplay = String(format: "%.2f", weight)
                }
            }
            
            // Labour charges
            if showMap.labour_charges {
                let charges = parseDouble(data["labour_charges"])
                if charges > 0 {
                    labourChargesDisplay = "₹\(String(format: "%.2f", charges))"
                }
            }
            
            // Stone amount
            if showMap.stone_amount {
                if let stones = data["stones"] as? [[String: Any]] {
                    let totalStoneAmount = stones.reduce(0.0) { sum, stone in
                        sum + parseDouble(stone["amount"])
                    }
                    if totalStoneAmount > 0 {
                        stoneAmountDisplay = "₹\(String(format: "%.2f", totalStoneAmount))"
                    }
                }
            }
            
            isLoading = false
            
            // Add to recently viewed (fire and forget, don't block UI)
            let currentProductId = self.productId
            Task.detached(priority: .background) {
                try? await RecentlyViewedService.shared.addToRecentlyViewed(productId: currentProductId)
            }
            
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Helpers
    
    private func parseDouble(_ value: Any?) -> Double {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let stringValue = value as? String {
            return Double(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
        } else if let intValue = value as? Int {
            return Double(intValue)
        } else if let int64Value = value as? Int64 {
            return Double(int64Value)
        } else if let floatValue = value as? Float {
            return Double(floatValue)
        } else if let num = value as? NSNumber {
            return num.doubleValue
        }
        return 0.0
    }
}

struct ShowMap {
    var available = false
    var category_id = false
    var collection_id = false
    var custom_price = false
    var description = false
    var effective_metal_weight = false
    var effective_weight = false
    var featured = false
    var has_stones = false
    var images = false
    var is_collection_product = false
    var labour_charges = false
    var labour_rate = false
    var making_percent = false
    var material_id = false
    var material_type = false
    var material_weight = false
    var name = false
    var price = false
    var quantity = false
    var stone_amount = false
    var stone_weight = false
    var stones = false
    var total_weight = false
}

struct StoneDetail: Identifiable {
    let id: String
    let name: String
    let weight: String
    let amount: Double
    
    var formattedAmount: String {
        "₹\(String(format: "%.2f", amount))"
    }
}
