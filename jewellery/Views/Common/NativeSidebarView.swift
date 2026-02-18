import SwiftUI
import FirebaseAuth

/// Native sidebar menu content - used in NavigationSplitView sidebar and in sheet
struct NativeSidebarContent: View {
    @EnvironmentObject var router: AppRouter
    @Binding var isPresented: Bool
    @StateObject private var viewModel = SidebarViewModel()
    @StateObject private var getInTouchViewModel = GetInTouchViewModel()
    @State private var expandedMetal = false
    @State private var expandedCategories = false
    @State private var userName: String = ""
    @State private var showRatesDialog = false
    @State private var showGetInTouchAlert = false
    
    private func dismissAndNavigate(_ action: () -> Void) {
        action()
        isPresented = false
    }
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: "#E8E8E8"))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Color(hex: "#9A9A9A"))
                                .font(.system(size: 24))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back!")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#666666"))
                        Text(userName.isEmpty ? "Guest" : userName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            }
            .listSectionSeparator(.hidden)
            
            Section {
                Button { dismissAndNavigate { router.navigate(to: .profile) } } label: {
                    Label("My Profile", systemImage: "person")
                }
                Button { dismissAndNavigate { router.navigate(to: .orderHistory, clearStack: true) } } label: {
                    Label("Order History", systemImage: "doc.text")
                }
            }
            
//            Section {
//                RatesCardView(metalRates: viewModel.metalRates) {
//                    showRatesDialog = true
//                }
//                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
//                .listRowBackground(Color.clear)
//            }

            Section("Shop By") {
                Button { dismissAndNavigate { router.navigate(to: .allProducts(), clearStack: true) } } label: {
                    Label("All Jewellery", systemImage: "square.grid.2x2")
                }
                
                DisclosureGroup("Metal", isExpanded: $expandedMetal) {
                    ForEach(viewModel.metals) { metal in
                        Button {
                            dismissAndNavigate {
                                router.navigate(to: .allProducts(metalId: metal.id, metalName: metal.name), clearStack: true)
                            }
                        }                         label: {
                            Text(metal.name)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#79696C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                DisclosureGroup("Categories", isExpanded: $expandedCategories) {
                    ForEach(viewModel.categories) { category in
                        Button {
                            dismissAndNavigate {
                                router.navigate(to: .categoryProducts(categoryId: category.id, categoryName: category.name), clearStack: true)
                            }
                        }                         label: {
                            Text(category.name)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#79696C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            
            Section {
                RatesCardView(metalRates: viewModel.metalRates) {
                    showRatesDialog = true
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .padding(.top, -10)
            .padding(.bottom, -10)
            
            Section("More") {
                Button { dismissAndNavigate { router.navigate(to: .videoConsultation, clearStack: true) } } label: {
                    Label("Video Call Consultation", systemImage: "headphones")
                }
                Button { dismissAndNavigate { router.navigate(to: .storeInfo, clearStack: true) } } label: {
                    Label("Store Info", systemImage: "mappin")
                }
                
                // Get In Touch - Opens WhatsApp
                Button {
                    isPresented = false
                    getInTouchViewModel.openWhatsApp()
                } label: {
                    HStack {
                        Label("Get In Touch", systemImage: "message.fill")
                        if getInTouchViewModel.isLoading {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                
                Button {
                    isPresented = false
                    openStoreInMaps()
                } label: {
                    Label("Store Locator", systemImage: "mappin")
                }
                Button { logout() } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .foregroundStyle(Color(hex: "#79696C"))
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadUserData()
            viewModel.loadData()
        }
        .sheet(isPresented: $showRatesDialog) {
            TodaysRatesDialog(
                metalRates: viewModel.metalRates,
                lastUpdated: viewModel.ratesLastUpdated
            ) {
                showRatesDialog = false
            }
        }
        .alert("Contact Error", isPresented: Binding(
            get: { getInTouchViewModel.errorMessage != nil },
            set: { if !$0 { getInTouchViewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                getInTouchViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = getInTouchViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            userName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User"
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            isPresented = false
            router.navigate(to: .welcome, clearStack: true)
        } catch {
            #if DEBUG
            print("Error signing out: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Opens Apple Maps (with Google Maps browser fallback) - same logic as Get Directions on Store Info screen
    private func openStoreInMaps() {
        Task {
            do {
                let storeInfo = try await StoreInfoService.shared.fetchStoreInfo()
                let storeName = storeInfo.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? storeInfo.name
                let appleMapsUrl = "http://maps.apple.com/?ll=\(storeInfo.latitude),\(storeInfo.longitude)&q=\(storeName)"
                
                await MainActor.run {
                    if let url = URL(string: appleMapsUrl), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    } else {
                        // Fallback to Google Maps in browser
                        let googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=\(storeInfo.latitude),\(storeInfo.longitude)"
                        if let url = URL(string: googleMapsUrl) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } catch {
                #if DEBUG
                print("❌ Failed to open store in maps: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

#Preview {
    NavigationStack {
        NativeSidebarContent(isPresented: .constant(true))
            .environmentObject(AppRouter())
    }
}
