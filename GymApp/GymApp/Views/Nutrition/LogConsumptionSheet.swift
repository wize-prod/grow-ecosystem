import SwiftUI

public struct LogConsumptionSheet: View {
    public let item: PantryItem
    public let targetDate: Date
    @ObservedObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    @State private var logDate: Date
    @State private var amountString: String
    @State private var selectedUnit: String
    @State private var selectedMealType: String = "Mahlzeit"
    @State private var bookedSuccess: Bool = false
    @FocusState private var isAmountFocused: Bool

    private let mealTypes = [
        "Frühstück",
        "Mittagessen",
        "Abendessen",
        "Snack",
        "Pre-Workout",
        "Post-Workout"
    ]

    public init(item: PantryItem, store: LocalStore, targetDate: Date = Date()) {
        self.item = item
        self.store = store
        self.targetDate = targetDate
        _logDate = State(initialValue: targetDate)
        
        let initialAmount: Double = {
            if item.isPieceBased {
                return 1.0
            } else if item.isLiterUnit {
                return 200.0
            } else {
                return min(100.0, max(20.0, item.currentStockQty > 0 ? min(item.currentStockQty, 100.0) : 100.0))
            }
        }()
        
        let initialUnit: String = {
            if item.isPieceBased {
                return item.unit.isEmpty ? "Stück" : item.unit
            } else if item.isLiterUnit {
                return "ml"
            } else {
                return "g"
            }
        }()

        _amountString = State(initialValue: initialAmount.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(initialAmount))" : String(format: "%.1f", initialAmount))
        _selectedUnit = State(initialValue: initialUnit)
    }

    private var enteredAmount: Double {
        let clean = amountString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        return Double(clean) ?? 0.0
    }

    private var calculatedGrams: Double {
        let amt = enteredAmount
        guard amt > 0 else { return 0 }

        if item.hasSubUnits && (selectedUnit.lowercased() == "stück" || selectedUnit.lowercased() == "stk" || selectedUnit.lowercased() == item.effectiveSubUnitName.lowercased()) {
            return amt * item.effectiveSubUnitSize
        } else if item.isPieceBased && (selectedUnit.lowercased() == "stück" || selectedUnit.lowercased() == "stk" || selectedUnit.lowercased() == "kapseln") {
            return amt * item.unitWeightGrams
        } else if item.isLiterUnit && selectedUnit.lowercased() == "l" {
            return amt * 1000.0
        } else {
            return amt
        }
    }

    private var stockDeduction: Double {
        let amt = enteredAmount
        guard amt > 0 else { return 0 }

        if item.hasSubUnits && (selectedUnit.lowercased() == "stück" || selectedUnit.lowercased() == "stk" || selectedUnit.lowercased() == item.effectiveSubUnitName.lowercased()) {
            return (item.unit.lowercased() == "stück" || item.unit.lowercased() == "stk") ? amt : (amt * item.effectiveSubUnitSize)
        } else if item.isPieceBased {
            if selectedUnit.lowercased() == "stück" || selectedUnit.lowercased() == "stk" || selectedUnit.lowercased() == "kapseln" {
                return amt
            } else {
                return max(1.0, (amt / item.unitWeightGrams).rounded())
            }
        } else if item.isLiterUnit {
            if selectedUnit.lowercased() == "ml" || selectedUnit.lowercased() == "g" || (selectedUnit.isEmpty && amt >= 10.0) {
                return amt / 1000.0
            } else {
                return amt
            }
        } else {
            if selectedUnit.lowercased() == "l" {
                return amt * 1000.0
            } else {
                return amt
            }
        }
    }

    private var remainingStock: Double {
        max(0.0, item.currentStockQty - stockDeduction)
    }

    private var calculatedKcal: Double { (calculatedGrams / 100.0) * item.kcal100g }
    private var calculatedProtein: Double { (calculatedGrams / 100.0) * item.protein100g }
    private var calculatedCarbs: Double { (calculatedGrams / 100.0) * item.carbs100g }
    private var calculatedFat: Double { (calculatedGrams / 100.0) * item.fat100g }
    private var calculatedFiber: Double { (calculatedGrams / 100.0) * item.fiber100g }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Item Overview Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.store.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(1.0)
                            Spacer()
                            Text(item.priceFormatted)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.sageGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.surfaceElevated))
                        }
                        
                        Text(item.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        if !item.brand.isEmpty && item.brand.uppercased() != "PANTRY" {
                            Text(item.brand)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }

                        Divider().background(Theme.border).padding(.vertical, 4)

                        HStack {
                            Text("Aktueller Vorrat:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text("\(item.formattedStockWithSubUnits) \(item.unit)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(item.isLowStock ? Theme.terracotta : Theme.sageGreen)
                        }
                    }
                    .wellnessCard()

                    // Amount Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VERZEHRTE MENGE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        HStack(spacing: 10) {
                            HStack {
                                TextField("0", text: $amountString)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                                    .keyboardType(.decimalPad)
                                    .focused($isAmountFocused)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Text(selectedUnit)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.warmSand)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isAmountFocused ? Theme.warmSand : Theme.border, lineWidth: 1))

                            // Unit Picker Menu if flexible
                            Menu {
                                if item.isPieceBased {
                                    Button("Stück") { selectedUnit = "Stück" }
                                    Button("g") { selectedUnit = "g" }
                                } else if item.isLiterUnit {
                                    Button("ml") { selectedUnit = "ml" }
                                    Button("l") { selectedUnit = "l" }
                                } else {
                                    Button("g") { selectedUnit = "g" }
                                    Button("ml") { selectedUnit = "ml" }
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.2.square")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(width: 48, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                        }

                        // Smart Preset Pills
                        presetPillsView
                    }
                    .wellnessCard()

                    // Meal Type Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MAHLZEIT-KATEGORIE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(mealTypes, id: \.self) { type in
                                    Button {
                                        HapticFeedbackService.shared.lightDetent()
                                        selectedMealType = type
                                    } label: {
                                        Text(type)
                                            .font(.system(size: 12, weight: selectedMealType == type ? .bold : .medium))
                                            .foregroundColor(selectedMealType == type ? Theme.bg : Theme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedMealType == type ? Theme.warmSand : Theme.surfaceElevated)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .wellnessCard()

                    // Calculated Nutritional Output
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BERECHNETE NÄHRWERTE FÜR VERZEHR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        HStack(spacing: 6) {
                            macroTile(title: "ENERGIE", value: "\(Int(calculatedKcal)) kcal", accent: Theme.textPrimary)
                            macroTile(title: "PROTEIN", value: String(format: "%.1f g", calculatedProtein), accent: Theme.sageGreen)
                            macroTile(title: "CARBS", value: String(format: "%.1f g", calculatedCarbs), accent: Theme.textSecondary)
                            macroTile(title: "FETT", value: String(format: "%.1f g", calculatedFat), accent: Theme.textSecondary)
                            if calculatedFiber > 0 {
                                macroTile(title: "FIBER", value: String(format: "%.1f g", calculatedFiber), accent: Theme.warmSand)
                            }
                        }

                        // Stock Deduction Indicator
                        HStack {
                            Text("Neuer Vorratsbestand:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text(String(format: "%.1f %@", remainingStock, item.unit))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(remainingStock <= 0 ? Theme.terracotta : Theme.textPrimary)
                        }
                        .padding(.top, 4)
                    }
                    .wellnessCard()

                    // Date / Time of Consumption (Allows past logging)
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

                    // Submit Action Button
                    Button {
                        commitConsumption()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: bookedSuccess ? "checkmark" : "fork.knife")
                                .font(.system(size: 14, weight: .bold))
                            Text(bookedSuccess ? "Verzehr gebucht & gespeichert" : "Verzehr buchen & speichern")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(bookedSuccess ? Theme.warmSand : Theme.sageGreen)
                        .cornerRadius(12)
                        .shadow(color: (bookedSuccess ? Theme.warmSand : Theme.sageGreen).opacity(0.35), radius: 6, y: 3)
                    }
                    .disabled(enteredAmount <= 0)
                    .opacity(enteredAmount <= 0 ? 0.5 : 1.0)
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Verzehr erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private var presetPillsView: some View {
        HStack(spacing: 6) {
            if item.isPieceBased {
                presetPill(label: "1 Stk.", val: 1.0, unit: "Stück")
                presetPill(label: "2 Stk.", val: 2.0, unit: "Stück")
                presetPill(label: "3 Stk.", val: 3.0, unit: "Stück")
                presetPill(label: "4 Stk.", val: 4.0, unit: "Stück")
            } else if item.isLiterUnit {
                presetPill(label: "100 ml", val: 100.0, unit: "ml")
                presetPill(label: "200 ml", val: 200.0, unit: "ml")
                presetPill(label: "250 ml", val: 250.0, unit: "ml")
                presetPill(label: "500 ml", val: 500.0, unit: "ml")
            } else {
                presetPill(label: "30 g", val: 30.0, unit: "g")
                presetPill(label: "50 g", val: 50.0, unit: "g")
                presetPill(label: "100 g", val: 100.0, unit: "g")
                presetPill(label: "150 g", val: 150.0, unit: "g")
                presetPill(label: "200 g", val: 200.0, unit: "g")
            }
        }
    }

    private func presetPill(label: String, val: Double, unit: String) -> some View {
        Button {
            HapticFeedbackService.shared.lightDetent()
            amountString = val.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(val))" : String(format: "%.1f", val)
            selectedUnit = unit
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
        }
    }

    private func macroTile(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private func commitConsumption() {
        guard enteredAmount > 0 else { return }
        HapticFeedbackService.shared.commitSuccess()
        
        let isPiece = item.isPieceBased && (selectedUnit.lowercased() == "stück" || selectedUnit.lowercased() == "stk" || selectedUnit.lowercased() == "kapseln")
        
        store.depleteAndLog(
            item: item,
            amount: enteredAmount,
            isPieceCount: isPiece,
            inputUnit: selectedUnit,
            mealType: selectedMealType,
            syncCalendar: false,
            targetDate: logDate
        )
        
        bookedSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}
