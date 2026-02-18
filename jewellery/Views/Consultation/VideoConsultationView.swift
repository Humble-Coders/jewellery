import SwiftUI

struct VideoConsultationView: View {
    @StateObject private var viewModel = VideoConsultationViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var showDatePicker = false
    @State private var currentStep = 1
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F5")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card
                    heroCard
                    
                    // Steps Indicator
                    stepsIndicator
                    
                    // Current Step Content
                    if currentStep == 1 {
                        dateSelectionStep
                    } else if currentStep == 2 {
                        availabilitySelectionStep
                    } else if currentStep == 3 {
                        slotSelectionStep
                    }
                }
                .padding(.vertical, 20)
            }
            
            // Phone Number Dialog
            if viewModel.showPhoneDialog {
                phoneNumberDialog
            }
            
            // Success Dialog
            if viewModel.bookingSuccess {
                bookingSuccessDialog
            }
        }
        .navigationTitle("Video Consultation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.navigate(to: .home)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    router.push(to: .myBookings)
                } label: {
                    Image(systemName: "clock")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: Binding(
                    get: { viewModel.selectedDate ?? Date() },
                    set: { date in
                        viewModel.selectDate(date)
                        currentStep = 2
                        showDatePicker = false
                    }
                )
            )
        }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            Text("Book Your Video Consultation")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Connect with our jewelry experts for personalized advice")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(Color(hex: "#8B7171"))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Steps Indicator
    
    private var stepsIndicator: some View {
        HStack(spacing: 40) {
            stepBadge(number: 1, label: "Date", isActive: currentStep >= 1, isCompleted: currentStep > 1)
            stepBadge(number: 2, label: "Availability", isActive: currentStep >= 2, isCompleted: currentStep > 2)
            stepBadge(number: 3, label: "Slot", isActive: currentStep >= 3, isCompleted: false)
        }
        .padding(.horizontal, 16)
    }
    
    private func stepBadge(number: Int, label: String, isActive: Bool, isCompleted: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color(hex: "#4CAF50") : (isActive ? Color(hex: "#8B7171") : Color(hex: "#CCCCCC")))
                    .frame(width: 50, height: 50)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? .black : Color(hex: "#CCCCCC"))
        }
    }
    
    // MARK: - Step 1: Date Selection
    
    private var dateSelectionStep: some View {
        VStack(spacing: 20) {
            // Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#CCCCCC"))
                
                Text("Select Date")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Choose the date for your video consultation")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 40)
            
            // Pick a Date Button
            Button(action: {
                showDatePicker = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                    
                    Text("Pick a Date")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "#8B7171"))
                .cornerRadius(8)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Step 2: Availability Selection
    
    private var availabilitySelectionStep: some View {
        VStack(spacing: 16) {
            // Selected Date with Back Button
            HStack {
                Button(action: {
                    currentStep = 1
                    viewModel.selectedDate = nil
                    viewModel.selectedAvailability = nil
                    viewModel.availableSlots = []
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#8B7171"))
                }
                
                if let date = viewModel.selectedDate {
                    Text(
                        DateFormatter.localizedString(
                            from: date,
                            dateStyle: .medium,
                            timeStyle: .none
                        )
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                }

                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Available Time Blocks Title
            Text("Available Time Blocks")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
            
            if viewModel.isLoadingSlots {
                VStack(spacing: 16) {
                    ProgressView()
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
            } else if viewModel.availabilities.isEmpty {
                // No Availability
                noAvailabilityView
            } else {
                // Show availabilities
                VStack(spacing: 12) {
                    ForEach(viewModel.availabilities) { availability in
                        availabilityCard(availability)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func availabilityCard(_ availability: Availability) -> some View {
        Button(action: {
            currentStep = 3
            Task {
                await viewModel.generateSlots(for: availability)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(availability.formattedDate)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(availability.formattedTimeRange)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
    
    private var noAvailabilityView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#CCCCCC"))
            
            Text("No Availability")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            Text("No time blocks are available for this date. Please select a different date.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Step 3: Slot Selection
    
    private var slotSelectionStep: some View {
        VStack(spacing: 16) {
            // Selected Date with Back Button
            HStack {
                Button(action: {
                    currentStep = 2
                    viewModel.selectedAvailability = nil
                    viewModel.availableSlots = []
                    viewModel.selectedSlot = nil
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#8B7171"))
                }
                
                if viewModel.selectedDate != nil {
                    Text(formattedSelectedDate)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }

                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Available Time Slots Title
            Text("Available Time Slots")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
            
            if viewModel.isLoadingSlots {
                VStack(spacing: 16) {
                    ProgressView()
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
            } else if viewModel.availableSlots.isEmpty {
                // No slots available
                noAvailabilityView
            } else {
                // Slots Grid
                slotsGridView
                
                // Confirm Button
                if viewModel.selectedSlot != nil {
                    confirmBookingButton
                }
            }
        }
    }
    
    private var formattedSelectedDate: String {
        guard let date = viewModel.selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    private var slotsGridView: some View {
        VStack(spacing: 16) {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.availableSlots) { slot in
                    slotCard(slot)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    private func slotCard(_ slot: TimeSlot) -> some View {
        Button(action: {
            if !slot.isBooked {
                viewModel.selectSlot(slot)
            }
        }) {
            VStack(spacing: 4) {
                Text(slot.formattedTime)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(slot.isBooked ? .white : (viewModel.selectedSlot?.id == slot.id ? .white : .black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                slot.isBooked ? Color(hex: "#CCCCCC") :
                (viewModel.selectedSlot?.id == slot.id ? Color(hex: "#8B7171") : Color(hex: "#F5F5F5"))
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        viewModel.selectedSlot?.id == slot.id ? Color(hex: "#8B7171") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(slot.isBooked)
    }
    
    private var confirmBookingButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                if let slot = viewModel.selectedSlot {
                    Task {
                        await viewModel.bookSlot(slot)
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isBooking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(viewModel.isBooking ? "Booking..." : "Confirm Booking")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "#8B7171"))
                .cornerRadius(8)
            }
            .disabled(viewModel.isBooking)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            if let error = viewModel.bookingError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Phone Number Dialog
    
    private var phoneNumberDialog: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Phone Number Required")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Please provide your phone number to complete the booking")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("Enter phone number", text: $viewModel.phoneInput)
                    .keyboardType(.phonePad)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color(hex: "#F5F5F5"))
                    .cornerRadius(8)
                
                if let error = viewModel.phoneUpdateError {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.dismissPhoneDialog()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                    
                    Button("Submit") {
                        Task {
                            await viewModel.updatePhone()
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#8B7171"))
                    .cornerRadius(8)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Booking Success Dialog
    
    private var bookingSuccessDialog: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#4CAF50"))
                
                Text("Booking Confirmed!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                if let message = viewModel.bookingSuccessMessage {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("View My Bookings") {
                    viewModel.clearBookingMessages()
                    router.push(to: .myBookings)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "#8B7171"))
                .cornerRadius(8)
                
                Button("Book Another") {
                    viewModel.clearBookingMessages()
                    viewModel.resetBookingFlow()
                    currentStep = 1
                }
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8B7171"))
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select date")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text("Selected date")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    
                    Button("Select") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#8B7171"))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VideoConsultationView()
            .environmentObject(AppRouter())
    }
}
