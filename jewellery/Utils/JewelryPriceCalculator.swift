import Foundation

// MARK: - Price breakdown (matches Kotlin PriceBreakdown)
struct PriceBreakdown {
    let finalAmount: Double
    let amountBeforeTax: Double
}

/// Calculates jewellery price from product data and material info.
/// Mirrors the Kotlin `calculateJewelryPrice` logic:
/// - Gold: (effective_metal_weight × rate) + labour_charges + stoneAmount
/// - Silver: (material_weight × rate) + stoneAmount
enum JewelryPriceCalculator {

    /// Calculate price for a product.
    /// - Parameters:
    ///   - productData: Firestore product document data (snake_case keys)
    ///   - materialName: Material name from materials collection (e.g. "gold", "silver")
    ///   - materialRate: Rate per gram from materials collection for the product's material_type
    /// - Returns: PriceBreakdown with finalAmount and amountBeforeTax (rounded to 2 decimals)
    static func calculate(
        productData: [String: Any],
        materialName: String,
        materialRate: Double
    ) -> PriceBreakdown {
        let materialNameLower = materialName.lowercased()
        let isGold = materialNameLower == "gold"
        let isSilver = materialNameLower == "silver"

        guard isGold || isSilver else {
            #if DEBUG
            print("[JewelryPriceCalculator] Unknown material: \(materialName)")
            #endif
            return PriceBreakdown(finalAmount: 0, amountBeforeTax: 0)
        }

        // Stone amount: sum of stones[].amount
        let stoneAmount = sumStoneAmounts(productData["stones"])

        let finalPrice: Double
        if isGold {
            // Try effective_metal_weight first (primary field)
            var effectiveMetalWeight: Double? = getDoubleField(productData, "effective_metal_weight")
            
            // If not found, try alternative field names
            if effectiveMetalWeight == nil || effectiveMetalWeight == 0 {
                effectiveMetalWeight = getDoubleField(productData, "effectiveMetalWeight")
            }
            if effectiveMetalWeight == nil || effectiveMetalWeight == 0 {
                effectiveMetalWeight = getDoubleField(productData, "effective_weight")
            }
            if effectiveMetalWeight == nil || effectiveMetalWeight == 0 {
                effectiveMetalWeight = getDoubleField(productData, "effectiveWeight")
            }
            
            let labourCharges = getDoubleField(productData, "labour_charges")
                ?? getDoubleField(productData, "labourCharges")
                ?? 0

            #if DEBUG
            print("[JewelryPriceCalculator] Gold calculation:")
            print("  - effective_metal_weight: \(effectiveMetalWeight ?? -1)")
            print("  - material_rate: \(materialRate)")
            print("  - labour_charges: \(labourCharges)")
            print("  - stone_amount: \(stoneAmount)")
            print("  - All product keys: \(productData.keys.sorted())")
            #endif

            guard let weight = effectiveMetalWeight, weight > 0 else {
                #if DEBUG
                print("[JewelryPriceCalculator] ERROR: effective_metal_weight is 0 or missing")
                #endif
                return PriceBreakdown(finalAmount: 0, amountBeforeTax: 0)
            }

            // Allow materialRate to be 0 - just calculate with metal amount as 0
            let metalAmount = weight * materialRate
            finalPrice = metalAmount + labourCharges + stoneAmount
            
            #if DEBUG
            print("[JewelryPriceCalculator] Gold final: (\(weight) × \(materialRate)) + \(labourCharges) + \(stoneAmount) = \(finalPrice)")
            #endif

        } else if isSilver {
            let materialWeight: Double? = getDoubleField(productData, "material_weight")
                ?? getDoubleField(productData, "materialWeight")

            #if DEBUG
            print("[JewelryPriceCalculator] Silver calculation:")
            print("  - material_weight: \(materialWeight ?? -1)")
            print("  - material_rate: \(materialRate)")
            print("  - stone_amount: \(stoneAmount)")
            print("  - All product keys: \(productData.keys.sorted())")
            #endif

            guard let weight = materialWeight, weight > 0 else {
                #if DEBUG
                print("[JewelryPriceCalculator] ERROR: material_weight is 0 or missing")
                #endif
                return PriceBreakdown(finalAmount: 0, amountBeforeTax: 0)
            }

            guard materialRate > 0 else {
                #if DEBUG
                print("[JewelryPriceCalculator] ERROR: material_rate is 0")
                #endif
                return PriceBreakdown(finalAmount: 0, amountBeforeTax: 0)
            }

            let metalAmount = weight * materialRate
            finalPrice = metalAmount + stoneAmount
            
            #if DEBUG
            print("[JewelryPriceCalculator] Silver final: (\(weight) × \(materialRate)) + \(stoneAmount) = \(finalPrice)")
            #endif

        } else {
            finalPrice = 0
        }

        let rounded = (finalPrice * 100).rounded() / 100
        return PriceBreakdown(finalAmount: rounded, amountBeforeTax: rounded)
    }

    // MARK: - Helpers

    /// Parse one value (Double, Int, String, NSNumber, etc.). Returns nil for missing/invalid.
    private static func parseDoubleValue(_ value: Any?) -> Double? {
        guard let value = value else { return nil }
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        if let n = value as? Int64 { return Double(n) }
        if let n = value as? Float { return Double(n) }
        if let n = value as? NSNumber { return n.doubleValue }
        if let s = value as? String, let n = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) { return n }
        return nil
    }

    /// Get a Double? from a field (returns nil if missing)
    private static func getDoubleField(_ data: [String: Any], _ key: String) -> Double? {
        guard let value = data[key] else { return nil }
        return parseDoubleValue(value)
    }

    /// Sum of `amount` from stones array. Handles Map with Number or String amount.
    private static func sumStoneAmounts(_ value: Any?) -> Double {
        guard let list = value as? [[String: Any]] else { return 0 }
        return list.reduce(0.0) { sum, map in
            let amountValue = map["amount"]
            if let n = amountValue as? Double { return sum + n }
            if let n = amountValue as? Int { return sum + Double(n) }
            if let n = amountValue as? String, let n = Double(n) { return sum + n }
            if let n = amountValue as? NSNumber { return sum + n.doubleValue }
            return sum
        }
    }
}
