import SwiftUI
import UIKit
import GrowCore

public struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LocalStore.shared

    @State private var showingImagePicker: Bool = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var isProcessing: Bool = false
    @State private var draftReceipt: ParsedReceiptDraft?
    @State private var errorMessage: String?
    @State private var updatePantryPrices: Bool = true
    @State private var editingLineItem: ReceiptLineItem?
    @State private var itemSearchQuery: String = ""
    @State private var showingAddCustomStoreAlert: Bool = false
    @State private var customStoreInput: String = ""
    @State private var showingReassignmentBarcodeScanner: Bool = false
    @State private var isResolvingBarcode: Bool = false
    @State private var barcodeStatusMessage: String?

    public var onReceiptSaved: ((ReceiptRecord) -> Void)?

    public init(onReceiptSaved: ((ReceiptRecord) -> Void)? = nil) {
        self.onReceiptSaved = onReceiptSaved
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isProcessing {
                    processingView
                } else if let draft = draftReceipt {
                    reconciliationView(draft: draft)
                } else {
                    capturePromptView
                }
            }
            .navigationTitle("Quittung erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Theme.warmSand)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ReceiptImagePicker(sourceType: pickerSourceType) { img in
                    self.selectedImage = img
                    processImage(img)
                }
            }
            .sheet(item: $editingLineItem) { line in
                itemReassignmentSheet(for: line)
            }
            .alert("Neues Geschäft hinzufügen", isPresented: $showingAddCustomStoreAlert) {
                TextField("Name des Geschäfts (z.B. SPAR)", text: $customStoreInput)
                Button("Speichern") {
                    let trimmed = customStoreInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        let canonical = store.canonicalStoreName(for: trimmed)
                        store.registerStoreIfNeeded(canonical)
                        draftReceipt?.storeName = canonical
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Das Geschäft wird dauerhaft in der Liste gespeichert und zukünftig automatisch erkannt.")
            }
        }
    }

    // MARK: - Initial Capture Prompt
    private var capturePromptView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 80, height: 80)
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.sageGreen)
                }

                Text("Kassenzettel erfassen")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text("Kamera-Scan oder Foto-Upload. Das System erkennt Artikel, Preise und gleicht Bon-Abkuerzungen mit Ihrem Vorrat ab.")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(Theme.terracotta)
                    .padding(10)
                    .wellnessCard(borderColor: Theme.terracotta)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(action: {
                        pickerSourceType = .camera
                        showingImagePicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 15))
                            Text("Mit Kamera fotografieren")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.sageGreen))
                    }
                }

                Button(action: {
                    pickerSourceType = .photoLibrary
                    showingImagePicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 15))
                        Text("Aus Fotos auswaehlen")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - OCR Processing Progress
    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.sageGreen))
                .scaleEffect(1.3)

            Text("Beleg wird analysiert...")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Text("Texterkennung (OCR) und automatischer Abgleich mit Ihrem Lebensmittel-Katalog laufen.")
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Reconciliation & Confirmation View
    private func reconciliationView(draft: ParsedReceiptDraft) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Data (Store, Date, Total)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("GESCHAEFT")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                Picker("Store", selection: Binding(
                                    get: { draftReceipt?.storeName ?? draft.storeName },
                                    set: { newStore in
                                        if newStore == "__ADD_NEW__" {
                                            customStoreInput = ""
                                            showingAddCustomStoreAlert = true
                                        } else {
                                            draftReceipt?.storeName = newStore
                                            store.registerStoreIfNeeded(newStore)
                                        }
                                    }
                                )) {
                                    ForEach(store.allKnownStores, id: \.self) { s in
                                        Text(s).tag(s)
                                    }
                                    Text("+ Neues Geschäft...").tag("__ADD_NEW__")
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.warmSand)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("SUMME ERKANNT")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.warmSand)
                                Text(String(format: "%.2f €", draft.totalAmount))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.sageGreen)

                                let nonFoodSum = draft.lines.filter { $0.isNonFood }.reduce(0.0) { $0 + $1.lineTotalPrice }
                                let foodSum = draft.lines.filter { !$0.isNonFood }.reduce(0.0) { $0 + $1.lineTotalPrice }
                                if nonFoodSum > 0.01 {
                                    HStack(spacing: 6) {
                                        Text(String(format: "Food: %.2f €", foodSum))
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundColor(Theme.sageGreen)
                                        Text(String(format: "Non-Food: %.2f €", nonFoodSum))
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color.orange)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .wellnessCard()

                    // Items Reconciliation List
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ERFASSTE ARTIKEL (\(draft.lines.count))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text("Tippen zum Neuzuordnen")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Theme.textMuted)
                        }

                        if draft.lines.isEmpty {
                            Text("Keine eindeutigen Preispositionen auf dem Beleg erkannt.")
                                .font(.system(size: 12, weight: .regular, design: .default))
                                .foregroundColor(Theme.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .wellnessCard()
                        } else {
                            ForEach(draft.lines.indices, id: \.self) { idx in
                                lineItemRow(index: idx)
                            }
                        }
                    }

                    // Price Update Policy Toggle
                    Toggle(isOn: $updatePantryPrices) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preise im Vorrat aktualisieren")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Aktualisiert die hinterlegten Artikelpreise im Vorrat auf Basis dieses Belegs.")
                                .font(.system(size: 11, weight: .regular, design: .default))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .tint(Theme.sageGreen)
                    .padding(14)
                    .wellnessCard()
                }
                .padding(16)
            }

            // Bottom Action Dock
            VStack(spacing: 8) {
                Button(action: { commitReceipt() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                        Text("Quittung archivieren (\(draft.lines.count) Artikel)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.sageGreen))
                }

                Button(action: {
                    draftReceipt = nil
                    selectedImage = nil
                }) {
                    Text("Neu einlesen")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface)
            .overlay(Divider().background(Theme.border), alignment: .top)
        }
    }

    private func lineItemRow(index: Int) -> some View {
        guard let draft = draftReceipt, index < draft.lines.count else { return AnyView(EmptyView()) }
        let line = draft.lines[index]

        return AnyView(
            Button(action: {
                editingLineItem = line
            }) {
                HStack(alignment: .top, spacing: 10) {
                    // Checkbox or Pfand Tag
                    let isPfand = line.rawText.contains("Pfand")
                    Button(action: {
                        if !isPfand {
                            draftReceipt?.lines[index].isConfirmed.toggle()
                        }
                    }) {
                        if isPfand {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textMuted)
                        } else {
                            Image(systemName: line.isConfirmed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(line.isConfirmed ? Theme.sageGreen : Theme.textMuted)
                        }
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        if isPfand {
                            Text(line.rawText.isEmpty ? "Dosen-/Flaschenpfand" : line.rawText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textMuted)
                            Text("Gehoert zu Dosengetraenken (kein Vorratsartikel)")
                                .font(.system(size: 10, weight: .regular, design: .default))
                                .foregroundColor(Theme.textMuted)
                        } else if line.isNonFood {
                            HStack(spacing: 6) {
                                Text(line.rawText)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("NON-FOOD")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.18))
                                    .foregroundColor(Color.orange)
                                    .clipShape(Capsule())
                            }
                            Text("Nicht relevant für deine Gesundheit")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Theme.textMuted)
                        } else if let matchedName = line.matchedPantryItemName, line.matchedPantryItemId != nil {
                            Text(matchedName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            if matchedName.lowercased() != line.rawText.lowercased() {
                                Text("Bon: \(line.rawText)")
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                            }
                        } else {
                            Text(line.rawText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                        }

                        if !isPfand && line.confidenceScore > 0 && line.matchedPantryItemId != nil {
                            Text(String(format: "Abgleich: %.0f%% Konfidenz", line.confidenceScore * 100))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(line.confidenceScore >= 0.7 ? Theme.sageGreen : Theme.warmSand)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f €", line.lineTotalPrice))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)

                        if line.quantity > 1 {
                            Text(String(format: "%d × %.2f €", line.quantity, line.parsedPrice))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                        }

                        if line.hasPriceDifference, let prev = line.previousPrice {
                            HStack(spacing: 2) {
                                Text(String(format: "%.2f €", prev))
                                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                    .strikethrough()
                                Text(String(format: "(%@%.2f)", line.priceDifference > 0 ? "+" : "", line.priceDifference))
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(line.priceDifference > 0 ? Theme.terracotta : Theme.sageGreen)
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button {
                    draftReceipt?.lines[index].isNonFood.toggle()
                    if draftReceipt?.lines[index].isNonFood == true {
                        draftReceipt?.lines[index].matchedPantryItemId = nil
                        draftReceipt?.lines[index].matchedPantryItemName = "Non-Food / Genussmittel (Kein Vorratsposten)"
                        draftReceipt?.lines[index].confidenceScore = 1.0
                        draftReceipt?.lines[index].isConfirmed = true
                    } else {
                        draftReceipt?.lines[index].matchedPantryItemName = nil
                        draftReceipt?.lines[index].confidenceScore = 0.0
                        draftReceipt?.lines[index].isConfirmed = false
                    }
                    HapticFeedbackService.shared.lightDetent()
                } label: {
                    Label(line.isNonFood ? "Als Lebensmittel/Vorrat einstufen" : "Als Non-Food / Genussmittel einstufen (Kein Vorrat)",
                          systemImage: line.isNonFood ? "cart.badge.plus" : "slash.circle")
                }
            }
        )
    }

    // MARK: - Reassignment Sheet (Fuzzy match manual override + Barcode/EAN Scanner)
    private func itemReassignmentSheet(for line: ReceiptLineItem) -> some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 12) {
                    // Secondary Action: Toggle Non-Food / Genussmittel (Excluded Consumable)
                    Button(action: {
                        if let idx = draftReceipt?.lines.firstIndex(where: { $0.id == line.id }) {
                            let currentNF = draftReceipt?.lines[idx].isNonFood ?? false
                            let newNF = !currentNF
                            draftReceipt?.lines[idx].isNonFood = newNF
                            if newNF {
                                draftReceipt?.lines[idx].matchedPantryItemId = nil
                                draftReceipt?.lines[idx].matchedPantryItemName = "Non-Food / Genussmittel (Kein Vorratsposten)"
                                draftReceipt?.lines[idx].confidenceScore = 1.0
                                draftReceipt?.lines[idx].isConfirmed = true
                                HapticFeedbackService.shared.lightDetent()
                                editingLineItem = nil
                            } else {
                                draftReceipt?.lines[idx].matchedPantryItemName = nil
                                draftReceipt?.lines[idx].confidenceScore = 0.0
                                draftReceipt?.lines[idx].isConfirmed = false
                                HapticFeedbackService.shared.lightDetent()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: line.isNonFood ? "cart.badge.plus" : "slash.circle")
                                .font(.system(size: 14, weight: .bold))
                            Text(line.isNonFood ? "Als Lebensmittel/Vorrat erfassen" : "Als Non-Food / Genussmittel einstufen (Kein Vorrat)")
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            if line.isNonFood {
                                Text("NON-FOOD")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(Color.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(line.isNonFood ? Theme.terracotta : Theme.warmSand)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if let msg = barcodeStatusMessage {
                        Text(msg)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.textMuted)
                        TextField("Artikel im Vorrat suchen...", text: $itemSearchQuery)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                    .padding(.horizontal, 16)

                    List {
                        Section("Bon-Text: \(line.rawText)") {
                            ForEach(filteredCatalog) { item in
                                Button(action: {
                                    assignPantryItem(item, to: line)
                                    editingLineItem = nil
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(Theme.textPrimary)
                                            Text("\(item.brand) • \(item.store)")
                                                .font(.system(size: 11))
                                                .foregroundColor(Theme.textMuted)
                                        }
                                        Spacer()
                                        Text(String(format: "%.2f €", item.defaultPrice))
                                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Theme.warmSand)
                                    }
                                }
                            }
                        }

                        // Bottom spacer so last items are never obscured by floating circular button
                        Spacer()
                            .frame(height: 60)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }

                // Floating Circular Barcode / EAN Scanner Button (Bottom Right)
                Button(action: {
                    showingReassignmentBarcodeScanner = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Theme.sageGreen)
                            .frame(width: 58, height: 58)
                            .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)

                        if isResolvingBarcode {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.bg))
                                .scaleEffect(1.0)
                        } else {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Theme.bg)
                        }
                    }
                }
                .disabled(isResolvingBarcode)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Barcode oder EAN scannen")
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Artikel zuordnen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { editingLineItem = nil }
                        .foregroundColor(Theme.warmSand)
                }
            }
            .sheet(isPresented: $showingReassignmentBarcodeScanner) {
                BarcodeScannerView { scannedCode in
                    showingReassignmentBarcodeScanner = false
                    handleReassignmentBarcode(scannedCode: scannedCode, for: line)
                }
            }
            .onAppear {
                itemSearchQuery = ""
                barcodeStatusMessage = nil
                isResolvingBarcode = false
            }
        }
    }

    private func assignPantryItem(_ item: PantryItem, to line: ReceiptLineItem) {
        guard let idx = draftReceipt?.lines.firstIndex(where: { $0.id == line.id }) else { return }

        draftReceipt?.lines[idx].matchedPantryItemId = item.id
        draftReceipt?.lines[idx].matchedPantryItemName = item.name
        draftReceipt?.lines[idx].previousPrice = item.defaultPrice
        draftReceipt?.lines[idx].confidenceScore = 1.0
        draftReceipt?.lines[idx].isConfirmed = true

        ReceiptMatchingEngine.shared.learnAlias(rawReceiptLine: line.rawText, targetItem: item)

        if let storeName = draftReceipt?.storeName {
            var updated = item
            updated.updatePrice(line.parsedPrice, for: storeName)
            store.addOrUpdatePantryItem(updated)
        }
    }

    private func handleReassignmentBarcode(scannedCode: String, for line: ReceiptLineItem) {
        let code = scannedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        HapticFeedbackService.shared.lightDetent()

        let lineIsNonFood = line.isNonFood || NonFoodClassifier.isNonFood(name: line.rawText)

        // 1. Check existing local pantry items
        if let local = store.pantryItems.first(where: { $0.barcode == code }) {
            if NonFoodClassifier.isNonFood(item: local) || lineIsNonFood {
                handleScannedAsNonFood(name: local.name, for: line)
                return
            }
            assignPantryItem(local, to: line)
            barcodeStatusMessage = "Gefunden im Vorrat: \(local.name)"
            HapticFeedbackService.shared.commitSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                editingLineItem = nil
            }
            return
        }

        // 2. Check MasterDataSeed
        if let master = MasterDataSeed.getMasterCatalog().first(where: { $0.barcode == code }) {
            if NonFoodClassifier.isNonFood(item: master) || lineIsNonFood {
                handleScannedAsNonFood(name: master.name, for: line)
                return
            }
            var itemToAdd = master
            if let storeName = draftReceipt?.storeName {
                itemToAdd.store = storeName
                itemToAdd.updatePrice(line.parsedPrice, for: storeName)
            }
            store.addOrUpdatePantryItem(itemToAdd)
            assignPantryItem(itemToAdd, to: line)
            barcodeStatusMessage = "Aus Stammdaten geladen: \(master.name)"
            HapticFeedbackService.shared.commitSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                editingLineItem = nil
            }
            return
        }

        // 2.5 Check if local pantry already has an item matching this receipt line's name
        let cleanLineName = line.rawText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !cleanLineName.isEmpty, let matchedIndex = store.pantryItems.firstIndex(where: {
            $0.name.lowercased() == cleanLineName ||
            $0.name.lowercased().contains(cleanLineName) ||
            cleanLineName.contains($0.name.lowercased())
        }) {
            var existing = store.pantryItems[matchedIndex]
            existing.barcode = code
            if let storeName = draftReceipt?.storeName {
                existing.store = storeName
                existing.updatePrice(line.parsedPrice, for: storeName)
            }
            store.addOrUpdatePantryItem(existing)
            assignPantryItem(existing, to: line)
            barcodeStatusMessage = "EAN aktualisiert & verknüpft: \(existing.name)"
            HapticFeedbackService.shared.commitSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                editingLineItem = nil
            }
            return
        }

        // 3. Query Open Food Facts online API
        isResolvingBarcode = true
        barcodeStatusMessage = "Lade EAN \(code) von OpenFoodFacts..."

        Task {
            if let fetched = await OpenFoodFactsService.shared.fetchProduct(barcode: code) {
                await MainActor.run {
                    isResolvingBarcode = false
                    if NonFoodClassifier.isNonFood(item: fetched) || lineIsNonFood {
                        handleScannedAsNonFood(name: fetched.name, for: line)
                        return
                    }

                    var newItem = fetched
                    if let storeName = draftReceipt?.storeName {
                        newItem.store = storeName
                        newItem.updatePrice(line.parsedPrice, for: storeName)
                    }
                    store.addOrUpdatePantryItem(newItem)
                    assignPantryItem(newItem, to: line)
                    barcodeStatusMessage = "Gefunden: \(newItem.name)"
                    HapticFeedbackService.shared.commitSuccess()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        editingLineItem = nil
                    }
                }
            } else {
                await MainActor.run {
                    isResolvingBarcode = false
                    if lineIsNonFood {
                        handleScannedAsNonFood(name: line.rawText, for: line)
                        return
                    }

                    // EAN not in OpenFoodFacts: automatically create, persist in database, and assign
                    let rawName = line.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let storeName = draftReceipt?.storeName ?? "PENNY"

                    var newItem = PantryItem(
                        id: "ean_\(code)",
                        name: rawName.isEmpty ? "Neuer Artikel (\(code))" : rawName,
                        brand: storeName,
                        barcode: code,
                        defaultPackQty: 500.0,
                        defaultPrice: line.parsedPrice > 0 ? line.parsedPrice : 1.99,
                        currentStockQty: 0.0,
                        unit: "g",
                        kcal100g: 100.0,
                        protein100g: 5.0,
                        carbs100g: 10.0,
                        fat100g: 2.0,
                        fiber100g: 2.0,
                        nutriscore: "b",
                        store: storeName
                    )
                    newItem.profile = CommodityReferenceCatalog.enrich(
                        profile: newItem.profile,
                        forProductName: newItem.name,
                        brand: newItem.brand
                    )
                    store.addOrUpdatePantryItem(newItem)
                    assignPantryItem(newItem, to: line)
                    barcodeStatusMessage = "EAN gespeichert & zugewiesen: \(newItem.name)"
                    HapticFeedbackService.shared.commitSuccess()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        editingLineItem = nil
                    }
                }
            }
        }
    }

    private func handleScannedAsNonFood(name: String, for line: ReceiptLineItem) {
        if let idx = draftReceipt?.lines.firstIndex(where: { $0.id == line.id }) {
            draftReceipt?.lines[idx].isNonFood = true
            draftReceipt?.lines[idx].matchedPantryItemId = nil
            let cleanTitle = name.isEmpty ? line.rawText : name
            draftReceipt?.lines[idx].matchedPantryItemName = "\(cleanTitle) (Non-Food / Kein Vorrat)"
            draftReceipt?.lines[idx].confidenceScore = 1.0
            draftReceipt?.lines[idx].isConfirmed = true
        }
        barcodeStatusMessage = "Nicht relevant für deine Gesundheit"
        HapticFeedbackService.shared.lightDetent()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            editingLineItem = nil
        }
    }

    private var filteredCatalog: [PantryItem] {
        if itemSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return store.pantryItems
        }
        let q = itemSearchQuery.lowercased()
        return store.pantryItems.filter {
            $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q)
        }
    }

    // MARK: - Actions
    private func processImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil

        ReceiptOCRService.shared.parseReceipt(image: image, pantryCatalog: store.pantryItems, knownStores: store.allKnownStores) { result in
            isProcessing = false
            switch result {
            case .success(let draft):
                self.store.registerStoreIfNeeded(draft.storeName)
                self.draftReceipt = draft
            case .failure(let err):
                self.errorMessage = "Fehler bei der Beleg-Erkennung: \(err.localizedDescription)"
            }
        }
    }

    private func commitReceipt() {
        guard let draft = draftReceipt else { return }

        let canonical = store.canonicalStoreName(for: draft.storeName)
        store.registerStoreIfNeeded(canonical)
        let record = ReceiptRecord(
            date: draft.date,
            storeName: canonical,
            totalAmount: draft.totalAmount,
            imageFilename: draft.savedImageFilename,
            items: draft.lines
        )

        store.archiveReceipt(record, updatePantryPrices: updatePantryPrices)

        // Automatically record expense into GrowFinance / Haushaltsbuch ledger
        let tx = BankTransaction(
            id: "receipt_\(record.id)",
            date: record.date,
            recipientOrPurpose: "\(record.storeName) Kassenbon",
            amount: -abs(record.totalAmount),
            category: .groceries,
            accountIBAN: "DE28300209003201649568",
            rawBookingText: "Grow Quittung \(record.storeName) - \(record.items.count) Artikel",
            isManual: true,
            partnerName: record.storeName.uppercased(),
            tags: ["Quittung", "Lebensmittel", record.storeName],
            necessity: .necessary,
            budgetCategory: .essen,
            isInternalTransfer: false
        )
        FinanceStore.shared.addTransaction(tx)

        onReceiptSaved?(record)
        dismiss()
    }
}

// MARK: - UIImagePickerController Representable
struct ReceiptImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ReceiptImagePicker

        init(_ parent: ReceiptImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                let fixed = image.fixOrientation()
                parent.onImagePicked(fixed)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
