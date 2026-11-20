import SwiftUI

public struct FiveGateSimulatorView: View {
    @ObservedObject private var store = FinanceStore.shared
    
    // Form Inputs
    @State private var itemTitle: String = ""
    @State private var amountString: String = ""
    @State private var category: TransactionCategory = .entertainmentGaming
    @State private var hasUnresolvedRealLifeDuties: Bool = false
    @State private var simulationNotes: String = ""
    
    // Evaluation Result
    @State private var evaluationResult: FiveGateCheckResult? = nil
    
    public init() {}
    
    private var amountDouble: Double {
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0.0
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        
                        inputFormCard
                        
                        if let result = evaluationResult {
                            resultCard(result)
                        }
                        
                        quarantineShelfSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AUTONOME GOVERNANCE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(FinanceTheme.accent)
                Text("5-Gate Kauf-Pruefer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(FinanceTheme.textPrimary)
            }
            
            Spacer()
            
            FinanceCircularWaterButton()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Input Form
    private var inputFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ANSCHAFFUNGS-PARAMETER")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(FinanceTheme.textSecondary)
            
            VStack(spacing: 10) {
                // Item Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Produkt / Anschaffung")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    TextField("z. B. Sony Kopfhoerer, Amazon Gadget...", text: $itemTitle)
                        .font(.system(size: 13))
                        .padding(10)
                        .background(FinanceTheme.surfaceBorder.opacity(0.3))
                        .cornerRadius(6)
                        .foregroundColor(FinanceTheme.textPrimary)
                }
                
                // Amount
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kaufpreis (EUR)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinanceTheme.textSecondary)
                        TextField("0.00", text: $amountString)
                            #if os(iOS)
                            .decimalPadKeyboard()
                            #endif
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(10)
                            .background(FinanceTheme.surfaceBorder.opacity(0.3))
                            .cornerRadius(6)
                            .foregroundColor(FinanceTheme.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kategorie")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinanceTheme.textSecondary)
                        Picker("Kategorie", selection: $category) {
                            ForEach(TransactionCategory.allCases, id: \.self) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FinanceTheme.surfaceBorder.opacity(0.3))
                        .cornerRadius(6)
                    }
                }
                
                // Toggle: Unresolved duties
                Toggle(isOn: $hasUnresolvedRealLifeDuties) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Administrative Pflichten unerledigt?")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FinanceTheme.textPrimary)
                        Text("Spies-Meldung, Fuehrerschein-Antrag, Arzt-Termine o.ae. ungeloest?")
                            .font(.system(size: 10))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                }
                .tint(FinanceTheme.negative)
                .padding(.vertical, 4)
                
                // Trigger Button
                Button {
                    runAudit()
                } label: {
                    HStack {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("5-Gate Pruefprotokoll starten")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(FinanceTheme.accent)
                    .foregroundColor(FinanceTheme.background)
                    .cornerRadius(8)
                }
                .disabled(itemTitle.isEmpty || amountDouble <= 0)
                .opacity((itemTitle.isEmpty || amountDouble <= 0) ? 0.5 : 1.0)
            }
        }
        .padding(16)
        .financeCardStyle()
    }
    
    private func runAudit() {
        GrowHaptics.medium()
        
        let result = store.engine.evaluatePurchase(
            title: itemTitle,
            amount: amountDouble,
            category: category,
            hasUnresolvedRealLifeDuties: hasUnresolvedRealLifeDuties,
            currentBalance: store.currentEstimatedBalance,
            transactions: store.transactions
        )
        self.evaluationResult = result
    }
    
    // MARK: - Result Card
    private func resultCard(_ result: FiveGateCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PRUEFURTEIL (REGEL 6)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(FinanceTheme.textSecondary)
                
                Spacer()
                
                Text(result.verdict.displayName.uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(result.verdict.color.opacity(0.2))
                    .foregroundColor(result.verdict.color)
                    .cornerRadius(4)
            }
            
            Text(result.reason)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(FinanceTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Empirical Behavioral & Counterfactual Box
            VStack(alignment: .leading, spacing: 10) {
                Text("EMPIRISCHER VERHALTENS-CHECK (CLOSED-LOOP)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.accent)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TILGUNGS-VERZOEGERUNG")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        Text(String(format: "+%.1f Tage", result.debtRepaymentDelayDays))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.terracotta)
                        Text("Ziel: Juni 2027")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OPPORTUNITAETS-ZINSEN")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        Text(String(format: "%.2f €", result.opportunityCostEur))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.warning)
                        Text("13,73% p.a. Zinsverlust")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if let warning = result.riskWindowWarning {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FinanceTheme.warning)
                        Text(warning)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.warning)
                    }
                    .padding(8)
                    .background(FinanceTheme.warning.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if result.historicalMerchantTransactionsCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundColor(FinanceTheme.accent)
                        Text("Historisch: \(String(format: "%.2f €", result.historicalPastSpendOnMerchant)) in \(result.historicalMerchantTransactionsCount) Buchungen registriert.")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                    .padding(6)
                    .background(FinanceTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Divider()
                .background(FinanceTheme.surfaceBorder)
            
            // Gates Checklist
            VStack(spacing: 8) {
                gateStatusRow(title: "Gate 1: Keine Lebens-Blockaden", passed: result.gate1Passed)
                gateStatusRow(title: "Gate 2: Liquiditaet (>100 €) & Tilgungsdeckung", passed: result.gate2Passed)
                gateStatusRow(title: "Gate 3: Direkte Ziel-Konvergenz", passed: result.gate3Passed)
                gateStatusRow(title: "Gate 4: 72h-Anti-Leak Quarantäneschutz", passed: result.gate4Passed)
            }
            
            // Action buttons
            if result.requires72hQuarantine || result.verdict == .quarantine {
                Button {
                    store.addQuarantinedPurchase(
                        title: itemTitle,
                        amount: amountDouble,
                        category: category,
                        notes: result.reason
                    )
                    itemTitle = ""
                    amountString = ""
                    evaluationResult = nil
                } label: {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                        Text("In 72h-Abkuehlungs-Matrix uebertragen")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(FinanceTheme.warning)
                    .foregroundColor(FinanceTheme.background)
                    .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .financeCardStyle()
    }
    
    private func gateStatusRow(title: String, passed: Bool) -> some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(passed ? FinanceTheme.positive : FinanceTheme.negative)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FinanceTheme.textSecondary)
            Spacer()
            Text(passed ? "BESTANDEN" : "ABGELEHNT")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(passed ? FinanceTheme.positive : FinanceTheme.negative)
        }
    }
    
    // MARK: - Quarantine Shelf
    private var quarantineShelfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hourglass")
                    .font(.system(size: 12))
                    .foregroundColor(FinanceTheme.warning)
                
                Text("72H-ANTI-LEAK QUARANTAENE-REGAL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(FinanceTheme.textSecondary)
                
                Spacer()
                
                Text("\(store.quarantinedPurchases.filter { !$0.isResolved }.count) AKTIV")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
            }
            
            let activeItems = store.quarantinedPurchases.filter { !$0.isResolved }
            if activeItems.isEmpty {
                VStack(spacing: 8) {
                    Text("Keine Anschaffungen in der 72-Stunden-Quarantaene.")
                        .font(.system(size: 12))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Text("Impulskäufe ueber 50 EUR werden hier automatisch 72h geparkt, um Spontankaeufe zu eliminieren.")
                        .font(.system(size: 10))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(FinanceTheme.surfaceRaised)
                .cornerRadius(8)
            } else {
                ForEach(activeItems) { item in
                    quarantineCard(item)
                }
            }
        }
    }
    
    private func quarantineCard(_ item: QuarantinedPurchase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FinanceTheme.textPrimary)
                    Text("\(String(format: "%.2f", item.amount)) EUR • \(item.category.displayName)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Verbleibend")
                        .font(.system(size: 9))
                        .foregroundColor(FinanceTheme.textTertiary)
                    Text(item.remainingTimeFormatted)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(item.hoursRemaining > 0 ? FinanceTheme.warning : FinanceTheme.positive)
                }
            }
            
            HStack(spacing: 8) {
                // Cancel (Leak eliminated)
                Button {
                    store.updateQuarantinedPurchase(item, isCancelled: true)
                } label: {
                    Text("Kauf verwerfen (+ \(String(format: "%.0f", item.amount)) € gespart)")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(FinanceTheme.positive.opacity(0.15))
                        .foregroundColor(FinanceTheme.positive)
                        .cornerRadius(6)
                }
                
                // Approve if 72h passed
                if item.hoursRemaining <= 0 {
                    Button {
                        store.updateQuarantinedPurchase(item, isCancelled: false)
                    } label: {
                        Text("Freigeben")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(FinanceTheme.accent)
                            .foregroundColor(FinanceTheme.background)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .financeCardStyle()
    }
}
