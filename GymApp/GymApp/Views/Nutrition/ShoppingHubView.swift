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
                // 1. Circular Quick Action Bar for Finance Modules
                circularFinanceActionBar

                // 2. Segment Switcher Header (3 Tabs)
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
                    TransactionsListView(embedInNavigationStack: false)
                        .tag(ShoppingHubSegment.transactions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(selectedSegment.rawValue)
            .navigationBarTitleDisplayMode(store.isPadInstance ? .inline : .large)
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

    // MARK: - Circular Finance Action Bar
    private var circularFinanceActionBar: some View {
        HStack(spacing: 12) {
            circularButton(
                title: "Konten",
                icon: "creditcard.fill",
                color: Theme.sageGreen
            ) {
                showingAccountsSheet = true
            }

            circularButton(
                title: "Budgets",
                icon: "chart.pie.fill",
                color: Theme.warmSand
            ) {
                showingBudgetsSheet = true
            }

            circularButton(
                title: "5-Gate",
                icon: "shield.checkerboard",
                color: Theme.accent
            ) {
                showingFiveGateSheet = true
            }

            circularButton(
                title: "Berichte",
                icon: "chart.bar.xaxis",
                color: Theme.textSecondary
            ) {
                showingReportsSheet = true
            }

            circularButton(
                title: "Targo-Scan",
                icon: "camera.viewfinder",
                color: Theme.terracotta
            ) {
                showingTargobankScanSheet = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Theme.bg)
    }

    private func circularButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedbackService.shared.lightDetent()
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Theme.border.opacity(0.8), lineWidth: 1))

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
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

    public var body: some View {
        let isOverBudget = store.shoppingTotalCost > store.remainingCurrentMonthBudget

        return ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 14) {
                    // 1. GROWFINANCE MONATSBUDGET
                    financeBudgetCard

                    // 2. EINKAUFSLISTE ZUSAMMENFASSUNG
                    shoppingSummaryCard(isOverBudget: isOverBudget)

                    // 3. EINKAUFSLISTE
                    shoppingListSection

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
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

                    Button(action: {
                        HapticFeedbackService.shared.mechanicalClick()
                        showingShoppingBarcodeScanner = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.sageGreen))
                    }
                    .accessibilityLabel("Barcode scannen")
                }
            }

            // Checkout Bar when items are checked
            if !checkedItems.isEmpty {
                Button(action: {
                    HapticFeedbackService.shared.commitSuccess()
                    store.checkInPurchasedItems()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Einkauf abschließen & Verbuchen (\(checkedItems.count) Artikel • \(String(format: "%.2f €", checkedTotalCost)))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                    .shadow(color: Theme.sageGreen.opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .buttonStyle(PlainButtonStyle())
            }
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

    // MARK: - Finance Budget Card
    private var financeBudgetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("GROWFINANCE MONATSRAHMEN")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                Spacer()
                Text("\(String(format: "%.2f €", store.foodPurchasedThisMonth)) / \(String(format: "%.2f €", store.monthlyFinanceFoodBudget))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }

            let pct = min(1.0, store.foodPurchasedThisMonth / max(1.0, store.monthlyFinanceFoodBudget))
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceElevated)
                    .frame(height: 6)
                Capsule()
                    .fill(pct > 0.9 ? Theme.terracotta : Theme.sageGreen)
                    .frame(height: 6)
                    .scaleEffect(x: CGFloat(max(0.01, pct)), y: 1.0, anchor: .leading)
            }
            .frame(height: 6)

            HStack {
                Text("Restbudget lfd. Monat:")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.textMuted)
                Text(String(format: "%.2f €", store.remainingCurrentMonthBudget))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(store.remainingCurrentMonthBudget < 25.0 ? Theme.terracotta : Theme.sageGreen)
                Spacer()
            }
        }
        .wellnessCard(borderColor: Theme.border)
    }

    // MARK: - Shopping Summary Card
    private func shoppingSummaryCard(isOverBudget: Bool) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SUMME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                    Text(String(format: "%.2f €", store.shoppingTotalCost))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(isOverBudget ? Theme.terracotta : Theme.warmSand)
                }
                Spacer()
                VStack(alignment: .center, spacing: 3) {
                    Text("POSITIONEN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                    Text("\(store.shoppingList.count)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("GESAMT-PROTEIN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                    Text("\(Int(store.shoppingTotalProtein)) g")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)
                }
            }

            if isOverBudget {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.terracotta)
                    Text("Übersteigt Monatsbudget um \(String(format: "%.2f €", store.shoppingTotalCost - store.remainingCurrentMonthBudget)).")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.terracotta)
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .wellnessCard(borderColor: isOverBudget ? Theme.terracotta.opacity(0.6) : Theme.warmSand.opacity(0.4))
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
