import SwiftUI
import SDWebImageSwiftUI

struct StoreInfoView: View {
    @StateObject private var viewModel = StoreInfoViewModel()
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F5")
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.storeInfo == nil {
                LoadingView()
            } else if let store = viewModel.storeInfo {
                ScrollView {
                    VStack(spacing: 16) {
                        // Logo Section
                        logoSection(store: store)
                        
                        // Store Name and Address Card
                        storeDetailsCard(store: store)
                        
                        // Contact Information Card
                        contactInformationCard(store: store)
                        
                        // Store Hours Card
                        if let _ = viewModel.storeInfo?.storeHours {
                            storeHoursCard()
                        }
                    }
                    .padding(.vertical, 16)
                }
            } else {
                // Error state
                ErrorView(message: viewModel.errorMessage ?? "Unable to load store information") {
                    viewModel.loadStoreData()
                }
            }
        }
        .navigationTitle("Store Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
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
        .onAppear {
            router.currentRoute = .storeInfo
        }
    }
    
    // MARK: - Logo Section
    
    private func logoSection(store: StoreInfo) -> some View {
        VStack(spacing: 0) {
            if let logoUrl = store.logoUrl, !logoUrl.isEmpty {
                WebImage(url: URL(string: logoUrl))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            } else {
                // Placeholder logo
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 280, height: 200)
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#C9A87C"))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Store Details Card
    
    private func storeDetailsCard(store: StoreInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Store Name
            Text(store.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#A08C80"))
            
            // Address Section
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#6B5A52"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Address")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                        .padding(.bottom, 5)
                    
                    Text(store.formattedAddress)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Get Directions Button
            Button(action: {
                viewModel.openDirections()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                    
                    Text("Get Directions")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "#926F6F"))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Contact Information Card
    
    private func contactInformationCard(store: StoreInfo) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Contact Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            // Primary Phone
            contactRow(
                icon: "phone.fill",
                label: "Primary Phone",
                value: store.primaryPhone,
                action: {
                    viewModel.callPrimaryPhone()
                }
            )
            
            // Secondary Phone (if available)
            if let secondaryPhone = store.secondaryPhone {
                contactRow(
                    icon: "phone.fill",
                    label: "Secondary Phone",
                    value: secondaryPhone,
                    action: {
                        viewModel.callSecondaryPhone()
                    }
                )
            }
            
            // Email
            contactRow(
                icon: "envelope.fill",
                label: "Email",
                value: store.email,
                action: {
                    viewModel.sendEmail()
                }
            )
            
            // WhatsApp Button
//            Button(action: {
//                viewModel.openWhatsApp()
//            }) {
//                HStack(spacing: 8) {
//                    Image(systemName: "message.fill")
//                        .font(.system(size: 16))
//                    
//                    Text("Chat on WhatsApp")
//                        .font(.system(size: 16, weight: .semibold))
//                }
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .frame(height: 50)
//                .background(Color(hex: "#25D366"))
//                .cornerRadius(8)
//            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Contact Row
    
    private func contactRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#6B5A52"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                    
                    Text(value)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Store Hours Card
    
    private func storeHoursCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with Status Badge
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6B5A52"))
                
                Text("Store Hours")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Open/Closed Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isOpenNow ? Color(hex: "#4CAF50") : Color(hex: "#FF0000"))
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isOpenNow ? "OPEN" : "CLOSED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(viewModel.isOpenNow ? Color(hex: "#4CAF50") : Color(hex: "#FF0000"))
                }
            }
            
            // Current Time Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#9A9A9A"))
                
                Text(viewModel.currentTime)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            // Today Section
            if let todayHours = viewModel.todayHours {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                    
                    HStack {
                        let calendar = Calendar.current
                        let weekday = calendar.component(.weekday, from: Date())
                        let dayName = StoreInfo.dayName(for: weekday)
                        
                        Text(dayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text(todayHours)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#4CAF50"))
                    }
                }
            }
            
            Divider()
            
            // Weekly Schedule Section
            if let storeHours = viewModel.storeInfo?.storeHours {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Schedule")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                    
                    VStack(spacing: 13) {
                        storeHourRow(day: "Monday", hours: storeHours["monday"] ?? "Closed")
                        storeHourRow(day: "Tuesday", hours: storeHours["tuesday"] ?? "Closed")
                        storeHourRow(day: "Wednesday", hours: storeHours["wednesday"] ?? "Closed")
                        storeHourRow(day: "Thursday", hours: storeHours["thursday"] ?? "Closed")
                        storeHourRow(day: "Friday", hours: storeHours["friday"] ?? "Closed")
                        storeHourRow(day: "Saturday", hours: storeHours["saturday"] ?? "Closed")
                        storeHourRow(day: "Sunday", hours: storeHours["sunday"] ?? "Closed")
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Store Hour Row
    
    private func storeHourRow(day: String, hours: String) -> some View {
        HStack {
            Text(day)
                .font(.system(size: 15))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(hours)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#4CAF50"))
        }
    }
}

#Preview {
    NavigationStack {
        StoreInfoView()
            .environmentObject(AppRouter())
    }
}
