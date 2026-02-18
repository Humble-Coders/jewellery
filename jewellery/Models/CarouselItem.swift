import Foundation

struct CarouselItem: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let buttonText: String
    let imageUrl: String
    let productIds: [String]
    let order: Int
}
