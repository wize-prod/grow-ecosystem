import SwiftUI

public struct EditMealLogSheet: View {
    public let log: MealLogEntry
    @ObservedObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    @State private var weightGrams: Double
    @State private var inputString: String
    @State private var mealType: String
    @State private var logDate: Date
    @State private var showingDetailSheet: Bool = false

    private let mealTypeOptions = [
        "Mahlzeit",
        "Frühstück",
        "Mittagessen",
        "Abendessen",
        "Snack",
        "Pre-Workout",
        "Post-Workout"
    ]

    public init(log: MealLogEntry, store: LocalStore) {
        self.log = log
        self.store = store
        _weightGrams = State(initialValue: log.weightGrams)
        _inputString = State(initialValue: "\(Int(log.weightGrams))")
        _mealType = State(initialValue: log.mealType)
        _logDate = State(initialValue: log.timestamp)
    }

    private var pantryItem: PantryItem? {
        store.pantryItems.first(where: { $0.id == log.pantryItemId })
    }

    private var isPieceBased: Bool {
        pantryItem?.isPieceBased ?? false
    }

    private var unitWeight: Double {
        max(1.0, pantryItem?.unitWeightGrams ?? 50.0)
    }

    private var pieceCount: Double {
        weightGrams / unitWeight
    }

    // Computed live preview values
    private var liveKcal: Double {
        if let item = pantryItem {
            return ((item.kcal100g * (weightGrams / 100.0))).rounded()
        }
        let ratio = weightGrams / max(1.0, log.weightGrams)
        return (log.kcal * ratio).rounded()
    }

    private var liveProtein: Double {
        if let item = pantryItem {
            return (((item.protein100g * (weightGrams / 100.0)) * 10).rounded()) / 10
        }
        let ratio = weightGrams / max(1.0, log.weightGrams)
        return ((log.protein * ratio * 10).rounded()) / 10
    }

    private var liveCarbs: Double {
        if let item = pantryItem {
            return (((item.carbs100g * (weightGrams / 100.0)) * 10).rounded()) / 10
        }
        let ratio = weightGrams / max(1.0, log.weightGrams)
        return ((log.carbs * ratio * 10).rounded()) / 10
    }

    private var liveFat: Double {
        if let item = pantryItem {
            return (((item.fat100g * (weightGrams / 100.0)) * 10).rounded()) / 10
        }
        let ratio = weightGrams / max(1.0, log.weightGrams)
        return ((log.fat * ratio * 10).rounded()) / 10
    }

    private var liveFiber: Double {
        if let item = pantryItem {
            return (((item.fiber100g * (weightGrams / 100.0)) * 10).rounded()) / 10
        }
        let ratio = weightGrams / max(1.0, log.weightGrams)
        return ((log.fiber * ratio * 10).rounded()) / 10
    }

    private var liveCost: Double {
        guard let item = pantryItem, item.defaultPrice > 0, item.defaultPackQty > 0 else {
            let ratio = weightGrams / max(1.0, log.weightGrams)
            return ((log.cost * ratio * 100).rounded()) / 100
        }
        if item.isPieceBased {
            let pieces = weightGrams / unitWeight
            let costPerPiece = item.defaultPrice / item.defaultPackQty
            return max(0.01, ((pieces * costPerPiece * 100).rounded()) / 100)
        } else if item.isLiterUnit {
            let packVolumeMl = item.defaultPackQty * 1000.0
            let costPerMl = item.defaultPrice / packVolumeMl
            return max(0.01, ((weightGrams * costPerMl * 100).rounded()) / 100)
        } else {
            let costPerUnit = item.defaultPrice / item.defaultPackQty
            return max(0.01, ((weightGrams * costPerUnit * 100).rounded()) / 100)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Item Header Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.brand.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(1.0)
                            Spacer()
                            Text(formattedTimestamp(log.timestamp))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }

                        Text(log.foodName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        if let p = pantryItem {
                            Text("Vorrat: \(p.formattedStockWithSubUnits) verbleibend")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .wellnessCard()

                    // Amount Editor Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("VERZEHRTE MENGE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            if isPieceBased {
                                Text("\(formatPieceCount(pieceCount)) Stück")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.warmSand)
                            }
                        }

                        // Large Grams Display & Stepper
                        HStack(spacing: 12) {
                            Button(action: {
                                adjustGrams(by: isPieceBased ? -unitWeight : -10.0)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                            }

                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                TextField("0", text: $inputString)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.sageGreen)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 140)
                                    .onChange(of: inputString) { newVal in
                                        if let val = Double(newVal), val >= 0 {
                                            weightGrams = val
                                        }
                                    }
                                Text("g")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)

                            Button(action: {
                                adjustGrams(by: isPieceBased ? unitWeight : 10.0)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                            }
                        }

                        // Quick delta buttons
                        HStack(spacing: 8) {
                            if isPieceBased {
                                quickAdjustButton(label: "-2 Stk", delta: -2 * unitWeight)
                                quickAdjustButton(label: "-1 Stk", delta: -1 * unitWeight)
                                quickAdjustButton(label: "+1 Stk", delta: 1 * unitWeight)
                                quickAdjustButton(label: "+2 Stk", delta: 2 * unitWeight)
                            } else {
                                quickAdjustButton(label: "-50g", delta: -50.0)
                                quickAdjustButton(label: "-20g", delta: -20.0)
                                quickAdjustButton(label: "+20g", delta: 20.0)
                                quickAdjustButton(label: "+50g", delta: 50.0)
                                quickAdjustButton(label: "+100g", delta: 100.0)
                            }
                        }
                    }
                    .wellnessCard()

                    // Live Calculated Macros Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("NEUE NAEHRWERTE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        HStack(spacing: 8) {
                            macroTile(title: "KALORIEN", value: "\(Int(liveKcal))", unit: "kcal", color: Theme.warmSand)
                            macroTile(title: "PROTEIN", value: String(format: "%.1f", liveProtein), unit: "g", color: Theme.sageGreen)
                            macroTile(title: "KOHLENHYDRATE", value: String(format: "%.1f", liveCarbs), unit: "g", color: Theme.textPrimary)
                            macroTile(title: "FETT", value: String(format: "%.1f", liveFat), unit: "g", color: Theme.textSecondary)
                        }

                        HStack {
                            Text("Ballaststoffe: \(String(format: "%.1f", liveFiber))g")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Kosten: \(String(format: "%.2f €", liveCost))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                                if let p = pantryItem, p.defaultPrice > 0 {
                                    Text("(\(p.unitPriceFormatted))")
                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .wellnessCard()

                    // Meal Type Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("KATEGORIE / MAHLZEIT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(mealTypeOptions, id: \.self) { opt in
                                    mealTypeChip(opt: opt)
                                }
                            }
                        }
                    }
                    .wellnessCard()

                    // Date & Time Selector (Allows moving or backdating past meals)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("DATUM & UHRZEIT DER MAHLZEIT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            DatePicker("", selection: $logDate)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    .wellnessCard()

                    // Detailed Micronutrients Link
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        showingDetailSheet = true
                    }) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.sageGreen)
                            Text("Vollständiges Mikronährstoffprofil")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    }

                    // Save & Delete Buttons
                    VStack(spacing: 10) {
                        Button(action: {
                            saveChanges()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                Text("Änderungen speichern")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                        }

                        Button(action: {
                            deleteEntry()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Mahlzeit entfernen")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.terracotta)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }

                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            dismiss()
                        }) {
                            Text("Abbrechen")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Mahlzeit anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.warmSand)
                }
            }
            .sheet(isPresented: $showingDetailSheet) {
                NutritionDetailSheet(log: log, store: store)
            }
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func mealTypeChip(opt: String) -> some View {
        let isSelected = (mealType == opt)
        Button(action: {
            HapticFeedbackService.shared.lightDetent()
            mealType = opt
        }) {
            Text(opt)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Theme.bg : Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Theme.warmSand : Theme.surfaceElevated)
                )
        }
    }

    private func adjustGrams(by delta: Double) {
        let newGrams = max(1.0, weightGrams + delta)
        weightGrams = newGrams
        inputString = "\(Int(newGrams))"
        HapticFeedbackService.shared.mechanicalClick()
    }

    private func quickAdjustButton(label: String, delta: Double) -> some View {
        Button(action: {
            adjustGrams(by: delta)
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
        }
    }

    private func macroTile(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .tracking(0.5)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private func saveChanges() {
        guard weightGrams > 0 else { return }
        store.updateMealLog(id: log.id, newWeightGrams: weightGrams, newMealType: mealType, newTimestamp: logDate)
        dismiss()
    }

    private func deleteEntry() {
        store.deleteMealLog(id: log.id)
        dismiss()
    }

    private func formatPieceCount(_ count: Double) -> String {
        if count.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(count))"
        } else {
            return String(format: "%.1f", count)
        }
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm 'Uhr'"
        return df.string(from: date)
    }
}
