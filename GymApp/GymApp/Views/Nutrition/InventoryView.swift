import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - InventoryView (Dedicated Vorratskammer Tab)
public struct InventoryView: View {
    @ObservedObject private var store = LocalStore.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            DepotInventorySection()
                .background(Theme.bg.ignoresSafeArea())
                .navigationTitle("Vorratskammer")
                .navigationBarTitleDisplayMode(store.isPadInstance ? .inline : .large)
        }
        .task {
            if store.pantryItems.isEmpty {
                _ = await store.performFullGrowcerySync()
            }
        }
    }
}

public struct DepotInventorySection: View {
    @ObservedObject var store = LocalStore.shared

    @State private var storeFilter: String = "ALLE"
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var inspectingItem: PantryItem? = nil
    @State private var editingStockItem: PantryItem? = nil
    @State private var selectedPantryItem: PantryItem? = nil
    @State private var selectedItemForConsumption: PantryItem? = nil
    @State private var showingScanner: Bool = false
    @State private var showingStoreScouter: Bool = false
    @State private var showingReceiptScanner: Bool = false
    @State private var scannedItemForInspection: PantryItem? = nil

    public init() {}

    private var storeSources: [String] {
        ["ALLE"] + store.allKnownStores
    }

    private func itemCount(for source: String) -> Int {
        if source == "ALLE" { return store.pantryItems.count }
        return store.pantryItems.filter { $0.store.caseInsensitiveCompare(source) == .orderedSame }.count
    }

    private var filteredItems: [PantryItem] {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isFilteredStore = storeFilter != "ALLE"
        let upperStore = storeFilter

        return store.pantryItems.filter { item in
            if isFilteredStore && item.store.uppercased() != upperStore {
                return false
            }
            if cleanQuery.isEmpty {
                return true
            }
            return item.matches(query: cleanQuery)
        }
    }

    public var body: some View {
        let items = filteredItems
        return ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if items.isEmpty {
                        VStack(spacing: 4) {
                            Text("Keine Artikel im Vorrat")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .wellnessCard()
                    } else {
                        ForEach(items) { item in
                            InventoryItemRowView(
                                item: item,
                                isSelected: selectedPantryItem?.id == item.id,
                                onTapInspect: {
                                    HapticFeedbackService.shared.lightDetent()
                                    inspectingItem = item
                                },
                                onLogConsumption: {
                                    HapticFeedbackService.shared.lightDetent()
                                    selectedPantryItem = item
                                    selectedItemForConsumption = item
                                },
                                onEditStock: {
                                    HapticFeedbackService.shared.lightDetent()
                                    editingStockItem = item
                                },
                                onRestockPack: {
                                    HapticFeedbackService.shared.lightDetent()
                                    store.restockItem(id: item.id, addQuantity: item.defaultPackQty)
                                },
                                onAddShoppingItem: {
                                    HapticFeedbackService.shared.lightDetent()
                                    store.addManualShoppingItem(pantryItem: item)
                                }
                            )
                        }
                    }

                    Spacer().frame(height: 75)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)

            InventoryBottomCommandDeck(
                searchText: $searchText,
                storeFilter: $storeFilter,
                storeSources: storeSources,
                itemCount: { itemCount(for: $0) },
                localizedStoreName: { localizedStoreName($0) },
                onScanBarcode: {
                    HapticFeedbackService.shared.mechanicalClick()
                    showingScanner = true
                },
                onOpenStoreScouter: {
                    HapticFeedbackService.shared.mechanicalClick()
                    showingStoreScouter = true
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Einkaufswagen Button (Store Scouter)
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        showingStoreScouter = true
                    }) {
                        Image(systemName: "cart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.warmSand)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.surfaceElevated))
                            .overlay(Circle().stroke(Theme.warmSand.opacity(0.35), lineWidth: 1))
                    }
                    .accessibilityLabel("Einkaufswagen")

                    // PDF Export Button direkt daneben
                    ShareLink(
                        item: PDFTransferable(
                            data: store.generateAIRecipeMasterPDFData(),
                            title: "Growcery_AI_Recipe_Master_Context"
                        ),
                        preview: SharePreview("Growcery Master PDF Export", image: Image(systemName: "doc.text.fill"))
                    ) {
                        Image(systemName: "arrow.up.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.sageGreen)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.surfaceElevated))
                            .overlay(Circle().stroke(Theme.sageGreen.opacity(0.35), lineWidth: 1))
                    }
                    .accessibilityLabel("PDF exportieren")

                    // Kontext-Menü
                    Menu {
                        ShareLink(
                            item: PDFTransferable(
                                data: store.generateAIRecipeMasterPDFData(),
                                title: "Growcery_AI_Recipe_Master_Context"
                            ),
                            preview: SharePreview("Growcery Master PDF", image: Image(systemName: "doc.text.fill"))
                        ) {
                            Label("PDF Master exportieren", systemImage: "doc.text.fill")
                        }
                        ShareLink(
                            item: store.getAIRecipeMasterExportURL(),
                            preview: SharePreview("Growcery Master Markdown", image: Image(systemName: "doc.plaintext"))
                        ) {
                            Label("Markdown-Kontext exportieren", systemImage: "arrow.up.doc")
                        }
                        Button(action: {
                            UIPasteboard.general.string = store.generateAIRecipeMasterExportContent()
                            HapticFeedbackService.shared.commitSuccess()
                        }) {
                            Label("KI-Prompt kopieren", systemImage: "doc.on.doc")
                        }
                        Button(action: { showingStoreScouter = true }) {
                            Label("Store Scouter", systemImage: "cart")
                        }
                        Button(action: { showingReceiptScanner = true }) {
                            Label("Kassenbon scannen", systemImage: "doc.text.viewfinder")
                        }
                        Button(action: {
                            let defaultStore = storeFilter == "ALLE" ? "PENNY" : storeFilter
                            let placeholder = PantryItem(
                                id: "custom_\(UUID().uuidString.prefix(8))",
                                name: "",
                                brand: "",
                                barcode: "",
                                defaultPackQty: 500.0,
                                defaultPrice: 1.99,
                                currentStockQty: 500.0,
                                unit: "g",
                                kcal100g: 0.0,
                                protein100g: 0.0,
                                carbs100g: 0.0,
                                fat100g: 0.0,
                                fiber100g: 0.0,
                                nutriscore: "a",
                                store: defaultStore
                            )
                            editingStockItem = placeholder
                        }) {
                            Label("Neuer Vorratsartikel", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 30, height: 36)
                    }
                }
            }
        }
        .sheet(item: $inspectingItem) { item in
            NutritionDetailSheet(item: item)
        }
        .sheet(item: $editingStockItem) { item in
            EditStockSheet(item: item, store: store)
        }
        .sheet(item: $selectedItemForConsumption) { item in
            LogConsumptionSheet(item: item, store: store)
        }
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView { code in
                showingScanner = false
                handleBarcodeScanned(code)
            }
        }
        .sheet(isPresented: $showingStoreScouter) {
            StoreScouterView()
        }
        .sheet(isPresented: $showingReceiptScanner) {
            ReceiptScannerView()
        }
        .sheet(item: $scannedItemForInspection) { item in
            ScannedProductInspectorSheet(item: item, store: store)
        }
        .onChange(of: store.targetedPantrySearchText) { text in
            if let text = text, !text.isEmpty {
                self.searchText = text
                store.targetedPantrySearchText = nil
            }
        }
        .onChange(of: store.targetedPantryItemForInspection) { item in
            if let item = item {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.inspectingItem = item
                    store.targetedPantryItemForInspection = nil
                }
            }
        }
    }

    private func handleBarcodeScanned(_ barcode: String) {
        if let match = store.pantryItems.first(where: { $0.barcode == barcode }) {
            if NonFoodClassifier.isNonFood(item: match) {
                HapticFeedbackService.shared.lightDetent()
                return
            }
            HapticFeedbackService.shared.mechanicalClick()
            inspectingItem = match
            return
        }

        Task {
            if let fetched = await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                if NonFoodClassifier.isNonFood(item: fetched) {
                    await MainActor.run {
                        HapticFeedbackService.shared.lightDetent()
                    }
                    return
                }
                var clean = fetched
                clean.currentStockQty = 0.0
                await MainActor.run {
                    self.scannedItemForInspection = clean
                }
            } else {
                let placeholder = PantryItem(
                    id: "ean_\(barcode)",
                    name: "Produkt (EAN \(barcode))",
                    brand: "Unbekannt",
                    barcode: barcode,
                    defaultPackQty: 500.0,
                    defaultPrice: 1.99,
                    currentStockQty: 0.0,
                    unit: "g",
                    kcal100g: 0.0,
                    protein100g: 0.0,
                    carbs100g: 0.0,
                    fat100g: 0.0,
                    fiber100g: 0.0,
                    nutriscore: "c",
                    store: "PENNY"
                )
                await MainActor.run {
                    self.scannedItemForInspection = placeholder
                }
            }
        }
    }
}

// MARK: - Inventory Bottom Command Deck (Singular Sleek Capsule)
struct InventoryBottomCommandDeck: View {
    @Binding var searchText: String
    @Binding var storeFilter: String
    let storeSources: [String]
    let itemCount: (String) -> Int
    let localizedStoreName: (String) -> String
    let onScanBarcode: () -> Void
    let onOpenStoreScouter: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            TextField("Suchen...", text: $searchText)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Singular Filter Button with Menu
            Menu {
                ForEach(storeSources, id: \.self) { source in
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        storeFilter = source
                    }) {
                        HStack {
                            Text(localizedStoreName(source))
                            if source != "ALLE" {
                                Text("(\(itemCount(source)))")
                            }
                            if storeFilter == source {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                let isFiltered = storeFilter != "ALLE"
                HStack(spacing: 4) {
                    Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                        .font(.system(size: 13, weight: .semibold))
                    if isFiltered {
                        Text(storeFilter.prefix(6))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                }
                .foregroundColor(isFiltered ? Theme.sageGreen : Theme.textSecondary)
                .padding(.horizontal, isFiltered ? 8 : 6)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isFiltered ? Theme.sageGreen.opacity(0.15) : Color.clear)
                )
            }
            .accessibilityLabel("Store Filter auswählen")

            // Dedicated Store Scouter Action
            Button(action: onOpenStoreScouter) {
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bg)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.warmSand))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Store Scouter öffnen")

            // Barcode Scanner Action
            Button(action: onScanBarcode) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bg)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.sageGreen))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Barcode scannen")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Theme.surface
                .opacity(0.95)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.border, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, y: 3)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Inventory Item Row View
struct InventoryItemRowView: View {
    let item: PantryItem
    let isSelected: Bool
    let onTapInspect: () -> Void
    let onLogConsumption: () -> Void
    let onEditStock: () -> Void
    let onRestockPack: () -> Void
    let onAddShoppingItem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    if !item.brand.isEmpty && item.brand.uppercased() != "PANTRY" && item.brand.uppercased() != "UNBEKANNT" {
                        Text(item.brand.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.warmSand)
                            .tracking(0.6)
                    }

                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    if !item.hasNutritionalData {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 9, weight: .bold))
                            Text("Nährwerte unvollständig")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(Theme.warmSand)
                        .padding(.top, 1)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: item.storageLocation.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text(item.storageLocation.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
                }
            }

            // Stock Capsule Bar (GPU-accelerated, zero-layout pass)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.surfaceElevated)
                    .frame(height: 6)
                Capsule()
                    .fill(item.isLowStock ? Theme.terracotta : Theme.sageGreen)
                    .frame(height: 6)
                    .scaleEffect(x: CGFloat(min(1.0, max(0.04, item.stockRatio))), y: 1.0, anchor: .leading)
            }
            .frame(height: 6)

            // Stock Details & Distinctive Action Symbols
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Text("\(item.formattedStockWithSubUnits) von \(Int(item.defaultPackQty)) \(item.unit)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text("(\(Int(item.stockRatio * 100)) %)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                HStack(spacing: 6) {
                    // Fork and knife symbol (Verzehr loggen)
                    Button(action: onLogConsumption) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                            .frame(width: 34, height: 30)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    // Bestand button (slider symbol)
                    Button(action: onEditStock) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.warmSand)
                            .frame(width: 34, height: 30)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    // + Packung button
                    Button(action: onRestockPack) {
                        HStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .heavy))
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Theme.sageGreen)
                        .frame(width: 36, height: 30)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    // + Liste button
                    Button(action: onAddShoppingItem) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 34, height: 30)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTapInspect)
        .wellnessCard(borderColor: isSelected ? Theme.sageGreen : (item.isLowStock ? Theme.terracotta.opacity(0.4) : Theme.border))
    }
}

// MARK: - 2. DepotRecipesSection (Rezepte)
