import SwiftUI

public struct LoanAccountDetailSheet: View {
    @ObservedObject private var store = FinanceStore.shared
    @Environment(\.dismiss) private var dismiss
    
    public let account: BankAccount
    @State private var selectedTab: Int = 0 // 0 = Uebersicht & Auto-Withdrawals, 1 = Transaktionsverlauf
    @State private var showingInfoSheet: Bool = false
    @State private var showingEditNameSheet: Bool = false
    
    public init(account: BankAccount) {
        self.account = account
    }
    
    private var currentAccount: BankAccount {
        store.accounts.first(where: { $0.id == account.id }) ?? account
    }
    
    // Filter past transactions matching loan account or debt servicing
    private var pastLoanTransactions: [BankTransaction] {
        store.transactions.filter { tx in
            if let accId = tx.accountId, accId == account.id || accId == account.accountNumber {
                return true
            }
            if tx.category == .debtServicing {
                return true
            }
            let lower = (tx.recipientOrPurpose + " " + tx.partnerName).lowercased()
            return lower.contains("7203978276") || lower.contains("kreditrate") || lower.contains("sondertilgung")
        }.sorted(by: { $0.date > $1.date })
    }
    
    // Compute total past principal & interest debited
    private var totalPastServicedAmount: Double {
        pastLoanTransactions.reduce(0.0) { sum, tx in
            sum + abs(tx.amount)
        }
    }
    
    // Scheduled future auto-withdrawals based on Targobank contracts
    private var scheduledAutoWithdrawals: [(date: Date, title: String, amount: Double, type: String)] {
        let cal = Calendar.current
        var list: [(date: Date, title: String, amount: Double, type: String)] = []
        let today = Date()
        
        // Generate next 6 upcoming scheduled auto-withdrawals
        for monthOffset in 0..<6 {
            guard let futureMonth = cal.date(byAdding: .month, value: monthOffset, to: today) else { continue }
            var components = cal.dateComponents([.year, .month], from: futureMonth)
            components.day = 1
            guard let firstOfMonth = cal.date(from: components) else { continue }
            
            // Only add if on or after current month
            if firstOfMonth >= cal.startOfDay(for: today) || monthOffset == 0 {
                list.append((
                    date: firstOfMonth,
                    title: "Targobank Kreditrate",
                    amount: 274.70,
                    type: "Regulaere Zwangstilgung"
                ))
                list.append((
                    date: firstOfMonth,
                    title: "Targobank Sondertilgung",
                    amount: 1000.00,
                    type: "Avalanche Sondertilgung"
                ))
            }
        }
        return list.sorted(by: { $0.date < $1.date })
    }
    
    private var monthsUntilDebtFreedom: Int {
        let monthlyPayment = 1274.70
        let currentDebt = abs(account.balance)
        guard monthlyPayment > 0 else { return 0 }
        return Int(ceil(currentDebt / monthlyPayment))
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Account Identity & Balance Hero
                    accountHeroCard
                    
                    // 2. Avalanche Tilgung Engine
                    FinanceAvalancheCardView(
                        debtStatus: store.activeDebtStatus,
                        onInfoTapped: {
                            showingInfoSheet = true
                            HapticFeedback.light()
                        }
                    )
                    
                    // 3. Tab Selector
                    tabSelector
                    
                    if selectedTab == 0 {
                        // Metrics: Total debited, Monthly burn rate, Amortization
                        metricsSummaryCard
                        
                        // Future Scheduled Auto-Withdrawals
                        futureAutoWithdrawalsSection
                    } else {
                        // Past Transactions History
                        pastTransactionsSection
                    }
                }
                .padding(16)
            }
            .background(FinanceTheme.background.ignoresSafeArea())
            .navigationTitle("Finanzierungsdetails")
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $showingInfoSheet) {
                FinanceInfoExplanationSheet(topic: .avalancheTilgung)
            }
            .sheet(isPresented: $showingEditNameSheet) {
                EditAccountSheetView(account: currentAccount) { newName in
                    store.updateAccountName(id: currentAccount.id, newName: newName)
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
                    Text(currentAccount.name.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    
                    Text("TARGOBANK ONLINE-KREDIT")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(FinanceTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text("KTO: \(currentAccount.accountNumber)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FinanceTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .foregroundColor(FinanceTheme.textSecondary)
                        
                        if !currentAccount.iban.isEmpty {
                            Text(currentAccount.iban)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(FinanceTheme.terracotta)
            }
            
            Divider().background(FinanceTheme.surfaceBorder)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OFFENER RESTSALDO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(currentAccount.formattedBalance)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.terracotta)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("STATUS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("AKTIVE TILGUNG")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FinanceTheme.terracotta.opacity(0.15))
                        .foregroundColor(FinanceTheme.terracotta)
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
            tabButton(title: "Planung & Abbuchungen", index: 0, icon: "calendar.badge.clock")
            tabButton(title: "Verlauf (\(pastLoanTransactions.count))", index: 1, icon: "clock.arrow.circlepath")
        }
    }
    
    private func tabButton(title: String, index: Int, icon: String) -> some View {
        Button {
            selectedTab = index
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
    
    // MARK: - Metrics Summary Card
    private var metricsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TILGUNGS-KENNZAHLEN & PROGNOSE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCell(
                    title: "Bisher getilgt (Gesamt)",
                    value: String(format: "%.2f €", totalPastServicedAmount),
                    color: FinanceTheme.sageGreen,
                    subtitle: "Erfasste Zahlungsabfluesse"
                )
                
                metricCell(
                    title: "Monatlicher Abfluss",
                    value: "1.274,70 €",
                    color: FinanceTheme.textPrimary,
                    subtitle: "274,70 € Rate + 1.000 € Sondertilgung"
                )
                
                metricCell(
                    title: "Regulaere Kreditrate",
                    value: "274,70 €",
                    color: FinanceTheme.textSecondary,
                    subtitle: "Auto-Lastschrift (1. des Monats)"
                )
                
                metricCell(
                    title: "Monatliche Sondertilgung",
                    value: "1.000,00 €",
                    color: FinanceTheme.accent,
                    subtitle: "Avalanche-Zinsminimierung"
                )
            }
            
            Divider().background(FinanceTheme.surfaceBorder)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROGNOSTIZIERTE RESTLAUFZEIT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("ca. \(monthsUntilDebtFreedom) Monate bis Schuldenfreiheit")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FinanceTheme.sageGreen)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(FinanceTheme.sageGreen)
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
    
    private func metricCell(title: String, value: String, color: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(FinanceTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Future Auto-Withdrawals Section
    private var futureAutoWithdrawalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GEPLANTE AUTO-ABBUCHUNGEN (FIXKOSTEN)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Automatische Lastschriften & geplante Sondertilgungen")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                Spacer()
                Text("Monatlich 1.274,70 €")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.accent)
            }
            
            let dateFormatter: DateFormatter = {
                let df = DateFormatter()
                df.dateFormat = "dd.MM.yyyy"
                return df
            }()
            
            ForEach(Array(scheduledAutoWithdrawals.prefix(8).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FinanceTheme.accent)
                        Text(dateFormatter.string(from: item.date))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    .frame(width: 70)
                    .padding(.vertical, 6)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FinanceTheme.textPrimary)
                        Text(item.type)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "-%.2f €", item.amount))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.terracotta)
                        Text("AUTO")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(FinanceTheme.surfaceRaised)
                            .foregroundColor(FinanceTheme.accent)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
                
                Divider().background(FinanceTheme.surfaceBorder)
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
    
    // MARK: - Past Transactions History
    private var pastTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VERGANGENE ABBUCHUNGEN & ZAHLUNGEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text("Erfasste Tilgungsbuchungen fuer dieses Darlehenskonto")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                Spacer()
                Text("Gesamt: \(pastLoanTransactions.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
            }
            
            if pastLoanTransactions.isEmpty {
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
                
                ForEach(pastLoanTransactions) { tx in
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(FinanceTheme.terracotta)
                        
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
                            Text(String(format: "%.2f €", tx.amount))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.terracotta)
                            
                            Text("VERBUCHT")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(FinanceTheme.sageGreen.opacity(0.15))
                                .foregroundColor(FinanceTheme.sageGreen)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if tx.id != pastLoanTransactions.last?.id {
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

