import SwiftUI

// MARK: - SubAllocation Edit Context
public struct SubAllocationEditContext: Identifiable {
    public var id: String { subAllocation.id }
    public let accountId: String
    public let accountName: String
    public var subAllocation: AccountSubAllocation
    
    public init(accountId: String, accountName: String, subAllocation: AccountSubAllocation) {
        self.accountId = accountId
        self.accountName = accountName
        self.subAllocation = subAllocation
    }
}

public struct AccountsAndProfileView: View {
    @ObservedObject private var store = FinanceStore.shared
    @State private var showingAddAccountSheet: Bool = false
    @State private var showingAddIncomeSheet: Bool = false
    
    // Account editing & loan detail
    @State private var editingAccount: BankAccount? = nil
    @State private var editingAccountNameText: String = ""
    @State private var selectedLoanAccount: BankAccount? = nil

    // Sub-Allocation (Sparziele) expansion & management
    @State private var expandedAccountIds: Set<String> = []
    @State private var accountForNewSubGoal: BankAccount? = nil
    @State private var subAllocationToEdit: SubAllocationEditContext? = nil

    // New Account Form State
    @State private var newAccountName: String = ""
    @State private var newAccountType: AccountType = .bank
    @State private var newAccountBalanceText: String = "0.00"
    @State private var newAccountIBAN: String = ""

    // New Income Source Form State
    @State private var newIncomeName: String = ""
    @State private var newIncomeAmountText: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header: Total Net Income & Sources
                    profileIncomeCard

                    // Unified Targobank Accounts & Embedded Sub-Allocations (Sparziele)
                    accountsSection
                }
                .padding(16)
            }
            .background(FinanceTheme.background.ignoresSafeArea())
            .navigationTitle("Profil & Konten")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddIncomeSheet = true
                        } label: {
                            Label("Einnahmequelle hinzufuegen", systemImage: "arrow.down.circle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(FinanceTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddAccountSheet) {
                addAccountSheet
            }
            .sheet(isPresented: $showingAddIncomeSheet) {
                addIncomeSheet
            }
            .sheet(item: $editingAccount) { acc in
                editAccountSheet(account: acc)
            }
            .sheet(item: $selectedLoanAccount) { loan in
                LoanAccountDetailSheet(account: loan)
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
        }
    }

    // MARK: - 1. Profile & Income Sources Card
    private var profileIncomeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MONATLICHES NETTO-GESAMTEINKOMMEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f €", store.userProfile.monthlyNetIncome))
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

            ForEach(store.userProfile.incomeSources) { src in
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
                            store.deleteIncomeSource(id: src.id)
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

    // MARK: - 2. Unified Accounts Section (Girokonten, Geldanlagen, Finanzierungen)
    private var accountsSection: some View {
        let girokonten = store.accounts.filter { $0.type == .checking }
        let geldanlagen = store.accounts.filter { $0.type == .dailySavings || $0.type == .emergencyFund || $0.type == .savingsGoal }
        let finanzierungen = store.accounts.filter { $0.type == .loan }

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TARGOBANK KONTEN & SPARZIELE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
                Spacer()
                Text("Antippen zum Aufklappen")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.accent)
            }

            // 1. Girokonten
            if !girokonten.isEmpty {
                accountGroupCard(title: "GIROKONTEN", accounts: girokonten)
            }

            // 2. Geldanlagen (5 Tagesgelder)
            if !geldanlagen.isEmpty {
                accountGroupCard(title: "GELDANLAGEN", accounts: geldanlagen)
            }

            // 3. Finanzierungen (Online-Kredit)
            if !finanzierungen.isEmpty {
                accountGroupCard(title: "FINANZIERUNGEN", accounts: finanzierungen)
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

    private func accountGroupCard(title: String, accounts: [BankAccount]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)

            ForEach(accounts) { acc in
                accountCard(for: acc)
            }
        }
    }

    // MARK: - Individual Account Card (Unterziele hidden until tap on KTO)
    private func accountCard(for acc: BankAccount) -> some View {
        let isExpanded = expandedAccountIds.contains(acc.id)

        return VStack(alignment: .leading, spacing: 10) {
            // Tappable Header Card: Icon, Name, KTO, Balance, Chevron
            Button {
                if acc.type == .loan {
                    selectedLoanAccount = acc
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if expandedAccountIds.contains(acc.id) {
                            expandedAccountIds.remove(acc.id)
                        } else {
                            expandedAccountIds.insert(acc.id)
                        }
                    }
                }
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
                                editingAccount = acc
                                editingAccountNameText = acc.name
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
                                Text("Tilgungsdetails")
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
                                }
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(FinanceTheme.accent)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Unterziele are ONLY visible when this specific KTO is tapped and expanded
            if acc.type != .loan && isExpanded {
                subAllocationsExpandedSection(for: acc)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(FinanceTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Sub-Allocations (Sparziele) Expanded Section
    private func subAllocationsExpandedSection(for acc: BankAccount) -> some View {
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
                    accountForNewSubGoal = acc
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
                                subAllocationToEdit = SubAllocationEditContext(
                                    accountId: acc.id,
                                    accountName: acc.name,
                                    subAllocation: sub
                                )
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
                        subAllocationToEdit = SubAllocationEditContext(
                            accountId: acc.id,
                            accountName: acc.name,
                            subAllocation: sub
                        )
                    }
                }
            }

            // Big, explicit Add-Unterziel Button at bottom of expanded KTO
            Button {
                accountForNewSubGoal = acc
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
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

    // MARK: - Add Account Sheet
    private var addAccountSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kontodetails")) {
                    TextField("Kontoname (z.B. Barclays Visa, Bargeld)", text: $newAccountName)
                    Picker("Kategorie", selection: $newAccountType) {
                        Text("Bankkonto").tag(AccountType.bank)
                        Text("Kreditkarte").tag(AccountType.creditCard)
                        Text("Bargeld").tag(AccountType.cash)
                        Text("Andere (Brokerage/Depot)").tag(AccountType.other)
                        Text("Urlaubskonto").tag(AccountType.vacation)
                    }
                    TextField("Startsaldo (EUR)", text: $newAccountBalanceText)
                        .numbersAndPunctuationKeyboard()
                    TextField("IBAN / Notiz (optional)", text: $newAccountIBAN)
                }
            }
            .navigationTitle("Neues Konto")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingAddAccountSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufuegen") {
                        let cleanBal = newAccountBalanceText.replacingOccurrences(of: ",", with: ".")
                        let bal = Double(cleanBal) ?? 0.0
                        let acc = BankAccount(
                            name: newAccountName.isEmpty ? newAccountType.rawValue : newAccountName,
                            type: newAccountType,
                            balance: bal,
                            iban: newAccountIBAN
                        )
                        store.addAccount(acc)
                        newAccountName = ""
                        newAccountBalanceText = "0.00"
                        newAccountIBAN = ""
                        showingAddAccountSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Add Income Sheet
    private var addIncomeSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Neue Einnahmequelle")) {
                    TextField("Bezeichnung (z.B. Nebenverdienst)", text: $newIncomeName)
                    TextField("Monatlicher Betrag in EUR", text: $newIncomeAmountText)
                        .decimalPadKeyboard()
                }
            }
            .navigationTitle("Einnahmequelle")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingAddIncomeSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let clean = newIncomeAmountText.replacingOccurrences(of: ",", with: ".")
                        if let amt = Double(clean), amt > 0, !newIncomeName.isEmpty {
                            store.addIncomeSource(name: newIncomeName, amount: amt)
                        }
                        newIncomeName = ""
                        newIncomeAmountText = ""
                        showingAddIncomeSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Edit Account Sheet (Rename Account while preserving ID/Number)
    private func editAccountSheet(account: BankAccount) -> some View {
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
                    TextField("Name (z.B. Karriere & Bildung, Notfallreserve)", text: $editingAccountNameText)
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
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { editingAccount = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        store.updateAccountName(id: account.id, newName: editingAccountNameText)
                        editingAccount = nil
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Add SubGoal Sheet View (Independent local State)
public struct AddSubGoalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let account: BankAccount
    public let onAdd: (String, Double, Double, String, String) -> Void
    
    @State private var name: String = ""
    @State private var allocatedText: String = ""
    @State private var targetText: String = ""
    @State private var notes: String = ""
    @State private var icon: String = "target"
    
    public init(account: BankAccount, onAdd: @escaping (String, Double, Double, String, String) -> Void) {
        self.account = account
        self.onAdd = onAdd
        let initialFree = account.unallocatedBalance
        _allocatedText = State(initialValue: initialFree > 0 ? String(format: "%.2f", initialFree) : "0.00")
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Konto-Zuordnung")) {
                    HStack {
                        Text("Konto:")
                        Spacer()
                        Text(account.displayName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FinanceTheme.textPrimary)
                    }
                    HStack {
                        Text("Verfuegbarer Gesamtsaldo:")
                        Spacer()
                        Text(account.formattedBalance)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    HStack {
                        Text("Frei unzugeordnet:")
                        Spacer()
                        Text(String(format: "%.2f €", account.unallocatedBalance))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.accent)
                    }
                }
                
                Section(header: Text("Details des Unterziels")) {
                    TextField("Bezeichnung (z.B. B-Fuehrerschein, AHS-Matura, CompTIA)", text: $name)
                    TextField("Zugewiesener Betrag (EUR)", text: $allocatedText)
                        .decimalPadKeyboard()
                    TextField("Zielbetrag (EUR)", text: $targetText)
                        .decimalPadKeyboard()
                    TextField("Notizen / Verwendungszweck (optional)", text: $notes)
                }
                
                Section(header: Text("Symbol")) {
                    let icons = ["target", "car.fill", "graduationcap.fill", "laptopcomputer", "airplane.departure", "shield.fill", "cross.case.fill", "fork.knife", "banknote.fill", "house.fill"]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { ic in
                            Button {
                                icon = ic
                            } label: {
                                Image(systemName: ic)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 40, height: 40)
                                    .background(icon == ic ? FinanceTheme.accent : FinanceTheme.surfaceRaised)
                                    .foregroundColor(icon == ic ? FinanceTheme.background : FinanceTheme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Unterziel anlegen")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufuegen") {
                        let cleanAlloc = allocatedText.replacingOccurrences(of: ",", with: ".")
                        let cleanTgt = targetText.replacingOccurrences(of: ",", with: ".")
                        let alloc = Double(cleanAlloc) ?? 0.0
                        let tgt = Double(cleanTgt) ?? 0.0
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !trimmedName.isEmpty {
                            onAdd(trimmedName, alloc, tgt, icon, notes)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Edit SubGoal Sheet View (Independent local State)
public struct EditSubGoalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let context: SubAllocationEditContext
    public let onSave: (AccountSubAllocation) -> Void
    public let onDelete: () -> Void
    
    @State private var name: String
    @State private var allocatedText: String
    @State private var targetText: String
    @State private var notes: String
    @State private var icon: String
    @State private var showingDeleteConfirm: Bool = false
    
    public init(context: SubAllocationEditContext, onSave: @escaping (AccountSubAllocation) -> Void, onDelete: @escaping () -> Void) {
        self.context = context
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: context.subAllocation.name)
        _allocatedText = State(initialValue: String(format: "%.2f", context.subAllocation.allocatedAmount))
        _targetText = State(initialValue: String(format: "%.2f", context.subAllocation.targetAmount))
        _notes = State(initialValue: context.subAllocation.notes)
        _icon = State(initialValue: context.subAllocation.icon)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Konto: \(context.accountName)")) {
                    TextField("Bezeichnung des Unterziels", text: $name)
                    TextField("Zugewiesener Betrag (EUR)", text: $allocatedText)
                        .decimalPadKeyboard()
                    TextField("Zielbetrag (EUR)", text: $targetText)
                        .decimalPadKeyboard()
                    TextField("Notiz / Verwendungszweck", text: $notes)
                }
                
                Section(header: Text("Symbol")) {
                    let icons = ["target", "car.fill", "graduationcap.fill", "laptopcomputer", "airplane.departure", "shield.fill", "cross.case.fill", "fork.knife", "banknote.fill", "house.fill"]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { ic in
                            Button {
                                icon = ic
                            } label: {
                                Image(systemName: ic)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 40, height: 40)
                                    .background(icon == ic ? FinanceTheme.accent : FinanceTheme.surfaceRaised)
                                    .foregroundColor(icon == ic ? FinanceTheme.background : FinanceTheme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Unterziel unwiderruflich loeschen")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Unterziel anpassen")
            .inlineTitleDisplayMode()
            .confirmationDialog("Unterziel wirklich loeschen?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Loeschen", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let cleanAlloc = allocatedText.replacingOccurrences(of: ",", with: ".")
                        let cleanTgt = targetText.replacingOccurrences(of: ",", with: ".")
                        let alloc = Double(cleanAlloc) ?? context.subAllocation.allocatedAmount
                        let tgt = Double(cleanTgt) ?? context.subAllocation.targetAmount
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        var updated = context.subAllocation
                        updated.name = trimmedName.isEmpty ? context.subAllocation.name : trimmedName
                        updated.allocatedAmount = alloc
                        updated.targetAmount = tgt
                        updated.notes = notes
                        updated.icon = icon
                        
                        onSave(updated)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
