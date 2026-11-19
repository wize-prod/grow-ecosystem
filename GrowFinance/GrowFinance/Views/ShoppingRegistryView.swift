import SwiftUI

// MARK: - Domain Models

public enum ShoppingSource: String, CaseIterable, Codable, Identifiable {
    case growcery   = "Growcery"
    case care       = "Pflege"
    case gym        = "Gym / Ausruestung"
    case wishlist   = "Wunschliste"
    case manual     = "Manuell"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .growcery: return "cart.fill"
        case .care:     return "drop.fill"
        case .gym:      return "dumbbell.fill"
        case .wishlist: return "star.fill"
        case .manual:   return "plus.circle.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .growcery: return FinanceTheme.sageGreen
        case .care:     return Color(hex: "A78BFA")
        case .gym:      return FinanceTheme.strongBlue
        case .wishlist: return FinanceTheme.warmSand
        case .manual:   return FinanceTheme.textMuted
        }
    }
}

public struct RegistryItem: Identifiable, Codable, Equatable {
    public var id: String = UUID().uuidString
    public var name: String
    public var source: ShoppingSource
    public var estimatedPriceEUR: Double
    public var amazonURL: String?
    public var note: String
    public var isPurchased: Bool = false
    public var isSaved: Bool = false
    public var addedDate: Date = Date()
    public var recurrence: CustomRecurrenceRule? = nil

    public init(
        id: String = UUID().uuidString,
        name: String,
        source: ShoppingSource,
        estimatedPriceEUR: Double,
        amazonURL: String? = nil,
        note: String = "",
        isPurchased: Bool = false,
        isSaved: Bool = false,
        addedDate: Date = Date(),
        recurrence: CustomRecurrenceRule? = nil
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.estimatedPriceEUR = estimatedPriceEUR
        self.amazonURL = amazonURL
        self.note = note
        self.isPurchased = isPurchased
        self.isSaved = isSaved
        self.addedDate = addedDate
        self.recurrence = recurrence
    }
}

// MARK: - Store with Cross-App Ecosystem Sync

public final class ShoppingRegistryStore: ObservableObject {
    @Published public var items: [RegistryItem] = []
    @Published public var monthlyBudgetEUR: Double = 200.0

    private let storageKey = "growfinance_registry_items_v2"
    private let budgetKey = "growfinance_monthly_budget"

    public init() {
        loadItems()
        loadMonthlyBudget()
        listenForExternalUpdates()
    }

    public var pendingTotal: Double {
        items.filter { !$0.isPurchased }.reduce(0) { $0 + $1.estimatedPriceEUR }
    }

    public var budgetRemaining: Double {
        monthlyBudgetEUR - purchasedThisMonthTotal
    }

    public var purchasedThisMonthTotal: Double {
        let cal = Calendar.current
        return items
            .filter { $0.isPurchased && cal.isDate($0.addedDate, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.estimatedPriceEUR }
    }

    public func toggle(item: RegistryItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        if !items[idx].isPurchased {
            // Marking as purchased
            items[idx].isPurchased = true
            if var rec = items[idx].recurrence {
                rec.completedOccurrences += 1
                items[idx].recurrence = rec
                // If recurring and not expired, schedule next pending item
                if !rec.isExpired {
                    let nextItem = RegistryItem(
                        name: items[idx].name,
                        source: items[idx].source,
                        estimatedPriceEUR: items[idx].estimatedPriceEUR,
                        amazonURL: items[idx].amazonURL,
                        note: items[idx].note,
                        isPurchased: false,
                        isSaved: items[idx].isSaved,
                        addedDate: Date(),
                        recurrence: rec
                    )
                    items.insert(nextItem, at: 0)
                }
            }
        } else {
            items[idx].isPurchased = false
        }
        saveItems()
        broadcastSync()
    }

    public func toggleSave(item: RegistryItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isSaved.toggle()
        saveItems()
        broadcastSync()
    }

    public func delete(_ item: RegistryItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
        broadcastSync(deletedId: item.id)
    }

    public func add(_ item: RegistryItem) {
        items.insert(item, at: 0)
        saveItems()
        broadcastSync()
    }

    public func update(_ item: RegistryItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            saveItems()
            broadcastSync()
        }
    }

    public func setMonthlyBudget(_ budget: Double) {
        monthlyBudgetEUR = max(0, budget)
        UserDefaults.standard.set(monthlyBudgetEUR, forKey: budgetKey)
    }

    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([RegistryItem].self, from: data),
           !saved.isEmpty {
            self.items = saved
        } else {
            self.items = ShoppingRegistryStore.seedItems()
            saveItems()
        }
    }

    private func loadMonthlyBudget() {
        let val = UserDefaults.standard.double(forKey: budgetKey)
        if val > 0 {
            monthlyBudgetEUR = val
        }
    }

    // Cross-App Bridge Sync
    private func broadcastSync(deletedId: String? = nil) {
        let existingBridge = GrowSuiteBridge.shared.loadShopping()
        var updatedDeleted = existingBridge.deletedIds
        if let dId = deletedId, !updatedDeleted.contains(dId) {
            updatedDeleted.append(dId)
            if updatedDeleted.count > 100 {
                updatedDeleted.removeFirst(updatedDeleted.count - 100)
            }
        }

        let payload = items.map { item in
            SharedShoppingItem(
                id: item.id,
                name: item.name,
                price: item.estimatedPriceEUR,
                store: "AMAZON",
                quantity: 1,
                category: item.source.rawValue,
                webUrl: item.amazonURL,
                isBought: item.isPurchased,
                isSaved: item.isSaved,
                recurrenceRule: item.recurrence,
                lastUpdated: Date()
            )
        }
        GrowSuiteBridge.shared.saveShopping(SharedShoppingPayload(items: payload, deletedIds: updatedDeleted))
        DarwinNotificationCenter.post(DarwinNotificationCenter.shoppingUpdated)
    }

    private func listenForExternalUpdates() {
        DarwinNotificationCenter.observe(DarwinNotificationCenter.shoppingUpdated) { [weak self] in
            guard let self = self else { return }
            let shared = GrowSuiteBridge.shared.loadShopping()
            let sharedIds = Set(shared.items.map { $0.id })
            let deletedIds = Set(shared.deletedIds)

            // 1. Remove items explicitly deleted in bridge
            if !deletedIds.isEmpty {
                self.items.removeAll { deletedIds.contains($0.id) }
            }

            // 2. Handle deletions of items originating from Growcery/Care
            if !shared.items.isEmpty {
                self.items.removeAll { localItem in
                    !sharedIds.contains(localItem.id) && (localItem.source == .growcery || localItem.source == .care)
                }
            }

            for sItem in shared.items {
                if let idx = self.items.firstIndex(where: { $0.id == sItem.id }) {
                    self.items[idx].isPurchased = sItem.isBought
                    self.items[idx].isSaved = sItem.isSaved
                    self.items[idx].estimatedPriceEUR = sItem.price
                    self.items[idx].name = sItem.name
                    self.items[idx].recurrence = sItem.recurrenceRule
                } else if !deletedIds.contains(sItem.id) {
                    let source: ShoppingSource = sItem.category == "Pflege & Hygiene" ? .care : .growcery
                    let newItem = RegistryItem(
                        id: sItem.id,
                        name: sItem.name,
                        source: source,
                        estimatedPriceEUR: sItem.price,
                        amazonURL: sItem.webUrl,
                        note: "Aus Growcery synchronisiert",
                        isPurchased: sItem.isBought,
                        isSaved: sItem.isSaved,
                        recurrence: sItem.recurrenceRule
                    )
                    self.items.insert(newItem, at: 0)
                }
            }
            self.saveItems()
        }
    }

    private static func seedItems() -> [RegistryItem] {
        [
            RegistryItem(
                name: "Paula's Choice 2% BHA Liquid Exfoliant",
                source: .care,
                estimatedPriceEUR: 34.90,
                amazonURL: "https://www.amazon.de/dp/B00IJXK98Q",
                note: "Pflicht-Restock fuer Pseudofolliculitis Barbae Protokoll",
                recurrence: CustomRecurrenceRule(interval: 1, unit: .month, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "CeraVe Feuchtigkeitscreme (236 ml)",
                source: .care,
                estimatedPriceEUR: 12.99,
                amazonURL: "https://www.amazon.de/dp/B003YC5JK0",
                note: "Taeglich nach Rasur anwenden",
                recurrence: CustomRecurrenceRule(interval: 1, unit: .month, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "La Roche-Posay Anthelios UVMune 400 SPF 50+",
                source: .care,
                estimatedPriceEUR: 22.50,
                amazonURL: "https://www.amazon.de/dp/B09T9B8V76",
                note: "Morgenpflege UVA/UVB Schutz",
                recurrence: CustomRecurrenceRule(interval: 6, unit: .week, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "JRL Diamante 2025T Trimmer",
                source: .care,
                estimatedPriceEUR: 189.00,
                amazonURL: "https://www.amazon.de/s?k=JRL+Diamante+2025T",
                note: "Trocken-Trimmer PFB Protokoll - kein Nassrasierer",
                recurrence: nil
            ),
            RegistryItem(
                name: "Rhodiola Rosea 3% Salidrosid (60 Kapseln)",
                source: .growcery,
                estimatedPriceEUR: 24.90,
                amazonURL: "https://www.amazon.de/s?k=Rhodiola+Rosea+3%25+Salidrosid",
                note: "Supplement-Stack 06:00 Uhr - max. 500mg/Tag",
                recurrence: CustomRecurrenceRule(interval: 2, unit: .month, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "Magnesium Bisglycinat (300 Kapseln)",
                source: .growcery,
                estimatedPriceEUR: 18.90,
                amazonURL: "https://www.amazon.de/s?k=Magnesium+Bisglycinat+300",
                note: "Abend-Supplement 21:00 - max. 350mg elementar/Tag",
                recurrence: CustomRecurrenceRule(interval: 3, unit: .month, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "Omega-3 EPA/DHA 2000mg (120 Kapseln)",
                source: .growcery,
                estimatedPriceEUR: 19.90,
                amazonURL: "https://www.amazon.de/s?k=Omega+3+EPA+DHA+2000mg",
                note: "16:45 Uhr Einnahme",
                recurrence: CustomRecurrenceRule(interval: 1, unit: .month, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "Vitamin D3 5000 IE + K2 MK-7 200mcg",
                source: .growcery,
                estimatedPriceEUR: 16.90,
                amazonURL: "https://www.amazon.de/s?k=Vitamin+D3+5000+K2+MK7",
                note: "Einmalgabe 11:45 Uhr zum Mittagessen",
                recurrence: CustomRecurrenceRule(interval: 4, unit: .month, repeatDays: [1], endType: .never)
            ),
            RegistryItem(
                name: "Resistance Band Set (Calisthenics)",
                source: .gym,
                estimatedPriceEUR: 39.90,
                amazonURL: "https://www.amazon.de/s?k=Resistance+Band+Set+Pull+Up",
                note: "Fuer Klimmzug-Progression (Apoll Archetyp)",
                recurrence: nil
            )
        ]
    }
}

// MARK: - Main View

public struct ShoppingRegistryView: View {
    @StateObject private var store = ShoppingRegistryStore()

    @State private var searchText: String = ""
    @State private var selectedSource: ShoppingSource? = nil
    @State private var showSavedOnly: Bool = false
    @State private var showAllArchived: Bool = false
    @State private var showingAddSheet: Bool = false
    @State private var showingBudgetEditor: Bool = false
    @State private var editingItem: RegistryItem? = nil
    @State private var prefilledShareURL: String? = nil

    // Filter Logic:
    // 1. Items that have been bought and are NOT recurring are hidden!
    // 2. Unless showAllArchived is toggled.
    private var filteredItems: [RegistryItem] {
        store.items
            .filter { item in
                if showSavedOnly && !item.isSaved { return false }
                if !showAllArchived {
                    // Hide bought non-recurring items
                    if item.isPurchased && item.recurrence == nil {
                        return false
                    }
                }
                return true
            }
            .filter { selectedSource == nil || $0.source == selectedSource }
            .filter {
                searchText.isEmpty
                || $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.note.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                // Saved items first, then recurring items, then date
                if $0.isSaved != $1.isSaved { return $0.isSaved && !$1.isSaved }
                if ($0.recurrence != nil) != ($1.recurrence != nil) { return $0.recurrence != nil }
                return $0.addedDate > $1.addedDate
            }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                budgetBanner
                clipboardPasteBanner
                itemList
            }
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(FinanceTheme.bg.ignoresSafeArea())
            .navigationTitle("Einkauf")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Artikel, Links oder Notizen...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showSavedOnly.toggle()
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: showSavedOnly ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(showSavedOnly ? FinanceTheme.warmSand : FinanceTheme.textSecondary)
                        }

                        Button {
                            showAllArchived.toggle()
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: showAllArchived ? "archivebox.fill" : "archivebox")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(showAllArchived ? FinanceTheme.accent : FinanceTheme.textSecondary)
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    filterMenuButton

                    Menu {
                        Section("Budget & Verwaltung") {
                            Button {
                                showingBudgetEditor = true
                                HapticFeedback.light()
                            } label: {
                                Label("Monatsbudget anpassen", systemImage: "slider.horizontal.3")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }

                    // Primary Prominent Action: Artikel hinzufügen
                    Button {
                        HapticFeedback.medium()
                        showingAddSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(FinanceTheme.accent)
                                .frame(width: 28, height: 28)

                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FinanceTheme.background)
                        }
                    }
                    .accessibilityLabel("Artikel hinzufügen")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRegistryItemSheet(store: store, initialURL: prefilledShareURL)
                    .onDisappear { prefilledShareURL = nil }
            }
            .sheet(item: $editingItem) { item in
                EditRegistryItemSheet(item: item, store: store)
            }
            .sheet(isPresented: $showingBudgetEditor) {
                BudgetEditorSheet(store: store)
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    // MARK: - Clipboard Smart Detection Banner
    @ViewBuilder
    private var clipboardPasteBanner: some View {
        if let string = UIPasteboard.general.string,
           (string.contains("amazon.de") || string.contains("http://") || string.contains("https://")),
           prefilledShareURL == nil {
            HStack {
                Image(systemName: "link.badge.plus")
                    .font(.caption)
                    .foregroundColor(FinanceTheme.accent)
                Text("Link in Zwischenablage erkannt")
                    .font(.caption2)
                    .foregroundColor(FinanceTheme.textPrimary)
                Spacer()
                Button("Hinzufuegen") {
                    HapticFeedback.medium()
                    prefilledShareURL = string
                    showingAddSheet = true
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FinanceTheme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(FinanceTheme.surfaceElevated)
            .overlay(Rectangle().frame(height: 1).foregroundColor(FinanceTheme.border), alignment: .bottom)
        }
    }

    // MARK: - Dynamic Filter Calculation
    private var filteredPendingTotal: Double {
        if let sel = selectedSource {
            return store.items
                .filter { !$0.isPurchased && $0.source == sel }
                .reduce(0) { $0 + $1.estimatedPriceEUR }
        } else {
            return store.pendingTotal
        }
    }

    // MARK: - Budget Banner
    private var budgetBanner: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedSource != nil ? "Offen (\(selectedSource!.rawValue))" : "Offene Posten")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(FinanceTheme.textTertiary)
                    .lineLimit(1)
                Text(String(format: "%.2f EUR", filteredPendingTotal))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(FinanceTheme.textPrimary)
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("Budget frei")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(FinanceTheme.textTertiary)
                Text(String(format: "%.0f EUR", max(0, store.budgetRemaining)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(store.budgetRemaining >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Monatsbudget")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(FinanceTheme.textTertiary)
                Text(String(format: "%.0f EUR", store.monthlyBudgetEUR))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(FinanceTheme.textPrimary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(FinanceTheme.surfaceElevated)
        .overlay(Rectangle().frame(height: 1).foregroundColor(FinanceTheme.border.opacity(0.4)), alignment: .bottom)
    }

    // MARK: - Filter Menu Button
    private var filterMenuButton: some View {
        Menu {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedSource = nil
                }
                HapticFeedback.light()
            } label: {
                Label("Alle (\(String(format: "%.2f EUR", store.pendingTotal)))", systemImage: selectedSource == nil ? "checkmark.circle.fill" : "tray.2.fill")
            }

            Divider()

            ForEach(ShoppingSource.allCases) { source in
                let catTotal = store.items
                    .filter { !$0.isPurchased && $0.source == source }
                    .reduce(0) { $0 + $1.estimatedPriceEUR }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSource = selectedSource == source ? nil : source
                    }
                    HapticFeedback.light()
                } label: {
                    Label("\(source.rawValue) (\(String(format: "%.2f EUR", catTotal)))", systemImage: selectedSource == source ? "checkmark.circle.fill" : source.icon)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedSource != nil ? selectedSource!.accentColor : Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selectedSource != nil ? Color.white.opacity(0.35) : Color.white.opacity(0.12), lineWidth: 0.8)
                    )
                    .shadow(color: (selectedSource?.accentColor ?? Color.black).opacity(0.35), radius: 6, y: 3)

                Image(systemName: selectedSource != nil ? selectedSource!.icon : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(selectedSource != nil ? .white : FinanceTheme.textPrimary)
            }
        }
    }

    // MARK: - Item List
    private var itemList: some View {
        Group {
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 38))
                        .foregroundColor(FinanceTheme.textMuted)
                    Text("Keine aktiven Einkaeufe")
                        .font(.headline)
                        .foregroundColor(FinanceTheme.textPrimary)
                    Text(showAllArchived ? "Das Archiv ist leer." : "Gekaufte Einmal-Artikel sind ausgeblendet.\nTippe auf + fuer neue Artikel.")
                        .font(.caption)
                        .foregroundColor(FinanceTheme.textTertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(filteredItems) { item in
                        RegistryItemRow(item: item, store: store)
                            .onTapGesture { editingItem = item }
                            .listRowBackground(FinanceTheme.surface)
                            .listRowSeparatorTint(FinanceTheme.border.opacity(0.3))
                            // Swiping to the left gives option to SAVE (Bookmark) or DELETE
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    store.toggleSave(item: item)
                                    HapticFeedback.light()
                                } label: {
                                    Label(item.isSaved ? "Entfernen" : "Merken", systemImage: item.isSaved ? "bookmark.slash" : "bookmark.fill")
                                }
                                .tint(FinanceTheme.warmSand)

                                Button(role: .destructive) {
                                    store.delete(item)
                                    HapticFeedback.light()
                                } label: {
                                    Label("Loeschen", systemImage: "trash.fill")
                                }
                            }
                            // Swiping to the right gives option to mark as bought/open
                            .swipeActions(edge: .leading) {
                                Button {
                                    store.toggle(item: item)
                                    HapticFeedback.success()
                                } label: {
                                    Label(item.isPurchased ? "Offen" : "Gekauft", systemImage: item.isPurchased ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(item.isPurchased ? FinanceTheme.textMuted : FinanceTheme.sageGreen)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(FinanceTheme.bg)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 110)
                }
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // growfinance://add-item?url=...&name=...
        guard url.scheme == "growfinance" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = components?.queryItems {
            if let urlParam = queryItems.first(where: { $0.name == "url" })?.value {
                self.prefilledShareURL = urlParam
                self.showingAddSheet = true
            }
        }
    }
}

// MARK: - Clean Registry Item Row (Hyperlinks under Title, No Prio/Freigegeben)

private struct RegistryItemRow: View {
    let item: RegistryItem
    let store: ShoppingRegistryStore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkmark button
            Button {
                store.toggle(item: item)
                HapticFeedback.light()
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isPurchased ? FinanceTheme.sageGreen : FinanceTheme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(item.isPurchased ? FinanceTheme.textMuted : FinanceTheme.textPrimary)
                        .strikethrough(item.isPurchased, color: FinanceTheme.textMuted)
                        .lineLimit(2)

                    if item.isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10))
                            .foregroundColor(FinanceTheme.warmSand)
                    }
                }

                // Clickable Hyperlink under title
                if let urlString = item.amazonURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square.fill")
                                .font(.system(size: 10))
                            Text(displayHost(for: url))
                                .font(.system(size: 11, weight: .medium))
                                .underline()
                        }
                        .foregroundColor(FinanceTheme.strongBlue)
                    }
                    .buttonStyle(.plain)
                }

                // Recurrence Badge
                if let rec = item.recurrence {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 8, weight: .bold))
                        Text(rec.summaryText)
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(FinanceTheme.accent.opacity(0.18))
                    .foregroundColor(FinanceTheme.accent)
                    .cornerRadius(4)
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption2)
                        .foregroundColor(FinanceTheme.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Price & Source
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f €", item.estimatedPriceEUR))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: item.source.icon)
                        .font(.system(size: 8))
                    Text(item.source.rawValue)
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundColor(item.source.accentColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(item.source.accentColor.opacity(0.12))
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 6)
        .opacity(item.isPurchased ? 0.6 : 1.0)
    }

    private func displayHost(for url: URL) -> String {
        if let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return "Weblink oeffnen"
    }
}

// MARK: - Add / Edit Sheets with Recurrence Engine

struct AddRegistryItemSheet: View {
    let store: ShoppingRegistryStore
    var initialURL: String? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var note: String = ""
    @State private var priceText: String = ""
    @State private var source: ShoppingSource = .manual
    @State private var amazonURL: String = ""
    @State private var isSaved: Bool = false
    @State private var isRecurring: Bool = false
    @State private var recurrenceRule: CustomRecurrenceRule = CustomRecurrenceRule()
    @State private var showingRecurrenceSheet: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Artikel-Details") {
                    TextField("Name des Artikels", text: $name)
                    TextField("Weblink / Amazon URL", text: $amazonURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("Preis in EUR (z.B. 19.99)", text: $priceText)
                        .keyboardType(.decimalPad)
                    TextField("Notiz", text: $note)
                }
                .listRowBackground(FinanceTheme.surfaceElevated)

                Section("Kategorie & Merkliste") {
                    Picker("Quelle / Ökosystem", selection: $source) {
                        ForEach(ShoppingSource.allCases) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }

                    Toggle("Auf Merkliste speichern", isOn: $isSaved)
                }
                .listRowBackground(FinanceTheme.surfaceElevated)

                Section("Wiederholung (Google Calendar Engine)") {
                    Toggle("Wiederkehrender Einkauf", isOn: $isRecurring)

                    if isRecurring {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Rhythmus")
                                    .font(.caption)
                                    .foregroundColor(FinanceTheme.textTertiary)
                                Text(recurrenceRule.summaryText)
                                    .font(.subheadline)
                                    .foregroundColor(FinanceTheme.accent)
                            }
                            Spacer()
                            Button("Anpassen") {
                                showingRecurrenceSheet = true
                            }
                            .font(.caption)
                            .foregroundColor(FinanceTheme.accent)
                        }
                    }
                }
                .listRowBackground(FinanceTheme.surfaceElevated)
            }
            .scrollContentBackground(.hidden)
            .background(FinanceTheme.bg)
            .navigationTitle("Neuer Artikel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let parsedPrice = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        let item = RegistryItem(
                            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Neuer Artikel" : name,
                            source: source,
                            estimatedPriceEUR: parsedPrice,
                            amazonURL: amazonURL.trimmingCharacters(in: .whitespaces).isEmpty ? nil : amazonURL,
                            note: note,
                            isSaved: isSaved,
                            recurrence: isRecurring ? recurrenceRule : nil
                        )
                        store.add(item)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            .sheet(isPresented: $showingRecurrenceSheet) {
                CustomRecurrenceSheet(rule: $recurrenceRule) { updated in
                    recurrenceRule = updated
                }
            }
            .onAppear {
                if let u = initialURL {
                    self.amazonURL = u
                    if u.contains("amazon") {
                        self.source = .wishlist
                        self.name = "Amazon Artikel"
                    }
                }
            }
        }
    }
}

struct EditRegistryItemSheet: View {
    let item: RegistryItem
    let store: ShoppingRegistryStore

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var note: String
    @State private var priceText: String
    @State private var source: ShoppingSource
    @State private var amazonURL: String
    @State private var isSaved: Bool
    @State private var isRecurring: Bool
    @State private var recurrenceRule: CustomRecurrenceRule
    @State private var showingRecurrenceSheet: Bool = false

    init(item: RegistryItem, store: ShoppingRegistryStore) {
        self.item = item
        self.store = store
        self._name = State(initialValue: item.name)
        self._note = State(initialValue: item.note)
        self._priceText = State(initialValue: String(format: "%.2f", item.estimatedPriceEUR))
        self._source = State(initialValue: item.source)
        self._amazonURL = State(initialValue: item.amazonURL ?? "")
        self._isSaved = State(initialValue: item.isSaved)
        self._isRecurring = State(initialValue: item.recurrence != nil)
        self._recurrenceRule = State(initialValue: item.recurrence ?? CustomRecurrenceRule())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Artikel") {
                    TextField("Name", text: $name)
                    TextField("Weblink", text: $amazonURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("Preis (EUR)", text: $priceText).keyboardType(.decimalPad)
                    TextField("Notiz", text: $note)
                }
                .listRowBackground(FinanceTheme.surfaceElevated)

                Section("Status") {
                    Picker("Quelle", selection: $source) {
                        ForEach(ShoppingSource.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    Toggle("Auf Merkliste", isOn: $isSaved)
                }
                .listRowBackground(FinanceTheme.surfaceElevated)

                Section("Wiederholung") {
                    Toggle("Wiederkehrender Einkauf", isOn: $isRecurring)

                    if isRecurring {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rhythmus")
                                    .font(.caption)
                                    .foregroundColor(FinanceTheme.textTertiary)
                                Text(recurrenceRule.summaryText)
                                    .font(.subheadline)
                                    .foregroundColor(FinanceTheme.accent)
                            }
                            Spacer()
                            Button("Anpassen") {
                                showingRecurrenceSheet = true
                            }
                            .font(.caption)
                            .foregroundColor(FinanceTheme.accent)
                        }
                    }
                }
                .listRowBackground(FinanceTheme.surfaceElevated)

                Section {
                    Button(role: .destructive) {
                        store.delete(item)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Artikel loeschen")
                            Spacer()
                        }
                    }
                }
                .listRowBackground(FinanceTheme.surfaceElevated)
            }
            .scrollContentBackground(.hidden)
            .background(FinanceTheme.bg)
            .navigationTitle("Artikel bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        let parsedPrice = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? item.estimatedPriceEUR
                        var updated = item
                        updated.name = name
                        updated.note = note
                        updated.estimatedPriceEUR = parsedPrice
                        updated.source = source
                        updated.amazonURL = amazonURL.isEmpty ? nil : amazonURL
                        updated.isSaved = isSaved
                        updated.recurrence = isRecurring ? recurrenceRule : nil
                        store.update(updated)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            .sheet(isPresented: $showingRecurrenceSheet) {
                CustomRecurrenceSheet(rule: $recurrenceRule) { updated in
                    recurrenceRule = updated
                }
            }
        }
    }
}

struct BudgetEditorSheet: View {
    let store: ShoppingRegistryStore
    @Environment(\.dismiss) private var dismiss
    @State private var budgetText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Monatliches Einkaufsbudget") {
                    TextField("Budget in EUR", text: $budgetText)
                        .keyboardType(.numberPad)
                    Text("Das Monatsbudget dient der Transparenz ueber alle anstehenden Einkauefe im Grow-Oekosystem.")
                        .font(.caption)
                        .foregroundColor(FinanceTheme.textTertiary)
                }
                .listRowBackground(FinanceTheme.surfaceElevated)
            }
            .scrollContentBackground(.hidden)
            .background(FinanceTheme.bg)
            .navigationTitle("Budget anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        if let b = Double(budgetText) {
                            store.setMonthlyBudget(b)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            .onAppear {
                budgetText = String(format: "%.0f", store.monthlyBudgetEUR)
            }
        }
    }
}
