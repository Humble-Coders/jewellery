import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    @EnvironmentObject var router: AppRouter
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    private let balanceCardGray = Color(hex: "#F5F5F5")
    private let textGray = Color(hex: "#666666")
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Account Balance Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account Balance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textGray)
                        Text(viewModel.formattedBalance)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(balanceCardGray)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Order History Content
                    if viewModel.orders.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        ordersList
                    }
                }
                .padding(.bottom, 24)
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
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
        .onAppear {
            router.currentRoute = .orderHistory
            viewModel.loadData()
        }
        .refreshable {
            viewModel.refreshData()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(textGray)
            Text("No Orders Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            Text("Your order history will appear here")
                .font(.system(size: 14))
                .foregroundColor(textGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
    
    private var ordersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Orders")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
            
            ForEach(viewModel.orders) { order in
                OrderCard(order: order)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Order Card
struct OrderCard: View {
    let order: Order
    @State private var showPDFViewer = false
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    private let cardGray = Color(hex: "#F9F9F9")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.displayId)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#888888"))
                    Text(order.formattedDate)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black)
                }
                Spacer()
                Text(order.formattedAmount)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryBrown)
            }
            
            if let invoiceUrl = order.invoiceUrl, !invoiceUrl.isEmpty, let url = URL(string: invoiceUrl) {
                Button {
                    showPDFViewer = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 14))
                        Text("View Bill")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(primaryBrown)
                }
                .fullScreenCover(isPresented: $showPDFViewer) {
                    PDFViewerView(pdfUrl: url, orderId: order.id)
                }
            }
        }
        .padding(16)
        .background(cardGray)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        OrderHistoryView()
            .environmentObject(AppRouter())
    }
}
