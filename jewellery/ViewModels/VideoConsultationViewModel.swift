import Foundation
import Combine

@MainActor
class VideoConsultationViewModel: BaseViewModel {
    // MARK: - Published State
    
    @Published var availabilities: [Availability] = []
    @Published var selectedDate: Date?
    @Published var selectedAvailability: Availability?
    @Published var availableSlots: [TimeSlot] = []
    @Published var selectedSlot: TimeSlot?
    @Published var upcomingBookings: [Booking] = []
    @Published var consultationHistory: [Booking] = []
    
    // Phone validation state
    @Published var userPhone: String?
    @Published var showPhoneDialog = false
    @Published var phoneInput = ""
    @Published var phoneUpdateSuccess = false
    @Published var phoneUpdateError: String?
    
    /// Continuation for phone dialog flow (replaces busy-loop polling)
    private var phoneDialogContinuation: CheckedContinuation<Void, Never>?
    
    // Booking state
    @Published var bookingSuccess = false
    @Published var bookingSuccessMessage: String?
    @Published var bookingError: String?
    @Published var isBooking = false
    
    // Loading states
    @Published var isLoadingSlots = false
    @Published var isLoadingBookings = false
    
    private let service = VideoConsultationService.shared
    private var allConfirmedBookings: [Booking] = []
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        loadInitialData()
    }
    
    // MARK: - Load Initial Data
    
    func loadInitialData() {
        Task {
            await loadAvailabilities()
            await loadUpcomingBookings()
        }
    }
    
    // MARK: - Load Availabilities
    
    private func loadAvailabilities() async {
        do {
            let fetched = try await service.fetchAllAvailabilities()
            availabilities = fetched
        } catch {
            #if DEBUG
            print("❌ Failed to load availabilities: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Availabilities for Date
    
    func loadAvailabilitiesForDate(_ date: Date) async {
        isLoadingSlots = true
        
        do {
            let fetched = try await service.fetchAvailabilities(for: date)
            availabilities = fetched
            
            // Reset dependent state
            selectedAvailability = nil
            availableSlots = []
            selectedSlot = nil
            
        } catch {
            #if DEBUG
            print("❌ Failed to load availabilities for date: \(error)")
            #endif
        }
        
        isLoadingSlots = false
    }
    
    // MARK: - Load Upcoming Bookings
    
    func loadUpcomingBookings() async {
        isLoadingBookings = true
        
        do {
            let fetched = try await service.fetchUpcomingBookings()
            upcomingBookings = fetched
        } catch {
            #if DEBUG
            print("❌ Failed to load upcoming bookings: \(error)")
            #endif
        }
        
        isLoadingBookings = false
    }
    
    // MARK: - Load Consultation History
    
    func loadConsultationHistory() async {
        do {
            let history = try await service.fetchConsultationHistory()
            consultationHistory = history
        } catch {
            #if DEBUG
            print("❌ Failed to load consultation history: \(error)")
            #endif
        }
    }
    
    // MARK: - Generate Time Slots
    
    func generateSlots(for availability: Availability) async {
        selectedAvailability = availability
        isLoadingSlots = true
        
        // Load confirmed bookings for the selected date only (reduces reads)
        do {
            allConfirmedBookings = try await service.fetchAllConfirmedBookings(for: availability.startDate)
        } catch {
            #if DEBUG
            print("⚠️ Failed to load confirmed bookings: \(error)")
            #endif
            allConfirmedBookings = []
        }
        
        var slots: [TimeSlot] = []
        let duration = TimeInterval(availability.slotDuration * 60) // Convert to seconds
        
        var currentStart = availability.startDate
        let end = availability.endDate
        
        while currentStart.addingTimeInterval(duration) <= end {
            let slotEnd = currentStart.addingTimeInterval(duration)
            
            // Check if this slot is booked
            let isBooked = isSlotBooked(start: currentStart, end: slotEnd)
            
            let slot = TimeSlot(
                startTime: currentStart,
                endTime: slotEnd,
                isBooked: isBooked,
                availabilityId: availability.id ?? ""
            )
            
            slots.append(slot)
            currentStart = slotEnd
        }
        
        availableSlots = slots.sorted { $0.startTime < $1.startTime }
        selectedSlot = nil
        isLoadingSlots = false
        
        #if DEBUG
        print("✅ Generated \(slots.count) time slots")
        #endif
    }
    
    // MARK: - Check Slot Booking Status
    
    private func isSlotBooked(start: Date, end: Date) -> Bool {
        for booking in allConfirmedBookings {
            let bookingStart = booking.startDate
            let bookingEnd = booking.endDate
            
            // Check for overlap
            if start < bookingEnd && end > bookingStart {
                return true
            }
        }
        return false
    }
    
    // MARK: - Book Slot
    
    func bookSlot(_ slot: TimeSlot) async {
        // Validate phone number first
        do {
            try await validateAndUpdatePhoneIfNeeded()
        } catch {
            // Phone validation failed or was cancelled
            return
        }
        
        isBooking = true
        clearBookingMessages()
        
        do {
            // Create booking atomically
            let bookingId = try await service.createBooking(
                startTime: slot.startTime,
                endTime: slot.endTime
            )
            
            bookingSuccess = true
            bookingSuccessMessage = "Booking confirmed! ID: \(bookingId)"
            
            // Refresh slots and upcoming bookings
            if let availability = selectedAvailability {
                await generateSlots(for: availability)
            }
            await loadUpcomingBookings()
            
        } catch {
            bookingError = error.localizedDescription
            #if DEBUG
            print("❌ Booking failed: \(error)")
            #endif
        }
        
        isBooking = false
    }
    
    // MARK: - Phone Validation
    
    private func validateAndUpdatePhoneIfNeeded() async throws {
        // Fetch user profile
        let user = try await service.fetchUserProfile()
        
        // Check if phone exists
        if let phone = user.phone, !phone.isEmpty {
            userPhone = phone
            return // Phone exists, no need to update
        }
        
        // Show phone dialog and wait for user input
        await showPhoneDialogAndWait()
        
        // After dialog dismissed, verify phone was actually provided
        guard let phone = userPhone, !phone.isEmpty else {
            throw NSError(domain: "VideoConsultation", code: 400, userInfo: [NSLocalizedDescriptionKey: "Phone number is required to book a consultation"])
        }
    }
    
    private func showPhoneDialogAndWait() async {
        await withCheckedContinuation { continuation in
            phoneDialogContinuation = continuation
            showPhoneDialog = true
        }
    }
    
    // MARK: - Update Phone
    
    func updatePhone() async {
        guard !phoneInput.isEmpty else {
            phoneUpdateError = "Please enter a phone number"
            return
        }
        
        isLoading = true
        phoneUpdateError = nil
        
        do {
            try await service.updateUserPhone(phone: phoneInput)
            
            userPhone = phoneInput
            phoneUpdateSuccess = true
            phoneUpdateError = nil
            
            // Close dialog after short delay and resume the waiting continuation
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            showPhoneDialog = false
            resumePhoneDialogContinuation()
            
        } catch {
            phoneUpdateError = error.localizedDescription
            #if DEBUG
            print("❌ Phone update failed: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - State Management
    
    func selectDate(_ date: Date) {
        selectedDate = date
        
        // Reset dependent state
        selectedAvailability = nil
        availableSlots = []
        selectedSlot = nil
        
        // Load availabilities for this date
        Task {
            await loadAvailabilitiesForDate(date)
        }
    }
    
    func selectSlot(_ slot: TimeSlot) {
        guard !slot.isBooked else { return }
        selectedSlot = slot
    }
    
    // MARK: - Reset & Cleanup
    
    func resetBookingFlow() {
        selectedDate = nil
        selectedAvailability = nil
        availableSlots = []
        selectedSlot = nil
        clearBookingMessages()
    }
    
    func clearBookingMessages() {
        bookingSuccess = false
        bookingSuccessMessage = nil
        bookingError = nil
    }
    
    func clearPhoneMessages() {
        phoneUpdateSuccess = false
        phoneUpdateError = nil
    }
    
    func dismissPhoneDialog() {
        showPhoneDialog = false
        phoneInput = ""
        clearPhoneMessages()
        resumePhoneDialogContinuation()
    }
    
    /// Safely resumes the phone dialog continuation exactly once, preventing double-resume crashes.
    private func resumePhoneDialogContinuation() {
        guard let continuation = phoneDialogContinuation else { return }
        phoneDialogContinuation = nil
        continuation.resume()
    }
    
    // MARK: - Refresh Slots
    
    func refreshSlots() async {
        guard let availability = selectedAvailability else { return }
        await generateSlots(for: availability)
    }
}
