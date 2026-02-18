import Foundation

struct ThemedCollection: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageUrls: [String]
    let productIds: [String]
    let order: Int
}
