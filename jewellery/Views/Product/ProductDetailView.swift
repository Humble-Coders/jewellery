import SwiftUI
import SDWebImageSwiftUI

struct ProductDetailView: View {
    let productId: String
    
    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject var router: AppRouter
    @State private var isFavorite = false
    @State private var isTogglingWishlist = false
    @State private var selectedImageIndex = 0
    @State private var wishlistError: String?
    
    init(productId: String) {
        self.productId = productId
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productId: productId))
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Product image
                        if viewModel.showMap.images && !viewModel.imageUrls.isEmpty {
                            GeometryReader { geometry in
                                let imageSize = geometry.size.width
                                ZStack(alignment: .topTrailing) {
                                    TabView(selection: $selectedImageIndex) {
                                        ForEach(Array(viewModel.imageUrls.enumerated()), id: \.offset) { index, urlString in
                                            if let url = URL(string: urlString) {
                                                WebImage(url: url)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: imageSize)
                                                    .frame(height: imageSize)
                                                    .clipped()
                                                    .tag(index)
                                            }
                                        }
                                    }
                                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                                    .frame(height: imageSize)
                                
                                let shareURL = Constants.DeepLinks.productShareURL(
                                    productId: productId,
                                    name: viewModel.productName,
                                    price: viewModel.formattedPrice
                                )
                                ShareLink(
                                    item: Constants.DeepLinks.productShareMessage(
                                        name: viewModel.productName,
                                        price: viewModel.formattedPrice,
                                        url: shareURL
                                    ),
                                    subject: Text("Exquisite Jewelry from Gagan Jewellers")
                                ) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(16)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                        
                        // Single details card
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            if viewModel.isPremiumCollection {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                                    Text("Premium Collection")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: "#666666"))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#F0F0F0"))
                                .cornerRadius(20)
                            }
                            
                            if viewModel.showMap.name {
                                Text(viewModel.productName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            if viewModel.showMap.price {
                                HStack(alignment: .top) {
                                    Text(viewModel.formattedPrice)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Button(action: {
                                        guard !isTogglingWishlist else { return }
                                        isTogglingWishlist = true
                                        let previousState = isFavorite
                                        isFavorite.toggle()
                                        wishlistError = nil
                                        Task {
                                            do {
                                                let result = try await WishlistService.shared.toggleWishlist(productId: productId)
                                                await MainActor.run { isFavorite = result }
                                            } catch {
                                                await MainActor.run {
                                                    isFavorite = previousState
                                                    wishlistError = (error as? WishlistError)?.errorDescription ?? "Could not update wishlist"
                                                }
                                            }
                                            await MainActor.run { isTogglingWishlist = false }
                                        }
                                    }) {
                                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                                            .font(.system(size: 22))
                                            .foregroundColor(isFavorite ? .red : .gray)
                                    }
                                    .disabled(isTogglingWishlist)
                                }
                                
                                Text("Exclusive of taxes")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.top, -7)
                            }
                            
                            // Material & Availability row
//                            HStack(spacing: Theme.Spacing.md) {
//                                if viewModel.showMap.material_id || viewModel.showMap.material_type {
//                                    DetailMiniCard(
//                                        icon: "gearshape.fill",
//                                        label: "Material",
//                                        value: viewModel.materialDisplay
//                                    )
//                                }
//                                if viewModel.showMap.quantity || true {
//                                    DetailMiniCard(
//                                        icon: "checkmark.circle.fill",
//                                        label: "Availability",
//                                        value: viewModel.availabilityDisplay
//                                    )
//                                }
//                            }
                            
                            // Detail grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                                if viewModel.showMap.material_id || viewModel.showMap.material_type, !viewModel.materialDisplay.isEmpty {
                                    DetailCard(icon: "gearshape.fill", label: "Material", value: viewModel.materialDisplay)
                                }
                                if viewModel.showMap.quantity {
                                    DetailCard(icon: "checkmark.circle.fill", label: "Availability", value: viewModel.availabilityDisplay)
                                }
                                if viewModel.showMap.material_weight, !viewModel.materialWeight.isEmpty {
                                    DetailCard(icon: "scalemass.fill", label: "Material Weight", value: viewModel.materialWeight)
                                }
                                if viewModel.showMap.effective_metal_weight, !viewModel.metalWeight.isEmpty {
                                    DetailCard(icon: "scalemass.fill", label: "Metal Weight", value: viewModel.metalWeight)
                                }
                                if viewModel.showMap.total_weight || viewModel.showMap.effective_weight, !viewModel.totalWeight.isEmpty {
                                    DetailCard(icon: "scalemass.fill", label: "Total Weight", value: viewModel.totalWeight)
                                }
                                if (viewModel.showMap.stones || viewModel.showMap.has_stones), !viewModel.stoneDisplay.isEmpty {
                                    DetailCard(icon: "diamond.fill", label: "Stone", value: viewModel.stoneDisplay)
                                }
                                if viewModel.showMap.stone_weight, !viewModel.stoneWeightDisplay.isEmpty {
                                    DetailCard(icon: "diamond.fill", label: "Stone Weight", value: viewModel.stoneWeightDisplay + " ct")
                                }
                                if viewModel.showMap.labour_charges, !viewModel.labourChargesDisplay.isEmpty {
                                    DetailCard(icon: "indianrupeesign", label: "Labour Charges", value: viewModel.labourChargesDisplay)
                                }
                                if viewModel.showMap.stone_amount, !viewModel.stoneAmountDisplay.isEmpty {
                                    DetailCard(icon: "diamond.fill", label: "Stone Amount", value: viewModel.stoneAmountDisplay)
                                }
                                if viewModel.showMap.price {
                                    DetailCard(icon: "percent", label: "GST", value: viewModel.gstDisplay)
                                }
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .background(Color.white)
                        .cornerRadius(Theme.CornerRadius.large)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)
                        
                        // Stone Details
                        if (viewModel.showMap.stones || viewModel.showMap.has_stones) && !viewModel.stoneDetails.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Stone Details")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, Theme.Spacing.md)
                                
                                VStack(spacing: 0) {
                                    ForEach(viewModel.stoneDetails) { stone in
                                        HStack {
                                            Text("Name")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(stone.name)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .padding(.vertical, 10)
                                        
                                        Divider()
                                        
                                        HStack {
                                            Text("Weight")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(stone.weight)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .padding(.vertical, 10)
                                        
                                        Divider()
                                        
                                        HStack {
                                            Text("Amount")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(stone.formattedAmount)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .padding(.vertical, 10)
                                    }
                                }
                                .background(Color(hex: "#F5F5F5"))
                                .cornerRadius(Theme.CornerRadius.medium)
                                .padding(.horizontal, Theme.Spacing.md)
                            }
                            .padding(.top, Theme.Spacing.lg)
                        }
                        
                        // Description
                        if viewModel.showMap.description && !viewModel.productDescription.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Description")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, Theme.Spacing.md)
                                
                                Text(viewModel.productDescription)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.bottom, Theme.Spacing.xl)
                            }
                            .padding(.top, Theme.Spacing.lg)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            if viewModel.showError, let message = viewModel.errorMessage {
                ErrorView(message: message) {
                    viewModel.refreshData()
                }
            }
        }
        .navigationTitle(viewModel.productName.isEmpty ? "Product" : viewModel.productName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.productName.isEmpty ? "Product" : viewModel.productName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        guard !isTogglingWishlist else { return }
                        isTogglingWishlist = true
                        let previousState = isFavorite
                        isFavorite.toggle()
                        wishlistError = nil
                        Task {
                            do {
                                let result = try await WishlistService.shared.toggleWishlist(productId: productId)
                                await MainActor.run { isFavorite = result }
                            } catch {
                                await MainActor.run {
                                    isFavorite = previousState
                                    wishlistError = (error as? WishlistError)?.errorDescription ?? "Could not update wishlist"
                                }
                            }
                            await MainActor.run { isTogglingWishlist = false }
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.white)
                    }
                    .disabled(isTogglingWishlist)
                    ShareLink(
                        item: Constants.DeepLinks.productShareMessage(
                            name: viewModel.productName,
                            price: viewModel.formattedPrice,
                            url: Constants.DeepLinks.productShareURL(
                                productId: productId,
                                name: viewModel.productName,
                                price: viewModel.formattedPrice
                            )
                        ),
                        subject: Text("Exquisite Jewelry from Gagan Jewellers")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            router.currentRoute = .itemDetail(productId: productId)
            if viewModel.productName.isEmpty {
                viewModel.refreshData()
            }
        }
        .task {
            isFavorite = await WishlistService.shared.isInWishlistAsync(productId: productId)
        }
        .alert("Wishlist", isPresented: Binding(
            get: { wishlistError != nil },
            set: { if !$0 { wishlistError = nil } }
        )) {
            Button("OK", role: .cancel) { wishlistError = nil }
        } message: {
            if let msg = wishlistError {
                Text(msg)
            }
        }
    }
}

// MARK: - Detail card (grid cell)
struct DetailCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Color(hex: "#F5F5F5"))
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Mini card (Material / Availability in white card)
struct DetailMiniCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(Color(hex: "#F8F8F8"))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(productId: "SP4kYLxevv19Rnr2mITZ")
            .environmentObject(AppRouter())
    }
}
