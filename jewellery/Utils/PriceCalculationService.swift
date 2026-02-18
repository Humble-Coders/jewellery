//
//  PriceCalculationService.swift
//  jewellery
//
//  Created by Sharnya  Goel on 31/01/26.
//


import Foundation
import FirebaseFirestore

actor PriceCalculationService {
    static let shared = PriceCalculationService()
    private let db = Firestore.firestore()
    
    // MARK: - Material Cache
    /// In-memory cache for material documents to avoid redundant Firestore reads.
    /// Key: materialId, Value: (document data, timestamp of fetch)
    private var materialCache: [String: (data: [String: Any], fetchedAt: Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Public Methods
    
    func calculateProductPrice(productData: [String: Any]) async -> PriceBreakdown {
        let materialId = productData["material_id"] as? String ?? ""
        var materialType = (productData["material_type"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if materialType.isEmpty {
            let num = parseDouble(productData["material_type"])
            if num > 0 { materialType = "\(Int(num))K" }
        }
        if materialType.isEmpty { materialType = "24K" }
        
        // Fetch material document ONCE (cached) and extract both name and rate
        let materialData = await getMaterialDocument(materialId: materialId)
        let materialName = materialData?["name"] as? String ?? ""
        let rate = extractRate(from: materialData, materialType: materialType)
        
        return JewelryPriceCalculator.calculate(
            productData: productData,
            materialName: materialName,
            materialRate: rate
        )
    }
    
    /// Public method to get material name (uses cache). Exposed for use by other ViewModels.
    func getMaterialName(materialId: String) async -> String {
        guard !materialId.isEmpty else { return "" }
        let materialData = await getMaterialDocument(materialId: materialId)
        return materialData?["name"] as? String ?? ""
    }
    
    /// Invalidate all cached materials (e.g. on pull-to-refresh or when rates may have changed)
    func clearCache() {
        materialCache.removeAll()
    }
    
    // MARK: - Private: Material Document Cache
    
    /// Fetches the material document from Firestore, or returns it from cache if fresh.
    /// This is the ONLY method that ever calls Firestore for material data.
    private func getMaterialDocument(materialId: String) async -> [String: Any]? {
        guard !materialId.isEmpty else { return nil }
        
        // Check cache
        if let cached = materialCache[materialId],
           Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return cached.data
        }
        
        // Fetch from Firestore and cache
        do {
            let document = try await db.collection("materials").document(materialId).getDocument()
            guard let data = document.data() else { return nil }
            materialCache[materialId] = (data: data, fetchedAt: Date())
            return data
        } catch {
            #if DEBUG
            print("[PriceCalculationService] Failed to fetch material \(materialId): \(error.localizedDescription)")
            #endif
            return nil
        }
    }
    
    // MARK: - Private: Rate Extraction (no Firestore call)
    
    /// Extracts the rate from already-fetched material data. Pure in-memory operation.
    private func extractRate(from data: [String: Any]?, materialType: String) -> Double {
        guard let data = data else { return 0.0 }
        
        let requestedPurity = materialType.trimmingCharacters(in: .whitespacesAndNewlines)
        func normalizePurity(_ s: String) -> String {
            s.lowercased().replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let requestedNormalized = normalizePurity(requestedPurity)

        // Check types array
        if let typesArray = data["types"] as? [[String: Any]] {
            for entry in typesArray {
                let purity = (entry["purity"] as? String ?? entry["Purity"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let rateValue = entry["rate"] ?? entry["Rate"]
                
                if purity.isEmpty { continue }
                let purityNormalized = normalizePurity(purity)
                let matches = purityNormalized == requestedNormalized
                    || (purityNormalized.hasSuffix("k") && String(purityNormalized.dropLast()) == requestedNormalized)
                    || (requestedNormalized + "k" == purityNormalized)
                
                if matches {
                    // Try to parse rate - String first, then numbers
                    if let rateStr = rateValue as? String {
                        let trimmed = rateStr.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let rate = Double(trimmed), rate > 0 {
                            return rate
                        }
                    }
                    if let rate = rateValue as? Double, rate > 0 {
                        return rate
                    }
                    if let rate = rateValue as? Int, rate > 0 {
                        return Double(rate)
                    }
                    if let rate = rateValue as? NSNumber, rate.doubleValue > 0 {
                        return rate.doubleValue
                    }
                }
            }
        }

        // Fallback: rates map
        if let rates = data["rates"] as? [String: Any] {
            let candidates = [requestedPurity, requestedPurity.uppercased(), requestedPurity.lowercased()]
            for key in candidates {
                let value = parseDouble(rates[key])
                if value > 0 { return value }
            }
        }

        // Single top-level rate
        for key in ["rate", requestedPurity, requestedPurity.uppercased(), requestedPurity.lowercased()] {
            let value = parseDouble(data[key])
            if value > 0 { return value }
        }

        return 0.0
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