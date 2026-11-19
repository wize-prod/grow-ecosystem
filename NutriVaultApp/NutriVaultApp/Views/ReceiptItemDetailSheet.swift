import SwiftUI

public struct ReceiptItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LocalStore.shared

    public let receiptId: String
    public let lineItemId: String

    @State private var selectedTab: CreationMode = .create
    @State private var showingBarcodeScanner: Bool = false
    @State private var showingNutritionDetail: Bool = false
    @State private var showingEditStock: Bool = false
    @State private var showingLinkPicker: Bool = false

    // Form fields for creating/editing product
    @State private var productName: String = ""
    @State private var productBrand: String = ""
    @State private var productBarcode: String = ""
    @State private var productStore: String = ""
    @State private var productUnit: String = "g"
    @State private var productPackQty: String = "500"
    @State private var productPrice: String = "0.00"
    @State private var productKcal: String = "100"
    @State private var productProtein: String = "10.0"
    @State private var productCarbs: String = "10.0"
    @State private var productFat: String = "2.0"
    @State private var productFiber: String = "1.0"

    // Search for linking existing
    @State private var pantrySearchText: String = ""
    @State private var isLookingUpEAN: Bool = false
    @State private var lookupMessage: String? = nil
    @State private var statusMessage: String? = nil

    // Editing EAN for already linked item
    @State private var isEditingLinkedEAN: Bool = false
    @State private var editedLinkedEAN: String = ""

    // Editing receipt line item price and quantity
    @State private var isEditingReceiptLine: Bool = false
    @State private var editedLinePrice: String = ""
    @State private var editedLineQuantity: Int = 1
    @State private var editedLineRawText: String = ""

    // Editing product name for already linked item
    @State private var isEditingProductName: Bool = false
    @State private var editedProductName: String = ""
    @State private var editedProductBrand: String = ""

    // Variant disambiguation & inline variant creator
    @State private var isCreatingNewVariant: Bool = false
    @State private var variantPackQty: String = "400"
    @State private var variantPrice: String = "3.99"
    @State private var variantBarcode: String = ""
    @State private var variantSuffix: String = "400g Packung"

    enum CreationMode: String, CaseIterable {
        case create = "Neu anlegen & EAN"
        case link = "Aus Vorrat verknuepfen"
    }

    public init(receiptId: String, lineItemId: String) {
        self.receiptId = receiptId
        self.lineItemId = lineItemId
    }

    private var currentReceipt: ReceiptRecord? {
        store.receipts.first(where: { $0.id == receiptId })
    }

    private var currentLineItem: ReceiptLineItem? {
        currentReceipt?.items.first(where: { $0.id == lineItemId })
    }

    private var matchedPantryItem: PantryItem? {
        guard let item = currentLineItem else { return nil }
        if let pId = item.matchedPantryItemId, let match = store.pantryItems.first(where: { $0.id == pId }) {
            return match
        }
        // Fallback name matching
        return store.pantryItems.first(where: {
            $0.name.lowercased() == item.rawText.lowercased() ||
            ($0.name.lowercased() == (item.matchedPantryItemName ?? "").lowercased())
        })
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header: Bon-Position Card
                        if let item = currentLineItem, let r = currentReceipt {
                            bonPositionHeaderCard(item: item, receipt: r)
                        }

                        if let matched = matchedPantryItem {
                            // Section: Linked Database Product
                            linkedProductSection(matched)
                        } else {
                            // Section: Unlinked - Add EAN or Link
                            unlinkedItemSection
                        }

                        // Action Button at bottom of content when scrolling down
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Aenderungen uebernehmen & Fertig")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.sageGreen)
                            .cornerRadius(12)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Beleg-Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(Theme.sageGreen)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .onDisappear {
                saveLineEditsIfDirty()
                store.saveReceipts()
                store.savePantry()
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { scannedCode in
                    handleScannedBarcode(scannedCode)
                }
            }
            .sheet(isPresented: $showingNutritionDetail) {
                if let p = matchedPantryItem {
                    NutritionDetailSheet(item: p)
                }
            }
            .sheet(isPresented: $showingEditStock) {
                if let p = matchedPantryItem {
                    EditStockSheet(item: p, store: store)
                }
            }
            .sheet(isPresented: $showingLinkPicker) {
                linkExistingPickerSheet
            }
            .onDisappear {
                store.saveReceipts()
                store.savePantry()
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header: Bon Position
    private func bonPositionHeaderCard(item: ReceiptLineItem, receipt: ReceiptRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("QUITTUNGS-POSITION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                Spacer()
                Text(receipt.storeName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.warmSand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.surface))
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.rawText)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    if item.quantity > 1 {
                        Text("\(item.quantity) Packungen / Stk à \(String(format: "%.2f €", item.singlePackPrice))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    } else if let note = item.quantityNote, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.quantity > 1 ? "EINZELPREIS" : "BON-PREIS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    Text(String(format: "%.2f €", item.singlePackPrice))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)

                    if item.quantity > 1 {
                        Text(String(format: "Gesamt: %.2f €", item.lineTotalPrice))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    }
                }
            }

            // Quick Inline Editor for Line Item Price & Quantity
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditingReceiptLine.toggle()
                    if isEditingReceiptLine {
                        editedLinePrice = String(format: "%.2f", item.singlePackPrice)
                        editedLineQuantity = item.quantity
                        editedLineRawText = item.rawText
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isEditingReceiptLine ? "xmark.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 13))
                    Text(isEditingReceiptLine ? "Bearbeitung schliessen" : "Preis & Packungsanzahl korrigieren")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(Theme.warmSand)
                .padding(.top, 4)
            }

            if isEditingReceiptLine {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(Theme.border)

                    Text("BON-PREIS & MENGE KORRIGIEREN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Einzelpreis (€)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                            TextField("1.49", text: $editedLinePrice)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Menge (Packungen)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                            HStack(spacing: 6) {
                                Button(action: { if editedLineQuantity > 1 { editedLineQuantity -= 1 } }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(width: 28, height: 28)
                                        .background(Theme.surface)
                                        .cornerRadius(6)
                                }
                                Text("\(editedLineQuantity)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .frame(minWidth: 24)
                                Button(action: { editedLineQuantity += 1 }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(width: 28, height: 28)
                                        .background(Theme.surface)
                                        .cornerRadius(6)
                                }
                            }
                            .foregroundColor(Theme.textPrimary)
                            .padding(4)
                        }
                    }

                    Button(action: {
                        let cleanPrice = Double(editedLinePrice.replacingOccurrences(of: ",", with: ".")) ?? item.singlePackPrice
                        store.updateReceiptLineItem(
                            receiptId: receiptId,
                            lineItemId: lineItemId,
                            newName: editedLineRawText.isEmpty ? item.rawText : editedLineRawText,
                            newUnitPrice: cleanPrice,
                            newQuantity: editedLineQuantity,
                            updatePantryPrice: true
                        )
                        isEditingReceiptLine = false
                        statusMessage = "Einzelpreis (\(String(format: "%.2f €", cleanPrice))) dauerhaft gesichert."
                        HapticFeedbackService.shared.commitSuccess()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Dauerhaft speichern")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                        }
                        .foregroundColor(Theme.bg)
                        .padding(.vertical, 10)
                        .background(Theme.sageGreen)
                        .cornerRadius(8)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surface))
            }

            if let msg = statusMessage {
                Text(msg)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.sageGreen)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .wellnessCard(borderColor: matchedPantryItem != nil ? Theme.sageGreen : Theme.warmSand)
    }

    // MARK: - Linked Product Section
    private func linkedProductSection(_ item: PantryItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.sageGreen)
                Text("IN LEBENSMITTELDATENBANK VERKNUEPFT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.sageGreen)
                Spacer()
            }

            // Product summary card
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textPrimary)

                            Button(action: {
                                editedProductName = item.name
                                editedProductBrand = item.brand
                                isEditingProductName.toggle()
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.warmSand)
                            }
                        }

                        Text(item.brand.isEmpty ? item.store : "\(item.brand) | \(item.store)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BESTAND")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        Text("\(Int(item.currentStockQty)) \(item.unit)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(item.isLowStock ? Theme.terracotta : Theme.warmSand)
                    }
                }

                if isEditingProductName {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            VStack(spacing: 6) {
                                TextField("Produktname", text: $editedProductName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(8)
                                    .background(Theme.surface)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.warmSand, lineWidth: 1))

                                TextField("Marke (optional)", text: $editedProductBrand)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(8)
                                    .background(Theme.surface)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }

                            Button(action: {
                                if !editedProductName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    store.updateProductMetadata(id: item.id, name: editedProductName, brand: editedProductBrand)
                                    isEditingProductName = false
                                    statusMessage = "Produktname aktualisiert."
                                }
                            }) {
                                Text("Sichern")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.bg)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                                    .background(Theme.sageGreen)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                }

                // Macro quick strip
                HStack(spacing: 8) {
                    macroBadge(label: "Kcal", value: "\(Int(item.kcal100g))")
                    macroBadge(label: "Protein", value: String(format: "%.1f g", item.protein100g))
                    macroBadge(label: "Kohlenh.", value: String(format: "%.1f g", item.carbs100g))
                    macroBadge(label: "Fett", value: String(format: "%.1f g", item.fat100g))
                    macroBadge(label: "Ballastst.", value: String(format: "%.1f g", item.fiber100g))
                }

                // EAN display & edit row
                HStack {
                    Image(systemName: "barcode")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                    if item.barcode.isEmpty {
                        Text("Kein EAN hinterlegt")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    } else {
                        Text("EAN: \(item.barcode)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    }
                    Spacer()
                    Button(action: {
                        editedLinkedEAN = item.barcode
                        isEditingLinkedEAN = true
                        showingBarcodeScanner = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 12, weight: .bold))
                            Text("EAN scannen")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.sageGreen)
                        .cornerRadius(8)
                    }
                    Button(action: {
                        editedLinkedEAN = item.barcode
                        isEditingLinkedEAN.toggle()
                    }) {
                        Text(isEditingLinkedEAN ? "Schliessen" : "Tippen")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.top, 4)

                // Inline EAN editing interface
                if isEditingLinkedEAN {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            TextField("EAN eingeben", text: $editedLinkedEAN)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(8)
                                .keyboardType(.numberPad)

                            Button(action: {
                                showingBarcodeScanner = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.bg)
                                    .padding(8)
                                    .background(Theme.warmSand)
                                    .cornerRadius(8)
                            }

                            Button("Speichern") {
                                store.updatePantryItemEAN(itemId: item.id, newBarcode: editedLinkedEAN.trimmingCharacters(in: .whitespaces))
                                isEditingLinkedEAN = false
                                statusMessage = "EAN aktualisiert."
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.sageGreen)
                            .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceElevated))

            // Variant Disambiguation & Variant Creation Section
            variantDisambiguationSection(item)

            // Primary Navigation & Action Buttons
            VStack(spacing: 10) {
                // 1. View Nutrition & Micronutrients
                Button(action: { showingNutritionDetail = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                        Text("In Lebensmitteldatenbank ansehen (Naehrwerte & Mikros)")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.bg)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                }

                // 2. Edit Stock in Pantry
                Button(action: { showingEditStock = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.and.arrow.backward")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Im Vorrat bearbeiten (Bestand & Packung)")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                }

                // 3. Re-link or Unlink
                HStack(spacing: 8) {
                    Button(action: { showingLinkPicker = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                            Text("Verknuepfung aendern")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Theme.warmSand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    }

                    Button(action: {
                        unlinkCurrentItem()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 12))
                            Text("Trennen")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Theme.terracotta)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    }
                }
            }
        }
    }

    private func macroBadge(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
    }

    // MARK: - Unlinked Item Section
    private var unlinkedItemSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.warmSand)
                Text("NOCH NICHT IN DATENBANK HINTERLEGT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.warmSand)
                Spacer()
            }

            // Mode Selector
            Picker("Aktion", selection: $selectedTab) {
                ForEach(CreationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if selectedTab == .create {
                createNewProductForm
            } else {
                linkExistingList
            }
        }
    }

    // MARK: - Create New Product Form
    private var createNewProductForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            // EAN Scan Banner
            Button(action: {
                showingBarcodeScanner = true
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.bg.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.bg)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("EAN mit Kamera scannen")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.bg)
                        Text(isLookingUpEAN ? "Lade Naehrwerte & Produktdaten..." : (lookupMessage ?? "Automatisch Produktdaten via EAN erfassen"))
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .foregroundColor(Theme.bg.opacity(0.85))
                    }

                    Spacer()

                    if isLookingUpEAN {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.bg))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.bg)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.warmSand))
            }

            // Form Fields
            VStack(alignment: .leading, spacing: 10) {
                Text("PRODUKTDATEN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)

                formField(title: "Produktname", text: $productName, placeholder: "z.B. Salatgurke frisch")
                formField(title: "Marke / Hersteller", text: $productBrand, placeholder: "z.B. Penny")

                HStack(spacing: 8) {
                    formField(title: "EAN-Barcode", text: $productBarcode, placeholder: "4000000000000", keyboard: .numberPad)
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        showingBarcodeScanner = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 14, weight: .bold))
                            Text("EAN scannen")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Theme.sageGreen)
                        .cornerRadius(10)
                    }
                    .padding(.top, 16)
                }
                .onChange(of: productBarcode) { newCode in
                    let clean = newCode.trimmingCharacters(in: .whitespaces)
                    if (clean.count == 8 || clean.count == 13) && !isLookingUpEAN {
                        lookupEANData(clean)
                    }
                }

                formField(title: "Geschaeft", text: $productStore, placeholder: "PENNY")
            }

            Divider().background(Theme.border)

            // Pack & Price
            VStack(alignment: .leading, spacing: 10) {
                Text("PACKUNGSGROESSE & PREIS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)

                HStack(spacing: 6) {
                    ForEach(["Stück", "g", "ml", "l", "Kapseln"], id: \.self) { u in
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            productUnit = u
                        }) {
                            Text(u)
                                .font(.system(size: 11, weight: productUnit == u ? .bold : .medium))
                                .foregroundColor(productUnit == u ? Theme.bg : Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(productUnit == u ? Theme.sageGreen : Theme.surfaceElevated)
                                )
                        }
                    }
                }

                HStack(spacing: 12) {
                    formField(title: "Packung (\(productUnit))", text: $productPackQty, placeholder: "500", keyboard: .decimalPad)
                    formField(title: "Preis (€)", text: $productPrice, placeholder: "1.99", keyboard: .decimalPad)
                }
            }

            Divider().background(Theme.border)

            // Macros
            VStack(alignment: .leading, spacing: 10) {
                Text("NAEHRWERTE PRO 100G")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)

                HStack(spacing: 12) {
                    formField(title: "Kalorien (kcal)", text: $productKcal, placeholder: "100", keyboard: .decimalPad)
                    formField(title: "Protein (g)", text: $productProtein, placeholder: "10.0", keyboard: .decimalPad)
                }

                HStack(spacing: 12) {
                    formField(title: "Kohlenhydrate (g)", text: $productCarbs, placeholder: "10.0", keyboard: .decimalPad)
                    formField(title: "Fett (g)", text: $productFat, placeholder: "2.0", keyboard: .decimalPad)
                }

                formField(title: "Ballaststoffe (g)", text: $productFiber, placeholder: "1.0", keyboard: .decimalPad)
            }

            // Commit Button
            Button(action: {
                commitNewProduct()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("In Datenbank speichern & mit Beleg verknuepfen")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.sageGreen))
                .shadow(color: Theme.sageGreen.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            .padding(.top, 8)
        }
    }

    private func formField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            TextField(placeholder, text: text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.textPrimary)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                .keyboardType(keyboard)
        }
    }

    // MARK: - Link Existing List
    private var linkExistingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
                TextField("Vorrat durchsuchen...", text: $pantrySearchText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))

            let filtered = store.pantryItems.filter {
                if pantrySearchText.trimmingCharacters(in: .whitespaces).isEmpty { return true }
                let q = pantrySearchText.lowercased()
                return $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || $0.barcode.contains(q)
            }

            VStack(spacing: 6) {
                ForEach(filtered.prefix(15)) { p in
                    Button(action: {
                        linkToExistingItem(p)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(p.brand.isEmpty ? p.store : p.brand) | \(Int(p.currentStockQty)) \(p.unit) vorraetig")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Text(String(format: "%.2f €", p.defaultPrice))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    }
                }
            }
        }
    }

    // MARK: - Link Existing Modal Picker
    private var linkExistingPickerSheet: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        linkExistingList
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Artikel zuweisen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingLinkPicker = false }
                        .foregroundColor(Theme.warmSand)
                }
            }
        }
    }

    // MARK: - Logic & Actions
    private func setupInitialValues() {
        guard let item = currentLineItem, let r = currentReceipt else { return }

        // Clean receipt text to title case
        productName = cleanRawReceiptName(item.rawText)
        productBrand = r.storeName
        productStore = r.storeName
        productPrice = String(format: "%.2f", item.parsedPrice)

        if let matched = matchedPantryItem {
            editedLinkedEAN = matched.barcode
        }
    }

    private func cleanRawReceiptName(_ raw: String) -> String {
        // Normalize uppercase string to capitalized words
        let words = raw.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let cleaned = words.map { word -> String in
            let lower = word.lowercased()
            // Ignore single-letter tax keys like A, B
            if lower == "a" || lower == "b" { return "" }
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }.filter { !$0.isEmpty }.joined(separator: " ")
        return cleaned.isEmpty ? raw : cleaned
    }

    private func handleScannedBarcode(_ code: String) {
        let cleanCode = code.trimmingCharacters(in: .whitespaces)
        guard !cleanCode.isEmpty else { return }

        if let matched = matchedPantryItem {
            store.updatePantryItemEAN(itemId: matched.id, newBarcode: cleanCode)
            isEditingLinkedEAN = false
            statusMessage = "EAN \(cleanCode) auf \(matched.name) und alle Belege uebertragen."
            HapticFeedbackService.shared.commitSuccess()
            return
        }

        productBarcode = cleanCode
        lookupEANData(cleanCode)
    }

    private func lookupEANData(_ code: String) {
        guard !code.isEmpty else { return }
        isLookingUpEAN = true
        lookupMessage = "Suche Produktdaten fuer EAN \(code)..."

        // 1. Check local catalog
        if let local = store.pantryItems.first(where: { $0.barcode == code }) {
            populateFromPantryItem(local)
            store.linkReceiptItem(receiptId: receiptId, lineItemId: lineItemId, to: local, updatePrice: true)
            isLookingUpEAN = false
            lookupMessage = "Aus Vorrat geladen & verknuepft: \(local.name)"
            statusMessage = "Mit Vorratsartikel verknuepft: \(local.name)"
            HapticFeedbackService.shared.commitSuccess()
            return
        }

        // 2. Check master seed
        if let master = MasterDataSeed.getMasterCatalog().first(where: { $0.barcode == code }) {
            populateFromPantryItem(master)
            isLookingUpEAN = false
            lookupMessage = "Aus Stammdaten geladen: \(master.name)"
            return
        }

        // 3. Query Open Food Facts
        Task {
            if let fetched = await OpenFoodFactsService.shared.fetchProduct(barcode: code) {
                await MainActor.run {
                    populateFromPantryItem(fetched)
                    isLookingUpEAN = false
                    lookupMessage = "Gefunden: \(fetched.name)"
                }
            } else {
                await MainActor.run {
                    isLookingUpEAN = false
                    lookupMessage = "Keine Daten online gefunden. Manuelle Eingabe aktiv."
                }
            }
        }
    }

    private func populateFromPantryItem(_ item: PantryItem) {
        productName = item.name
        if !item.brand.isEmpty { productBrand = item.brand }
        productUnit = item.unit
        productPackQty = (item.defaultPackQty == floor(item.defaultPackQty)) ? "\(Int(item.defaultPackQty))" : String(format: "%.2f", item.defaultPackQty)
        productKcal = "\(Int(item.kcal100g))"
        productProtein = String(format: "%.1f", item.protein100g)
        productCarbs = String(format: "%.1f", item.carbs100g)
        productFat = String(format: "%.1f", item.fat100g)
        productFiber = String(format: "%.1f", item.fiber100g)
    }

    private func commitNewProduct() {
        guard let item = currentLineItem, let r = currentReceipt else { return }
        let cleanName = productName.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else { return }

        let cleanPrice = Double(productPrice.replacingOccurrences(of: ",", with: ".")) ?? item.parsedPrice
        let cleanPack = Double(productPackQty.replacingOccurrences(of: ",", with: ".")) ?? 500.0
        let cleanKcal = Double(productKcal.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let cleanProtein = Double(productProtein.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let cleanCarbs = Double(productCarbs.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let cleanFat = Double(productFat.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let cleanFiber = Double(productFiber.replacingOccurrences(of: ",", with: ".")) ?? 0.0

        let newPantryItem = PantryItem(
            id: "pantry_\(UUID().uuidString)",
            name: cleanName,
            brand: productBrand.trimmingCharacters(in: .whitespaces),
            barcode: productBarcode.trimmingCharacters(in: .whitespaces),
            defaultPackQty: cleanPack,
            defaultPrice: cleanPrice,
            currentStockQty: 0.0,
            unit: productUnit,
            kcal100g: cleanKcal,
            protein100g: cleanProtein,
            carbs100g: cleanCarbs,
            fat100g: cleanFat,
            fiber100g: cleanFiber,
            nutriscore: "a",
            store: productStore.isEmpty ? r.storeName : productStore
        )

        store.createAndLinkProduct(receiptId: receiptId, lineItemId: lineItemId, item: newPantryItem)
        statusMessage = "Produkt in Vorrat gespeichert und verknuepft."
        HapticFeedbackService.shared.commitSuccess()
    }

    private func linkToExistingItem(_ p: PantryItem) {
        store.linkReceiptItem(receiptId: receiptId, lineItemId: lineItemId, to: p, updatePrice: true)
        showingLinkPicker = false
        statusMessage = "Mit \(p.name) verknuepft."
        HapticFeedbackService.shared.commitSuccess()
    }

    private func unlinkCurrentItem() {
        store.unlinkReceiptItem(receiptId: receiptId, lineItemId: lineItemId)
        statusMessage = "Verknuepfung aufgehoben."
        HapticFeedbackService.shared.lightDetent()
    }

    // MARK: - Variant Disambiguation Section

    @ViewBuilder
    private func variantDisambiguationSection(_ currentMatchedItem: PantryItem) -> some View {
        let rawSearch = currentLineItem?.rawText ?? currentMatchedItem.name
        let allVariants = store.findVariants(forItemName: rawSearch)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.warmSand)
                Text("PRODUKT-VARIANTEN & GRAMMATUREN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.warmSand)
                Spacer()
                Text("\(allVariants.count) Varianten")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }

            Text("Belege haben oft denselben Namen für verschiedene Packungsgrößen (z.B. 400g vs. 350g) oder EANs. Wähle die exakte Variante oder erstelle eine neue.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Theme.textSecondary)

            if !allVariants.isEmpty {
                VStack(spacing: 8) {
                    ForEach(allVariants) { v in
                        let isSelected = v.id == currentMatchedItem.id
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(v.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isSelected ? Theme.sageGreen : Theme.textPrimary)

                                    if isSelected {
                                        Text("Aktiv")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.bg)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Theme.sageGreen))
                                    }
                                }

                                HStack(spacing: 8) {
                                    Text("\(Int(v.defaultPackQty)) \(v.unit)")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Theme.textSecondary)

                                    Text(v.priceFormatted)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)

                                    if !v.barcode.isEmpty {
                                        Text("EAN: \(v.barcode)")
                                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }
                            }

                            Spacer()

                            if !isSelected {
                                Button(action: {
                                    linkToExistingItem(v)
                                }) {
                                    Text("Auswählen")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Theme.bg)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.warmSand)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? Theme.surfaceElevated : Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Theme.sageGreen.opacity(0.5) : Theme.border, lineWidth: 1))
                    }
                }
            }

            // Create new Variant Button & Form
            if isCreatingNewVariant {
                VStack(alignment: .leading, spacing: 10) {
                    Text("NEUE VARIANTE DEFINIEREN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Packungsgröße (\(currentMatchedItem.unit))")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                            TextField("z.B. 350", text: $variantPackQty)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preis (€)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                            TextField("z.B. 3.49", text: $variantPrice)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(8)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("EAN Barcode (Optional)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        HStack {
                            TextField("EAN eingeben", text: $variantBarcode)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .keyboardType(.numberPad)
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(8)

                            Button(action: {
                                showingBarcodeScanner = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.bg)
                                    .padding(8)
                                    .background(Theme.warmSand)
                                    .cornerRadius(8)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Button("Abbrechen") {
                            isCreatingNewVariant = false
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Theme.surface)
                        .cornerRadius(8)

                        Spacer()

                        Button("Als Variante sichern & verknüpfen") {
                            commitNewVariant(baseItem: currentMatchedItem)
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.bg)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Theme.sageGreen)
                        .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.sageGreen.opacity(0.4), lineWidth: 1))
            } else {
                Button(action: {
                    if let parsed = currentLineItem?.parsedPrice, parsed > 0 {
                        variantPrice = String(format: "%.2f", parsed)
                    } else {
                        variantPrice = String(format: "%.2f", currentMatchedItem.defaultPrice)
                    }
                    variantPackQty = String(format: "%.0f", currentMatchedItem.defaultPackQty)
                    variantBarcode = ""
                    isCreatingNewVariant = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("+ Als neue Variante anlegen (z.B. andere Grammatur / neuer EAN)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Theme.warmSand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.warmSand.opacity(0.4), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .wellnessCard(borderColor: Theme.border)
    }

    private func commitNewVariant(baseItem: PantryItem) {
        let cleanPack = Double(variantPackQty.replacingOccurrences(of: ",", with: ".")) ?? baseItem.defaultPackQty
        let cleanPrice = Double(variantPrice.replacingOccurrences(of: ",", with: ".")) ?? (currentLineItem?.parsedPrice ?? baseItem.defaultPrice)
        let cleanEAN = variantBarcode.trimmingCharacters(in: .whitespaces)

        let newVariant = store.createVariant(
            from: baseItem,
            newPackQty: cleanPack,
            newPrice: cleanPrice,
            newBarcode: cleanEAN
        )
        linkToExistingItem(newVariant)
        isCreatingNewVariant = false
        statusMessage = "Neue Variante '\(newVariant.name)' gespeichert und verknüpft."
    }

    private func saveLineEditsIfDirty() {
        guard let item = currentLineItem else { return }
        let cleanPrice = Double(editedLinePrice.replacingOccurrences(of: ",", with: ".")) ?? item.singlePackPrice
        let cleanName = editedLineRawText.trimmingCharacters(in: .whitespaces)
        let resolvedName = cleanName.isEmpty ? item.rawText : cleanName
        let cleanQty = max(1, editedLineQuantity)
        if abs(cleanPrice - item.singlePackPrice) > 0.001 || cleanQty != item.quantity || resolvedName != item.rawText {
            store.updateReceiptLineItem(
                receiptId: receiptId,
                lineItemId: lineItemId,
                newName: resolvedName,
                newUnitPrice: cleanPrice,
                newQuantity: cleanQty,
                updatePantryPrice: true
            )
        }
    }
}
