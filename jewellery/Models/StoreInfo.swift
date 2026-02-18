import Foundation
import FirebaseFirestore

struct StoreInfo: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let address: String
    let phonesPrimary: String
    let phonesSecondary: String?
    let email: String
    let latitude: Double
    let longitude: Double
    let logoImages: [String]
    let establishedYear: String?
    let gstin: String?
    let storeHours: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case phonesPrimary = "phone_primary"
        case phonesSecondary = "phone_secondary"
        case email
        case latitude
        case longitude
        case logoImages = "logo_images"
        case establishedYear
        case gstin
        case storeHours = "store_hours"
    }
    
    var primaryPhone: String {
        phonesPrimary
    }
    
    var secondaryPhone: String? {
        phonesSecondary
    }
    
    var logoUrl: String? {
        logoImages.first
    }
    
    var formattedAddress: String {
        address
    }
    
    /// Get store hours for a specific weekday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    func hoursForWeekday(_ weekday: Int) -> String? {
        let dayKey = Self.dayKey(for: weekday)
        return storeHours?[dayKey]
    }
    
    /// Get the day key for a weekday number
    static func dayKey(for weekday: Int) -> String {
        switch weekday {
        case 1: return "sunday"
        case 2: return "monday"
        case 3: return "tuesday"
        case 4: return "wednesday"
        case 5: return "thursday"
        case 6: return "friday"
        case 7: return "saturday"
        default: return ""
        }
    }
    
    /// Get the day name for a weekday number
    static func dayName(for weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }
    
    /// Check if store is currently open based on current time
    func isCurrentlyOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        
        guard let todayHours = hoursForWeekday(weekday) else {
            return false
        }
        
        // Parse the time string (e.g., "10:00 AM - 8:00 PM")
        return isTimeInRange(todayHours, currentTime: now)
    }
    
    /// Parse time string and check if current time falls within range
    private func isTimeInRange(_ hoursString: String, currentTime: Date) -> Bool {
        // Split by " - " to get opening and closing times
        let components = hoursString.components(separatedBy: " - ")
        guard components.count == 2 else { return false }
        
        let openingStr = components[0].trimmingCharacters(in: .whitespaces)
        let closingStr = components[1].trimmingCharacters(in: .whitespaces)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        guard let openingTime = formatter.date(from: openingStr),
              let closingTime = formatter.date(from: closingStr) else {
            return false
        }
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        let openingHour = calendar.component(.hour, from: openingTime)
        let openingMinute = calendar.component(.minute, from: openingTime)
        
        let closingHour = calendar.component(.hour, from: closingTime)
        let closingMinute = calendar.component(.minute, from: closingTime)
        
        let currentMinutes = currentHour * 60 + currentMinute
        let openingMinutes = openingHour * 60 + openingMinute
        let closingMinutes = closingHour * 60 + closingMinute
        
        return currentMinutes >= openingMinutes && currentMinutes <= closingMinutes
    }
}
