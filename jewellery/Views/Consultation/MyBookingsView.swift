import SwiftUI

struct MyBookingsView: View {
    @StateObject private var viewModel = VideoConsultationViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F5")
                .ignoresSafeArea()
            
            if viewModel.isLoadingBookings && viewModel.upcomingBookings.isEmpty {
                LoadingView()
            } else if viewModel.upcomingBookings.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.upcomingBookings) { booking in
                            bookingCard(booking)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .refreshable {
            await viewModel.loadUpcomingBookings()
        }
        .task {
            await viewModel.loadUpcomingBookings()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 70))
                .foregroundColor(Color(hex: "#CCCCCC"))
            
            Text("No Upcoming Bookings")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            Text("You haven't booked any video consultations yet")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                router.push(to: .videoConsultation)
            }) {
                Text("Book Consultation")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#8B7171"))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private func bookingCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status Badge
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: booking.statusColor))
                        .frame(width: 8, height: 8)
                    
                    Text(booking.status)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: booking.statusColor))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: booking.statusColor).opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            
            // Date and Time
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#8B7171"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.formattedDate)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(booking.formattedTimeRange)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Booking ID
            if let id = booking.id {
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("ID: \(id.prefix(8))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        MyBookingsView()
            .environmentObject(AppRouter())
    }
}
