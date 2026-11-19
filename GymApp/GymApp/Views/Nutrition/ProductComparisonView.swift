import SwiftUI

public struct ProductComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LocalStore

    public let initialItemA: PantryItem
    @State private var itemA: PantryItem
    @State private var itemB: PantryItem? = nil
    @State private var showingItemBPicker: Bool = false
    @State private var showingItemBScanner: Bool = false

    public init(itemA: PantryItem, store: LocalStore) {
        self.initialItemA = itemA
        self._itemA = State(initialValue: itemA)
        self.store = store
    }

    private var scoreA: ComprehensiveNutritionScore {
        NutritionalScoringEngine.shared.evaluate(item: itemA)
    }

    private var scoreB: ComprehensiveNutritionScore? {
        guard let b = itemB else { return nil }
        return NutritionalScoringEngine.shared.evaluate(item: b)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header & Selector
                        HStack(spacing: 8) {
                            productHeaderCard(item: itemA, label: "PRODUKT A (REFERENZ)")
                            if let b = itemB {
                                productHeaderCard(item: b, label: "PRODUKT B (VERGLEICH)")
                            } else {
                                emptyProductBCard
                            }
                        }

                        if let b = itemB, let sB = scoreB {
                            // Comparison Summary / Verdict Banner
                            comparisonVerdictCard(scoreA: scoreA, scoreB: sB, itemA: itemA, itemB: b)

                            // Side-by-Side Scoring Benchmarks
                            sideBySideScoresSection(scoreA: scoreA, scoreB: sB)

                            // Side-by-Side Macronutrients (per 100g)
                            sideBySideMacrosSection(itemA: itemA, itemB: b)

                            // Side-by-Side Key Micronutrients & Processing
                            sideBySideMicrosSection(itemA: itemA, itemB: b, scoreA: scoreA, scoreB: sB)
                        } else {
                            // Guidance prompt to select Product B
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                Text("Wähle ein zweites Produkt zum Nährwert-Vergleich")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("Vergleiche Nutri-Score, Food Compass, Ty Beal Dichte, Glykämischen Index und K:Na-Verarbeitung quotienten direkt nebeneinander.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)

                                HStack(spacing: 12) {
                                    Button {
                                        showingItemBPicker = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "tray.full.fill")
                                            Text("Aus Vorrat wählen")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.bg)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Theme.sageGreen)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }

                                    Button {
                                        showingItemBScanner = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "barcode.viewfinder")
                                            Text("EAN Scannen")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Theme.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                                    }
                                }
                                .padding(.top, 6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .wellnessCard()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Nährwert-Vergleich")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.sageGreen)
                    .font(.system(size: 14, weight: .bold))
                }
            }
            .sheet(isPresented: $showingItemBPicker) {
                pantryPickerSheet
            }
            .sheet(isPresented: $showingItemBScanner) {
                BarcodeScannerView { barcode in
                    showingItemBScanner = false
                    resolveItemB(barcode: barcode)
                }
            }
        }
    }

    // MARK: - Header Cards
    private func productHeaderCard(item: PantryItem, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)

            Text(item.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
                .frame(height: 34, alignment: .topLeading)

            HStack {
                Text(item.brand.isEmpty ? "Standard" : item.brand)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(String(format: "%.0f kcal", item.kcal100g))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.warmSand)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
    }

    private var emptyProductBCard: some View {
        Button {
            showingItemBPicker = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                Text("Produkt B hinzufügen")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .padding(10)
            .background(Theme.surfaceElevated.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.sageGreen.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
    }

    // MARK: - Verdict Banner
    private func comparisonVerdictCard(scoreA: ComprehensiveNutritionScore, scoreB: ComprehensiveNutritionScore, itemA: PantryItem, itemB: PantryItem) -> some View {
        let pDiff = itemA.protein100g - itemB.protein100g
        let fiberDiff = itemA.fiber100g - itemB.fiber100g
        let kNaDiff = scoreA.potassiumSodiumRatio - scoreB.potassiumSodiumRatio

        let winnerText: String = {
            if scoreA.foodCompassScore > scoreB.foodCompassScore && itemA.protein100g >= itemB.protein100g {
                return "\(itemA.name) weist die höhere Nährstoffdichte und bessere Gesamtbewertung auf."
            } else if scoreB.foodCompassScore > scoreA.foodCompassScore && itemB.protein100g >= itemA.protein100g {
                return "\(itemB.name) weist die höhere Nährstoffdichte und bessere Gesamtbewertung auf."
            } else if pDiff > 2.0 {
                return "\(itemA.name) liefert signifikant mehr Protein (+ \(String(format: "%.1f", pDiff)) g / 100g)."
            } else if pDiff < -2.0 {
                return "\(itemB.name) liefert signifikant mehr Protein (+ \(String(format: "%.1f", -pDiff)) g / 100g)."
            }
            return "Beide Produkte weisen vergleichbare Nährstoffprofile auf."
        }()

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                Text("VERGLEICHS-ANALYSE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.warmSand)
                    .tracking(0.8)
            }
            Text(winnerText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 8) {
                if abs(pDiff) >= 1.0 {
                    metricDiffBadge(title: "Protein-Delta", value: "\(pDiff > 0 ? "+" : "")\(String(format: "%.1f", pDiff)) g", isPositive: pDiff > 0)
                }
                if abs(fiberDiff) >= 1.0 {
                    metricDiffBadge(title: "Ballaststoff-Delta", value: "\(fiberDiff > 0 ? "+" : "")\(String(format: "%.1f", fiberDiff)) g", isPositive: fiberDiff > 0)
                }
                if abs(kNaDiff) >= 0.5 {
                    metricDiffBadge(title: "K:Na Quotient", value: "\(kNaDiff > 0 ? "+" : "")\(String(format: "%.1f", kNaDiff))", isPositive: kNaDiff > 0)
                }
            }
            .padding(.top, 4)
        }
        .padding(12)
        .wellnessCard(borderColor: Theme.sageGreen.opacity(0.4))
    }

    private func metricDiffBadge(title: String, value: String, isPositive: Bool) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(isPositive ? Theme.sageGreen : Theme.terracotta)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Side-by-Side Scores Section
    private func sideBySideScoresSection(scoreA: ComprehensiveNutritionScore, scoreB: ComprehensiveNutritionScore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SCORING SYSTEME IM DIREKTVERGLEICH")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.warmSand)
                .tracking(0.8)

            VStack(spacing: 8) {
                scoreCompareRow(label: "Nutri-Score", valA: scoreA.nutriScoreGrade.uppercased(), valB: scoreB.nutriScoreGrade.uppercased())
                scoreCompareRow(label: "Food Compass (Tufts)", valA: "\(scoreA.foodCompassScore)/100", valB: "\(scoreB.foodCompassScore)/100")
                scoreCompareRow(label: "Ty Beal Score", valA: String(format: "%.0f/100", scoreA.tyBealScore), valB: String(format: "%.0f/100", scoreB.tyBealScore))
                scoreCompareRow(label: "K:Na Quotient (Verarbeitung)", valA: String(format: "%.1f", scoreA.potassiumSodiumRatio), valB: String(format: "%.1f", scoreB.potassiumSodiumRatio))
                scoreCompareRow(label: "Health Star Rating", valA: String(format: "%.1f ★", scoreA.healthStarRating), valB: String(format: "%.1f ★", scoreB.healthStarRating))
                scoreCompareRow(label: "Glykämischer Index (GI)", valA: "\(scoreA.glycemicIndex)", valB: "\(scoreB.glycemicIndex)")
                scoreCompareRow(label: "Protein-Dichte (BPI)", valA: String(format: "%.1f g/100kcal", scoreA.bpiProteinIndex), valB: String(format: "%.1f g/100kcal", scoreB.bpiProteinIndex))
            }
        }
        .wellnessCard()
    }

    private func scoreCompareRow(label: String, valA: String, valB: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            HStack(spacing: 16) {
                Text(valA)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 80, alignment: .trailing)

                Text("vs")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.textMuted)

                Text(valB)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 80, alignment: .leading)
            }
        }
        .padding(.vertical, 3)
    }

    // MARK: - Side-by-Side Macros
    private func sideBySideMacrosSection(itemA: PantryItem, itemB: PantryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MAKRONÄHRWERTE (PRO 100g)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.warmSand)
                .tracking(0.8)

            VStack(spacing: 8) {
                macroCompareRow(label: "Energie", valA: String(format: "%.0f kcal", itemA.kcal100g), valB: String(format: "%.0f kcal", itemB.kcal100g))
                macroCompareRow(label: "Protein", valA: String(format: "%.1f g", itemA.protein100g), valB: String(format: "%.1f g", itemB.protein100g))
                macroCompareRow(label: "Kohlenhydrate", valA: String(format: "%.1f g", itemA.carbs100g), valB: String(format: "%.1f g", itemB.carbs100g))
                macroCompareRow(label: "davon Zucker", valA: String(format: "%.1f g", itemA.effectiveProfile().sugars ?? 0.0), valB: String(format: "%.1f g", itemB.effectiveProfile().sugars ?? 0.0))
                macroCompareRow(label: "Ballaststoffe", valA: String(format: "%.1f g", itemA.fiber100g), valB: String(format: "%.1f g", itemB.fiber100g))
                macroCompareRow(label: "Fett", valA: String(format: "%.1f g", itemA.fat100g), valB: String(format: "%.1f g", itemB.fat100g))
                macroCompareRow(label: "davon gesättigt", valA: String(format: "%.1f g", itemA.effectiveProfile().saturatedFat ?? 0.0), valB: String(format: "%.1f g", itemB.effectiveProfile().saturatedFat ?? 0.0))
            }
        }
        .wellnessCard()
    }

    private func macroCompareRow(label: String, valA: String, valB: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            HStack(spacing: 16) {
                Text(valA)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 80, alignment: .trailing)

                Text("•")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.textMuted)

                Text(valB)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 80, alignment: .leading)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Side-by-Side Micros
    private func sideBySideMicrosSection(itemA: PantryItem, itemB: PantryItem, scoreA: ComprehensiveNutritionScore, scoreB: ComprehensiveNutritionScore) -> some View {
        let pA = itemA.effectiveProfile()
        let pB = itemB.effectiveProfile()

        return VStack(alignment: .leading, spacing: 10) {
            Text("MIKRONÄHRSTOFFE & ELEKTROLYTE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.warmSand)
                .tracking(0.8)

            VStack(spacing: 8) {
                macroCompareRow(label: "Kalium", valA: String(format: "%.0f mg", pA.potassium ?? 0.0), valB: String(format: "%.0f mg", pB.potassium ?? 0.0))
                macroCompareRow(label: "Natrium", valA: String(format: "%.0f mg", pA.sodium ?? 0.0), valB: String(format: "%.0f mg", pB.sodium ?? 0.0))
                macroCompareRow(label: "Magnesium", valA: String(format: "%.1f mg", pA.magnesium ?? 0.0), valB: String(format: "%.1f mg", pB.magnesium ?? 0.0))
                macroCompareRow(label: "Eisen", valA: String(format: "%.1f mg", pA.iron ?? 0.0), valB: String(format: "%.1f mg", pB.iron ?? 0.0))
                macroCompareRow(label: "Zink", valA: String(format: "%.1f mg", pA.zinc ?? 0.0), valB: String(format: "%.1f mg", pB.zinc ?? 0.0))
                macroCompareRow(label: "Calcium", valA: String(format: "%.0f mg", pA.calcium ?? 0.0), valB: String(format: "%.0f mg", pB.calcium ?? 0.0))
            }
        }
        .wellnessCard()
    }

    // MARK: - Pantry Picker Sheet
    private var pantryPickerSheet: some View {
        NavigationStack {
            List(store.pantryItems.filter { $0.id != itemA.id }) { p in
                Button {
                    itemB = p
                    showingItemBPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text("\(p.brand) • \(Int(p.kcal100g)) kcal • \(String(format: "%.1f", p.protein100g))g Protein")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(Theme.sageGreen)
                    }
                }
            }
            .navigationTitle("Produkt B auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingItemBPicker = false }
                        .foregroundColor(Theme.terracotta)
                }
            }
        }
    }

    private func resolveItemB(barcode: String) {
        if let match = store.pantryItems.first(where: { $0.barcode == barcode }) {
            self.itemB = match
            return
        }
        if let catalogMatch = MasterDataSeed.getMasterCatalog().first(where: { $0.barcode == barcode && !$0.barcode.isEmpty }) {
            self.itemB = catalogMatch
            return
        }
        Task {
            if let fetched = await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                await MainActor.run {
                    self.itemB = fetched
                }
            }
        }
    }
}

