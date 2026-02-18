import Foundation

struct VideoHeader: Identifiable, Codable {
    let id: String
    let link: String
    let title: String?
    let description: String?
    let thumbnailUrl: String?
    let duration: Int?
    let isActive: Bool
}
