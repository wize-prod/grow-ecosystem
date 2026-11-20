import SwiftUI

public struct BudgetsDashboardView: View {
    @ObservedObject private var store = FinanceStore.shared
    @State private var selectedBudgetForEdit: CategoryBudget? = nil
    @State private var newLimitText: String = ""
    @State private var isFixedCostsExpanded: Bool = false

    private var budgetStatuses: [BudgetStatus] {
        store.smartEngine.calculateBudgetStatuses(
            budgets: store.budgets,
            transactions: store.transactions,
            plusKontoBalance: store.plusKontoBalance,
            pendingFixedCosts: store.totalRemainingFixedCosts,
            accounts: store.accounts
        )
    }

    private var hierarchyReport: HierarchyOfNeedsReport {
        store.hierarchyOfNeedsReport
    }

    private var totalBudgetLimit: Double {
        budgetStatuses.reduce(0.0) { $0 + $1.effectiveLimit }
    }

    private var totalSpentThisMonth: Double {
        budgetStatuses.reduce(0.0) { $0 + $1.spentThisMonth }
    }

    private var totalRemaining: Double {
        totalBudgetLimit - totalSpentThisMonth
    }

    public let embedInNavigationStack: Bool

    public init(embedInNavigationStack: Bool = true) {
        self.embedInNavigationStack = embedInNavigationStack
    }

    @ViewBuilder
    public var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                mainContent
                    .navigationTitle("Monatsbudgets")
            }
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Macro Summary Card
                macroHeaderCard

                // Verbleibende Fixkosten diesen Monat (Below Gesamtbudget)
                FinanceRemainingFixedCostsCardView(
                    items: store.recurringFixedCostsThisMonth,
                    pendingTotal: store.totalRemainingFixedCosts,
                    isExpanded: $isFixedCostsExpanded
                )

                // 9 Budget Cards Grid (Adaptive for iPad & iPhone)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 340), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(budgetStatuses) { status in
                        budgetCard(for: status)
                    }
                }
            }
            .padding(16)
        }
        .background(FinanceTheme.background.ignoresSafeArea())
        .sheet(item: $selectedBudgetForEdit) { b in
            editBudgetSheet(for: b)
        }
    }

    // MARK: - Macro Header Card
    private var macroHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GESAMTBUDGET DIESER MONAT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f €", totalBudgetLimit))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(FinanceTheme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(totalRemaining >= 0 ? "VERBLEIBEND" : "UEBERSCHRITTEN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(totalRemaining >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                    Text(String(format: "%@%.2f €", totalRemaining >= 0 ? "+" : "", totalRemaining))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(totalRemaining >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                }
            }

            // Macro Progress Bar
            let fraction = totalBudgetLimit > 0 ? min(1.0, max(0.0, totalSpentThisMonth / totalBudgetLimit)) : 0.0
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FinanceTheme.surfaceRaised)
                        .frame(height: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: fraction > 0.9 ? [FinanceTheme.alertRed, FinanceTheme.terracotta] : [FinanceTheme.sageGreen, FinanceTheme.strongBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(fraction), height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: "Ausgegeben: %.2f € (%.0f%%)", totalSpentThisMonth, fraction * 100))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(FinanceTheme.textSecondary)
                Spacer()
                Text("9 Kategorien aktiv")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
            }

            Divider()
                .background(FinanceTheme.surfaceBorder)

            // Envelope Rollover & Debt Sweep Protocol
            let ledger = store.rolloverLedger
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: EnvelopeRolloverType.sinkingFund.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FinanceTheme.sageGreen)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("SINKING FUNDS ANSPARUNG")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        Text(String(format: "+%.2f €", ledger.totalSinkingFundsAccumulated))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.sageGreen)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(FinanceTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: EnvelopeRolloverType.debtRepaymentSweep.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FinanceTheme.strongBlue)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("TARGOBANK SWEEP POOL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        Text(String(format: "+%.2f €", ledger.totalDebtSweepGenerated))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.strongBlue)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(FinanceTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
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

    // MARK: - Individual Budget Card
    private func budgetCard(for status: BudgetStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Category Icon, Title, Edit Button
            HStack(spacing: 10) {
                Image(systemName: status.budget.category.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(status.budget.category.color)
                    .frame(width: 34, height: 34)
                    .background(status.budget.category.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.budget.category.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FinanceTheme.textPrimary)
                    Text(String(format: "Budget: %.2f €", status.effectiveLimit))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }

                Spacer()

                Button {
                    selectedBudgetForEdit = status.budget
                    newLimitText = String(format: "%.2f", status.budget.monthlyLimit)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .padding(8)
                        .background(FinanceTheme.surfaceRaised)
                        .clipShape(Circle())
                }
            }

            // Remaining Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(String(format: "Ausgegeben: %.2f €", status.spentThisMonth))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(FinanceTheme.textPrimary)

                    Spacer()

                    let remaining = status.remainingAmount
                    Text(remaining >= 0 ? String(format: "%.2f € übrig", remaining) : String(format: "+%.2f € drüber", abs(remaining)))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(remaining >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FinanceTheme.surfaceRaised)
                            .frame(height: 8)

                        let barColor: Color = status.progressFraction > 0.95 ? FinanceTheme.terracotta : (status.progressFraction > 0.8 ? FinanceTheme.warmSand : status.budget.category.color)
                        Capsule()
                            .fill(barColor)
                            .frame(width: geo.size.width * CGFloat(min(1.0, status.progressFraction)), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Envelope Rollover Indicator
            let rolloverStatus = store.rolloverLedger.categoryStatuses.first(where: { $0.category == status.budget.category })
            if let ro = rolloverStatus {
                HStack(spacing: 6) {
                    Image(systemName: ro.type.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ro.type.color)
                    if ro.type == .sinkingFund {
                        Text(String(format: "Sinking Fund: +%.2f € Rücklage | Verfügbar: %.2f €", ro.accumulatedSinkingBalance, ro.availableEffectiveBudget))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                    } else {
                        Text(String(format: "Sweep-Regel: %.2f € Monatsrest tilgt Targobank", ro.remainingUnspentInCurrentCycle))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(FinanceTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()
                .background(FinanceTheme.surfaceBorder)

            // 6-Month Spending Sparkline / Trend
            VStack(alignment: .leading, spacing: 6) {
                Text("VERLAUF (LETZTE 6 MONATE)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                let maxHistory = max(1.0, status.monthlyHistory.map { $0.amount }.max() ?? 1.0)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(status.monthlyHistory.enumerated()), id: \.offset) { idx, point in
                        VStack(spacing: 4) {
                            let barHeight = max(4.0, (point.amount / maxHistory) * 40.0)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(idx == status.monthlyHistory.count - 1 ? status.budget.category.color : FinanceTheme.surfaceRaised)
                                .frame(height: barHeight)

                            Text(point.month)
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 54)
            }

            // Latest Transactions in this Category
            if !status.latestTransactions.isEmpty {
                Divider()
                    .background(FinanceTheme.surfaceBorder)

                VStack(alignment: .leading, spacing: 6) {
                    Text("LETZTE BUCHUNGEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)

                    ForEach(status.latestTransactions) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tx.displayRecipient)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                    .lineLimit(1)
                                Text(DateFormatter.localizedString(from: tx.date, dateStyle: .short, timeStyle: .none))
                                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                            }
                            Spacer()
                            Text(String(format: "%.2f €", abs(tx.amount)))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.terracotta)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(16)
        .background(FinanceTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Edit Budget Sheet
    private func editBudgetSheet(for budget: CategoryBudget) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Budget für \(budget.category.rawValue)")) {
                    HStack {
                        Text("Monatliches Limit:")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        TextField("EUR", text: $newLimitText)
                            #if os(iOS)
                            .decimalPadKeyboard()
                            #endif
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                }

                Section(header: Text("Standard-Vorgabe")) {
                    Button("Auf Standard zurücksetzen (\(String(format: "%.2f €", budget.category.defaultMonthlyLimit)))") {
                        newLimitText = String(format: "%.2f", budget.category.defaultMonthlyLimit)
                    }
                    .foregroundColor(FinanceTheme.accent)
                }
            }
            .navigationTitle("Limit anpassen")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        selectedBudgetForEdit = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let cleaned = newLimitText.replacingOccurrences(of: ",", with: ".")
                        if let val = Double(cleaned), val > 0 {
                            store.updateBudgetLimit(category: budget.category, newLimit: val)
                        }
                        selectedBudgetForEdit = nil
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

