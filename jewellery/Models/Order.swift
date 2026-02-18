import Foundation

struct Order: Identifiable {
    let id: String
    let customerId: String
    let createdAt: Date
    let finalAmount: Double
    let invoiceUrl: String?
    let discountAmount: Double?
    let discountPercent: Double?
    let gstAmount: Double?
    let gstPercentage: Double?
    let isGstIncluded: Bool?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: finalAmount)) ?? "₹\(finalAmount)"
    }
    
    var displayId: String {
        id.count > 20 ? String(id.prefix(20)) + "…" : id
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
