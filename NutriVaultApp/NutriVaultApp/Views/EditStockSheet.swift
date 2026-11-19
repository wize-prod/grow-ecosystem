import SwiftUI

public struct EditStockSheet: View {
    public let item: PantryItem
    @ObservedObject var store: LocalStore
    @Environment(\.presentationMode) var presentationMode

    // Stammdaten
    @State private var productName: String
    @State private var productBrand: String
    @State private var productBarcode: String
    @State private var productStore: String
    @State private var priceString: String

    // Bestand & Einheit (Milli- / Komma-Genauigkeit)
    @State private var inputString: String
    @State private var packQtyString: String
    @State private var selectedUnit: String

    // Nährwerte pro 100g (Milli- / Komma-Genauigkeit)
    @State private var kcalString: String
    @State private var proteinString: String
    @State private var carbsString: String
    @State private var fatString: String
    @State private var fiberString: String

    // Multipack / Sub-unit configuration
    @State private var isMultipack: Bool
    @State private var subUnitCount: Int
    @State private var subUnitSizeString: String
    @State private var subUnitName: String

    // Storage Location & Instructions
    @State private var storageLocation: StorageLocation
    @State private var storageInstructions: String

    // Enrichment state
    @State private var isEnriching: Bool = false
    @State private var enrichmentStatus: String? = nil

    // Info Explanation Modal
    @State private var selectedExplanation: InfoExplanationItem? = nil

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, brand, barcode, store, price
        case stock, packQty
        case kcal, protein, carbs, fat, fiber
        case subUnitSize, subUnitName, storageInstructions
    }

    private let availableUnits = ["g", "ml", "l", "Stück", "Kapseln"]

    public static func formatDecimal(_ val: Double, maxDigits: Int = 3) -> String {
        if val == 0.0 { return "0" }
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(val))"
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxDigits
        return formatter.string(from: NSNumber(value: val)) ?? String(format: "%.\(maxDigits)f", val)
    }

    public static func parseDecimal(_ text: String) -> Double {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        return Double(clean) ?? 0.0
    }

    public init(item: PantryItem, store: LocalStore) {
        self.item = item
        self.store = store

        _productName = State(initialValue: item.name)
        _productBrand = State(initialValue: item.brand)
        _productBarcode = State(initialValue: item.barcode)
        _productStore = State(initialValue: item.store.isEmpty ? "PENNY" : item.store)
        _priceString = State(initialValue: item.defaultPrice > 0 ? EditStockSheet.formatDecimal(item.defaultPrice, maxDigits: 2) : "1,49")

        _inputString = State(initialValue: EditStockSheet.formatDecimal(item.currentStockQty, maxDigits: 3))
        let pQty = item.defaultPackQty > 0 ? item.defaultPackQty : 500.0
        _packQtyString = State(initialValue: EditStockSheet.formatDecimal(pQty, maxDigits: 3))
        _selectedUnit = State(initialValue: item.unit.isEmpty ? "g" : item.unit)

        _kcalString = State(initialValue: EditStockSheet.formatDecimal(item.kcal100g, maxDigits: 1))
        _proteinString = State(initialValue: EditStockSheet.formatDecimal(item.protein100g, maxDigits: 2))
        _carbsString = State(initialValue: EditStockSheet.formatDecimal(item.carbs100g, maxDigits: 2))
        _fatString = State(initialValue: EditStockSheet.formatDecimal(item.fat100g, maxDigits: 2))
        _fiberString = State(initialValue: EditStockSheet.formatDecimal(item.fiber100g, maxDigits: 2))

        _storageLocation = State(initialValue: item.storageLocation)
        _storageInstructions = State(initialValue: item.storageInstructions)

        let hasSub = item.hasSubUnits
        _isMultipack = State(initialValue: hasSub)
        let sCount = item.subUnitCount ?? 3
        _subUnitCount = State(initialValue: max(2, sCount))
        let sSize = item.subUnitSize ?? (pQty > 0 ? (pQty / Double(max(2, sCount))) : 200.0)
        _subUnitSizeString = State(initialValue: EditStockSheet.formatDecimal(sSize, maxDigits: 3))
        _subUnitName = State(initialValue: item.effectiveSubUnitName)
    }

    private var currentStockVal: Double {
        EditStockSheet.parseDecimal(inputString)
    }

    private var packQtyVal: Double {
        EditStockSheet.parseDecimal(packQtyString)
    }

    private var subUnitSizeVal: Double {
        let clean = EditStockSheet.parseDecimal(subUnitSizeString)
        return clean > 0 ? clean : (selectedUnit == "l" ? 0.25 : 200.0)
    }

    private var isPieceUnit: Bool {
        let u = selectedUnit.lowercased()
        return u == "stück" || u == "kapseln" || u == "kapsel" || u == "stk"
    }

    private var isLiterUnit: Bool {
        selectedUnit.lowercased() == "l"
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Clean Austere Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(productBrand.isEmpty ? "PANTRY DATENBANK" : productBrand.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.warmSand)
                        .tracking(1.0)
                    Text("Artikel & Nährwert-Editor")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    if !productName.isEmpty {
                        Text(productName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Schließen")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.surfaceElevated))
                }
            }
            .padding(16)
            .background(Theme.bg)

            Divider().background(Theme.border)

            ScrollView {
                VStack(spacing: 16) {
                    // Status banner if enriched
                    if let status = enrichmentStatus {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.sageGreen)
                            Text(status)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                        }
                        .padding(10)
                        .wellnessCard(borderColor: Theme.sageGreen.opacity(0.4), cornerRadius: 8)
                    }

                    // 1. Stammdaten (Name, Marke, EAN, Store, Preis)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ARTIKEL-STAMMDATEN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.warmSand)
                                    .frame(width: 20)
                                TextField("Produktname", text: $productName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                    .focused($focusedField, equals: .name)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))

                            HStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "tag")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                    TextField("Marke", text: $productBrand)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textPrimary)
                                        .focused($focusedField, equals: .brand)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))

                                HStack(spacing: 8) {
                                    Image(systemName: "cart")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                    TextField("Geschäft", text: $productStore)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textPrimary)
                                        .focused($focusedField, equals: .store)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }

                            HStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                    TextField("EAN / Barcode", text: $productBarcode)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .barcode)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))

                                HStack(spacing: 4) {
                                    Text("€")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.warmSand)
                                    TextField("Preis", text: $priceString)
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .price)
                                }
                                .frame(width: 90)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                    }

                    // 2. Nährwerte pro 100g / 100ml (Milli- / Komma-Genauigkeit)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("NÄHRWERTE PRO 100G / 100ML")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            Button(action: {
                                Task {
                                    await performLiveEnrichment()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if isEnriching {
                                        ProgressView().scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    Text("OFF / BLS LADEN")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(Theme.warmSand)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Theme.surfaceElevated))
                            }
                        }

                        // Macro Inputs Grid
                        HStack(spacing: 6) {
                            macroInputField(title: "KCAL", text: $kcalString, focus: .kcal)
                            macroInputField(title: "PROTEIN", text: $proteinString, focus: .protein, highlight: true)
                            macroInputField(title: "KH", text: $carbsString, focus: .carbs)
                            macroInputField(title: "FETT", text: $fatString, focus: .fat)
                            macroInputField(title: "FASER", text: $fiberString, focus: .fiber)
                        }

                        // Protein-Efficiency Ratio indicator
                        let parsedKcal = EditStockSheet.parseDecimal(kcalString)
                        let parsedProt = EditStockSheet.parseDecimal(proteinString)
                        if parsedKcal > 0 {
                            let pe = (parsedProt / parsedKcal) * 100.0
                            HStack(spacing: 6) {
                                Circle().fill(pe >= 12.0 ? Theme.sageGreen : (pe >= 7.0 ? Theme.warmSand : Theme.textMuted)).frame(width: 5, height: 5)
                                Text("Protein-Effizienz: \(String(format: "%.1f", pe))% (P/kcal)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text("Komma-Eingabe (0,001) aktiv")
                                    .font(.system(size: 9, weight: .regular))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .padding(.top, 2)
                        }
                    }

                    // 3. Bestand & Standard-Packung
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BESTAND & EINHEIT (MILLI-PRÄZISION)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        // Unit Selector
                        HStack(spacing: 6) {
                            ForEach(availableUnits, id: \.self) { u in
                                let isSelected = selectedUnit.lowercased() == u.lowercased()
                                Button(action: {
                                    HapticFeedbackService.shared.lightDetent()
                                    selectedUnit = u
                                }) {
                                    Text(u)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? Theme.textPrimary : Theme.textMuted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 7)
                                        .background(isSelected ? Theme.surfaceElevated : Theme.bg)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.warmSand : Theme.border, lineWidth: 1))
                                }
                            }
                        }

                        // Stock & Pack Inputs
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Aktueller Bestand")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                                HStack {
                                    TextField("0,0", text: $inputString)
                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .stock)
                                    Text(selectedUnit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.textMuted)
                                }
                                .padding(10)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Packungsgröße")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                                HStack {
                                    TextField("500", text: $packQtyString)
                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .packQty)
                                    Text(selectedUnit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.textMuted)
                                }
                                .padding(10)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }
                        }

                        // Steppers
                        HStack(spacing: 8) {
                            stepperPill(delta: -1.0, label: "- 1")
                            stepperPill(delta: 1.0, label: "+ 1")
                            if selectedUnit == "g" || selectedUnit == "ml" {
                                stepperPill(delta: 100.0, label: "+ 100")
                            }
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                inputString = packQtyString
                            }) {
                                Text("Voll")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.sageGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                            }
                        }
                    }

                    // 4. Lagerort & Anweisungen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LAGERORT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(StorageLocation.allCases) { loc in
                                    let isSel = storageLocation == loc
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        storageLocation = loc
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: loc.iconName)
                                                .font(.system(size: 10))
                                            Text(loc.shortLabel)
                                                .font(.system(size: 11, weight: isSel ? .bold : .medium))
                                        }
                                        .foregroundColor(isSel ? Theme.textPrimary : Theme.textMuted)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(isSel ? Theme.surfaceElevated : Theme.bg)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSel ? Theme.warmSand : Theme.border, lineWidth: 1))
                                    }
                                }
                            }
                        }

                        TextField("Lagerhinweis (z.B. Kühl & trocken lagern)", text: $storageInstructions)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textPrimary)
                            .padding(10)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            .focused($focusedField, equals: .storageInstructions)
                    }

                    // 5. Multipack / Gebinde Unterteilung
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isMultipack) {
                            Text("GEBINDE-UNTERTEILUNG (MULTIPACK)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.warmSand))

                        if isMultipack {
                            HStack(spacing: 8) {
                                Stepper("Anzahl: \(subUnitCount)", value: $subUnitCount, in: 2...48)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)

                                TextField("Größe", text: $subUnitSizeString)
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(width: 70)
                                    .padding(6)
                                    .background(Theme.surfaceElevated)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                                    .keyboardType(.decimalPad)
                            }
                            .padding(10)
                            .wellnessCard(cornerRadius: 8)
                        }
                    }

                    Spacer().frame(height: 20)
                }
                .padding(16)
            }

            // Bottom Save Bar
            Divider().background(Theme.border)
            VStack(spacing: 8) {
                Button(action: saveAndDismiss) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("SPEICHERN & ENTSCHEIDUNGSMATRIX AKTUALISIEREN")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.warmSand))
                }
            }
            .padding(16)
            .background(Theme.surface)
        }
        .background(Theme.bg.edgesIgnoringSafeArea(.all))
    }

    private func macroInputField(title: String, text: Binding<String>, focus: Field, highlight: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(highlight ? Theme.warmSand : Theme.textMuted)

            TextField("0,0", text: text)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(highlight ? Theme.warmSand : Theme.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(Theme.surfaceElevated)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(highlight ? Theme.warmSand.opacity(0.6) : Theme.border, lineWidth: 1))
                .focused($focusedField, equals: focus)
        }
    }

    private func stepperPill(delta: Double, label: String) -> some View {
        Button(action: {
            HapticFeedbackService.shared.lightDetent()
            let current = EditStockSheet.parseDecimal(inputString)
            let newQty = max(0.0, current + delta)
            inputString = EditStockSheet.formatDecimal(newQty, maxDigits: 3)
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
        }
    }

    private func performLiveEnrichment() async {
        isEnriching = true
        HapticFeedbackService.shared.lightDetent()

        var foundKcal: Double? = nil
        var foundProt: Double? = nil
        var foundCarb: Double? = nil
        var foundFat: Double? = nil
        var foundFib: Double? = nil

        let barcode = productBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !barcode.isEmpty {
            if let off = await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                if off.kcal100g > 0 || off.protein100g > 0 {
                    foundKcal = off.kcal100g
                    foundProt = off.protein100g
                    foundCarb = off.carbs100g
                    foundFat = off.fat100g
                    foundFib = off.fiber100g
                }
            }
        }

        if foundKcal == nil || foundProt == nil {
            let n = productName.lowercased()
            if n.contains("skyr") {
                foundKcal = 65; foundProt = 11.0; foundCarb = 4.0; foundFat = 0.2; foundFib = 0.0
            } else if n.contains("quark") {
                foundKcal = 68; foundProt = 12.0; foundCarb = 4.1; foundFat = 0.2; foundFib = 0.0
            } else if n.contains("thunf") {
                foundKcal = 112; foundProt = 26.0; foundCarb = 0.0; foundFat = 0.8; foundFib = 0.0
            } else if n.contains("hafer") {
                foundKcal = 370; foundProt = 13.5; foundCarb = 58.7; foundFat = 7.0; foundFib = 10.0
            } else if n.contains("kartoffel") {
                foundKcal = 77; foundProt = 2.0; foundCarb = 17.0; foundFat = 0.1; foundFib = 2.1
            } else if n.contains("reis") {
                foundKcal = 360; foundProt = 7.0; foundCarb = 78.0; foundFat = 0.7; foundFib = 1.4
            } else if n.contains("hähnchen") || n.contains("huhn") {
                foundKcal = 106; foundProt = 23.0; foundCarb = 0.0; foundFat = 1.2; foundFib = 0.0
            } else if n.contains("ei") || n.contains("eier") {
                foundKcal = 143; foundProt = 12.8; foundCarb = 0.7; foundFat = 9.9; foundFib = 0.0
            } else if n.contains("bohne") || n.contains("kidney") {
                foundKcal = 110; foundProt = 8.4; foundCarb = 15.0; foundFat = 0.5; foundFib = 6.5
            } else if n.contains("kichererbse") {
                foundKcal = 120; foundProt = 7.0; foundCarb = 17.0; foundFat = 2.5; foundFib = 5.0
            } else if n.contains("apfel") {
                foundKcal = 52; foundProt = 0.3; foundCarb = 13.8; foundFat = 0.2; foundFib = 2.4
            } else if n.contains("beere") {
                foundKcal = 45; foundProt = 1.0; foundCarb = 7.5; foundFat = 0.5; foundFib = 4.5
            } else if n.contains("banan") {
                foundKcal = 89; foundProt = 1.1; foundCarb = 22.8; foundFat = 0.3; foundFib = 2.6
            } else if n.contains("whey") || n.contains("protein") {
                foundKcal = 390; foundProt = 75.0; foundCarb = 6.0; foundFat = 5.5; foundFib = 1.0
            } else if n.contains("toast") || n.contains("brot") {
                foundKcal = 225; foundProt = 8.0; foundCarb = 42.0; foundFat = 1.5; foundFib = 6.0
            }
        }

        await MainActor.run {
            isEnriching = false
            if let k = foundKcal, let p = foundProt {
                kcalString = EditStockSheet.formatDecimal(k, maxDigits: 1)
                proteinString = EditStockSheet.formatDecimal(p, maxDigits: 2)
                carbsString = EditStockSheet.formatDecimal(foundCarb ?? 0.0, maxDigits: 2)
                fatString = EditStockSheet.formatDecimal(foundFat ?? 0.0, maxDigits: 2)
                fiberString = EditStockSheet.formatDecimal(foundFib ?? 0.0, maxDigits: 2)
                enrichmentStatus = "Nährwerte erfolgreich geladen & übernommen"
                HapticFeedbackService.shared.commitSuccess()
            } else {
                enrichmentStatus = "Keine Daten online/im Referenzkatalog gefunden"
                HapticFeedbackService.shared.lightDetent()
            }
        }
    }

    private func saveAndDismiss() {
        let parsedStock = EditStockSheet.parseDecimal(inputString)
        let parsedPack = EditStockSheet.parseDecimal(packQtyString)
        let parsedPrice = EditStockSheet.parseDecimal(priceString)

        let parsedKcal = EditStockSheet.parseDecimal(kcalString)
        let parsedProt = EditStockSheet.parseDecimal(proteinString)
        let parsedCarbs = EditStockSheet.parseDecimal(carbsString)
        let parsedFat = EditStockSheet.parseDecimal(fatString)
        let parsedFiber = EditStockSheet.parseDecimal(fiberString)

        let cleanSubSize = EditStockSheet.parseDecimal(subUnitSizeString)
        let sSize = cleanSubSize > 0 ? cleanSubSize : (parsedPack / Double(max(subUnitCount, 1)))

        let effectivePackQty = isMultipack ? (Double(subUnitCount) * sSize) : parsedPack
        let effectiveName = productName.trimmingCharacters(in: .whitespaces).isEmpty ? "Neuer Artikel" : productName.trimmingCharacters(in: .whitespaces)
        let effectiveBrand = productBrand.trimmingCharacters(in: .whitespaces).isEmpty ? "Pantry" : productBrand.trimmingCharacters(in: .whitespaces)
        let effectiveStore = productStore.trimmingCharacters(in: .whitespaces).isEmpty ? "PENNY" : productStore.trimmingCharacters(in: .whitespaces)

        store.updatePantryItemFull(
            id: item.id,
            name: effectiveName,
            brand: effectiveBrand,
            barcode: productBarcode.trimmingCharacters(in: .whitespaces),
            store: effectiveStore,
            unit: selectedUnit,
            currentStockQty: parsedStock,
            defaultPackQty: max(0.001, effectivePackQty),
            defaultPrice: parsedPrice,
            kcal100g: parsedKcal,
            protein100g: parsedProt,
            carbs100g: parsedCarbs,
            fat100g: parsedFat,
            fiber100g: parsedFiber,
            storageLocation: storageLocation,
            storageInstructions: storageInstructions,
            subUnitCount: isMultipack ? subUnitCount : nil,
            subUnitSize: isMultipack ? sSize : nil,
            subUnitName: isMultipack ? (subUnitName.isEmpty ? "Einheiten" : subUnitName) : nil
        )

        presentationMode.wrappedValue.dismiss()
    }
}
