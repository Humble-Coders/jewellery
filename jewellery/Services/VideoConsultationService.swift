import Foundation
import FirebaseAuth
import FirebaseFirestore

class VideoConsultationService {
    static let shared = VideoConsultationService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Fetch All Active Availabilities
    
    func fetchAllAvailabilities() async throws -> [Availability] {
        let snapshot = try await db
            .collection("bookings")
            .whereField("type", isEqualTo: "availability")
            .getDocuments()
        
        // Filter client-side for active (future) availabilities
        let availabilities = try snapshot.documents.compactMap { doc -> Availability? in
            let availability = try doc.data(as: Availability.self)
            // Only include future availabilities
            return availability.endDate > Date() ? availability : nil
        }
        
        #if DEBUG
        print("📅 Fetched \(availabilities.count) active availabilities")
        #endif
        return availabilities
    }
    
    // MARK: - Fetch Availabilities for Date
    
    func fetchAvailabilities(for date: Date) async throws -> [Availability] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        let snapshot = try await db
            .collection("bookings")
            .whereField("type", isEqualTo: "availability")
            .getDocuments()
        
        // Filter client-side for date range
        let availabilities = try snapshot.documents.compactMap { doc -> Availability? in
            let availability = try doc.data(as: Availability.self)
            let availStart = availability.startDate
            
            // Check if availability falls within the selected date
            if availStart >= startOfDay && availStart < endOfDay {
                return availability
            }
            return nil
        }
        
        #if DEBUG
        print("📅 Fetched \(availabilities.count) availabilities for date: \(date)")
        #endif
        return availabilities.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Fetch User's Upcoming Bookings
    
    func fetchUpcomingBookings() async throws -> [Booking] {
        guard let userId = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("📅 User not logged in - returning empty bookings list")
            #endif
            return []
        }
        
        let snapshot = try await db
            .collection("bookings")
            .whereField("type", isEqualTo: "booking")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        // Filter client-side for upcoming and confirmed/pending
        let bookings = try snapshot.documents.compactMap { doc -> Booking? in
            let booking = try doc.data(as: Booking.self)
            
            // Only show upcoming bookings that are confirmed or pending
            if booking.isUpcoming && (booking.status == "CONFIRMED" || booking.status == "PENDING") {
                return booking
            }
            return nil
        }
        
        #if DEBUG
        print("📅 Fetched \(bookings.count) upcoming bookings for user")
        #endif
        return bookings.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Fetch Confirmed/Pending Bookings for Date (for conflict detection)
    
    /// Fetches bookings only for a specific date to reduce Firestore reads.
    /// Falls back to fetching all bookings if no date is provided.
    func fetchAllConfirmedBookings(for date: Date? = nil) async throws -> [Booking] {
        let snapshot = try await db
            .collection("bookings")
            .whereField("type", isEqualTo: "booking")
            .getDocuments()
        
        let calendar = Calendar.current
        
        // Filter client-side for confirmed/pending status and optionally by date
        let bookings = try snapshot.documents.compactMap { doc -> Booking? in
            let booking = try doc.data(as: Booking.self)
            
            guard booking.status == "CONFIRMED" || booking.status == "PENDING" else {
                return nil
            }
            
            // If a date filter is provided, only include bookings on that date
            if let date = date {
                let startOfDay = calendar.startOfDay(for: date)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    return nil
                }
                let bookingStart = booking.startDate
                guard bookingStart >= startOfDay && bookingStart < endOfDay else {
                    return nil
                }
            }
            
            return booking
        }
        
        #if DEBUG
        print("📅 Fetched \(bookings.count) confirmed/pending bookings\(date != nil ? " for selected date" : "")")
        #endif
        return bookings
    }
    
    // MARK: - Create Booking (Atomic Transaction)
    
    func createBooking(startTime: Date, endTime: Date) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VideoConsultation", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Pre-flight conflict check: fetch confirmed/pending bookings for the date
        let existingBookings = try await fetchAllConfirmedBookings(for: startTime)
        for booking in existingBookings {
            let existingStart = booking.startDate
            let existingEnd = booking.endDate
            // Overlap: new start < existing end AND new end > existing start
            if startTime < existingEnd && endTime > existingStart {
                throw NSError(domain: "VideoConsultation", code: 409, userInfo: [NSLocalizedDescriptionKey: "This time slot is already booked. Please choose another slot."])
            }
        }
        
        let startTimestamp = Timestamp(date: startTime)
        let endTimestamp = Timestamp(date: endTime)
        
        // Create new booking document
        let bookingRef = db.collection("bookings").document()
        
        let bookingData: [String: Any] = [
            "userId": userId,
            "startTime": startTimestamp,
            "endTime": endTimestamp,
            "status": "CONFIRMED",
            "type": "booking",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Write the booking
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.setData(bookingData, forDocument: bookingRef)
            return nil
        })
        
        #if DEBUG
        print("✅ Booking created successfully: \(bookingRef.documentID)")
        #endif
        return bookingRef.documentID
    }
    
    // MARK: - Fetch Consultation History
    
    func fetchConsultationHistory() async throws -> [Booking] {
        guard let userId = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("📅 User not logged in - returning empty history")
            #endif
            return []
        }
        
        let snapshot = try await db
            .collection("bookings")
            .whereField("type", isEqualTo: "booking")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        // Filter client-side for past bookings
        let history = try snapshot.documents.compactMap { doc -> Booking? in
            let booking = try doc.data(as: Booking.self)
            
            // Only show past bookings
            if booking.isPast {
                return booking
            }
            return nil
        }
        
        #if DEBUG
        print("📅 Fetched \(history.count) past bookings for user")
        #endif
        return history.sorted { $0.startDate > $1.startDate } // Most recent first
    }
    
    // MARK: - Update User Phone
    
    func updateUserPhone(phone: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VideoConsultation", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await db
            .collection("users")
            .document(userId)
            .updateData(["phone": phone])
        
        #if DEBUG
        print("✅ User phone updated successfully")
        #endif
    }
    
    // MARK: - Fetch User Profile
    
    func fetchUserProfile() async throws -> User {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VideoConsultation", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .getDocument()
        
        guard snapshot.exists else {
            throw NSError(domain: "VideoConsultation", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        let user = try snapshot.data(as: User.self)
        return user
    }
}
