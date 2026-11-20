import SwiftUI

public struct ScannedProductInspectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LocalStore
    public let item: PantryItem

    @State private var shoppingQuantity: Int = 1
    @State private var pantryStockAmount: Double
    @State private var selectedStore: String
    @State private var isAddedToShopping: Bool = false
    @State private var isAddedToPantry: Bool = false
    @State private var showingComparison: Bool = false

    public init(item: PantryItem, store: LocalStore) {
        self.item = item
        self.store = store
        self._pantryStockAmount = State(initialValue: item.defaultPackQty > 0 ? item.defaultPackQty : 500.0)
        self._selectedStore = State(initialValue: item.store.isEmpty ? "PENNY" : item.store)
    }

    private var score: ComprehensiveNutritionScore {
        NutritionalScoringEngine.shared.evaluate(item: item)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Scan Info Banner (Pure Inspection Notice)
                        HStack(spacing: 6) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.sageGreen)
                            Text("PRODUKT GESCANNT • EAN: \(item.barcode)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.sageGreen)
                            Spacer()
                            Text("Prüfmodus")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Product Title & Meta Card
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.brand.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.warmSand)
                                    .tracking(0.8)
                                Spacer()
                                if item.defaultPrice > 0 {
                                    Text(String(format: "%.2f €", item.defaultPrice))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                } else {
                                    Text("Preis offen")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }

                            Text(item.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.textPrimary)

                            HStack(spacing: 8) {
                                HStack(spacing: 3) {
                                    Image(systemName: "shippingbox.fill")
                                        .font(.system(size: 9))
                                    Text("\(Int(item.defaultPackQty)) \(item.unit)")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                }
                                .foregroundColor(Theme.textSecondary)

                                Text("•")
                                    .foregroundColor(Theme.textMuted)

                                HStack(spacing: 3) {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 9))
                                    Text(item.store.isEmpty ? "Penny" : item.store)
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .wellnessCard()

                        // 3 Primary Action Buttons: Einkaufsliste / Vorrat / Vergleich
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AKTIONEN FÜR DIESEN ARTIKEL")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)

                            // Action 1: Add to Shopping List
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auf die Einkaufsliste")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Bedarf für den nächsten Einkauf vormerken")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Spacer()

                                // Stepper for packs
                                HStack(spacing: 8) {
                                    Button {
                                        if shoppingQuantity > 1 { shoppingQuantity -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Text("\(shoppingQuantity)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                    Button {
                                        shoppingQuantity += 1
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(Theme.sageGreen)
                                    }
                                }

                                Button {
                                    HapticFeedbackService.shared.commitSuccess()
                                    var shoppingItem = ShoppingItem(item: item, quantity: shoppingQuantity)
                                    shoppingItem.store = selectedStore
                                    store.addManualShoppingItem(pantryItem: item, packs: shoppingQuantity)
                                    withAnimation { isAddedToShopping = true }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: isAddedToShopping ? "checkmark" : "cart.badge.plus")
                                        Text(isAddedToShopping ? "Hinzugefügt" : "+ Liste")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.bg)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(isAddedToShopping ? Theme.warmSand : Theme.sageGreen)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(10)
                            .background(Theme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Action 2: Add to Inventory (Vorrat)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("In Vorratskammer einlagern")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Artikel ist bereits physisch vorhanden")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Spacer()

                                Button {
                                    HapticFeedbackService.shared.commitSuccess()
                                    var updatedItem = item
                                    updatedItem.currentStockQty = pantryStockAmount
                                    store.addOrUpdatePantryItem(updatedItem)
                                    withAnimation { isAddedToPantry = true }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: isAddedToPantry ? "checkmark" : "shippingbox.fill")
                                        Text(isAddedToPantry ? "Eingelagert" : "+ Vorrat")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Theme.surfaceElevated)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
                                }
                            }
                            .padding(10)
                            .background(Theme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Action 3: Compare with another item
                            Button {
                                showingComparison = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.warmSand)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Mit anderem Produkt vergleichen")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("Direkter Nährwert-, Protein- & Verarbeitungs-Vergleich")
                                            .font(.system(size: 9))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.warmSand)
                                }
                                .padding(10)
                                .background(Theme.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.warmSand.opacity(0.4), lineWidth: 1))
                            }
                        }
                        .wellnessCard()

                        // Full Multi-Score Scientific Engine View
                        NutritionalScoresView(score: score, compact: false)

                        // Macronutrients Breakdown Tile
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MAKRONÄHRWERTE (PRO 100g)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)

                            HStack(spacing: 6) {
                                macroMetricTile(title: "PROTEIN", value: String(format: "%.1f g", item.protein100g), accent: Theme.sageGreen)
                                macroMetricTile(title: "ENERGIE", value: "\(Int(item.kcal100g)) kcal", accent: Theme.textPrimary)
                                macroMetricTile(title: "CARBS", value: String(format: "%.1f g", item.carbs100g), accent: Theme.textSecondary)
                                macroMetricTile(title: "BALLASTSTOFF", value: String(format: "%.1f g", item.fiber100g), accent: Theme.warmSand)
                                macroMetricTile(title: "FETT", value: String(format: "%.1f g", item.fat100g), accent: Theme.textSecondary)
                            }
                        }
                        .wellnessCard()

                        // Key Micronutrients & Minerals
                        let p = item.effectiveProfile()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MIKRONÄHRSTOFF-PROFIL")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)

                            VStack(spacing: 6) {
                                if let val = p.potassium, val > 0 {
                                    microNutrientLine(name: "Kalium", amount: "\(Int(val)) mg", target: "Elektrolyt / K:Na Ratio")
                                }
                                if let val = p.sodium, val > 0 {
                                    microNutrientLine(name: "Natrium", amount: "\(Int(val)) mg", target: "Salzgehalt")
                                }
                                if let val = p.magnesium, val > 0 {
                                    microNutrientLine(name: "Magnesium", amount: String(format: "%.1f mg", val), target: "Muskel & ZNS")
                                }
                                if let val = p.iron, val > 0 {
                                    microNutrientLine(name: "Eisen", amount: String(format: "%.1f mg", val), target: "Sauerstofftransport")
                                }
                                if let val = p.zinc, val > 0 {
                                    microNutrientLine(name: "Zink", amount: String(format: "%.1f mg", val), target: "Immunsystem & Testo")
                                }
                                if let val = p.calcium, val > 0 {
                                    microNutrientLine(name: "Calcium", amount: "\(Int(val)) mg", target: "Knochen & Zähne")
                                }
                            }
                        }
                        .wellnessCard()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Produkt-Prüfung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(Theme.sageGreen)
                    .font(.system(size: 14, weight: .bold))
                }
            }
            .sheet(isPresented: $showingComparison) {
                ProductComparisonView(itemA: item, store: store)
            }
        }
    }

    private func macroMetricTile(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func microNutrientLine(name: String, amount: String, target: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(target)
                .font(.system(size: 9))
                .foregroundColor(Theme.textMuted)
            Text(amount)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

