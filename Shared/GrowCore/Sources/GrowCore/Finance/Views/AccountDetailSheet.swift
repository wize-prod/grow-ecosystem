import SwiftUI

public struct AccountDetailSheet: View {
    @ObservedObject private var store = FinanceStore.shared
    @Environment(\.dismiss) private var dismiss
    
    public let account: BankAccount
    @State private var selectedTab: Int = 0 // 0: Unterziele & Planung, 1: Transaktionsverlauf
    @State private var showingEditNameSheet: Bool = false
    @State private var showingAddSubGoalSheet: Bool = false
    @State private var subAllocationToEdit: SubAllocationEditContext? = nil
    
    public init(account: BankAccount) {
        self.account = account
    }
    
    // Live account state from store
    private var currentAccount: BankAccount {
        store.accounts.first(where: { $0.id == account.id }) ?? account
    }
    
    // Transactions matching this account
    private var accountTransactions: [BankTransaction] {
        store.transactions.filter { tx in
            if let txAccId = tx.accountId, !txAccId.isEmpty {
                return txAccId == currentAccount.id || txAccId == currentAccount.accountNumber
            }
            if !currentAccount.iban.isEmpty && tx.accountIBAN.contains(currentAccount.accountNumber) {
                return true
            }
            if currentAccount.isMainAccount && (tx.accountIBAN.contains("3201649568") || tx.accountIBAN.isEmpty || tx.accountIBAN == "DE28300209003201649568") {
                return true
            }
            return false
        }.sorted(by: { $0.date > $1.date })
    }
    
    private var totalInflows: Double {
        accountTransactions.filter { $0.amount > 0 }.reduce(0.0) { $0 + $1.amount }
    }
    
    private var totalOutflows: Double {
        accountTransactions.filter { $0.amount < 0 }.reduce(0.0) { $0 + abs($1.amount) }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Account Hero Card
                    accountHeroCard
                    
                    // 2. Tab Selector
                    tabSelector
                    
                    if selectedTab == 0 {
                        // Sub-Allocations & Goals
                        subAllocationsSection
                        
                        // If Checking account: show recurring fixed costs scheduled from Girokonto
                        if currentAccount.type == .checking {
                            recurringFixedCostsSection
                        }
                    } else {
                        // Account Transactions History
                        transactionsSection
                    }
                }
                .padding(16)
            }
            .background(FinanceTheme.background.ignoresSafeArea())
            .navigationTitle(currentAccount.displayName)
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showingEditNameSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Umbenennen")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FinanceTheme.accent)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            .sheet(isPresented: $showingEditNameSheet) {
                EditAccountSheetView(account: currentAccount) { newName in
                    store.updateAccountName(id: currentAccount.id, newName: newName)
                }
            }
            .sheet(isPresented: $showingAddSubGoalSheet) {
                AddSubGoalSheetView(account: currentAccount) { name, alloc, tgt, icon, notes in
                    store.addSubAllocation(
                        to: currentAccount.id,
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
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 580, idealWidth: 640, minHeight: 600, idealHeight: 700)
#endif
        .presentationDetents([.large])
    }
    
    // MARK: - Account Hero Card
    private var accountHeroCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentAccount.type.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    
                    HStack(spacing: 8) {
                        Text(currentAccount.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FinanceTheme.textPrimary)
                        
                        Button {
                            showingEditNameSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FinanceTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 8) {
                        if !currentAccount.accountNumber.isEmpty {
                            Text("KTO: \(currentAccount.accountNumber)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FinanceTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .foregroundColor(FinanceTheme.textSecondary)
                        }
                        
                        if !currentAccount.iban.isEmpty {
                            Text(currentAccount.iban)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: currentAccount.type.icon)
                    .font(.system(size: 26))
                    .foregroundColor(FinanceTheme.accent)
            }
            
            Divider().background(FinanceTheme.surfaceBorder)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AKTUELLER SALDO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(currentAccount.formattedBalance)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(currentAccount.balance >= 0 ? FinanceTheme.textPrimary : FinanceTheme.terracotta)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("UNTERZIELE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("\(currentAccount.subAllocations.count) ZUGEWIESEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FinanceTheme.accent.opacity(0.15))
                        .foregroundColor(FinanceTheme.accent)
                        .clipShape(Capsule())
                }
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
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 8) {
            tabButton(title: "Unterziele & Planung", index: 0, icon: "target")
            tabButton(title: "Buchungsverlauf (\(accountTransactions.count))", index: 1, icon: "clock.arrow.circlepath")
        }
    }
    
    private func tabButton(title: String, index: Int, icon: String) -> some View {
        Button {
            selectedTab = index
            HapticFeedback.light()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedTab == index ? FinanceTheme.accent : FinanceTheme.surfaceRaised)
            .foregroundColor(selectedTab == index ? FinanceTheme.background : FinanceTheme.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Sub-Allocations Section
    private var subAllocationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UNTERKATEGORIEN & SPARZIELE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    
                    HStack(spacing: 8) {
                        Text("Zugewiesen: \(String(format: "%.2f €", currentAccount.totalAllocated))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.sageGreen)
                        
                        if currentAccount.unallocatedBalance > 0.001 {
                            Text("Frei: \(String(format: "%.2f €", currentAccount.unallocatedBalance))")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.accent)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    showingAddSubGoalSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Unterziel")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(FinanceTheme.accent.opacity(0.15))
                    .foregroundColor(FinanceTheme.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if currentAccount.subAllocations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Keine Unterkategorien angelegt.\nDer gesamte Saldo von \(currentAccount.formattedBalance) ist frei verfuegbar.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(currentAccount.subAllocations) { sub in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: sub.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FinanceTheme.accent)
                                .frame(width: 32, height: 32)
                                .background(FinanceTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                
                                if !sub.notes.isEmpty {
                                    Text(sub.notes)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.2f €", sub.allocatedAmount))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.sageGreen)
                                
                                if sub.targetAmount > 0 {
                                    Text("Ziel: \(String(format: "%.2f €", sub.targetAmount))")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                }
                            }
                            
                            Button {
                                subAllocationToEdit = SubAllocationEditContext(
                                    accountId: currentAccount.id,
                                    accountName: currentAccount.displayName,
                                    subAllocation: sub
                                )
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(FinanceTheme.accent)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 4)
                        }
                        
                        // Progress bar if target is set
                        if sub.targetAmount > 0 {
                            let frac = min(1.0, max(0.0, sub.allocatedAmount / sub.targetAmount))
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(FinanceTheme.surfaceRaised)
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(frac >= 1.0 ? FinanceTheme.sageGreen : FinanceTheme.accent)
                                        .frame(width: max(0, g.size.width * CGFloat(frac)), height: 5)
                                }
                            }
                            .frame(height: 5)
                            
                            HStack {
                                Text(String(format: "%.0f%% erreicht", frac * 100))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(frac >= 1.0 ? FinanceTheme.sageGreen : FinanceTheme.textTertiary)
                                Spacer()
                                let rem = max(0.0, sub.targetAmount - sub.allocatedAmount)
                                if rem > 0 {
                                    Text("Noch \(String(format: "%.2f €", rem)) benoetigt")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
    
    // MARK: - Recurring Fixed Costs Section (Girokonto)
    private var recurringFixedCostsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WIEDERKEHRENDE FIXKOSTEN (GIROKONTO)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Geplante regelmaessige monatliche Abbuchungen")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                Spacer()
                Text(String(format: "%.2f €", store.totalRemainingFixedCosts))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.warning)
            }
            
            let list = store.recurringFixedCostsThisMonth
            if list.isEmpty {
                Text("Keine offenen Fixkosten fuer diesen Monat erfasst.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(list) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.isPaidThisMonth ? "checkmark.circle.fill" : "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(item.isPaidThisMonth ? FinanceTheme.sageGreen : FinanceTheme.warning)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            Text("Faellig am \(item.expectedDayOfMonth). des Monats")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "-%.2f €", item.expectedAmount))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(item.isPaidThisMonth ? FinanceTheme.textTertiary : FinanceTheme.terracotta)
                    }
                    .padding(.vertical, 4)
                    
                    if item.id != list.last?.id {
                        Divider().background(FinanceTheme.surfaceBorder)
                    }
                }
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
    
    // MARK: - Transactions History Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRANSAKTIONSVERLAUF")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Alle erfassten Buchungen fuer dieses Konto")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                Spacer()
                Text("Gesamt: \(accountTransactions.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
            }
            
            // Inflows & Outflows Metric
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EINZAHLUNGEN")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "+%.2f €", totalInflows))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.sageGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(FinanceTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AUSZAHLUNGEN")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "-%.2f €", totalOutflows))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.terracotta)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(FinanceTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if accountTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Noch keine individuellen Buchungen fuer dieses Konto erfasst.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                let df: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "dd.MM.yyyy"
                    return f
                }()
                
                ForEach(accountTransactions) { tx in
                    HStack(spacing: 12) {
                        Image(systemName: tx.amount >= 0 ? "arrow.up.left.circle.fill" : "arrow.down.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(tx.amount >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.partnerName.isEmpty ? tx.recipientOrPurpose : tx.partnerName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            
                            HStack(spacing: 6) {
                                Text(df.string(from: tx.date))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                                
                                if !tx.purpose.isEmpty {
                                    Text("• \(tx.purpose)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%@%.2f €", tx.amount >= 0 ? "+" : "", tx.amount))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(tx.amount >= 0 ? FinanceTheme.sageGreen : FinanceTheme.textPrimary)
                            
                            Text(tx.category.displayName)
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(FinanceTheme.surfaceRaised)
                                .foregroundColor(FinanceTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if tx.id != accountTransactions.last?.id {
                        Divider().background(FinanceTheme.surfaceBorder)
                    }
                }
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
