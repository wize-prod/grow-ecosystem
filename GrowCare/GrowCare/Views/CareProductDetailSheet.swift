import SwiftUI

public struct CareProductDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = GrowCareStore.shared
    public let product: CareProduct

    @State private var justRequested: Bool = false

    public init(product: CareProduct) {
        self.product = product
    }

    private var isRequested: Bool {
        store.isProductRequestedInFinance(product: product) || justRequested
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(product.brand.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.careLilac)

                            Text(product.zone.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(CareTheme.careLilac.opacity(0.18))
                                .foregroundColor(CareTheme.careLilac)
                                .clipShape(Capsule())

                            Spacer()

                            Text(product.category)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(CareTheme.surfaceElevated)
                                .foregroundColor(CareTheme.textSecondary)
                                .clipShape(Capsule())
                        }

                        Text(product.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(CareTheme.textPrimary)

                        HStack(alignment: .firstTextBaseline) {
                            Text(String(format: "%.2f EUR", product.price))
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.textPrimary)

                            Spacer()

                            if let wait = product.layeringWaitTime, !wait.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "hourglass")
                                        .font(.system(size: 11))
                                    Text("Einwirkzeit: \(wait)")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(CareTheme.warmSand)
                            }
                        }
                    }
                    .careCard()

                    // Active Ingredients & Application
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WIRKSTOFFE & TECHNOLOGIE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(CareTheme.textMuted)

                            Text(product.activeIngredients)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(CareTheme.textPrimary)
                                .lineSpacing(2)
                        }

                        Divider().background(CareTheme.border)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ANWENDUNGSHINWEISE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(CareTheme.textMuted)

                            Text(product.usageInstructions)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(CareTheme.textSecondary)
                                .lineSpacing(3)
                        }

                        Divider().background(CareTheme.border)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("KLINISCHER & DERMATOLOGISCHER NUTZEN")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(CareTheme.textMuted)

                            Text(product.clinicalBenefit)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(CareTheme.textSecondary)
                                .lineSpacing(3)
                        }
                    }
                    .careCard()

                    // GrowFinance Integration Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("GROWFINANCE BESCHAFFUNG")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(CareTheme.careBlue)

                            Spacer()

                            if isRequested {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("In GrowFinance angefordert")
                                }
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.careSage)
                            }
                        }

                        Text("Setzt diesen Pflegeartikel direkt auf die Einkaufsliste in GrowFinance unter Kategorie 'Pflege' zur Pruefung gegen das 5-Gate Budget.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(CareTheme.textSecondary)

                        HStack(spacing: 10) {
                            Button(action: {
                                let haptic = UINotificationFeedbackGenerator()
                                haptic.notificationOccurred(.success)
                                store.requestProductOrder(product: product)
                                withAnimation {
                                    justRequested = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isRequested ? "checkmark" : "cart.badge.plus")
                                    Text(isRequested ? "Bereits angefordert" : "In GrowFinance anfordern")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isRequested ? CareTheme.careSage : CareTheme.bg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(isRequested ? CareTheme.careSage.opacity(0.18) : CareTheme.careLilac)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isRequested ? CareTheme.careSage.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if GrowEcosystemRouter.shared.canOpen(.growfinance) {
                                Button(action: {
                                    GrowEcosystemRouter.shared.openApp(.growfinance)
                                }) {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(CareTheme.careBlue)
                                        .frame(width: 42, height: 42)
                                        .background(CareTheme.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .careCard(borderColor: isRequested ? CareTheme.careSage.opacity(0.3) : CareTheme.border)

                    // External Web Store Link
                    if let url = URL(string: product.amazonUrl), UIApplication.shared.canOpenURL(url) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Auf Amazon.de aufrufen")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(CareTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(CareTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(CareTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(CareTheme.bg.ignoresSafeArea())
            .navigationTitle("Produkt-Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(CareTheme.careLilac)
                }
            }
        }
    }
}

