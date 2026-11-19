import SwiftUI

public struct CareInventoryView: View {
    @ObservedObject var store = GrowCareStore.shared
    @State private var searchText: String = ""
    @State private var selectedZone: CareZone = .all
    @State private var selectedProduct: CareProduct? = nil

    private var filteredProducts: [CareProduct] {
        var list = store.products
        if selectedZone != .all {
            list = list.filter { $0.zone == selectedZone }
        }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.activeIngredients.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Status Card
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PRODUKT-INVENTAR")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1.0)
                                .foregroundColor(CareTheme.textMuted)

                            Text("Pflegemittel & Kasernen-Ausrüstung")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(CareTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(store.products.count) Artikel")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.careLilac)

                            let requestedCount = store.requestedShoppingProductIds.count
                            if requestedCount > 0 {
                                Text("\(requestedCount) in GrowFinance")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(CareTheme.careSage)
                            }
                        }
                    }
                    .careCard()

                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(CareTheme.textMuted)
                        TextField("Produkt, Marke oder Wirkstoff suchen...", text: $searchText)
                            .font(.system(size: 13))
                            .foregroundColor(CareTheme.textPrimary)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(CareTheme.textMuted)
                            }
                        }
                    }
                    .padding(10)
                    .background(CareTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(CareTheme.border, lineWidth: 1))

                    // Zone Pills Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CareZone.allCases) { zone in
                                let isSel = selectedZone == zone
                                Button(action: {
                                    let haptic = UIImpactFeedbackGenerator(style: .light)
                                    haptic.impactOccurred()
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                        selectedZone = zone
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: zone.icon)
                                            .font(.system(size: 10, weight: .bold))
                                        Text(zone.shortLabel)
                                            .font(.system(size: 11, weight: isSel ? .bold : .medium))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSel ? CareTheme.careLilac : CareTheme.surface)
                                    .foregroundColor(isSel ? CareTheme.bg : CareTheme.textSecondary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(isSel ? CareTheme.careLilac : CareTheme.border, lineWidth: 0.8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Products List
                    if filteredProducts.isEmpty {
                        VStack(spacing: 6) {
                            Text("Keine Artikel fuer diese Auswahl gefunden.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(CareTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .careCard()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredProducts) { product in
                                productCard(product)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(CareTheme.bg.ignoresSafeArea())
            .navigationTitle("Inventar")
            .sheet(item: $selectedProduct) { prod in
                CareProductDetailSheet(product: prod)
            }
        }
    }

    @ViewBuilder
    private func productCard(_ product: CareProduct) -> some View {
        let isRequested = store.isProductRequestedInFinance(product: product)

        Button(action: {
            selectedProduct = product
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(product.brand.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.careLilac)

                            Text(product.zone.shortLabel)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(CareTheme.surfaceElevated)
                                .foregroundColor(CareTheme.textMuted)
                                .clipShape(Capsule())
                        }

                        Text(product.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(CareTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f EUR", product.price))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(CareTheme.textPrimary)

                        Text(product.category)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(CareTheme.textSecondary)
                    }
                }

                Text(product.clinicalBenefit)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(CareTheme.textSecondary)
                    .lineLimit(2)

                HStack {
                    if let wait = product.layeringWaitTime, !wait.isEmpty {
                        Text("Einwirkzeit: \(wait)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(CareTheme.warmSand)
                    }

                    Spacer()

                    Button(action: {
                        let haptic = UINotificationFeedbackGenerator()
                        haptic.notificationOccurred(.success)
                        store.requestProductOrder(product: product)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isRequested ? "checkmark" : "cart.badge.plus")
                                .font(.system(size: 11))
                            Text(isRequested ? "In GrowFinance" : "Nachbestellen")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(isRequested ? CareTheme.careSage : CareTheme.bg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isRequested ? CareTheme.careSage.opacity(0.18) : CareTheme.careLilac)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isRequested ? CareTheme.careSage.opacity(0.4) : Color.clear, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
        .careCard()
    }
}

