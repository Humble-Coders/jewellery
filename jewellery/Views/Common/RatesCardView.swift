import SwiftUI

/// Card showing metal rates preview - for sidebar
struct RatesCardView: View {
    let metalRates: [MaterialWithRates]
    let onTap: () -> Void

    private let goldColor = Color(hex: "#C9A87C")
    private let silverColor = Color(hex: "#9E9E9E")

    private var goldMaterial: MaterialWithRates? {
        metalRates.first { $0.name.lowercased().contains("gold") }
    }

    private var goldDisplay: (purity: String, rate: Double)? {
        guard let m = goldMaterial else { return nil }
        let type = m.types.first { $0.purity.lowercased().contains("24") } ?? m.types.first
        return type.map { ($0.purity, $0.rate) }
    }

    private var silverMaterial: MaterialWithRates? {
        metalRates.first { $0.name.lowercased().contains("silver") }
    }

    private var silverDisplay: (purity: String, rate: Double)? {
        guard let m = silverMaterial else { return nil }
        let type = m.types.first { $0.purity.contains("999") } ?? m.types.first
        return type.map { ($0.purity, $0.rate) }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                    Text("Rates")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                }
                HStack(spacing: 0) {
                    if let gold = goldDisplay, let mat = goldMaterial {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(goldColor)
                                    .frame(width: 8, height: 8)
                                Text("\(gold.purity) \(mat.name)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Text(formatPrice(gold.rate))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if goldDisplay != nil, silverDisplay != nil {
                        Rectangle()
                            .fill(Color(hex: "#E0E0E0"))
                            .frame(width: 1, height: 36)
                            .padding(.horizontal, 8)
                    }
                    if let silver = silverDisplay, let mat = silverMaterial {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(silverColor)
                                    .frame(width: 8, height: 8)
                                Text("\(mat.name) \(silver.purity)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Text(formatPrice(silver.rate))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if goldDisplay == nil, silverDisplay == nil {
                        Text("Tap to view rates")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E8E8E8"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
        

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let ns = NSNumber(value: value)
        return "₹\(formatter.string(from: ns) ?? "\(Int(value))")"
    }
}
    

/// Full "Today's Rates" dialog/sheet
struct TodaysRatesDialog: View {
    let metalRates: [MaterialWithRates]
    let lastUpdated: Date?
    let onDismiss: () -> Void

    private let goldBgColor = Color(hex: "#FDF5E6")
    private let silverBgColor = Color(hex: "#F5F5F5")
    private let goldDotColor = Color(hex: "#C9A87C")
    private let silverDotColor = Color(hex: "#9E9E9E")

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy 'at' hh:mm a"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#9A9A9A"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Rates")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Live precious metal prices")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(20)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(metalRates) { material in
                        ForEach(material.types) { type in
                            let isGold = material.name.lowercased().contains("gold")
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(isGold ? goldDotColor : silverDotColor)
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(type.purity) \(material.name) (per gram)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                    Text(formatPrice(type.rate))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isGold ? goldBgColor : silverBgColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            if let date = lastUpdated {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last updated")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(hex: "#F5F5F5"))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return "₹\(formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))")"
    }
}
