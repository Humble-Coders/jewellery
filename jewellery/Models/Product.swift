import Foundation

struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let price: Double
    let imageUrls: [String]
    let categoryId: String?
    let materialId: String?
    let material: String?
    let weight: Double?
    let inStock: Bool?
    let sku: String?
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "₹\(price)"
    }
    
    init(id: String, name: String, description: String?, price: Double, imageUrls: [String], categoryId: String?, materialId: String? = nil, material: String?, weight: Double?, inStock: Bool?, sku: String?) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageUrls = imageUrls
        self.categoryId = categoryId
        self.materialId = materialId
        self.material = material
        self.weight = weight
        self.inStock = inStock
        self.sku = sku
    }
}
