import Foundation

struct EditorialImage: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let productId: String?
    let title: String?
    let description: String?
}
