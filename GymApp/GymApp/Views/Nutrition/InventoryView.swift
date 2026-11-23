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
                .background(Theme.bg)
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
    @State private var cloudSearchResults: [PantryItem] = []
    @State private var isSearchingCloud: Bool = false
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    public init() {}

    private var storeSources: [String] {
        ["ALLE"] + store.allKnownStores
    }

    private func itemCount(for source: String) -> Int {
        let inStock = store.pantryItems.filter { $0.currentStockQty > 0 }
        if source == "ALLE" { return inStock.count }
        return inStock.filter { $0.store.caseInsensitiveCompare(source) == .orderedSame }.count
    }

    private var filteredItems: [PantryItem] {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isFilteredStore = storeFilter != "ALLE"
        let upperStore = storeFilter

        return store.pantryItems.filter { item in
            // POKA-YOKE / SHI: Ausschließlich Artikel mit physischem Bestand > 0 anzeigen
            guard item.currentStockQty > 0 else { return false }

            if isFilteredStore && item.store.uppercased() != upperStore {
                return false
            }
            if cleanQuery.isEmpty {
                return true
            }
            return item.matches(query: cleanQuery)
        }
    }

    private var zeroStockLocalMatches: [PantryItem] {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.count >= 2 else { return [] }
        let isFilteredStore = storeFilter != "ALLE"
        let upperStore = storeFilter

        return store.pantryItems.filter { item in
            guard item.currentStockQty <= 0 else { return false }
            if isFilteredStore && item.store.uppercased() != upperStore {
                return false
            }
            return item.matches(query: cleanQuery)
        }
    }

    private var allCatalogMatches: [PantryItem] {
        var results = zeroStockLocalMatches
        for cloudItem in cloudSearchResults {
            if !results.contains(where: {
                (!$0.barcode.isEmpty && $0.barcode == cloudItem.barcode) ||
                $0.name.caseInsensitiveCompare(cloudItem.name) == .orderedSame
            }) {
                results.append(cloudItem)
            }
        }
        return results
    }

    public var body: some View {
        let items = filteredItems
        let catalogItems = allCatalogMatches
        return ScrollView {
            LazyVStack(spacing: 10) {
                    if items.isEmpty && catalogItems.isEmpty && !isSearchingCloud {
                        VStack(spacing: 4) {
                            Text(searchText.isEmpty ? "Keine Artikel im Vorrat" : "Keine Artikel im Vorrat gefunden")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .wellnessCard()
                    } else {
                        if !searchText.isEmpty && !items.isEmpty {
                            HStack {
                                Text("AKTUELL IM VORRAT (\(items.count))")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.sageGreen)
                                    .tracking(0.6)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }

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

                        // Föderierte Katalog-Suchergebnisse (Bestand = 0)
                        if !catalogItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "cart.badge.plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Theme.warmSand)
                                    Text("AUS DEM KATALOG (\(catalogItems.count))")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                        .tracking(0.6)
                                    Spacer()
                                    Text("0 im Bestand • 1-Klick auf Einkaufsliste")
                                        .font(.system(size: 9))
                                        .foregroundColor(Theme.textMuted)
                                }
                                .padding(.top, 14)
                                .padding(.bottom, 2)

                                ForEach(catalogItems) { catalogItem in
                                    InventoryItemRowView(
                                        item: catalogItem,
                                        isSelected: selectedPantryItem?.id == catalogItem.id,
                                        onTapInspect: {
                                            HapticFeedbackService.shared.lightDetent()
                                            inspectingItem = catalogItem
                                        },
                                        onLogConsumption: {
                                            HapticFeedbackService.shared.lightDetent()
                                            selectedPantryItem = catalogItem
                                            selectedItemForConsumption = catalogItem
                                        },
                                        onEditStock: {
                                            HapticFeedbackService.shared.lightDetent()
                                            editingStockItem = catalogItem
                                        },
                                        onRestockPack: {
                                            HapticFeedbackService.shared.lightDetent()
                                            var updated = catalogItem
                                            updated.currentStockQty = catalogItem.defaultPackQty
                                            store.addOrUpdatePantryItem(updated)
                                        },
                                        onAddShoppingItem: {
                                            HapticFeedbackService.shared.lightDetent()
                                            store.addManualShoppingItem(pantryItem: catalogItem)
                                        }
                                    )
                                }
                            }
                        }

                        if isSearchingCloud {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Suche in Cloud-Datenbank...")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }

                    Spacer().frame(height: 70)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Vorrat durchsuchen...")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Store Filter Menue
                    Menu {
                        ForEach(storeSources, id: \.self) { source in
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                storeFilter = source
                            }) {
                                HStack {
                                    Text(localizedStoreName(source))
                                    if source != "ALLE" {
                                        Text("(\(itemCount(for: source)))")
                                    }
                                    if storeFilter == source {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        let isFiltered = storeFilter != "ALLE"
                        Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isFiltered ? Theme.sageGreen : Theme.textSecondary)
                    }
                    .accessibilityLabel("Store Filter auswählen")

                    // PDF Export ShareLink
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
                    }
                    .accessibilityLabel("PDF exportieren")

                    // Mehr-Menue (Tools & Neuer Vorratsartikel)
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
                                defaultPrice: 0.0,
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

        .safeAreaInset(edge: .bottom) {
            Button(action: {
                HapticFeedbackService.shared.mechanicalClick()
                showingScanner = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 14, weight: .bold))
                    Text("Barcode scannen / erfassen")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                .shadow(color: Theme.sageGreen.opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 64)
            .background(
                LinearGradient(
                    colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
        .onAppear {
            if let idx = CommandLine.arguments.firstIndex(of: "-SearchVorrat"), idx + 1 < CommandLine.arguments.count {
                let query = CommandLine.arguments[idx + 1]
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.searchText = query
                }
            }
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
        .onChange(of: searchText) { newQuery in
            searchDebounceTask?.cancel()
            let clean = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            guard clean.count >= 2 else {
                cloudSearchResults = []
                isSearchingCloud = false
                return
            }

            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { isSearchingCloud = true }
                let results = await CloudProductCatalogService.shared.searchProducts(query: clean)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    let localBarcodes = Set(self.filteredItems.map { $0.barcode })
                    self.cloudSearchResults = results.filter { !localBarcodes.contains($0.barcode) }
                    self.isSearchingCloud = false
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
            if let fetched = await CloudProductCatalogService.shared.lookupProduct(barcode: barcode) {
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
                    defaultPrice: 0.0,
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

                HStack(spacing: 8) {
                    // 1. Verzehr erfassen (Point-of-Performance)
                    Button(action: onLogConsumption) {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 11, weight: .bold))
                            Text("Essen")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.sageGreen))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Verzehr erfassen")

                    // 2. Auf Einkaufsliste setzen
                    Button(action: onAddShoppingItem) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.warmSand)
                            .frame(width: 36, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Auf Einkaufsliste setzen")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTapInspect)
        .wellnessCard(borderColor: isSelected ? Theme.sageGreen : (item.isLowStock ? Theme.terracotta.opacity(0.4) : Theme.border))
    }
}

// MARK: - 2. DepotRecipesSection (Rezepte)
