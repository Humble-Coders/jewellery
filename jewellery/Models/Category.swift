import Foundation

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let imageUrl: String
    let description: String?
}
