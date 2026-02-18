import Foundation

struct CustomerTestimonial: Identifiable, Codable {
    let id: String
    let name: String
    let age: Int?
    let testimonial: String
    let imageUrl: String
    let productId: String?
}
