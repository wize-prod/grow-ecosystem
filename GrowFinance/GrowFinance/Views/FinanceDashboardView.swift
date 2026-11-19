import SwiftUI
import UniformTypeIdentifiers

// MARK: - FinanceDashboardView (Main Coordinator)
public struct FinanceDashboardView: View {
    @ObservedObject private var store = FinanceStore.shared
    @State private var showingAddAccountSheet: Bool = false
    @State private var showingSmartReportSheet: Bool = false
    @State private var showingImporter: Bool = false
    @State private var showingImportSuccessAlert: Bool = false
    @State private var importAlertMessage: String? = nil
    @State private var isFixedCostsExpanded: Bool = false
    @State private var activeInfoTopic: FinanceInfoTopic? = nil
    @State private var showingInfoSheet: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var isDateDetailExpanded: Bool = false
    
    // Account editing & detail windows (Integrated from Konten & Profil)
    @State private var editingAccount: BankAccount? = nil
    @State private var selectedAccountForDetail: BankAccount? = nil

    // Sub-Allocation (Sparziele) management
    @State private var accountForNewSubGoal: BankAccount? = nil
    @State private var subAllocationToEdit: SubAllocationEditContext? = nil

    // Income Source Form State
    @State private var showingAddIncomeSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // 1. Calendar Date Strip (Interactive day selection)
                    FinanceCalendarStripView(selectedDate: $selectedDate, isDetailExpanded: $isDateDetailExpanded)
                    
                    // 2. Selected Date Detail Card (Tagesnotiz & Buchungen)
                    if isDateDetailExpanded {
                        FinanceSelectedDateDetailCardView(
                            selectedDate: selectedDate,
                            onCollapse: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDateDetailExpanded = false
                                }
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // 3. Safe-to-Spend Hero Shield
                    FinanceSafeToSpendShieldView(
                        store: store,
                        onInfoTapped: { topic in
                            activeInfoTopic = topic
                            showingInfoSheet = true
                            HapticFeedback.light()
                        },
                        onSmartReportTapped: {
                            HapticFeedback.light()
                            showingSmartReportSheet = true
                        }
                    )
                    
                    // 4. TARGOBANK KONTEN & SPARZIELE (Tapping opens dedicated account detail window)
                    FinanceAccountsOverviewSection(
                        accounts: store.accounts,
                        onSelectAccount: { acc in
                            selectedAccountForDetail = acc
                            HapticFeedback.light()
                        },
                        onEditAccount: { acc in
                            editingAccount = acc
                        }
                    )
                }
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(FinanceTheme.background.ignoresSafeArea())
            .navigationTitle("Übersicht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    FinanceCircularProfileButton()
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Haushaltsbuch & Daten") {
                            Button {
                                showingImporter = true
                                HapticFeedback.medium()
                            } label: {
                                Label("CSV-Datei importieren", systemImage: "doc.badge.plus")
                            }

                            Button {
                                showingAddAccountSheet = true
                                HapticFeedback.light()
                            } label: {
                                Label("Konto hinzufügen", systemImage: "creditcard")
                            }

                            Button {
                                showingSmartReportSheet = true
                                HapticFeedback.light()
                            } label: {
                                Label("Smart Engine Bericht", systemImage: "brain.head.profile")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }

                    FinanceCircularWaterButton()

                    // Primary Prominent Action: Einnahmequelle hinzufügen
                    Button {
                        showingAddIncomeSheet = true
                        HapticFeedback.medium()
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
                    .accessibilityLabel("Einnahmequelle hinzufügen")
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText, .text, .json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let selectedUrl = urls.first else { return }
                    store.importCSV(from: selectedUrl)
                    if let error = store.importErrorMessage {
                        importAlertMessage = error
                    } else {
                        showingImportSuccessAlert = true
                    }
                case .failure(let error):
                    importAlertMessage = error.localizedDescription
                }
            }
            .alert("Haushaltsbuch Import", isPresented: $showingImportSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.lastImportReport?.summaryMessage ?? "\(store.lastImportCount) neue Buchungen erfolgreich importiert.")
            }
            .sheet(isPresented: $showingAddAccountSheet) {
                AddAccountSheet()
            }
            .sheet(isPresented: $showingSmartReportSheet) {
                SmartEngineReportSheet()
            }
            .sheet(isPresented: $showingInfoSheet) {
                if let topic = activeInfoTopic {
                    FinanceInfoExplanationSheet(topic: topic)
                }
            }
            .sheet(item: $editingAccount) { acc in
                EditAccountSheetView(account: acc) { newName in
                    store.updateAccountName(id: acc.id, newName: newName)
                }
            }
            .sheet(item: $selectedAccountForDetail) { acc in
                if acc.type == .loan {
                    LoanAccountDetailSheet(account: acc)
                } else {
                    AccountDetailSheet(account: acc)
                }
            }
            .sheet(item: $accountForNewSubGoal) { acc in
                AddSubGoalSheetView(account: acc) { name, alloc, tgt, icon, notes in
                    store.addSubAllocation(
                        to: acc.id,
                        name: name,
                        allocatedAmount: alloc,
                        targetAmount: tgt,
                        icon: icon,
                        notes: notes
                    )
                }
            }
            .sheet(item: $subAllocationToEdit) { ctx in
                EditSubGoalSheetView(context: ctx) { updated in
                    store.updateSubAllocation(accountId: ctx.accountId, subAllocation: updated)
                } onDelete: {
                    store.deleteSubAllocation(accountId: ctx.accountId, subAllocationId: ctx.subAllocation.id)
                }
            }
            .sheet(isPresented: $showingAddIncomeSheet) {
                AddIncomeSheetView { name, amt in
                    store.addIncomeSource(name: name, amount: amt)
                }
            }
        }
    }
}

// MARK: - Subcomponent 1: Header View
public struct FinanceHeaderView: View {
    public let onAddIncomeTapped: () -> Void
    
    public init(onAddIncomeTapped: @escaping () -> Void) {
        self.onAddIncomeTapped = onAddIncomeTapped
    }
    
    public var body: some View {
        HStack {
            Text("GROWFINANCE")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(1.8)
                .foregroundColor(FinanceTheme.accent)
            
            Spacer()
            
            Button {
                onAddIncomeTapped()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Einnahmequelle")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(FinanceTheme.accent.opacity(0.15))
                .foregroundColor(FinanceTheme.accent)
                .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Subcomponent 2: Profile & Netto-Einkommen Card
public struct FinanceProfileIncomeCardView: View {
    public let profile: UserProfile
    public let onDeleteIncomeSource: (String) -> Void
    
    public init(profile: UserProfile, onDeleteIncomeSource: @escaping (String) -> Void) {
        self.profile = profile
        self.onDeleteIncomeSource = onDeleteIncomeSource
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MONATLICHES NETTO-GESAMTEINKOMMEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f €", profile.monthlyNetIncome))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(FinanceTheme.sageGreen)
                }
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(FinanceTheme.accent)
            }

            Divider().background(FinanceTheme.surfaceBorder)

            Text("EINNAHMEQUELLEN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)

            ForEach(profile.incomeSources) { src in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(src.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            if src.isPrimary {
                                Text("HAUPT")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(FinanceTheme.accent.opacity(0.15))
                                    .foregroundColor(FinanceTheme.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(src.recurrence)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    Spacer()
                    Text(String(format: "+%.2f €", src.monthlyAmount))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.sageGreen)

                    if !src.isPrimary {
                        Button {
                            onDeleteIncomeSource(src.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(FinanceTheme.textTertiary)
                                .padding(.leading, 8)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .background(FinanceTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: - Subcomponent 3: Selected Date Detail Card
public struct FinanceSelectedDateDetailCardView: View {
    public let selectedDate: Date
    public let onCollapse: () -> Void
    @ObservedObject private var store = FinanceStore.shared
    
    public init(selectedDate: Date, onCollapse: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.onCollapse = onCollapse
    }
    
    public var body: some View {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        let dayTxs = store.transactions(on: selectedDate)
        
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isToday ? "HEUTE • TAGESDETAIL" : "TAGESDETAIL • \(formattedWeekday(selectedDate).uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.accent)
                    Text(formattedFullDate(selectedDate))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textPrimary)
                }
                Spacer()
                
                Button {
                    onCollapse()
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .padding(6)
                        .background(FinanceTheme.surfaceRaised)
                        .clipShape(Circle())
                }
            }
            
            // Tagesnotiz Section
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 10))
                        .foregroundColor(FinanceTheme.warmSand)
                    Text("TAGESNOTIZ (FINANZEN, AUDIT, DISPO-SCHUTZ)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                }
                
                ZStack(alignment: .topLeading) {
                    if store.note(for: selectedDate).isEmpty {
                        Text("Notiz fuer diesen Tag erfassen (z. B. Barkauf, Budget-Audit, Sparziele)...")
                            .font(.system(size: 12))
                            .foregroundColor(FinanceTheme.textTertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    
                    TextEditor(text: Binding(
                        get: { store.note(for: selectedDate) },
                        set: { store.setNote($0, for: selectedDate) }
                    ))
                    .font(.system(size: 12))
                    .foregroundColor(FinanceTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 52)
                }
                .padding(8)
                .background(FinanceTheme.surface)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(FinanceTheme.surfaceBorder, lineWidth: 1))
            }
            
            // Transactions on this date
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("BUCHUNGEN AN DIESEM TAG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Spacer()
                    Text("\(dayTxs.count)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FinanceTheme.accent.opacity(0.15))
                        .foregroundColor(FinanceTheme.accent)
                        .cornerRadius(4)
                }
                
                if dayTxs.isEmpty {
                    Text("Keine Buchungen an diesem Tag erfasst.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(dayTxs) { tx in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.displayRecipient)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(FinanceTheme.textPrimary)
                                        .lineLimit(1)
                                    Text(tx.purpose)
                                        .font(.system(size: 10))
                                        .foregroundColor(FinanceTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(tx.formattedAmount)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(tx.amount > 0 ? FinanceTheme.positive : FinanceTheme.textPrimary)
                                    Text(tx.category.displayName.uppercased())
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(tx.category.color.opacity(0.15))
                                        .foregroundColor(tx.category.color)
                                        .cornerRadius(3)
                                }
                            }
                            .padding(8)
                            .background(FinanceTheme.surface)
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Planned Fixed Costs / Debits for Selected Date
            let dayFixedCosts = store.recurringFixedCostsThisMonth.filter { cost in
                guard let due = cost.expectedDueDateThisMonth else { return false }
                return Calendar.current.isDate(due, inSameDayAs: selectedDate)
            }
            let upcomingFixedCosts = store.recurringFixedCostsThisMonth.filter { !$0.isPaidThisMonth }
            
            if !dayFixedCosts.isEmpty || (!isToday && selectedDate >= Date() && !upcomingFixedCosts.isEmpty) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dayFixedCosts.isEmpty ? "ANSTEHENDE FIXKOSTEN (VORAUSSCHAU)" : "FIXKOSTEN-FÄLLIGKEIT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.warning)
                        Spacer()
                    }
                    
                    let displayList = dayFixedCosts.isEmpty ? upcomingFixedCosts : dayFixedCosts
                    VStack(spacing: 6) {
                        ForEach(displayList) { cost in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cost.name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(FinanceTheme.textPrimary)
                                    if let due = cost.expectedDueDateThisMonth {
                                        Text("Fällig: \(formattedFullDate(due))")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(FinanceTheme.textSecondary)
                                    }
                                }
                                Spacer()
                                Text(String(format: "-%.2f €", cost.expectedAmount))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(cost.isPaidThisMonth ? FinanceTheme.textSecondary : FinanceTheme.warning)
                            }
                            .padding(8)
                            .background(FinanceTheme.surface)
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(FinanceTheme.surfaceRaised)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FinanceTheme.surfaceBorder, lineWidth: 1))
    }
    
    private func formattedWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    private func formattedFullDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d. MMMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Subcomponent 4: Safe-to-Spend Hero Shield
public struct FinanceSafeToSpendShieldView: View {
    @ObservedObject public var store: FinanceStore
    public let onInfoTapped: (FinanceInfoTopic) -> Void
    public let onSmartReportTapped: () -> Void
    
    private let engine = SmartFinanceEngine.shared
    
    public init(
        store: FinanceStore,
        onInfoTapped: @escaping (FinanceInfoTopic) -> Void,
        onSmartReportTapped: @escaping () -> Void
    ) {
        self.store = store
        self.onInfoTapped = onInfoTapped
        self.onSmartReportTapped = onSmartReportTapped
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text("FREI VERFÜGBAR BIS MONATSENDE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(FinanceTheme.textSecondary)
                    
                    Button {
                        onInfoTapped(.safeToSpend)
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(FinanceTheme.accent)
                    }
                }
                
                Spacer()
                
                // Binary Dispo Safety Status Indicator with ⓘ
                Button {
                    onInfoTapped(.dispoSchutz)
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(store.isDispoSafe ? FinanceTheme.positive : FinanceTheme.negative)
                            .frame(width: 7, height: 7)
                        
                        Text(store.isDispoSafe ? "DISPO-SCHUTZ: AKTIV" : "DISPO-WARNUNG")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(store.isDispoSafe ? FinanceTheme.positive : FinanceTheme.negative)
                        
                        Image(systemName: "info.circle")
                            .font(.system(size: 9))
                            .foregroundColor(store.isDispoSafe ? FinanceTheme.positive : FinanceTheme.negative)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill((store.isDispoSafe ? FinanceTheme.positive : FinanceTheme.negative).opacity(0.12)))
                    .overlay(Capsule().stroke((store.isDispoSafe ? FinanceTheme.positive : FinanceTheme.negative).opacity(0.3), lineWidth: 0.8))
                }
                .buttonStyle(AppleTactileButtonStyle())
            }
            
            // Single Dominant Hero Number with 3-Color Dynamic Spectrum & Netto-Gesamteinkommen Subtitle
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.2f", store.safeToSpend))
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundColor(safeToSpendDynamicColor(amount: store.safeToSpend))
                    
                    Text("EUR")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(safeToSpendDynamicColor(amount: store.safeToSpend).opacity(0.85))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "Giro: %.2f €", store.plusKontoBalance))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                        Text("-100 € Notfallpuffer")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(FinanceTheme.accent)
                        if store.totalRemainingFixedCosts > 0 {
                            Text(String(format: "-%.2f € Fixkosten", store.totalRemainingFixedCosts))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(FinanceTheme.warning)
                        }
                    }
                }

                // Aktuelles Nettovermögen (Between frei verfügbar and monatliches netto-Gesamteinkommen)
                HStack(spacing: 4) {
                    Text("Aktuelles Nettovermögen:")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%@%.2f €", store.netWorth >= 0 ? "+" : "", store.netWorth))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(store.netWorth >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                }

                // Subtitle directly below the frei verfügbar number
                HStack(spacing: 4) {
                    Text("Monatliches Netto-Gesamteinkommen:")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f €", store.userProfile.monthlyNetIncome))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.sageGreen)
                }
            }
            
            // Dual Pace Metrics: Erlaubter Tages-Satz vs. Echtzeit-Burn-Rate
            let allowance = engine.calculateDailyAllowance(
                plusKontoBalance: store.plusKontoBalance,
                pendingFixedCosts: store.totalRemainingFixedCosts
            )
            let velocity = engine.calculateRealTimeVelocity(
                transactions: store.transactions,
                plusKontoBalance: store.plusKontoBalance,
                pendingFixedCosts: store.totalRemainingFixedCosts
            )
            
            HStack(spacing: 8) {
                // Erlaubter Tages-Satz
                VStack(alignment: .leading, spacing: 2) {
                    Text("ERLAUBTER TAGES-SATZ")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.2f", allowance.dailyLimitEur))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(allowance.isCriticalDispoWarning ? FinanceTheme.warning : FinanceTheme.positive)
                        Text("€/Tag")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
                
                // Echtzeit-Burn-Rate
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("ECHTZEIT-BURN-RATE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                        Spacer()
                        Button {
                            onSmartReportTapped()
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 10))
                                .foregroundColor(FinanceTheme.accent)
                        }
                        .buttonStyle(AppleTactileButtonStyle())
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.2f", velocity.actualBurnRatePerDay))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(velocity.isOverpacing ? FinanceTheme.warning : FinanceTheme.accent)
                        Text("€/Tag")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
            }
            
            // Food-Leak Streak Pill
            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 10))
                    .foregroundColor(FinanceTheme.positive)
                
                Text("\(store.foodLeakFreeStreakDays) Tage lieferdienst-frei")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.positive)
                
                Spacer()
                
                Text(String(format: "+%.2f € gerettet", store.savedLeakCapitalTotal))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.positive)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(FinanceTheme.positive.opacity(0.08)))
            .overlay(Capsule().stroke(FinanceTheme.positive.opacity(0.25), lineWidth: 0.8))
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    // MARK: - 3-Color Dynamic Spectrum (Green -> Yellow -> Red)
    private func safeToSpendDynamicColor(amount: Double) -> Color {
        if amount <= 50 {
            return Color(red: 0.95, green: 0.25, blue: 0.25) // Rot (Kritisch)
        } else if amount <= 150 {
            // Rot zu Gelb
            let t = (amount - 50.0) / 100.0
            return Color(
                red: 0.95 + t * (1.0 - 0.95),
                green: 0.25 + t * (0.80 - 0.25),
                blue: 0.25 + t * (0.10 - 0.25)
            )
        } else if amount <= 350 {
            // Gelb zu Grün
            let t = (amount - 150.0) / 200.0
            return Color(
                red: 1.0 - t * (1.0 - 0.20),
                green: 0.80 + t * (0.82 - 0.80),
                blue: 0.10 + t * (0.40 - 0.10)
            )
        } else {
            return Color(red: 0.20, green: 0.82, blue: 0.40) // Grün (Ausreichend)
        }
    }
}

// MARK: - Subcomponent 5: Accounts Overview Section
public struct FinanceAccountsOverviewSection: View {
    public let accounts: [BankAccount]
    public let onSelectAccount: (BankAccount) -> Void
    public let onEditAccount: (BankAccount) -> Void
    
    public init(
        accounts: [BankAccount],
        onSelectAccount: @escaping (BankAccount) -> Void,
        onEditAccount: @escaping (BankAccount) -> Void
    ) {
        self.accounts = accounts
        self.onSelectAccount = onSelectAccount
        self.onEditAccount = onEditAccount
    }
    
    public var body: some View {
        let girokonten = accounts.filter { $0.type == .checking }
        let geldanlagen = accounts.filter { $0.type == .dailySavings || $0.type == .emergencyFund || $0.type == .savingsGoal }
        let finanzierungen = accounts.filter { $0.type == .loan }

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TARGOBANK KONTEN & SPARZIELE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
                Spacer()
                Text("Antippen für Details")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.accent)
            }

            // 1. Girokonten
            if !girokonten.isEmpty {
                FinanceAccountGroupCardView(
                    title: "GIROKONTEN",
                    accounts: girokonten,
                    onSelectAccount: onSelectAccount,
                    onEditAccount: onEditAccount
                )
            }

            // 2. Geldanlagen (5 Tagesgelder)
            if !geldanlagen.isEmpty {
                FinanceAccountGroupCardView(
                    title: "GELDANLAGEN",
                    accounts: geldanlagen,
                    onSelectAccount: onSelectAccount,
                    onEditAccount: onEditAccount
                )
            }

            // 3. Finanzierungen (Online-Kredit)
            if !finanzierungen.isEmpty {
                FinanceAccountGroupCardView(
                    title: "FINANZIERUNGEN",
                    accounts: finanzierungen,
                    onSelectAccount: onSelectAccount,
                    onEditAccount: onEditAccount
                )
            }
        }
        .padding(18)
        .background(FinanceTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: - Subcomponent 5a: Account Group Card View
public struct FinanceAccountGroupCardView: View {
    public let title: String
    public let accounts: [BankAccount]
    public let onSelectAccount: (BankAccount) -> Void
    public let onEditAccount: (BankAccount) -> Void
    
    public init(
        title: String,
        accounts: [BankAccount],
        onSelectAccount: @escaping (BankAccount) -> Void,
        onEditAccount: @escaping (BankAccount) -> Void
    ) {
        self.title = title
        self.accounts = accounts
        self.onSelectAccount = onSelectAccount
        self.onEditAccount = onEditAccount
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)

            ForEach(accounts) { acc in
                FinanceAccountCardView(
                    acc: acc,
                    onTapAccount: {
                        onSelectAccount(acc)
                    },
                    onEditAccount: {
                        onEditAccount(acc)
                    }
                )
            }
        }
    }
}

// MARK: - Subcomponent 5b: Individual Account Card View
public struct FinanceAccountCardView: View {
    public let acc: BankAccount
    public let onTapAccount: () -> Void
    public let onEditAccount: () -> Void
    
    public init(
        acc: BankAccount,
        onTapAccount: @escaping () -> Void,
        onEditAccount: @escaping () -> Void
    ) {
        self.acc = acc
        self.onTapAccount = onTapAccount
        self.onEditAccount = onEditAccount
    }
    
    public var body: some View {
        Button {
            onTapAccount()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: acc.type.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(acc.type == .loan ? FinanceTheme.terracotta : FinanceTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(acc.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(FinanceTheme.textPrimary)

                        Button {
                            onEditAccount()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(FinanceTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        if !acc.accountNumber.isEmpty {
                            Text("KTO: \(acc.accountNumber)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(FinanceTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                .foregroundColor(FinanceTheme.textSecondary)
                        }

                        if !acc.iban.isEmpty {
                            Text(acc.iban)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(acc.formattedBalance)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(acc.balance >= 0 ? FinanceTheme.textPrimary : FinanceTheme.terracotta)

                    if acc.type == .loan {
                        HStack(spacing: 3) {
                            Text("Avalanche & Tilgung")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(FinanceTheme.terracotta)
                    } else {
                        HStack(spacing: 4) {
                            if !acc.subAllocations.isEmpty {
                                Text("\(acc.subAllocations.count) Unterziele")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                            } else {
                                Text("Details")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(FinanceTheme.accent)
                        }
                    }
                }
            }
            .padding(14)
            .background(FinanceTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subcomponent 5c: Sub-Allocations Expanded Section
public struct FinanceSubAllocationsExpandedSection: View {
    public let acc: BankAccount
    public let onAddSubGoal: () -> Void
    public let onEditSubGoal: (SubAllocationEditContext) -> Void
    
    public init(
        acc: BankAccount,
        onAddSubGoal: @escaping () -> Void,
        onEditSubGoal: @escaping (SubAllocationEditContext) -> Void
    ) {
        self.acc = acc
        self.onAddSubGoal = onAddSubGoal
        self.onEditSubGoal = onEditSubGoal
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().background(FinanceTheme.surfaceBorder)

            // Section Header with Total Allocated & Unallocated Balance
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UNTERKATEGORIEN & SPARZIELE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    HStack(spacing: 8) {
                        Text("Zugewiesen: \(String(format: "%.2f €", acc.totalAllocated))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.sageGreen)
                        if acc.unallocatedBalance > 0.001 {
                            Text("Frei: \(String(format: "%.2f €", acc.unallocatedBalance))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.accent)
                        }
                    }
                }

                Spacer()

                Button {
                    onAddSubGoal()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Unterziel")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FinanceTheme.accent.opacity(0.15))
                    .foregroundColor(FinanceTheme.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if acc.subAllocations.isEmpty {
                HStack {
                    Text("Keine Unterkategorien angelegt. Der gesamte Saldo von \(acc.formattedBalance) ist frei verfuegbar.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                ForEach(acc.subAllocations) { sub in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: sub.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FinanceTheme.accent)
                                .frame(width: 24, height: 24)
                                .background(FinanceTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(sub.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                if !sub.notes.isEmpty {
                                    Text(sub.notes)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(sub.formattedAllocated) / \(sub.formattedTarget)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                Text(String(format: "%.0f%% erreicht", sub.progressFraction * 100))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(sub.progressFraction >= 1.0 ? FinanceTheme.sageGreen : FinanceTheme.textTertiary)
                            }

                            // Edit Button
                            Button {
                                onEditSubGoal(SubAllocationEditContext(
                                    accountId: acc.id,
                                    accountName: acc.name,
                                    subAllocation: sub
                                ))
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(FinanceTheme.accent)
                                    .padding(4)
                            }
                            .buttonStyle(.plain)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(FinanceTheme.surface).frame(height: 5)
                                Capsule()
                                    .fill(sub.progressFraction >= 1.0 ? FinanceTheme.sageGreen : FinanceTheme.accent)
                                    .frame(width: max(3, geo.size.width * CGFloat(sub.progressFraction)), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(10)
                    .background(FinanceTheme.surface.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEditSubGoal(SubAllocationEditContext(
                            accountId: acc.id,
                            accountName: acc.name,
                            subAllocation: sub
                        ))
                    }
                }
            }

            // Big, explicit Add-Unterziel Button at bottom of expanded KTO
            Button {
                onAddSubGoal()
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Neues Unterziel zu diesem Konto hinzufuegen")
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(FinanceTheme.accent.opacity(0.12))
                .foregroundColor(FinanceTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Subcomponent 6: Remaining Fixed Costs Card
public struct FinanceRemainingFixedCostsCardView: View {
    public let items: [MonthlyFixedCostItem]
    public let pendingTotal: Double
    @Binding public var isExpanded: Bool
    
    public init(items: [MonthlyFixedCostItem], pendingTotal: Double, isExpanded: Binding<Bool>) {
        self.items = items
        self.pendingTotal = pendingTotal
        self._isExpanded = isExpanded
    }
    
    public var body: some View {
        let pending = items.filter { !$0.isPaidThisMonth }
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("VERBLEIBENDE FIXKOSTEN DIESEN MONAT")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(FinanceTheme.textSecondary)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Weniger" : "Alle (\(items.count))")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.2f", pendingTotal))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(pendingTotal > 0 ? FinanceTheme.warning : FinanceTheme.positive)
                Text("EUR noch ausstehend")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textSecondary)
                Spacer()
            }
            
            VStack(spacing: 6) {
                let displayedItems = isExpanded ? items : (pending.isEmpty ? Array(items.prefix(3)) : pending)
                ForEach(displayedItems) { item in
                    HStack {
                        Image(systemName: item.isPaidThisMonth ? "checkmark.circle.fill" : "clock")
                            .font(.system(size: 11))
                            .foregroundColor(item.isPaidThisMonth ? FinanceTheme.positive : FinanceTheme.warning)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            Text("Fällig: ~\(item.expectedDayOfMonth). d. M.")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(String(format: "- %.2f €", item.expectedAmount))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(item.isPaidThisMonth ? FinanceTheme.textSecondary : FinanceTheme.warning)
                            Text(item.isPaidThisMonth ? "Abgebucht" : "Ausstehend")
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundColor(item.isPaidThisMonth ? FinanceTheme.positive : FinanceTheme.warning)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    if item.id != displayedItems.last?.id {
                        Divider()
                            .background(FinanceTheme.surfaceBorder.opacity(0.3))
                    }
                }
            }
        }
        .padding(14)
        .financeCardStyle()
    }
}

// MARK: - Subcomponent 7: Avalanche Debt Acceleration Engine Card
public struct FinanceAvalancheCardView: View {
    public let debtStatus: DebtStatus
    public let onInfoTapped: () -> Void
    
    public init(debtStatus: DebtStatus, onInfoTapped: @escaping () -> Void) {
        self.debtStatus = debtStatus
        self.onInfoTapped = onInfoTapped
    }
    
    public var body: some View {
        let progress = debtStatus.progressFraction
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(FinanceTheme.negative)
                    
                    Text("AVALANCHE-TILGUNG (TARGOBANK)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(FinanceTheme.textSecondary)
                    
                    Button {
                        onInfoTapped()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(FinanceTheme.accent)
                    }
                }
                
                Spacer()
                
                Text("ZIEL: JUNI 2027")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.positive)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FinanceTheme.surfaceBorder)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FinanceTheme.positive)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restschuld")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Text(String(format: "- %.2f €", debtStatus.remainingPrincipal))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.negative)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Monats-Tilgung")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Text(String(format: "%.2f €/Mo", debtStatus.totalMonthlyDebtServicing))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.positive)
                }
            }
        }
        .padding(14)
        .financeCardStyle()
    }
}

// MARK: - Subcomponent 8: Floating Action Cluster
public struct FinanceFloatingActionCluster: View {
    public let onImportCSVTapped: () -> Void
    
    public init(onImportCSVTapped: @escaping () -> Void) {
        self.onImportCSVTapped = onImportCSVTapped
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Upper: Solitary Circular Water Tracker (Synced across ecosystem)
            FinanceCircularWaterButton()
            
            // Middle: Circular Profile Button with Level Badge (1-999)
            FinanceCircularProfileButton()

            // Lower: Circular Add CSV Button
            Button {
                onImportCSVTapped()
            } label: {
                ZStack {
                    Circle()
                        .fill(FinanceTheme.surfaceRaised)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(FinanceTheme.accent.opacity(0.8), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FinanceTheme.accent)
                }
            }
            .accessibilityLabel("CSV-Datei importieren")
        }
    }
}

// MARK: - Subcomponent 9: Edit Account Sheet View
public struct EditAccountSheetView: View {
    public let account: BankAccount
    public let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var accountNameText: String
    
    public init(account: BankAccount, onSave: @escaping (String) -> Void) {
        self.account = account
        self.onSave = onSave
        self._accountNameText = State(initialValue: account.name)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kontonummer (Fest verankert & geschuetzt)")) {
                    HStack {
                        Text("Konto-Nummer:")
                        Spacer()
                        Text(account.accountNumber.isEmpty ? "Keine Nummer" : account.accountNumber)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    if !account.iban.isEmpty {
                        HStack {
                            Text("IBAN:")
                            Spacer()
                            Text(account.iban)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                }

                Section(header: Text("Kontoname anpassen")) {
                    TextField("Name (z.B. Karriere & Bildung, Notfallreserve)", text: $accountNameText)
                }

                Section(header: Text("Saldo (Exakte Targobank-Spiegelung)")) {
                    HStack {
                        Text("Aktueller Saldo:")
                        Spacer()
                        Text(account.formattedBalance)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                }
            }
            .navigationTitle("Konto umbenennen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(accountNameText)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Subcomponent 10: Add Income Sheet View
public struct AddIncomeSheetView: View {
    public let onSave: (String, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var amountText: String = ""
    
    public init(onSave: @escaping (String, Double) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Neue Einnahmequelle")) {
                    TextField("Bezeichnung (z.B. Nebenverdienst)", text: $name)
                    TextField("Monatlicher Betrag in EUR", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Einnahmequelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let clean = amountText.replacingOccurrences(of: ",", with: ".")
                        if let amt = Double(clean), amt > 0, !name.isEmpty {
                            onSave(name, amt)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Subcomponent 11: Smart Engine Report & Plan Sheet
public struct SmartEngineReportSheet: View {
    @ObservedObject private var store = FinanceStore.shared
    @Environment(\.presentationMode) var presentationMode
    
    private let engine = SmartFinanceEngine.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Section 1: Monatsbericht & Taktischer Plan
                        let report = engine.generateMonthlyReport(
                            monthlyTransactions: store.transactions,
                            totalSavings: store.totalSavingsBalance,
                            remainingLoan: store.totalLoanBalance
                        )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MONATSBERICHT & STRATEGIE (\(report.monthTitle.uppercased()))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.textSecondary)
                            
                            VStack(spacing: 6) {
                                reportRow(label: "Monatseinnahmen (Besoldung)", val: String(format: "+ %.2f €", report.incomeTotal), color: FinanceTheme.positive)
                                reportRow(label: "Gesamtausgaben", val: String(format: "- %.2f €", report.totalExpenses), color: FinanceTheme.textPrimary)
                                reportRow(label: "Getilgte Schulden", val: String(format: "%.2f €", report.debtServiced), color: FinanceTheme.positive)
                                reportRow(label: "Lieferdienst-Leaks geblockt", val: String(format: "%.2f €", store.savedLeakCapitalTotal), color: FinanceTheme.positive)
                            }
                            
                            Divider().background(FinanceTheme.surfaceBorder)
                            
                            Text("TAKTHISCHER 3-PUNKTE AKTIONSPLAN")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.accent)
                                .padding(.top, 4)
                            
                            ForEach(report.tacticalActionItems, id: \.self) { item in
                                Text(item)
                                    .font(.system(size: 11))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding(14)
                        .financeCardStyle()
                        
                        // Section 2: Szenario-Prognose (Monte Carlo)
                        let allowance = engine.calculateDailyAllowance(plusKontoBalance: store.plusKontoBalance, pendingFixedCosts: store.totalRemainingFixedCosts)
                        let scenarios = engine.runScenarioAnalysis(
                            plusKontoBalance: store.plusKontoBalance,
                            dailyAllowance: allowance.dailyLimitEur,
                            daysRemaining: allowance.daysRemainingUntilSalary,
                            historicalMonthlyLeak: 360.0
                        )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SZENARIO-SIMULATION BIS MONATSENDE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.textSecondary)
                            
                            ForEach(scenarios) { sc in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(sc.title)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(FinanceTheme.textPrimary)
                                        Spacer()
                                        Text(String(format: "Ende: %.2f €", sc.projectedMonthEndBalance))
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(sc.projectedMonthEndBalance >= 100 ? FinanceTheme.positive : FinanceTheme.warning)
                                    }
                                    
                                    Text(sc.directive)
                                        .font(.system(size: 10))
                                        .foregroundColor(FinanceTheme.textSecondary)
                                }
                                .padding(10)
                                .background(FinanceTheme.surfaceRaised)
                                .cornerRadius(8)
                            }
                        }
                        .padding(14)
                        .financeCardStyle()
                        
                        // Section 3: Kapital-Allokations-Direktiven (Wohin mit dem Geld)
                        let directives = engine.generateDirectives(
                            plusKonto: store.plusKontoBalance,
                            safeToSpend: store.safeToSpend,
                            totalSavings: store.totalSavingsBalance,
                            remainingLoan: store.totalLoanBalance,
                            foodLeakStreak: store.foodLeakFreeStreakDays
                        )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("KAPITAL-ALLOKATION: DIREKTIVEN")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.textSecondary)
                            
                            ForEach(directives) { d in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(d.priority)")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundColor(FinanceTheme.accent)
                                        .frame(width: 18)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(d.title)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(FinanceTheme.textPrimary)
                                            Spacer()
                                            Text(d.action)
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(d.isUrgent ? FinanceTheme.warning : FinanceTheme.positive)
                                        }
                                        Text(d.description)
                                            .font(.system(size: 10))
                                            .foregroundColor(FinanceTheme.textSecondary)
                                    }
                                }
                                .padding(8)
                                .background(FinanceTheme.surfaceRaised)
                                .cornerRadius(6)
                            }
                        }
                        .padding(14)
                        .financeCardStyle()
                        
                        // Section 4: Empirische Verhaltens-Prognose & Risikofenster
                        let trajectory = engine.predictMonthlyTrajectory(
                            currentBalance: store.plusKontoBalance,
                            pendingFixedCosts: store.totalRemainingFixedCosts,
                            transactions: store.transactions
                        )
                        let riskProfile = engine.analyzeTemporalVulnerability(
                            transactions: store.transactions
                        )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EMPIRISCHE VERHALTENS-PROGNOSE (CLOSED-LOOP)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.accent)
                            
                            VStack(spacing: 8) {
                                reportRow(
                                    label: "Prognostizierter Saldo zum 28.",
                                    val: String(format: "%.2f €", trajectory.projectedBalanceAtMonthEnd),
                                    color: trajectory.isDispoCollisionProjected ? FinanceTheme.terracotta : FinanceTheme.sageGreen
                                )
                                reportRow(
                                    label: "Empirische Tages-Burn-Rate",
                                    val: String(format: "%.2f €/Tag", trajectory.dailyBurnRateEur),
                                    color: FinanceTheme.textPrimary
                                )
                                if trajectory.isDispoCollisionProjected, let colDay = trajectory.collisionDayOfMonth {
                                    reportRow(
                                        label: "Dispo-Kollisions-Tag",
                                        val: "ca. \(colDay). des Monats",
                                        color: FinanceTheme.terracotta
                                    )
                                    reportRow(
                                        label: "Empfohlener Drossel-Satz",
                                        val: String(format: "%.2f €/Tag", trajectory.recommendedAdjustedDailyAllowance),
                                        color: FinanceTheme.accent
                                    )
                                }
                            }
                            
                            Divider().background(FinanceTheme.surfaceBorder)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HISTORISCHES RISIKOFENSTER")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: riskProfile.isCurrentlyHighRisk ? "exclamationmark.triangle.fill" : "shield.checkered")
                                        .font(.system(size: 12))
                                        .foregroundColor(riskProfile.isCurrentlyHighRisk ? FinanceTheme.warning : FinanceTheme.positive)
                                    Text(riskProfile.riskDescription)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(riskProfile.isCurrentlyHighRisk ? FinanceTheme.warning : FinanceTheme.textPrimary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(riskProfile.isCurrentlyHighRisk ? FinanceTheme.warning.opacity(0.1) : FinanceTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                HStack {
                                    Text("Hotspot: \(riskProfile.peakWeekday)s (\(riskProfile.peakHourRange))")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                    Spacer()
                                    Text("\(riskProfile.historicalLeakCount) Leaks (\(String(format: "%.2f €", riskProfile.historicalLeakVolumeEur)))")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(14)
                        .financeCardStyle()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Smart Engine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(FinanceTheme.accent)
                }
            }
        }
    }
    
    private func reportRow(label: String, val: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(FinanceTheme.textSecondary)
            Spacer()
            Text(val)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
