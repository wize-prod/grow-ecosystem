import SwiftUI
import GrowCore

// MARK: - ShoppingHubView (Dedicated Einkauf, Quittungen & Haushaltsbuch Hub)
public struct ShoppingHubView: View {
    @ObservedObject private var store = LocalStore.shared
    @State private var selectedSegment: ShoppingHubSegment = .shopping

    // Quick Action Sheets from GrowFinance
    @State private var showingAccountsSheet: Bool = false
    @State private var showingBudgetsSheet: Bool = false
    @State private var showingFiveGateSheet: Bool = false
    @State private var showingReportsSheet: Bool = false
    @State private var showingTargobankScanSheet: Bool = false

    public enum ShoppingHubSegment: String, CaseIterable {
        case shopping = "Einkaufsliste"
        case receipts = "Quittungen"
        case transactions = "Buchungen"
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Switcher Header (3 Tabs)
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        ForEach(ShoppingHubSegment.allCases, id: \.self) { seg in
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSegment = seg
                                }
                            }) {
                                Text(seg.rawValue)
                                    .font(.system(size: 13, weight: selectedSegment == seg ? .bold : .medium))
                                    .foregroundColor(selectedSegment == seg ? Theme.textPrimary : Theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedSegment == seg ? Theme.surfaceElevated : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 6)
                .background(Theme.bg)

                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
                    .opacity(0.5)

                TabView(selection: $selectedSegment) {
                    DepotShoppingSection()
                        .tag(ShoppingHubSegment.shopping)
                    DepotReceiptsSection()
                        .tag(ShoppingHubSegment.receipts)
                    DepotTransactionsSection(
                        showingAccountsSheet: $showingAccountsSheet,
                        showingBudgetsSheet: $showingBudgetsSheet,
                        showingFiveGateSheet: $showingFiveGateSheet,
                        showingReportsSheet: $showingReportsSheet,
                        showingTargobankScanSheet: $showingTargobankScanSheet
                    )
                    .tag(ShoppingHubSegment.transactions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(selectedSegment.rawValue)
            .navigationBarTitleDisplayMode(store.isPadInstance ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Finanz-Werkzeuge") {
                            Button { showingAccountsSheet = true } label: { Label("Konten & Schulden", systemImage: "creditcard") }
                            Button { showingBudgetsSheet = true } label: { Label("Monatsbudgets", systemImage: "chart.pie") }
                            Button { showingFiveGateSheet = true } label: { Label("5-Gate Kaufprüfer", systemImage: "shield.checkerboard") }
                            Button { showingReportsSheet = true } label: { Label("Finanzberichte", systemImage: "chart.bar.xaxis") }
                            Button { showingTargobankScanSheet = true } label: { Label("Targobank Scanner", systemImage: "camera.viewfinder") }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingAccountsSheet) {
                AccountsAndProfileView()
            }
            .sheet(isPresented: $showingBudgetsSheet) {
                BudgetsDashboardView()
            }
            .sheet(isPresented: $showingFiveGateSheet) {
                FiveGateSimulatorView()
            }
            .sheet(isPresented: $showingReportsSheet) {
                FinanceReportsView()
            }
            .sheet(isPresented: $showingTargobankScanSheet) {
                TargobankScanSheet(store: FinanceStore.shared)
            }
        }
        .onChange(of: store.targetedDepotSegment) { segment in
            guard let seg = segment?.lowercased() else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                if seg.contains("quitt") || seg.contains("receipt") {
                    selectedSegment = .receipts
                } else if seg.contains("einkauf") || seg.contains("shopping") {
                    selectedSegment = .shopping
                } else if seg.contains("buch") || seg.contains("finance") || seg.contains("trans") {
                    selectedSegment = .transactions
                }
            }
            store.targetedDepotSegment = nil
        }
    }
}



public struct DepotShoppingSection: View {
    @ObservedObject var store = LocalStore.shared

    @State private var shoppingSearchText: String = ""
    @FocusState private var isShoppingSearchFocused: Bool
    @State private var showingShoppingBarcodeScanner: Bool = false
    @State private var scannedItemForInspection: PantryItem? = nil
    @State private var inspectingItem: PantryItem? = nil

    public init() {}

    private var filteredShoppingList: [ShoppingItem] {
        var list = store.shoppingList
        if !shoppingSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = shoppingSearchText.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                $0.store.lowercased().contains(q)
            }
        }
        return list
    }

    private var groupedShoppingSections: [(store: String, aisleGroups: [(aisle: InStoreLocation, items: [ShoppingItem])])] {
        let items = filteredShoppingList
        let storeGroups = Dictionary(grouping: items) { $0.store }

        return storeGroups.keys.sorted().map { storeName in
            let storeItems = storeGroups[storeName] ?? []
            let aisleGroups = Dictionary(grouping: storeItems) { $0.inStoreLocation }
            let sortedAisles = InStoreLocation.allCases.compactMap { aisle -> (aisle: InStoreLocation, items: [ShoppingItem])? in
                if let items = aisleGroups[aisle], !items.isEmpty {
                    return (aisle: aisle, items: items)
                }
                return nil
            }
            return (store: storeName, aisleGroups: sortedAisles)
        }
    }

    private var checkedItems: [ShoppingItem] {
        store.shoppingList.filter { $0.isChecked }
    }

    private var checkedTotalCost: Double {
        checkedItems.reduce(0.0) { $0 + $1.totalCost }
    }

    private var currentFoodBudgetRemaining: Double {
        let statuses = FinanceStore.shared.smartEngine.calculateBudgetStatuses(
            budgets: FinanceStore.shared.budgets,
            transactions: FinanceStore.shared.transactions,
            plusKontoBalance: FinanceStore.shared.plusKontoBalance,
            pendingFixedCosts: FinanceStore.shared.totalRemainingFixedCosts,
            accounts: FinanceStore.shared.accounts
        )
        if let foodStatus = statuses.first(where: { $0.budget.category == .essen }) {
            return foodStatus.remainingAmount
        }
        return store.remainingCurrentMonthBudget
    }

    public var body: some View {
        let isOverBudget = store.shoppingTotalCost > currentFoodBudgetRemaining

        return ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 1. Schlanke Einzeil-Statuspille (Muda-Eliminierung)
                    unifiedShoppingStatusPill(isOverBudget: isOverBudget)

                    // 2. Einkaufsliste gruppiert nach Laden & Gang
                    shoppingListSection

                    Spacer().frame(height: 70)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .searchable(text: $shoppingSearchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Einkaufsartikel suchen...")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            store.shoppingList.removeAll(where: { $0.isChecked })
                            store.saveShopping()
                        }) {
                            Label("Erledigte entfernen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

            // 3. Ergonomisches Daumen-Dock (Muri-Eliminierung)
            bottomThumbDock
        }
        .sheet(isPresented: $showingShoppingBarcodeScanner) {
            BarcodeScannerView { code in
                showingShoppingBarcodeScanner = false
                handleBarcodeScanned(code)
            }
        }
        .sheet(item: $scannedItemForInspection) { item in
            ScannedProductInspectorSheet(item: item, store: store)
        }
        .sheet(item: $inspectingItem) { item in
            NutritionDetailSheet(item: item)
        }
    }

    // MARK: - Schlanke Status-Pille (Muda-Eliminierung)
    private func unifiedShoppingStatusPill(isOverBudget: Bool) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("Rest:")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Theme.textMuted)
                Text(String(format: "%.2f €", currentFoodBudgetRemaining))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(currentFoodBudgetRemaining < 25.0 ? Theme.terracotta : Theme.sageGreen)
            }

            Text("•")
                .foregroundColor(Theme.textMuted.opacity(0.6))

            HStack(spacing: 4) {
                Text("\(store.shoppingList.count) Art.")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                Text("(\(String(format: "%.2f €", store.shoppingTotalCost)))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(isOverBudget ? Theme.terracotta : Theme.warmSand)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.sageGreen)
                Text("\(Int(store.shoppingTotalProtein)) g Protein")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.sageGreen)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.surfaceElevated.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOverBudget ? Theme.terracotta.opacity(0.6) : Theme.border.opacity(0.6), lineWidth: 1)
                )
        )
    }

    // MARK: - Daumen-Dock (Muri-Eliminierung & Poka-Yoke)
    private var bottomThumbDock: some View {
        HStack(spacing: 10) {
            Button(action: {
                HapticFeedbackService.shared.mechanicalClick()
                showingShoppingBarcodeScanner = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 15, weight: .bold))
                    if checkedItems.isEmpty {
                        Text("Barcode scannen")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(checkedItems.isEmpty ? Theme.bg : Theme.textPrimary)
                .padding(.horizontal, checkedItems.isEmpty ? 16 : 14)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(checkedItems.isEmpty ? Theme.sageGreen : Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.border, lineWidth: checkedItems.isEmpty ? 0 : 1)
                )
            }
            .accessibilityLabel("Barcode scannen")

            if !checkedItems.isEmpty {
                Button(action: {
                    HapticFeedbackService.shared.commitSuccess()
                    store.checkInPurchasedItems()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("In Vorrat buchen (\(checkedItems.count) Art. • \(String(format: "%.2f €", checkedTotalCost)))")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                            Text("Physischer Bestand")
                                .font(.system(size: 8, weight: .medium))
                                .opacity(0.8)
                        }
                    }
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                    .shadow(color: Theme.sageGreen.opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Shopping List Section
    private var shoppingListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EINKAUFSLISTE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                    .tracking(0.6)
                Spacer()
                Text("\(filteredShoppingList.count) Positionen")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }

            if filteredShoppingList.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "cart")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textMuted)
                        .padding(.bottom, 2)
                    Text("Einkaufsliste ist leer")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Füge Artikel aus Rezepten oder dem Vorrats-Depot hinzu.")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.5), lineWidth: 1))
            } else {
                ForEach(groupedShoppingSections, id: \.store) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Store Header
                        HStack(spacing: 6) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                            Text(localizedStoreName(group.store).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)
                            Spacer()
                            let storeCost = group.aisleGroups.reduce(0.0) { acc, aisle in
                                acc + aisle.items.reduce(0.0) { $0 + $1.totalCost }
                            }
                            Text(String(format: "%.2f €", storeCost))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)

                        // In-Store Aisle Groups
                        ForEach(group.aisleGroups, id: \.aisle.rawValue) { aisleGroup in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text(aisleGroup.aisle.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.sageGreen)
                                        .tracking(0.4)
                                    Spacer()
                                    Text("\(aisleGroup.items.count)")
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 2)

                                ForEach(aisleGroup.items) { item in
                                    ShoppingItemRowView(
                                        item: item,
                                        onToggleCheck: {
                                            HapticFeedbackService.shared.lightDetent()
                                            store.toggleShoppingItem(id: item.id)
                                        },
                                        onPurchaseSingle: {
                                            HapticFeedbackService.shared.commitSuccess()
                                            store.purchaseSingleShoppingItem(item)
                                        },
                                        onRemove: {
                                            HapticFeedbackService.shared.lightDetent()
                                            store.removeShoppingItem(id: item.id)
                                        }
                                    )
                                }
                            }
                            .padding(.leading, 6)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated.opacity(0.4)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.5), lineWidth: 1))
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
            scannedItemForInspection = match
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

// MARK: - Shopping Item Row View
struct ShoppingItemRowView: View {
    let item: ShoppingItem
    let onToggleCheck: () -> Void
    var onPurchaseSingle: (() -> Void)? = nil
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleCheck) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(item.isChecked ? Theme.sageGreen : Theme.surfaceElevated)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.bg)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(item.isChecked ? Theme.textMuted : Theme.textPrimary)
                    .strikethrough(item.isChecked)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.warmSand)
                        Text("•")
                            .foregroundColor(Theme.textMuted)
                    }
                    Text(item.unitsToBuyFormatted)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(String(format: "%.2f €", item.totalCost))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(item.isChecked ? Theme.textMuted : Theme.warmSand)

                if let onPurchase = onPurchaseSingle, !item.isChecked {
                    Button(action: onPurchase) {
                        HStack(spacing: 3) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 9))
                            Text("Buchen")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.sageGreen))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.terracotta.opacity(0.8))
                        .padding(4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .wellnessCard(borderColor: item.isChecked ? Theme.sageGreen.opacity(0.4) : Theme.border)
    }
}

// MARK: - 4. DepotReceiptsSection (Quittungen)
public struct DepotReceiptsSection: View {
    @ObservedObject var store = LocalStore.shared

    @State private var receiptSearchText: String = ""
    @FocusState private var isReceiptSearchFocused: Bool
    @State private var receiptStoreFilter: String = "ALLE"
    @State private var receiptSortOption: ReceiptSortOption = .newestFirst
    @State private var inspectingReceipt: ReceiptRecord? = nil
    @State private var showingReceiptScanner: Bool = false

    public init() {}

    private var storeSources: [String] {
        ["ALLE"] + store.allKnownStores
    }

    private var filteredReceipts: [ReceiptRecord] {
        var list = store.receipts
        if receiptStoreFilter != "ALLE" {
            list = list.filter { $0.storeName.uppercased() == receiptStoreFilter }
        }
        if !receiptSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = receiptSearchText.lowercased()
            list = list.filter { receipt in
                receipt.storeName.lowercased().contains(q) ||
                receipt.items.contains(where: {
                    $0.rawText.lowercased().contains(q) ||
                    ($0.matchedPantryItemName?.lowercased().contains(q) ?? false)
                })
            }
        }
        switch receiptSortOption {
        case .newestFirst:
            list.sort { $0.date > $1.date }
        case .oldestFirst:
            list.sort { $0.date < $1.date }
        case .priceDesc:
            list.sort { $0.totalAmount > $1.totalAmount }
        case .priceAsc:
            list.sort { $0.totalAmount < $1.totalAmount }
        }
        return list
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if filteredReceipts.isEmpty {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.surfaceElevated)
                                    .frame(width: 54, height: 54)
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 22))
                                    .foregroundColor(Theme.sageGreen)
                            }
                            Text(store.receipts.isEmpty ? "Keine archivierten Quittungen" : "Keine passenden Quittungen gefunden")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Suchen Sie nach Supermärkten (Penny, Rewe, etc.) oder einzelnen Produkten auf den Belegen.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Theme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .wellnessCard()
                    } else {
                        ForEach(filteredReceipts) { receipt in
                            ReceiptRowView(receipt: receipt) {
                                HapticFeedbackService.shared.lightDetent()
                                inspectingReceipt = receipt
                            }
                        }
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .searchable(text: $receiptSearchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Quittungen durchsuchen...")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        ForEach(storeSources, id: \.self) { source in
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                receiptStoreFilter = source
                            }) {
                                HStack {
                                    Text(localizedStoreName(source))
                                    if receiptStoreFilter == source {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(receiptStoreFilter == "ALLE" ? Theme.textSecondary : Theme.sageGreen)
                    }

                    Button(action: {
                        HapticFeedbackService.shared.mechanicalClick()
                        showingReceiptScanner = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.sageGreen))
                    }
                    .accessibilityLabel("Kassenbon scannen")
                }
            }
        }
        .sheet(item: $inspectingReceipt) { rec in
            ReceiptDetailSheet(receipt: rec)
        }
        .sheet(isPresented: $showingReceiptScanner) {
            ReceiptScannerView()
        }
    }
}

// MARK: - Receipt Row View
struct ReceiptRowView: View {
    let receipt: ReceiptRecord
    let onInspect: () -> Void

    var body: some View {
        Button(action: onInspect) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surfaceElevated)
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.warmSand)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(receipt.storeName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(formattedDate(receipt.date)) • \(receipt.items.count) Artikel")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f €", receipt.totalAmount))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)

                    if receipt.priceChangeCount > 0 {
                        Text("\(receipt.priceChangeCount) Preis-Updates")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    }
                }
            }
            .padding(12)
            .wellnessCard()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private static let receiptDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        Self.receiptDateFormatter.string(from: date)
    }
}

// MARK: - DepotTransactionsSection (Buchungen & Haushaltsbuch)
public struct DepotTransactionsSection: View {
    @Binding var showingAccountsSheet: Bool
    @Binding var showingBudgetsSheet: Bool
    @Binding var showingFiveGateSheet: Bool
    @Binding var showingReportsSheet: Bool
    @Binding var showingTargobankScanSheet: Bool

    public init(
        showingAccountsSheet: Binding<Bool>,
        showingBudgetsSheet: Binding<Bool>,
        showingFiveGateSheet: Binding<Bool>,
        showingReportsSheet: Binding<Bool>,
        showingTargobankScanSheet: Binding<Bool>
    ) {
        self._showingAccountsSheet = showingAccountsSheet
        self._showingBudgetsSheet = showingBudgetsSheet
        self._showingFiveGateSheet = showingFiveGateSheet
        self._showingReportsSheet = showingReportsSheet
        self._showingTargobankScanSheet = showingTargobankScanSheet
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Contextual Finance Action Strip (Shi/Xu alignment)
            HStack(spacing: 12) {
                FinanceQuickActionButton(title: "Konten", icon: "creditcard", color: Theme.warmSand) {
                    showingAccountsSheet = true
                }
                FinanceQuickActionButton(title: "Budgets", icon: "chart.pie", color: Theme.sageGreen) {
                    showingBudgetsSheet = true
                }
                FinanceQuickActionButton(title: "5-Gate", icon: "shield.checkerboard", color: Theme.terracotta) {
                    showingFiveGateSheet = true
                }
                FinanceQuickActionButton(title: "Berichte", icon: "chart.bar.xaxis", color: Theme.warmSand) {
                    showingReportsSheet = true
                }
                FinanceQuickActionButton(title: "Targo-Scan", icon: "camera.viewfinder", color: Theme.sageGreen) {
                    showingTargobankScanSheet = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.surfaceElevated.opacity(0.6))

            Divider().opacity(0.3)

            // Dedicated Transactions List
            TransactionsListView(embedInNavigationStack: false)
        }
    }
}

struct FinanceQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.lightDetent()
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
