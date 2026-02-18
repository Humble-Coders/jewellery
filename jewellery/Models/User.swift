import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var phone: String?
    var dateOfBirth: Timestamp?
    var profilePictureUrl: String?
    var googleId: String?
    var isGoogleSignIn: Bool?
    var fcmToken: String?
    var createdAt: Timestamp?
    var lastTokenUpdate: Timestamp?
    
    // Collections within user document
    var recentlyViewed: [String]? // Array of product IDs
    var wishlist: [String]? // Array of product IDs
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case dateOfBirth
        case profilePictureUrl
        case googleId
        case isGoogleSignIn
        case fcmToken
        case createdAt
        case lastTokenUpdate
        case recentlyViewed = "recently_viewed"
        case wishlist
    }
    
    // Custom decoder to handle different data formats - FULLY DEFENSIVE
    init(from decoder: Decoder) throws {
        print("🔍 Decoding User document...")
        
        // Handle case where container itself might fail
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            print("❌ Failed to create container - creating default user")
            _id = DocumentID(wrappedValue: nil)
            name = ""
            email = ""
            phone = nil
            dateOfBirth = nil
            profilePictureUrl = nil
            googleId = nil
            isGoogleSignIn = nil
            fcmToken = nil
            createdAt = nil
            lastTokenUpdate = nil
            recentlyViewed = nil
            wishlist = nil
            return
        }
        
        // Required fields with defaults - NEVER THROW
        // Initialize these first before using any print statements that reference self
        do {
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        } catch {
            print("⚠️ Name decode failed: \(error)")
            name = ""
        }
        
        do {
            email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        } catch {
            print("⚠️ Email decode failed: \(error)")
            email = ""
        }
        
        // Decode @DocumentID separately - handle gracefully
        do {
            _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        } catch {
            print("⚠️ ID decode failed, using nil: \(error)")
            _id = DocumentID(wrappedValue: nil)
        }
        
        print("✅ Name: \(name), Email: \(email)")
        
        // Optional fields - all wrapped in try? to prevent crashes
        phone = try? container.decodeIfPresent(String.self, forKey: .phone)
        print("✅ Phone: \(String(describing: phone))")
        
        // Handle dateOfBirth gracefully
        do {
            dateOfBirth = try container.decodeIfPresent(Timestamp.self, forKey: .dateOfBirth)
            print("✅ DateOfBirth: \(String(describing: dateOfBirth))")
        } catch {
            print("⚠️ DateOfBirth decode failed: \(error)")
            dateOfBirth = nil
        }
        
        profilePictureUrl = try? container.decodeIfPresent(String.self, forKey: .profilePictureUrl)
        googleId = try? container.decodeIfPresent(String.self, forKey: .googleId)
        isGoogleSignIn = try? container.decodeIfPresent(Bool.self, forKey: .isGoogleSignIn)
        fcmToken = try? container.decodeIfPresent(String.self, forKey: .fcmToken)
        
        // Handle lastTokenUpdate gracefully
        do {
            lastTokenUpdate = try container.decodeIfPresent(Timestamp.self, forKey: .lastTokenUpdate)
        } catch {
            print("⚠️ lastTokenUpdate decode failed: \(error)")
            lastTokenUpdate = nil
        }
        
        // Handle arrays gracefully
        do {
            recentlyViewed = try container.decodeIfPresent([String].self, forKey: .recentlyViewed)
            print("✅ RecentlyViewed count: \(recentlyViewed?.count ?? 0)")
        } catch {
            print("⚠️ recentlyViewed decode failed: \(error)")
            recentlyViewed = nil
        }
        
        do {
            wishlist = try container.decodeIfPresent([String].self, forKey: .wishlist)
            print("✅ Wishlist count: \(wishlist?.count ?? 0)")
        } catch {
            print("⚠️ wishlist decode failed: \(error)")
            wishlist = nil
        }
        
        // Handle createdAt which might be Timestamp or a number (milliseconds)
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp
            print("✅ CreatedAt (Timestamp): \(timestamp)")
        } else if let milliseconds = try? container.decode(Int64.self, forKey: .createdAt) {
            // Convert milliseconds to seconds for Timestamp
            let seconds = Double(milliseconds) / 1000.0
            createdAt = Timestamp(seconds: Int64(seconds), nanoseconds: 0)
            print("✅ CreatedAt (from milliseconds): \(milliseconds)")
        } else if let seconds = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Timestamp(seconds: Int64(seconds), nanoseconds: 0)
            print("✅ CreatedAt (from seconds): \(seconds)")
        } else {
            createdAt = nil
            print("⚠️ CreatedAt not found or invalid")
        }
        
        print("✅ User decoding completed successfully")
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encodeIfPresent(profilePictureUrl, forKey: .profilePictureUrl)
        try container.encodeIfPresent(googleId, forKey: .googleId)
        try container.encodeIfPresent(isGoogleSignIn, forKey: .isGoogleSignIn)
        try container.encodeIfPresent(fcmToken, forKey: .fcmToken)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastTokenUpdate, forKey: .lastTokenUpdate)
        try container.encodeIfPresent(recentlyViewed, forKey: .recentlyViewed)
        try container.encodeIfPresent(wishlist, forKey: .wishlist)
    }
    
    // Helper computed properties
    var displayName: String {
        name.isEmpty ? "User" : name
    }
    
    var displayEmail: String {
        email
    }
    
    var displayPhone: String {
        phone ?? "Not provided"
    }
    
    var displayDateOfBirth: String {
        guard let dateOfBirth = dateOfBirth else { return "Not provided" }
        let date = dateOfBirth.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}
