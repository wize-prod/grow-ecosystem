import SwiftUI
import UniformTypeIdentifiers

public struct TransactionsListView: View {
    @ObservedObject private var store = FinanceStore.shared
    @State private var selectedTab: Int = 0 // 0: Buchungen, 1: Budgets, 2: Berichte & Analyse, 3: Belege
    @State private var showingScreenshotScanner: Bool = false
    @State private var showingUniversalScanner: Bool = false
    @State private var showingFileImporter: Bool = false
    @State private var showingImportAlert: Bool = false
    @State private var importAlertMessage: String = ""
    @State private var showingAddAccountSheet: Bool = false
    @State private var showingDateRangeSheet: Bool = false
    @State private var showingInfoSheet: Bool = false
    @State private var activeInfoTopic: FinanceInfoTopic = .belegScanner
    
    public let embedInNavigationStack: Bool
    public let showSubPicker: Bool

    public init(embedInNavigationStack: Bool = true, showSubPicker: Bool = true) {
        self.embedInNavigationStack = embedInNavigationStack
        self.showSubPicker = showSubPicker
    }

    private var currentTabTitle: String {
        switch selectedTab {
        case 0: return "Buchungen"
        case 1: return "Budgets"
        case 2: return "Berichte"
        case 3: return "Belege"
        default: return "Buchungen"
        }
    }
    
    @ViewBuilder
    public var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                mainContent
            }
            .background(FinanceTheme.background.ignoresSafeArea())
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        Group {
            switch selectedTab {
            case 0:
                transactionList
            case 1:
                BudgetsDashboardView(embedInNavigationStack: false)
            case 2:
                FinanceReportsView(embedInNavigationStack: false, scrollable: true)
            case 3:
                #if canImport(UIKit)
                TargobankBelegeGalleryView(store: store, showingScannerSheet: $showingScreenshotScanner)
                #else
                Text("Belege Galerie")
                #endif
            default:
                transactionList
            }
        }
        .frame(maxWidth: 1080)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(FinanceTheme.background.ignoresSafeArea())
        .modifier(TransactionsTitleModifier(title: currentTabTitle, isEnabled: embedInNavigationStack))
        .searchable(text: $store.searchQuery, prompt: "Empfänger, Datum, Betrag...")
        .toolbar {
            if showSubPicker {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedTab) {
                        Text("Buchungen").tag(0)
                        Text("Budgets").tag(1)
                        Text("Berichte").tag(2)
                        Text("Belege").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                // Filter (only relevant for transactions)
                if selectedTab == 0 {
                    unifiedFilterMenuButton
                }

                // More Menu
                Menu {
                    Section("Daten & Tools") {
                        Button {
                            showingFileImporter = true
                            HapticFeedback.light()
                        } label: {
                            Label("CSV importieren", systemImage: "doc.badge.plus")
                        }

                        Button {
                            showingDateRangeSheet = true
                            HapticFeedback.light()
                        } label: {
                            Label("Zeitraum anpassen", systemImage: "calendar")
                        }

                        Button {
                            activeInfoTopic = .belegScanner
                            showingInfoSheet = true
                            HapticFeedback.light()
                        } label: {
                            Label("Info zu Belegen", systemImage: "info.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(FinanceTheme.textSecondary)
                }

                // Primary Prominent Action: Beleg Scanner / Neue Buchung
                Menu {
                    Button {
                        showingUniversalScanner = true
                        HapticFeedback.light()
                    } label: {
                        Label("Quittung / Beleg scannen", systemImage: "doc.text.viewfinder")
                    }

                    Button {
                        showingScreenshotScanner = true
                        HapticFeedback.light()
                    } label: {
                        Label("Targobank Screenshot scannen", systemImage: "camera.viewfinder")
                    }

                    Button {
                        showingFileImporter = true
                        HapticFeedback.light()
                    } label: {
                        Label("Haushaltsbuch CSV importieren", systemImage: "doc.badge.plus")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(FinanceTheme.accent)
                            .frame(width: 28, height: 28)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FinanceTheme.background)
                    }
                }
                .accessibilityLabel("Scanner & Belege")
            }
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingScreenshotScanner) {
            TargobankScanSheet(store: store)
        }
        .sheet(isPresented: $showingUniversalScanner) {
            UniversalScanSheet()
        }
        #endif
        .sheet(isPresented: $showingAddAccountSheet) {
            AddAccountSheet()
        }
        .sheet(isPresented: $showingDateRangeSheet) {
            CustomDateRangeSheet()
        }
        .sheet(isPresented: $showingInfoSheet) {
            FinanceInfoExplanationSheet(topic: activeInfoTopic)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText, .text, .json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedUrl = urls.first else { return }
                store.importHaushaltsbuchFile(from: selectedUrl)
                if let err = store.importErrorMessage {
                    importAlertMessage = err
                } else if let report = store.lastImportReport {
                    importAlertMessage = report.summaryMessage
                } else {
                    importAlertMessage = "\(store.lastImportCount) neue Buchungen importiert."
                }
                showingImportAlert = true
            case .failure(let err):
                importAlertMessage = err.localizedDescription
                showingImportAlert = true
            }
        }
        .alert("Haushaltsbuch Import", isPresented: $showingImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importAlertMessage)
        }
    }
    
    // MARK: - Transaction List (Scrolls Under Hovering Bar, Deletion Removed)
    private var transactionList: some View {
        let items = store.filteredTransactions
        
        return Group {
            if items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Keine Buchungen gefunden")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Text("Passe Suchbegriff, Zeitraum oder Filter an.")
                        .font(.system(size: 12))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Active Filter Badges
                    if store.selectedAccountId != nil || store.selectedFilterCategory != nil || store.selectedDatePreset != .all {
                        activeFilterBadge
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(FinanceTheme.background)
                            .listRowSeparator(.hidden)
                    }
                    
                    ForEach(items) { tx in
                        transactionRow(tx)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(FinanceTheme.background)
                            .listRowSeparator(.hidden)
                    }
                    // NOTE: Deletion functionality removed per user directive to ensure financial audit compliance
                }
                .listStyle(.plain)
                .background(FinanceTheme.background)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 80)
                }
            }
        }
    }
    
    private var activeFilterBadge: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Account Badge
                if let acc = store.selectedAccount {
                    HStack(spacing: 4) {
                        Image(systemName: acc.type.icon)
                            .font(.system(size: 9))
                        Text(acc.accountNumber)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        
                        Button {
                            store.selectedAccountId = nil
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FinanceTheme.surfaceRaised)
                    .foregroundColor(FinanceTheme.accent)
                    .cornerRadius(6)
                }
                
                // Date Preset Badge
                if store.selectedDatePreset != .all {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(dateFilterBadgeTitle)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        
                        Button {
                            store.selectedDatePreset = .all
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FinanceTheme.accent.opacity(0.15))
                    .foregroundColor(FinanceTheme.accent)
                    .cornerRadius(6)
                }
                
                // Category Badge
                if let cat = store.selectedFilterCategory {
                    HStack(spacing: 4) {
                        Image(systemName: cat.iconName)
                            .font(.system(size: 9))
                        Text(cat.displayName)
                            .font(.system(size: 10, weight: .bold))
                        
                        Button {
                            store.selectedFilterCategory = nil
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cat.color.opacity(0.15))
                    .foregroundColor(cat.color)
                    .cornerRadius(6)
                }
                
                Text("\(store.filteredTransactions.count) Treffer")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var dateFilterBadgeTitle: String {
        if store.selectedDatePreset == .custom {
            let df = DateFormatter()
            df.dateFormat = "dd.MM."
            return "\(df.string(from: store.customStartDate)) - \(df.string(from: store.customEndDate))"
        }
        return store.selectedDatePreset.rawValue
    }
    
    private func transactionRow(_ tx: BankTransaction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(tx.category.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: tx.category.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(tx.category.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.partnerName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FinanceTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(tx.purpose)
                        .font(.system(size: 11))
                        .foregroundColor(FinanceTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tx.formattedAmount)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(tx.amount > 0 ? FinanceTheme.positive : FinanceTheme.textPrimary)
                    
                    Text(tx.date.formatted(.dateTime.day().month().year()))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                }
            }
            
            HStack {
                Text(tx.category.displayName.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tx.category.color.opacity(0.15))
                    .foregroundColor(tx.category.color)
                    .cornerRadius(4)
                
                Spacer()
                
                if !tx.iban.isEmpty {
                    Text(tx.iban)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .financeCardStyle()
    }
    

    
    // MARK: - Unified Filter Menu Button (Account, Date & Category)
    private var unifiedFilterMenuButton: some View {
        let isAccountFiltered = store.selectedAccountId != nil
        let isDateFiltered = store.selectedDatePreset != .all
        let isCategoryFiltered = store.selectedFilterCategory != nil
        let isAnyFilterActive = isAccountFiltered || isDateFiltered || isCategoryFiltered
        
        return Menu {
            // 1. Account Filter Section
            Section("Targobank Konten") {
                Button {
                    store.selectedAccountId = nil
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Text("Alle Konten (Konsolidiert)")
                        if store.selectedAccountId == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(store.accounts) { acc in
                    Button {
                        store.selectedAccountId = acc.id
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Text("\(acc.accountNumber) \(acc.name)")
                            if store.selectedAccountId == acc.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Button {
                    showingAddAccountSheet = true
                    HapticFeedback.light()
                } label: {
                    Label("Neues Konto anlegen...", systemImage: "plus.circle")
                }
            }
            
            // 2. Date / Period Filter Section
            Section("Zeitraum") {
                ForEach(DateFilterPreset.allCases) { preset in
                    if preset == .custom {
                        Button {
                            showingDateRangeSheet = true
                            HapticFeedback.light()
                        } label: {
                            HStack {
                                Label("Datumsbereich...", systemImage: "slider.horizontal.2.square")
                                if store.selectedDatePreset == .custom {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } else {
                        Button {
                            store.selectedDatePreset = preset
                            HapticFeedback.light()
                        } label: {
                            HStack {
                                Label(preset.rawValue, systemImage: preset.icon)
                                if store.selectedDatePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            
            // 3. Category Filter Section
            Section("Kategorie") {
                Button {
                    store.selectedFilterCategory = nil
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Text("Alle Kategorien")
                        if store.selectedFilterCategory == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(TransactionCategory.allCases) { cat in
                    Button {
                        store.selectedFilterCategory = cat
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Label(cat.rawValue, systemImage: cat.icon)
                            if store.selectedFilterCategory == cat {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            // 4. Reset All Filters
            if isAnyFilterActive {
                Section {
                    Button(role: .destructive) {
                        store.selectedAccountId = nil
                        store.selectedDatePreset = .all
                        store.selectedFilterCategory = nil
                        HapticFeedback.medium()
                    } label: {
                        Label("Alle Filter zuruecksetzen", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isAnyFilterActive ? FinanceTheme.accent : Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isAnyFilterActive ? FinanceTheme.accent : Color.white.opacity(0.12),
                                lineWidth: 0.8
                            )
                    )
                
                Image(systemName: isAnyFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isAnyFilterActive ? FinanceTheme.background : FinanceTheme.textPrimary)
            }
        }
        .accessibilityLabel("Transaktionen filtern")
    }
}

// MARK: - Custom Date Range Sheet
private struct CustomDateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FinanceStore.shared
    
    @State private var start: Date = Date()
    @State private var end: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Zeitraum eingrenzen") {
                        DatePicker("Von", selection: $start, displayedComponents: .date)
                            .foregroundColor(FinanceTheme.textPrimary)
                        
                        DatePicker("Bis", selection: $end, displayedComponents: .date)
                            .foregroundColor(FinanceTheme.textPrimary)
                    }
                    .listRowBackground(FinanceTheme.surfaceRaised)
                    
                    Section {
                        Button("Schnellwahl: Letzte 30 Tage") {
                            start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                            end = Date()
                        }
                        .foregroundColor(FinanceTheme.accent)
                        
                        Button("Schnellwahl: Dieser Monat") {
                            let cal = Calendar.current
                            let comps = cal.dateComponents([.year, .month], from: Date())
                            start = cal.date(from: comps) ?? Date()
                            end = Date()
                        }
                        .foregroundColor(FinanceTheme.accent)
                    }
                    .listRowBackground(FinanceTheme.surfaceRaised)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Datumsbereich")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anwenden") {
                        store.customStartDate = start
                        store.customEndDate = end
                        store.selectedDatePreset = .custom
                        dismiss()
                    }
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            .onAppear {
                start = store.customStartDate
                end = store.customEndDate
            }
        }
    }
}

// MARK: - Add Account Sheet
struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FinanceStore.shared
    
    @State private var accountNumber: String = ""
    @State private var name: String = ""
    @State private var type: AccountType = .dailySavings
    @State private var initialBalanceString: String = "0.00"
    @State private var iban: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Kontodaten (Targobank / Bank)") {
                        TextField("Kontonummer (z.B. 5221062404)", text: $accountNumber)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .foregroundColor(FinanceTheme.textPrimary)
                        
                        TextField("Kontoname (z.B. Notfallfonds / Savings)", text: $name)
                            .foregroundColor(FinanceTheme.textPrimary)
                        
                        Picker("Kontoart", selection: $type) {
                            ForEach(AccountType.allCases) { accType in
                                HStack {
                                    Image(systemName: accType.icon)
                                    Text(accType.rawValue)
                                }
                                .tag(accType)
                            }
                        }
                    }
                    .listRowBackground(FinanceTheme.surfaceRaised)
                    
                    Section("Saldo & IBAN") {
                        TextField("Startsaldo (EUR)", text: $initialBalanceString)
                            .decimalPadKeyboard()
                            .foregroundColor(FinanceTheme.textPrimary)
                        
                        TextField("IBAN (optional)", text: $iban)
                            .foregroundColor(FinanceTheme.textPrimary)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.characters)
                            #endif
                    }
                    .listRowBackground(FinanceTheme.surfaceRaised)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Konto anlegen")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        saveAccount()
                        dismiss()
                    }
                    .disabled(accountNumber.trimmingCharacters(in: .whitespaces).isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(FinanceTheme.accent)
                }
            }
        }
    }
    
    private func saveAccount() {
        let cleanBalance = initialBalanceString.replacingOccurrences(of: ",", with: ".")
        let balance = Double(cleanBalance) ?? 0.0
        store.addAccount(
            accountNumber: accountNumber.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            initialBalance: balance,
            iban: iban.trimmingCharacters(in: .whitespaces)
        )
    }
}

struct TransactionsTitleModifier: ViewModifier {
    let title: String
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .navigationTitle(title)
                .inlineTitleDisplayMode()
        } else {
            content
        }
    }
}
