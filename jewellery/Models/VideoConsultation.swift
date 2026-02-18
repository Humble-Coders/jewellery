import Foundation
import FirebaseFirestore

// MARK: - Availability Model

struct Availability: Identifiable, Codable {
    @DocumentID var id: String?
    let startTime: Timestamp
    let endTime: Timestamp
    let slotDuration: Int // in minutes
    let type: String // "availability"
    let createdAt: Timestamp
    
    var startDate: Date {
        startTime.dateValue()
    }
    
    var endDate: Date {
        endTime.dateValue()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Booking Model

struct Booking: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let startTime: Timestamp
    let endTime: Timestamp
    let status: String // "CONFIRMED", "PENDING", "CANCELLED", "COMPLETED"
    let type: String // "booking"
    let createdAt: Timestamp
    
    var startDate: Date {
        startTime.dateValue()
    }
    
    var endDate: Date {
        endTime.dateValue()
    }
    
    var isUpcoming: Bool {
        startDate > Date()
    }
    
    var isPast: Bool {
        endDate < Date()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var statusColor: String {
        switch status.uppercased() {
        case "CONFIRMED": return "#4CAF50"
        case "PENDING": return "#FF9800"
        case "CANCELLED": return "#FF0000"
        case "COMPLETED": return "#2196F3"
        default: return "#808080"
        }
    }
}

// MARK: - Time Slot Model

struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let isBooked: Bool
    let availabilityId: String
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}
