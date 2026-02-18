import Foundation

/// Filters products by search query across name, description, material, weight, sku, category
enum ProductSearchFilter {
    static func filter(_ products: [Product], query: String, categoryNameById: [String: String] = [:]) -> [Product] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return products }
        let terms = q.split(separator: " ").map(String.init)
        
        return products.filter { product in
            let searchableFields: [String] = [
                product.name,
                product.description ?? "",
                product.material ?? "",
                product.sku ?? "",
                product.weight.map { String(format: "%.2f", $0) } ?? "",
                categoryNameById[product.categoryId ?? ""] ?? ""
            ].filter { !$0.isEmpty }
            
            let combined = searchableFields.joined(separator: " ").lowercased()
            return terms.allSatisfy { term in
                combined.contains(term) ||
                product.name.lowercased().contains(term) ||
                (product.description?.lowercased().contains(term) ?? false) ||
                (product.material?.lowercased().contains(term) ?? false) ||
                (product.sku?.lowercased().contains(term) ?? false) ||
                (product.weight.map { String(format: "%.2f", $0).contains(term) } ?? false) ||
                (categoryNameById[product.categoryId ?? ""]?.lowercased().contains(term) ?? false)
            }
        }
    }
}
