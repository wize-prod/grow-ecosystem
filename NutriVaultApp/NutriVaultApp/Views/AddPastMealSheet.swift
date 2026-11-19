import SwiftUI

public struct AddPastMealSheet: View {
    public let targetDate: Date
    @ObservedObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery: String = ""
    @State private var selectedItem: PantryItem? = nil
    @State private var weightGrams: Double = 150.0
    @State private var inputString: String = "150"
    @State private var selectedMealType: String = "Mittagessen"

    private let mealTypes = [
        "Frühstück",
        "Mittagessen",
        "Abendessen",
        "Snack",
        "Pre-Workout",
        "Post-Workout"
    ]

    private let quickPortions = [50, 100, 150, 200, 250, 300, 400, 500]

    public init(targetDate: Date, store: LocalStore) {
        self.targetDate = targetDate
        self.store = store
    }

    private var filteredItems: [PantryItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            return store.pantryItems.sorted { $0.currentStockQty > $1.currentStockQty }
        }
        return store.pantryItems.filter {
            $0.name.lowercased().contains(q) ||
            $0.brand.lowercased().contains(q) ||
            $0.store.lowercased().contains(q)
        }
    }

    private var liveKcal: Double {
        guard let item = selectedItem else { return 0.0 }
        return ((item.kcal100g * (weightGrams / 100.0))).rounded()
    }

    private var liveProtein: Double {
        guard let item = selectedItem else { return 0.0 }
        return (((item.protein100g * (weightGrams / 100.0)) * 10).rounded()) / 10
    }

    private var liveCarbs: Double {
        guard let item = selectedItem else { return 0.0 }
        return (((item.carbs100g * (weightGrams / 100.0)) * 10).rounded()) / 10
    }

    private var liveFat: Double {
        guard let item = selectedItem else { return 0.0 }
        return (((item.fat100g * (weightGrams / 100.0)) * 10).rounded()) / 10
    }

    private var liveFiber: Double {
        guard let item = selectedItem else { return 0.0 }
        return (((item.fiber100g * (weightGrams / 100.0)) * 10).rounded()) / 10
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let item = selectedItem {
                        selectedItemConfigView(item: item)
                    } else {
                        itemPickerList
                    }
                }
            }
            .navigationTitle("Mahlzeit nachtragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Step 1: Pick Pantry Item
    private var itemPickerList: some View {
        VStack(spacing: 12) {
            // Target date indicator
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.sageGreen)
                Text("Datum: \(formattedTargetDate(targetDate))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textMuted)
                TextField("Vorrat durchsuchen...", text: $searchQuery)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textPrimary)
                if !searchQuery.isEmpty {
                    Button { searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textMuted)
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
            .padding(.horizontal, 16)

            List {
                ForEach(filteredItems) { item in
                    Button {
                        selectedItem = item
                        if item.isPieceBased {
                            weightGrams = item.unitWeightGrams ?? 50.0
                            inputString = "\(Int(weightGrams))"
                        } else {
                            weightGrams = 150.0
                            inputString = "150"
                        }
                        HapticFeedbackService.shared.lightDetent()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(item.brand.isEmpty ? item.store : item.brand) • \(Int(item.kcal100g)) kcal / 100g")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("P: \(String(format: "%.1f", item.protein100g))g")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.sageGreen)
                                Text("\(Int(item.currentStockQty)) \(item.unit)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)

            // Bottom Thumb-Zone Cancel (iPhone 16 Pro Max Ergonomie)
            Button {
                HapticFeedbackService.shared.lightDetent()
                dismiss()
            } label: {
                Text("Abbrechen")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Step 2: Configure Grams & Log
    private func selectedItemConfigView(item: PantryItem) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header banner
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button {
                            selectedItem = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Anderes Produkt")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.warmSand)
                        }
                        Spacer()
                        Text(formattedTargetDate(targetDate))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.sageGreen)
                    }

                    Text(item.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(item.brand) • \(item.store)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(14)
                .wellnessCard(borderColor: Theme.sageGreen.opacity(0.3))

                // Meal type selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("MAHLZEIT-KATEGORIE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(mealTypes, id: \.self) { type in
                                let isSel = (type == selectedMealType)
                                Button {
                                    selectedMealType = type
                                    HapticFeedbackService.shared.lightDetent()
                                } label: {
                                    Text(type)
                                        .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                        .foregroundColor(isSel ? Theme.bg : Theme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(isSel ? Theme.sageGreen : Theme.surfaceElevated)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .wellnessCard()

                // Weight input & Quick Chips
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("PORTIONSGROESSE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        Text("\(Int(weightGrams)) Gramm")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    }

                    HStack(spacing: 12) {
                        TextField("150", text: $inputString)
                            .keyboardType(.numberPad)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)
                            .padding(10)
                            .background(Theme.surface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                            .onChange(of: inputString) { val in
                                if let d = Double(val.replacingOccurrences(of: ",", with: ".")) {
                                    weightGrams = max(1.0, d)
                                }
                            }

                        Text("g")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    }

                    // Quick portion chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(quickPortions, id: \.self) { grams in
                                Button("\(grams)g") {
                                    weightGrams = Double(grams)
                                    inputString = "\(grams)"
                                    HapticFeedbackService.shared.lightDetent()
                                }
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(14)
                .wellnessCard()

                // Computed Macro Preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("BERECHNETE NAEHRWERTE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)

                    HStack(spacing: 8) {
                        macroTile(title: "KALORIEN", value: "\(Int(liveKcal))", unit: "kcal", color: Theme.warmSand)
                        macroTile(title: "PROTEIN", value: String(format: "%.1f", liveProtein), unit: "g", color: Theme.sageGreen)
                        macroTile(title: "KOHLENHYDRATE", value: String(format: "%.1f", liveCarbs), unit: "g", color: Theme.textPrimary)
                        macroTile(title: "FETT", value: String(format: "%.1f", liveFat), unit: "g", color: Theme.terracotta)
                    }
                }
                .padding(14)
                .wellnessCard()

                if let risk = sphincterRiskReason(for: item) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Theme.warmSand)
                                .font(.system(size: 11))
                            Text("AUTOMATISCHER LPR-SPHINKTER-FILTER")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                        }
                        Text("Enthält: \(risk). Führt zur Relaxation des unteren Ösophagussphinkters (LES). Für Abendmahlzeiten strikt kontraindiziert zur Vermeidung nächtlicher Refluxepisoden.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.warmSand.opacity(0.5), lineWidth: 1))
                }

                // Submit Button
                Button {
                    guard weightGrams > 0 else { return }
                    store.depleteAndLog(
                        item: item,
                        amount: weightGrams,
                        isPieceCount: item.isPieceBased,
                        mealType: selectedMealType,
                        targetDate: targetDate
                    )
                    HapticFeedbackService.shared.commitSuccess()
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                        Text("Mahlzeit fuer \(formattedTargetDate(targetDate)) buchen")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(Theme.bg)
                    .padding(.vertical, 14)
                    .background(Theme.sageGreen)
                    .cornerRadius(12)
                }
                .padding(.top, 8)

                // Bottom Thumb-Zone Dismiss (iPhone 16 Pro Max Ergonomie)
                Button {
                    HapticFeedbackService.shared.lightDetent()
                    dismiss()
                } label: {
                    Text("Abbrechen")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                        .padding(.vertical, 6)
                }
            }
            .padding(16)
        }
    }

    private func sphincterRiskReason(for item: PantryItem) -> String? {
        let text = (item.name + " " + item.brand).lowercased()
        if text.contains("tomate") || text.contains("tomato") || text.contains("passata") || text.contains("bolognese") {
            return "Tomatenbasis (Saeure- & Pepsin-Trigger)"
        }
        if text.contains("knoblauch") || text.contains("garlic") || text.contains("zwiebel") || text.contains("onion") {
            return "Knoblauch / Zwiebel (LES-Relaxans)"
        }
        if text.contains("minze") || text.contains("mint") || text.contains("pfefferminz") {
            return "Pfefferminz (Starke Sphinkter-Relaxation)"
        }
        if text.contains("schokolade") || text.contains("chocolate") || text.contains("kakao") {
            return "Schokolade (Methylxanthine)"
        }
        if text.contains("kaffee") || text.contains("coffee") || text.contains("espresso") {
            return "Kaffee / Koffein"
        }
        if liveFat >= 20.0 {
            return "Hoher Fettgehalt (> 20g verzoegert Magenentleerung)"
        }
        return nil
    }

    private func macroTile(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.textMuted)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Theme.surfaceElevated)
        .cornerRadius(8)
    }

    private func formattedTargetDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
}
