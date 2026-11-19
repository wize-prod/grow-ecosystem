import SwiftUI

public enum FinanceReportType: String, CaseIterable, Identifiable {
    case netWorth = "Nettovermögen"
    case categoryHistory = "Kategorien"
    case topCategories = "Top Kategorien"
    case subscriptions = "Abos & Fixkosten"
    case projection = "Projektion"
    case incomeVsExpense = "Einkommen / Ausgaben"
    case payees = "Empfänger"
    case tags = "Stichworte"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .netWorth: return "chart.line.uptrend.xyaxis"
        case .categoryHistory: return "list.bullet.indent"
        case .topCategories: return "chart.bar.xaxis"
        case .subscriptions: return "repeat"
        case .projection: return "sparkles"
        case .incomeVsExpense: return "arrow.left.arrow.right"
        case .payees: return "building.2.fill"
        case .tags: return "tag.fill"
        }
    }
}

public struct FinanceReportsView: View {
    @ObservedObject private var store = FinanceStore.shared
    @State public var selectedReport: FinanceReportType
    public let embedInNavigationStack: Bool
    public let scrollable: Bool
    @State private var selectedCategoryForHistory: TransactionCategory = .groceries
    @State private var isTopExpenses: Bool = true
    @State private var selectedPayeeForDetail: PayeeSummary? = nil
    @State private var selectedTagForDetail: TagSummary? = nil

    public init(selectedReport: FinanceReportType = .netWorth, embedInNavigationStack: Bool = true, scrollable: Bool = true) {
        self._selectedReport = State(initialValue: selectedReport)
        self.embedInNavigationStack = embedInNavigationStack
        self.scrollable = scrollable
    }

    @ViewBuilder
    public var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                reportsMainContent
                    .navigationTitle("Finanzberichte")
            }
        } else {
            reportsMainContent
        }
    }

    private var reportsContentVStack: some View {
        VStack(spacing: 16) {
            // Two-Leg Transfer Reconciler Banner
            if let summary = store.transferReconciliationSummary {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FinanceTheme.strongBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TWO-LEG TRANSFER RECONCILER AKTIV")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        Text(summary)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textPrimary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(FinanceTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FinanceTheme.strongBlue.opacity(0.3), lineWidth: 1)
                )
            }

            switch selectedReport {
            case .netWorth:
                netWorthReportView
            case .categoryHistory:
                categoryHistoryReportView
            case .topCategories:
                topCategoriesReportView
            case .subscriptions:
                subscriptionsReportView
            case .projection:
                projectionReportView
            case .incomeVsExpense:
                incomeVsExpenseReportView
            case .payees:
                payeesReportView
            case .tags:
                tagsReportView
            }
        }
        .padding(16)
    }

    private var reportsMainContent: some View {
        VStack(spacing: 0) {
            // Top Horizontal Report Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FinanceReportType.allCases) { report in
                        Button {
                            selectedReport = report
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: report.icon)
                                    .font(.system(size: 12, weight: .bold))
                                Text(report.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedReport == report ? FinanceTheme.accent : FinanceTheme.surfaceRaised)
                            .foregroundColor(selectedReport == report ? Color.black : FinanceTheme.textSecondary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(FinanceTheme.surface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(FinanceTheme.surfaceBorder),
                alignment: .bottom
            )

            // Report Content
            if scrollable {
                ScrollView {
                    reportsContentVStack
                }
            } else {
                reportsContentVStack
            }
        }
        .background(FinanceTheme.background.ignoresSafeArea())
        .sheet(item: $selectedPayeeForDetail) { payee in
            payeeDetailSheet(payee: payee)
        }
        .sheet(item: $selectedTagForDetail) { tag in
            tagDetailSheet(tag: tag)
        }
    }

    // MARK: - 1. Nettovermögen Report
    private var netWorthReportView: some View {
        let totalAssets = store.accounts
            .filter { $0.type != .loan }
            .reduce(0.0) { $0 + max(0.0, $1.balance) }
        let totalLiabilities = abs(store.totalLoanBalance)
        let netWorth = totalAssets - totalLiabilities

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("AKTUELLES NETTOVERMÖGEN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
                Text(String(format: "%@%.2f €", netWorth >= 0 ? "+" : "", netWorth))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(netWorth >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aktiva (Guthaben):")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                        Text(String(format: "+%.2f €", totalAssets))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(FinanceTheme.sageGreen)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Passiva (Verbindlichkeiten):")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                        Text(String(format: "-%.2f €", totalLiabilities))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(FinanceTheme.terracotta)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FinanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - 2. Kategoriezusammenfassung Report
    private var categoryHistoryReportView: some View {
        let summaries = store.smartEngine.calculateCategorySummaries(transactions: store.transactions)
        let activeSummary = summaries.first(where: { $0.categoryName == selectedCategoryForHistory.displayName }) ?? summaries.first

        return VStack(alignment: .leading, spacing: 16) {
            // Category Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionCategory.allCases) { cat in
                        Button {
                            selectedCategoryForHistory = cat
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                Text(cat.displayName)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategoryForHistory == cat ? cat.color : FinanceTheme.surfaceRaised)
                            .foregroundColor(selectedCategoryForHistory == cat ? Color.black : FinanceTheme.textSecondary)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            if let summary = activeSummary {
                // Summary KPI
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GESAMTVOLUMEN")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                            Text(String(format: "%.2f €", summary.totalAmount))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(FinanceTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("DURCHSCHNITT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                            Text(String(format: "%.2f €", summary.averageAmount))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(summary.color)
                        }
                    }

                    Text(String(format: "%d Buchungen insgesamt • %.1f%% der Gesamtausgaben", summary.transactionCount, summary.percentage))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FinanceTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
                )

                // Complete Transaction History for this Category
                VStack(alignment: .leading, spacing: 10) {
                    Text("VOLLSTAENDIGER VERLAUF")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)

                    if summary.transactions.isEmpty {
                        Text("Keine Buchungen in dieser Kategorie erfasst.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(FinanceTheme.textMuted)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(summary.transactions) { tx in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.displayRecipient)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(FinanceTheme.textPrimary)
                                    Text(DateFormatter.localizedString(from: tx.date, dateStyle: .medium, timeStyle: .none))
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textTertiary)
                                }
                                Spacer()
                                Text(String(format: "-%.2f €", abs(tx.amount)))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.terracotta)
                            }
                            .padding(.vertical, 4)
                            Divider().background(FinanceTheme.surfaceBorder)
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

            // Fixed Contracts & Insurances Register (Integrated directly into Abos & Fixkosten)
            let activeContracts = store.contracts.filter { !$0.isCancelled }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("VERTRAGS- UND VERSICHERUNGSREGISTER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Spacer()
                    Text("\(activeContracts.count) aktiv")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.accent)
                }

                ForEach(store.contracts) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(item.isCancelled ? FinanceTheme.textTertiary : FinanceTheme.accent)
                            .frame(width: 30, height: 30)
                            .background(FinanceTheme.surfaceRaised)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(item.isCancelled ? FinanceTheme.textTertiary : FinanceTheme.textPrimary)
                            Text("\(item.type.rawValue) • Tag \(item.billingDayOfMonth) • \(item.provider)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f €", item.monthlyAmount))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(item.isCancelled ? FinanceTheme.textTertiary : FinanceTheme.textPrimary)
                            
                            if item.isCancelled {
                                Text("GEKÜNDIGT")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.terracotta)
                            }
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
    }

    // MARK: - 3. Top Kategorien Report
    private var topCategoriesReportView: some View {
        let shares = store.smartEngine.calculateTopCategories(transactions: store.transactions, isExpense: isTopExpenses)

        return VStack(alignment: .leading, spacing: 16) {
            Picker("Modus", selection: $isTopExpenses) {
                Text("Ausgaben").tag(true)
                Text("Einnahmen").tag(false)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 14) {
                Text(isTopExpenses ? "TOP AUSGABEN-KATEGORIEN" : "TOP EINNAHMEN-QUELLEN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                ForEach(shares) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: item.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(item.color)
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            Spacer()
                            Text(String(format: "%.2f € (%.1f%%)", item.amount, item.percentage))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(isTopExpenses ? FinanceTheme.terracotta : FinanceTheme.sageGreen)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(FinanceTheme.surfaceRaised).frame(height: 7)
                                Capsule().fill(item.color)
                                    .frame(width: geo.size.width * CGFloat(min(1.0, item.percentage / 100.0)), height: 7)
                            }
                        }
                        .frame(height: 7)
                    }
                    .padding(.vertical, 4)
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

    // MARK: - 4. Abo-Auswertung Report
    private var subscriptionsReportView: some View {
        let metrics = store.smartEngine.calculateSubscriptionAnalytics(contracts: store.contracts, transactions: store.transactions)
        let totalMonthly = metrics.reduce(0.0) { $0 + $1.monthlyRate }
        let totalYearly = totalMonthly * 12.0

        return VStack(alignment: .leading, spacing: 16) {
            // Header KPI
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MONATLICHE ABO-KOSTEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f €", totalMonthly))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(FinanceTheme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("JAEHRLICHE BELASTUNG")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f € / Jahr", totalYearly))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.warmSand)
                }
            }
            .padding(18)
            .background(FinanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
            )

            // Individual Subscriptions Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("HISTORISCH AUSGEGEBENES GELD PRO ABO")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                ForEach(metrics) { sub in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.contract.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                Text("\(sub.contract.provider) • \(sub.contract.billingCycle)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.2f €/Mo", sub.monthlyRate))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textPrimary)
                                Text(String(format: "Bisher: %.2f €", sub.totalPaidHistorically))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.terracotta)
                            }
                        }

                        HStack {
                            Text(sub.contract.necessity.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(sub.contract.necessity.color.opacity(0.15))
                                .foregroundColor(sub.contract.necessity.color)
                                .clipShape(Capsule())

                            Spacer()

                            Text(String(format: "Projektion: %.2f €/Jahr", sub.yearlyProjectedCost))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textSecondary)
                        }
                    }
                    .padding(14)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(18)
            .background(FinanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
            )

            // Cadence Pattern Scanner & Stealth Price Hikes Section
            if !store.detectedCadences.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FinanceTheme.accent)
                        Text("CADENCE PATTERN SCANNER (ΔD & PREIS-RADAR)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }

                    ForEach(store.detectedCadences) { cad in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cad.counterparty)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(FinanceTheme.textPrimary)
                                    Text("Intervall: \(cad.cadence.rawValue) (~ \(String(format: "%.0f", cad.averageIntervalDays)) Tage)")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(cad.formattedLatestAmount)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(FinanceTheme.textPrimary)

                                    if cad.hasPriceHike {
                                        Text("Preissprung: \(cad.formattedPriceHikeDelta)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(FinanceTheme.terracotta)
                                    }
                                }
                            }

                            HStack(spacing: 8) {
                                if cad.hasPriceHike {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 8))
                                        Text("PREISERHÖHUNG ENTDECKT")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(FinanceTheme.terracotta.opacity(0.2))
                                    .foregroundColor(FinanceTheme.terracotta)
                                    .clipShape(Capsule())
                                }

                                if !cad.isRegisteredSubscription {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 8))
                                        Text("NEUES ABO ENTDECKT")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(FinanceTheme.warmSand.opacity(0.18))
                                    .foregroundColor(FinanceTheme.warmSand)
                                    .clipShape(Capsule())

                                    Button {
                                        store.adoptDetectedCadenceAsContract(cad)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 9, weight: .bold))
                                            Text("Als Fixkosten übernehmen")
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(FinanceTheme.accent)
                                        .foregroundColor(Color.black)
                                        .clipShape(Capsule())
                                    }
                                }

                                Spacer()

                                Text(DateFormatter.localizedString(from: cad.lastSeenDate, dateStyle: .short, timeStyle: .none))
                                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textTertiary)
                            }
                        }
                        .padding(12)
                        .background(FinanceTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(cad.hasPriceHike ? FinanceTheme.terracotta.opacity(0.4) : Color.clear, lineWidth: 1)
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

            // Fixed Contracts & Insurances Register (Integrated directly into Abos & Fixkosten)
            let activeContracts = store.contracts.filter { !$0.isCancelled }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("VERTRAGS- UND VERSICHERUNGSREGISTER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Spacer()
                    Text("\(activeContracts.count) aktiv")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.accent)
                }

                ForEach(store.contracts) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(item.isCancelled ? FinanceTheme.textTertiary : FinanceTheme.accent)
                            .frame(width: 30, height: 30)
                            .background(FinanceTheme.surfaceRaised)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(item.isCancelled ? FinanceTheme.textTertiary : FinanceTheme.textPrimary)
                            Text("\(item.type.rawValue) • Tag \(item.billingDayOfMonth) • \(item.provider)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f €", item.monthlyAmount))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(item.isCancelled ? FinanceTheme.textTertiary : FinanceTheme.textPrimary)
                            
                            if item.isCancelled {
                                Text("GEKÜNDIGT")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.terracotta)
                            }
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
    }

    // MARK: - 5. Jährliche Projektion Report
    private var projectionReportView: some View {
        let totalAssets = store.accounts.filter { $0.type != .loan }.reduce(0.0) { $0 + max(0.0, $1.balance) }
        let currentNet = totalAssets - abs(store.totalLoanBalance)
        let monthlySavings = 1000.00 // Sondertilgung + Rücklagenzuwachs
        let points = store.smartEngine.calculateAnnualNetWorthProjection(currentNetWorth: currentNet, monthlyNetSavings: monthlySavings)

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NETTOVERMOEGENS-PROJEKTION DIESES JAHR")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                if let endYear = points.last {
                    Text(String(format: "%@%.2f €", endYear.projectedNetWorth >= 0 ? "+" : "", endYear.projectedNetWorth))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(endYear.projectedNetWorth >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                    Text("Prognostizierter Stand zum 31. Dezember bei Fortführung der Tilgungsrate.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FinanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
            )

            // Month-by-month Trajectory
            VStack(alignment: .leading, spacing: 12) {
                Text("MONATLICHE ENTWICKLUNGSSTUFEN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                ForEach(points) { pt in
                    HStack {
                        Text(pt.monthName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FinanceTheme.textPrimary)
                        Spacer()
                        if pt.delta > 0 {
                            Text(String(format: "+%.2f €", pt.delta))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.sageGreen)
                        }
                        Text(String(format: "%@%.2f €", pt.projectedNetWorth >= 0 ? "+" : "", pt.projectedNetWorth))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(pt.projectedNetWorth >= 0 ? FinanceTheme.textPrimary : FinanceTheme.terracotta)
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
    }

    // MARK: - 6. Einkommen vs. Ausgaben Report
    private var incomeVsExpenseReportView: some View {
        let points = store.smartEngine.calculateMonthlyIncomeVsExpenses(transactions: store.transactions)

        return VStack(alignment: .leading, spacing: 16) {
            Text("MONATLICHE BILANZ (LETZTE 12 MONATE)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)

            ForEach(points) { m in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(m.monthName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(FinanceTheme.textPrimary)
                        Spacer()
                        Text(String(format: "%@%.2f € Delta", m.netSavings >= 0 ? "+" : "", m.netSavings))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(m.netSavings >= 0 ? FinanceTheme.sageGreen : FinanceTheme.terracotta)
                    }

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Einnahmen:")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                            Text(String(format: "+%.2f €", m.income))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.sageGreen)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ausgaben:")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                            Text(String(format: "-%.2f €", m.expenses))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(FinanceTheme.terracotta)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Sparquote:")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                            Text(String(format: "%.1f%%", m.savingsRate))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(m.savingsRate >= 20 ? FinanceTheme.sageGreen : FinanceTheme.accent)
                        }
                    }
                }
                .padding(14)
                .background(FinanceTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - 7. Fixkosten & Abos Report
    private var fixedCostsReportView: some View {
        let totalMonthly = store.contracts.filter { !$0.isCancelled }.reduce(0.0) { $0 + $1.monthlyAmount }

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GESAMTE MONATLICHE FIXKOSTEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(String(format: "%.2f €", totalMonthly))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(FinanceTheme.textPrimary)
                }
                Spacer()
                Text("\(store.contracts.filter { !$0.isCancelled }.count) Verträge aktiv")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(FinanceTheme.textSecondary)
            }
            .padding(18)
            .background(FinanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
            )

            // Contract list
            VStack(alignment: .leading, spacing: 10) {
                Text("VERTRAGS- UND VERSICHERUNGSREGISTER")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                ForEach(store.contracts) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(FinanceTheme.accent)
                            .frame(width: 30, height: 30)
                            .background(FinanceTheme.surfaceRaised)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            Text("\(item.type.rawValue) • Tag \(item.billingDayOfMonth) • \(item.provider)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }

                        Spacer()

                        Text(String(format: "%.2f €", item.monthlyAmount))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textPrimary)
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
    }

    // MARK: - 8. Zahlungsempfänger Report
    private var payeesReportView: some View {
        let payees = store.smartEngine.calculatePayees(transactions: store.transactions)

        return VStack(alignment: .leading, spacing: 16) {
            Text("TRANSAKTIONEN NACH EMPFAENGER / UNTERNEHMEN")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)

            ForEach(payees) { p in
                Button {
                    selectedPayeeForDetail = p
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.payeeName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FinanceTheme.textPrimary)
                            Text("\(p.transactionCount) Buchungen • Zuletzt: \(DateFormatter.localizedString(from: p.latestDate, dateStyle: .short, timeStyle: .none))")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textTertiary)
                        }

                        Spacer()

                        Text(String(format: "%.2f €", p.totalAmount))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.terracotta)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    .padding(14)
                    .background(FinanceTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - 9. Stichworte (Tags) Report
    private var tagsReportView: some View {
        let tags = store.smartEngine.calculateTags(transactions: store.transactions)

        return VStack(alignment: .leading, spacing: 16) {
            Text("TRANSAKTIONEN NACH STICHWORTEN (TAGS)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)

            ForEach(tags) { t in
                Button {
                    selectedTagForDetail = t
                } label: {
                    HStack {
                        Text(t.tagName)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(FinanceTheme.accent.opacity(0.15))
                            .clipShape(Capsule())

                        Text("\(t.count) Buchungen")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)

                        Spacer()

                        Text(String(format: "%.2f €", t.totalAmount))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textPrimary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    .padding(14)
                    .background(FinanceTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Detail Sheets
    private func payeeDetailSheet(payee: PayeeSummary) -> some View {
        NavigationStack {
            List(payee.transactions) { tx in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.purpose)
                            .font(.system(size: 13, weight: .bold))
                        Text(DateFormatter.localizedString(from: tx.date, dateStyle: .medium, timeStyle: .none))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    Spacer()
                    Text(String(format: "%+.2f €", tx.amount))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(tx.isDebit ? FinanceTheme.terracotta : FinanceTheme.sageGreen)
                }
            }
            .navigationTitle(payee.payeeName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { selectedPayeeForDetail = nil }
                }
            }
        }
    }

    private func tagDetailSheet(tag: TagSummary) -> some View {
        NavigationStack {
            List(tag.transactions) { tx in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.displayRecipient)
                            .font(.system(size: 13, weight: .bold))
                        Text(DateFormatter.localizedString(from: tx.date, dateStyle: .medium, timeStyle: .none))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    Spacer()
                    Text(String(format: "%+.2f €", tx.amount))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(tx.isDebit ? FinanceTheme.terracotta : FinanceTheme.sageGreen)
                }
            }
            .navigationTitle(tag.tagName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { selectedTagForDetail = nil }
                }
            }
        }
    }
}

