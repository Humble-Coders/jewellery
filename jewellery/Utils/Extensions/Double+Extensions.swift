import Foundation

extension Double {
    func roundedToNearestHundred() -> Double {
        return (self / 100.0).rounded() * 100.0
    }
    
    func formattedAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "₹0"
    }
    
    func formattedAsPrice() -> String {
        let rounded = self.roundedToNearestHundred()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return "₹\(formatter.string(from: NSNumber(value: rounded)) ?? "0")"
    }
}
