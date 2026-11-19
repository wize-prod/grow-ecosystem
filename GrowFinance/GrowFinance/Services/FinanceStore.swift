import Foundation
import SwiftUI
import Combine

@MainActor
public final class FinanceStore: ObservableObject {
    public static let shared = FinanceStore()
    
    public static let liveTargobankAccounts: [BankAccount] = [
        BankAccount(
            accountNumber: "3201649568",
            name: "PLUS-KONTO (Gesundheit & Operativ)",
            type: .checking,
            balance: 2292.19,
            iban: "DE28 3002 0900 3201 6495 68",
            isMainAccount: true,
            subAllocations: [
                AccountSubAllocation(name: "Lebensmittel & Ernährung", allocatedAmount: 350.00, targetAmount: 350.00, icon: "fork.knife", notes: "Monatlicher Truppenküche- & Lebensmittelbedarf"),
                AccountSubAllocation(name: "Supplements & Apotheke", allocatedAmount: 150.00, targetAmount: 150.00, icon: "cross.case.fill", notes: "Zirkadianer Supplement-Stack & Reha-Bedarf"),
                AccountSubAllocation(name: "BWK Ulm Reha & Physio", allocatedAmount: 80.00, targetAmount: 100.00, icon: "figure.walk", notes: "Funktionelles Rumpf- & Viszeral-Training")
            ]
        ),
        BankAccount(
            accountNumber: "5211062413",
            name: "TAGESGELDKONTO (Entschuldung & Tilgung)",
            type: .dailySavings,
            balance: 2317.12,
            iban: "DE10 3002 0900 5211 0624 13",
            subAllocations: [
                AccountSubAllocation(name: "Targobank Sondertilgung Puffer", allocatedAmount: 2000.00, targetAmount: 2000.00, icon: "banknote.fill", notes: "2 Monate Puffer für 1.000 EUR Sondertilgung"),
                AccountSubAllocation(name: "AOK Tilgungs-Rücklage", allocatedAmount: 317.12, targetAmount: 700.00, icon: "doc.text.fill", notes: "AOK Tilgungsreserve")
            ]
        ),
        BankAccount(
            accountNumber: "5221062404",
            name: "TAGESGELDKONTO (Taktische Reserve)",
            type: .dailySavings,
            balance: 0.00,
            iban: "DE44 3002 0900 5221 0624 04",
            subAllocations: [
                AccountSubAllocation(name: "Dienstliche Zusatzausrüstung", allocatedAmount: 0.00, targetAmount: 500.00, icon: "shield.fill", notes: "Militärische Zusatzausrüstung"),
                AccountSubAllocation(name: "Hardware & Mac Zubehör", allocatedAmount: 0.00, targetAmount: 500.00, icon: "desktopcomputer", notes: "Hardware & Zubehör")
            ]
        ),
        BankAccount(
            accountNumber: "5231062411",
            name: "TAGESGELDKONTO (Karriere & Bildung)",
            type: .dailySavings,
            balance: 2.35,
            iban: "DE34 3002 0900 5231 0624 11",
            subAllocations: [
                AccountSubAllocation(name: "B-Führerschein (theorie24)", allocatedAmount: 2.35, targetAmount: 2500.00, icon: "car.fill", notes: "Fahrschule & theorie24 Prüfungsgebühren"),
                AccountSubAllocation(name: "AHS-Matura Salzburg", allocatedAmount: 0.00, targetAmount: 500.00, icon: "graduationcap.fill", notes: "Prüfungsmodule & Lehrmaterial"),
                AccountSubAllocation(name: "CompTIA Security+ / A+", allocatedAmount: 0.00, targetAmount: 800.00, icon: "laptopcomputer", notes: "CyberSecurity Zertifikate")
            ]
        ),
        BankAccount(
            accountNumber: "5271062409",
            name: "TAGESGELDKONTO (Urlaub & Regeneration)",
            type: .dailySavings,
            balance: 0.47,
            iban: "DE28 3002 0900 5271 0624 09",
            subAllocations: [
                AccountSubAllocation(name: "Urlaub & Erholung", allocatedAmount: 0.47, targetAmount: 1500.00, icon: "airplane.departure", notes: "Regenerationsurlaub"),
                AccountSubAllocation(name: "Familienbesuche & Heimfahrten", allocatedAmount: 0.00, targetAmount: 500.00, icon: "house.fill", notes: "Bahn & Reisekosten")
            ]
        ),
        BankAccount(
            accountNumber: "5291062407",
            name: "TAGESGELDKONTO (Notfallfonds 3 Monate)",
            type: .dailySavings,
            balance: 6000.00,
            iban: "DE52 3002 0900 5291 0624 07",
            subAllocations: [
                AccountSubAllocation(name: "Existenzminimum Notfallfonds", allocatedAmount: 6000.00, targetAmount: 6000.00, icon: "shield.lefthalf.filled", notes: "Feste Notfallreserve (3 Monatsgehälter)")
            ]
        ),
        BankAccount(
            accountNumber: "7203978276",
            name: "ONLINE-KREDIT",
            type: .loan,
            balance: -11333.21,
            iban: "DE35 3002 0900 7203 9782 76"
        )
    ]
    
    // Published State
    @Published public var accounts: [BankAccount] = []
    @Published public var selectedAccountId: String? = nil
    @Published public var transactions: [BankTransaction] = []
    @Published public var screenshotRecords: [TargobankScreenshotRecord] = []
    @Published public var quarantinedPurchases: [QuarantinedPurchase] = []
    @Published public var selectedFilterCategory: TransactionCategory? = nil
    @Published public var selectedDatePreset: DateFilterPreset = .all
    @Published public var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published public var customEndDate: Date = Date()
    @Published public var searchQuery: String = ""
    @Published public var isImportingFile: Bool = false
    @Published public var importErrorMessage: String? = nil
    @Published public var lastImportCount: Int = 0
    @Published public var lastImportReport: HaushaltsbuchImportReport? = nil
    
    // User Profile, Budgets, Subscriptions & Contracts
    @Published public var userProfile: UserProfile = UserProfile()
    @Published public var budgets: [CategoryBudget] = []
    @Published public var contracts: [FinanceContractOrSubscription] = []
    
    // Cadence Pattern Scanner & Envelope Rollovers
    @Published public var detectedCadences: [DetectedCadencePattern] = []
    @Published public var rolloverLedger: EnvelopeRolloverLedger = EnvelopeRolloverLedger()
    @Published public var transferReconciliationSummary: String? = nil
    
    // Water synchronization state
    @Published public var currentWaterMl: Double = 0
    @Published public var targetWaterMl: Double = 3500
    
    // Engines & Diagnostics
    public let engine = AutonomousFinanceEngine()
    public let smartEngine = SmartFinanceEngine.shared
    
    // Daily Notes & Calendar
    @Published public var dailyNotes: [String: String] = [:]
    
    // Storage Paths
    private let accountsFileUrl: URL
    private let transactionsFileUrl: URL
    private let quarantineFileUrl: URL
    private let screenshotsFileUrl: URL
    private let dailyNotesFileUrl: URL
    private let profileFileUrl: URL
    private let budgetsFileUrl: URL
    private let contractsFileUrl: URL
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let directory = appSupport.appendingPathComponent("GrowFinance", isDirectory: true)
        
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.accountsFileUrl = directory.appendingPathComponent("accounts.json")
        self.transactionsFileUrl = directory.appendingPathComponent("transactions.json")
        self.quarantineFileUrl = directory.appendingPathComponent("quarantine.json")
        self.screenshotsFileUrl = directory.appendingPathComponent("screenshots.json")
        self.dailyNotesFileUrl = directory.appendingPathComponent("daily_notes.json")
        self.profileFileUrl = directory.appendingPathComponent("user_profile.json")
        self.budgetsFileUrl = directory.appendingPathComponent("budgets.json")
        self.contractsFileUrl = directory.appendingPathComponent("contracts.json")
        
        loadSavedData()
        setupWaterSynchronization()
        setupGroceryReceiptSynchronization()
        autoAllocateSubAllocationsInsideAccounts()
    }
    
    // MARK: - Computed Properties
    public var selectedAccount: BankAccount? {
        guard let id = selectedAccountId else { return nil }
        return accounts.first { $0.id == id }
    }
    
    public var filteredTransactions: [BankTransaction] {
        var list = transactions
        
        // Filter by active account if selected
        if let accountId = selectedAccountId, let account = selectedAccount {
            list = list.filter { tx in
                if let txAccId = tx.accountId, !txAccId.isEmpty {
                    return txAccId == accountId
                }
                // Fallback matching by IBAN or account number
                if !account.iban.isEmpty && tx.accountIBAN.contains(account.accountNumber) {
                    return true
                }
                if account.isMainAccount && (tx.accountIBAN.contains("3201649568") || tx.accountIBAN.isEmpty || tx.accountIBAN == "DE28300209003201649568") {
                    return true
                }
                return false
            }
        }
        
        // Filter by category
        if let category = selectedFilterCategory {
            list = list.filter { $0.category == category }
        }
        
        // Filter by date preset or custom range
        let cal = Calendar.current
        let now = Date()
        switch selectedDatePreset {
        case .all:
            break
        case .thisMonth:
            list = list.filter {
                cal.isDate($0.date, equalTo: now, toGranularity: .month) &&
                cal.isDate($0.date, equalTo: now, toGranularity: .year)
            }
        case .lastMonth:
            if let lastMonthDate = cal.date(byAdding: .month, value: -1, to: now) {
                list = list.filter {
                    cal.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month) &&
                    cal.isDate($0.date, equalTo: lastMonthDate, toGranularity: .year)
                }
            }
        case .last30Days:
            if let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) {
                list = list.filter { $0.date >= thirtyDaysAgo }
            }
        case .last90Days:
            if let ninetyDaysAgo = cal.date(byAdding: .day, value: -90, to: now) {
                list = list.filter { $0.date >= ninetyDaysAgo }
            }
        case .thisYear:
            list = list.filter {
                cal.isDate($0.date, equalTo: now, toGranularity: .year)
            }
        case .custom:
            let start = cal.startOfDay(for: customStartDate)
            let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
            list = list.filter { $0.date >= start && $0.date <= end }
        }
        
        // Filter by search query (including date search)
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let q = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            list = list.filter {
                $0.purpose.lowercased().contains(q) ||
                $0.partnerName.lowercased().contains(q) ||
                $0.category.displayName.lowercased().contains(q) ||
                String(format: "%.2f", $0.amount).contains(q) ||
                $0.matchesDateQuery(q)
            }
        }
        return list.sorted { $0.date > $1.date }
    }
    
    public var currentEstimatedBalance: Double {
        if let account = selectedAccount {
            return account.balance
        }
        return plusKontoBalance
    }
    
    public var plusKontoBalance: Double {
        accounts.first(where: { $0.type == .checking })?.balance ?? 202.49
    }
    
    public var totalLiquidBalance: Double {
        plusKontoBalance
    }
    
    public var totalSavingsBalance: Double {
        accounts.filter { $0.type != .checking && $0.type != .loan }.reduce(0.0) { $0 + $1.balance }
    }
    
    public var totalLoanBalance: Double {
        accounts.filter { $0.type == .loan }.reduce(0.0) { $0 + $1.balance }
    }
    
    public var netWorth: Double {
        plusKontoBalance + totalSavingsBalance + totalLoanBalance
    }
    
    public var emergencyFundBalance: Double {
        accounts.filter { $0.type == .emergencyFund }.reduce(0.0) { $0 + $1.balance }
    }
    
    // MARK: - Recurring Fixed Costs Tracking
    public var recurringFixedCostsThisMonth: [MonthlyFixedCostItem] {
        let calendar = Calendar.current
        let now = Date()
        let thisMonthTxs = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        
        let templates: [(id: String, name: String, amount: Double, day: Int, cat: TransactionCategory, match: (BankTransaction) -> Bool)] = [
            ("tilgung", "Targobank Sondertilgung", 1000.00, 1, .debtServicing, { $0.partnerName.lowercased().contains("sondertilgung") || $0.purpose.lowercased().contains("sondertilgung") }),
            ("kreditrate", "Targobank Kreditrate", 274.70, 1, .debtServicing, { $0.partnerName.lowercased().contains("kreditrate") || $0.purpose.lowercased().contains("kredit 00007203978276") }),
            ("o2_haupt", "Telefonica O2 Tarif", 95.05, 20, .fixedContracts, { ($0.partnerName.lowercased().contains("telefonica") || $0.purpose.lowercased().contains("telefonica")) && abs($0.amount) > 50.0 }),
            ("o2_rate1", "Telefonica Ratenplan 1", 22.50, 26, .fixedContracts, { ($0.partnerName.lowercased().contains("telefonica") || $0.purpose.lowercased().contains("telefonica")) && abs($0.amount - (-22.50)) < 1.0 }),
            ("o2_rate2", "Telefonica Ratenplan 2", 8.00, 27, .fixedContracts, { ($0.partnerName.lowercased().contains("telefonica") || $0.purpose.lowercased().contains("telefonica")) && abs($0.amount - (-8.00)) < 1.0 }),
            ("google", "Google One Speicher", 32.98, 18, .fixedContracts, { $0.partnerName.lowercased().contains("google one") || $0.purpose.lowercased().contains("google one") }),
            ("netflix", "Netflix Streaming", 19.99, 2, .fixedContracts, { $0.partnerName.lowercased().contains("netflix") || $0.purpose.lowercased().contains("netflix") }),
            ("apple", "Apple iCloud Speicher", 2.99, 15, .fixedContracts, { $0.partnerName.lowercased().contains("apple com/bill") || $0.purpose.lowercased().contains("apple com/bill") })
        ]
        
        return templates.map { t in
            let match = thisMonthTxs.first(where: t.match)
            return MonthlyFixedCostItem(
                id: t.id,
                name: t.name,
                expectedAmount: t.amount,
                expectedDayOfMonth: t.day,
                isPaidThisMonth: match != nil,
                paidDate: match?.date,
                paidAmount: match?.amount != nil ? abs(match!.amount) : nil,
                category: t.cat
            )
        }
    }
    
    public var totalRemainingFixedCosts: Double {
        recurringFixedCostsThisMonth
            .filter { !$0.isPaidThisMonth }
            .reduce(0.0) { $0 + $1.expectedAmount }
    }
    
    // MARK: - Neuro-Ergonomic Layer 1: Safe-to-Spend & Dispo Shield
    public var safeToSpend: Double {
        max(0.0, plusKontoBalance - 100.0 - totalRemainingFixedCosts)
    }
    
    public var isDispoSafe: Bool {
        (plusKontoBalance - totalRemainingFixedCosts) >= 100.0
    }
    
    public var dispoRiskPercentage: Double {
        if plusKontoBalance >= 100.0 { return 0.0 }
        if plusKontoBalance <= 0.0 { return 1.0 }
        return (100.0 - plusKontoBalance) / 100.0
    }
    
    // MARK: - Mathematical Hierarchy of Needs & Dynamic Budgets
    public var hierarchyOfNeedsReport: HierarchyOfNeedsReport {
        smartEngine.evaluateHierarchyOfNeeds(
            plusKontoBalance: plusKontoBalance,
            pendingFixedCosts: totalRemainingFixedCosts,
            accounts: accounts,
            transactions: transactions,
            currentDate: Date()
        )
    }
    
    // MARK: - Cross-App Synergy: Food Leak Radar & Streaks
    public var foodLeakFreeStreakDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let leakTxs = transactions.filter {
            $0.category == .deliveryLeak ||
            $0.partnerName.lowercased().contains("lieferando") ||
            $0.partnerName.lowercased().contains("takeaway") ||
            $0.partnerName.lowercased().contains("mcdonald") ||
            $0.partnerName.lowercased().contains("burger king")
        }.sorted { $0.date > $1.date }
        
        guard let lastLeak = leakTxs.first else { return 14 }
        let lastLeakDay = cal.startOfDay(for: lastLeak.date)
        let diff = cal.dateComponents([.day], from: lastLeakDay, to: today).day ?? 0
        return max(0, diff)
    }
    
    public var savedLeakCapitalTotal: Double {
        Double(foodLeakFreeStreakDays) * 12.0
    }
    
    // MARK: - Cross-App Synergy: Physical & Nutrition Gate Signals
    public var hasWorkoutToday: Bool {
        guard let workout = SharedMacrosBridge.shared.loadLatestWorkout() else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return workout.dateString == formatter.string(from: Date())
    }
    
    public var hasNutritionLoggedToday: Bool {
        guard let macros = SharedMacrosBridge.shared.loadMacros() else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return macros.dateString == formatter.string(from: Date()) && (macros.calories > 0 || macros.protein > 0)
    }
    
    public var somaticImpulseClearance: Bool {
        hasWorkoutToday || currentWaterMl >= 1000
    }
    
    public var currentMonthSummary: MonthlyFinanceSummary {
        let calendar = Calendar.current
        let now = Date()
        let thisMonthTxs = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        
        var income: Double = 0
        var expenses: Double = 0
        var debt: Double = 0
        var leaks: Double = 0
        
        for tx in thisMonthTxs {
            guard !tx.isInternalTransfer else { continue }
            if tx.amount > 0 {
                income += tx.amount
            } else {
                let absAmount = abs(tx.amount)
                expenses += absAmount
                if tx.category == .debtRepayment {
                    debt += absAmount
                } else if tx.category == .fastFoodDelivery || tx.category == .taxiTransport || tx.category == .bankFees {
                    leaks += absAmount
                }
            }
        }
        
        let monthName = DateFormatter.localizedString(from: now, dateStyle: .none, timeStyle: .none)
        return MonthlyFinanceSummary(
            monthName: monthName,
            totalIncome: income,
            totalExpenses: expenses,
            netCashflow: income - expenses,
            totalDebtRepaid: debt,
            totalLeaksDetected: leaks
        )
    }
    
    public var activeDebtStatus: DebtStatus {
        engine.calculateDebtStatus(transactions: transactions)
    }
    
    public var activeLeakReport: SpendingLeakReport {
        engine.analyzeLeaks(transactions: transactions)
    }
    
    // MARK: - Actions
    public func addTransaction(_ tx: BankTransaction) {
        let key = deduplicationKey(for: tx)
        guard !transactions.contains(where: { deduplicationKey(for: $0) == key }) else {
            return
        }
        transactions.insert(tx, at: 0)
        Task {
            await self.executeBackgroundFinancialPasses()
        }
        saveTransactions()
        
        // Telemetry Financial Leak Radar
        if tx.isDebit {
            let val = abs(tx.amount)
            let partner = tx.partnerName.isEmpty ? tx.recipientOrPurpose : tx.partnerName
            if tx.category == .deliveryLeak {
                GrowTelemetryService.shared.logLogicViolation(
                    appName: "GrowFinance",
                    category: .financialLeak,
                    title: "Konsum-Leak: Lieferdienst/Fast-Food",
                    detail: "Ausgabe von \(String(format: "%.2f", val)) EUR an \(partner) erfasst. Verletzt die Null-Lieferdienst-Doktrin.",
                    metadata: ["partner": partner, "amount": "\(val)"]
                )
            } else if val > 50.0 && tx.category != .fixedContracts && tx.category != .debtServicing {
                GrowTelemetryService.shared.logLogicViolation(
                    appName: "GrowFinance",
                    category: .financialLeak,
                    title: "Unquarantinierte Ausgabe ueber 50 EUR",
                    detail: "Transaktion ueber \(String(format: "%.2f", val)) EUR an \(partner) erfasst. Verletzt 72h-Anti-Leak-Quarantaene.",
                    metadata: ["partner": partner, "amount": "\(val)"]
                )
            }
        }
    }
    
    public func bookScreenshotTransaction(record: TargobankScreenshotRecord, draftTx: BankTransaction) {
        // Add transaction to ledger
        addTransaction(draftTx)
        
        // Update screenshot record status
        if let idx = screenshotRecords.firstIndex(where: { $0.id == record.id }) {
            var updated = screenshotRecords[idx]
            updated.isBooked = true
            screenshotRecords[idx] = updated
        } else {
            var newRecord = record
            newRecord.isBooked = true
            screenshotRecords.insert(newRecord, at: 0)
        }
        saveScreenshots()
    }
    
    public func importCSV(from url: URL) {
        importHaushaltsbuchFile(from: url)
    }

    public func importHaushaltsbuchFile(from url: URL) {
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            
            let data = try Data(contentsOf: url)
            guard let csvString = String(data: data, encoding: .utf8) ??
                                 String(data: data, encoding: .isoLatin1) ??
                                 String(data: data, encoding: .windowsCP1252) else {
                throw NSError(domain: "GrowFinance", code: 1, userInfo: [NSLocalizedDescriptionKey: "Konnte Datei-Kodierung nicht lesen (weder UTF-8 noch Windows/ISO)."])
            }
            
            let parsed = HaushaltsbuchCSVParser.parse(csvString: csvString)
            if parsed.isEmpty {
                throw NSError(domain: "GrowFinance", code: 2, userInfo: [NSLocalizedDescriptionKey: "Keine gueltigen Buchungszeilen in der Haushaltsbuch-Datei gefunden."])
            }
            
            // Intelligent Multi-Factor Deduplication
            var newCount = 0
            var duplicateCount = 0
            var newTransactionsToInsert: [BankTransaction] = []
            var matchedExistingIds = Set<String>()

            for tx in parsed {
                let dedup = TransactionDeduplicationEngine.shared.findDuplicate(
                    candidate: tx,
                    in: transactions + newTransactionsToInsert,
                    excludingIds: matchedExistingIds
                )
                if dedup.isDuplicate {
                    duplicateCount += 1
                    if let matched = dedup.matchedTransaction {
                        matchedExistingIds.insert(matched.id)
                        
                        // CRITICAL RECONCILIATION: If matched transaction was a manual Quittung scan from Growcery,
                        // reconcile it with the official bank booking, verifying it without creating a duplicate!
                        if matched.isManual || matched.rawBookingText.contains("Growcery") || matched.id.starts(with: "receipt_") || matched.tags.contains("Quittung") {
                            let receiptTag = matched.tags.first(where: { $0.starts(with: "receipt_") || ($0.count >= 32 && $0.contains("-")) })
                            for i in 0..<transactions.count {
                                if transactions[i].id == matched.id || (receiptTag != nil && transactions[i].tags.contains(receiptTag!)) {
                                    transactions[i].rawBookingText = "\(tx.rawBookingText) [Growcery ID: \(matched.id)]"
                                    if let accId = tx.accountId, !accId.isEmpty {
                                        transactions[i].accountId = accId
                                    }
                                    transactions[i].isManual = false // Verified by official bank booking!
                                    if !transactions[i].tags.contains("Bank-Verifiziert") {
                                        transactions[i].tags.append("Bank-Verifiziert")
                                    }
                                    matchedExistingIds.insert(transactions[i].id)
                                }
                            }
                        }
                    }
                } else {
                    newTransactionsToInsert.append(tx)
                    newCount += 1
                }
            }
            
            if !newTransactionsToInsert.isEmpty {
                transactions.append(contentsOf: newTransactionsToInsert)
                transactions.sort { $0.date > $1.date }
                Task {
                    await self.executeBackgroundFinancialPasses()
                }
                saveTransactions()
            }

            let report = HaushaltsbuchImportReport(
                fileName: url.lastPathComponent,
                totalParsed: parsed.count,
                newTransactionsAdded: newCount,
                duplicatesSkipped: duplicateCount,
                timestamp: Date()
            )

            self.lastImportCount = newCount
            self.lastImportReport = report
            self.importErrorMessage = nil
        } catch {
            self.importErrorMessage = "Haushaltsbuch Import Fehler: \(error.localizedDescription)"
        }
    }
    
    public func addQuarantinedPurchase(title: String, amount: Double, category: TransactionCategory, notes: String) {
        let purchase = QuarantinedPurchase(
            title: title,
            amount: amount,
            category: category,
            quarantineStartDate: Date(),
            notes: notes
        )
        quarantinedPurchases.insert(purchase, at: 0)
        saveQuarantine()
    }
    
    public func updateQuarantinedPurchase(_ item: QuarantinedPurchase, isCancelled: Bool) {
        if let idx = quarantinedPurchases.firstIndex(where: { $0.id == item.id }) {
            var updated = item
            if isCancelled {
                updated.isCancelled = true
            } else {
                updated.isApprovedAfter72h = true
            }
            quarantinedPurchases[idx] = updated
            saveQuarantine()
        }
    }
    
    // MARK: - Account Management
    public func addAccount(
        accountNumber: String,
        name: String,
        type: AccountType,
        initialBalance: Double = 0.0,
        iban: String = ""
    ) {
        let newAccount = BankAccount(
            accountNumber: accountNumber,
            name: name,
            type: type,
            balance: initialBalance,
            iban: iban.isEmpty ? "DE\(Int.random(in: 10...99))30020900\(accountNumber)" : iban,
            isMainAccount: accounts.isEmpty
        )
        accounts.append(newAccount)
        saveAccounts()
    }
    
    public func deleteAccount(id: String) {
        accounts.removeAll { $0.id == id }
        if selectedAccountId == id {
            selectedAccountId = nil
        }
        saveAccounts()
    }
    
    public func syncSavingsGoalsWithTagesgeldAccounts() {
        var updatedGoals: [SavingsGoal] = []
        for acc in accounts {
            for sub in acc.subAllocations {
                updatedGoals.append(
                    SavingsGoal(
                        id: sub.id,
                        title: "\(sub.name) (\(acc.accountNumber))",
                        targetAmount: sub.targetAmount,
                        currentAmount: sub.allocatedAmount,
                        notes: sub.notes.isEmpty ? "Unterziel von Kto. \(acc.accountNumber)" : sub.notes,
                        icon: sub.icon
                    )
                )
            }
        }
        if !updatedGoals.isEmpty {
            userProfile.savingsGoals = updatedGoals
        }
    }

    public func updateAccountBalance(id: String, newBalance: Double) {
        if let idx = accounts.firstIndex(where: { $0.id == id }) {
            accounts[idx].balance = newBalance
            saveAccounts()
            syncSavingsGoalsWithTagesgeldAccounts()
            saveUserProfile()
        }
    }

    public func updateAccountName(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = accounts.firstIndex(where: { $0.id == id }) {
            accounts[idx].name = trimmed
            saveAccounts()
            syncSavingsGoalsWithTagesgeldAccounts()
            saveUserProfile()
        }
    }

    // MARK: - Sub-Allocations (Sparziele within Accounts)
    public func addSubAllocation(to accountId: String, name: String, allocatedAmount: Double, targetAmount: Double, icon: String = "target", notes: String = "") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = accounts.firstIndex(where: { $0.id == accountId || $0.accountNumber == accountId }) else { return }
        let sub = AccountSubAllocation(
            name: trimmed,
            allocatedAmount: max(0.0, allocatedAmount),
            targetAmount: max(0.0, targetAmount),
            icon: icon,
            notes: notes
        )
        accounts[idx].subAllocations.append(sub)
        saveAccounts()
        syncSavingsGoalsWithTagesgeldAccounts()
        saveUserProfile()
    }

    public func updateSubAllocation(accountId: String, subAllocation: AccountSubAllocation) {
        guard let accIdx = accounts.firstIndex(where: { $0.id == accountId || $0.accountNumber == accountId }) else { return }
        if let subIdx = accounts[accIdx].subAllocations.firstIndex(where: { $0.id == subAllocation.id }) {
            accounts[accIdx].subAllocations[subIdx] = subAllocation
            saveAccounts()
            syncSavingsGoalsWithTagesgeldAccounts()
            saveUserProfile()
        }
    }

    public func deleteSubAllocation(accountId: String, subAllocationId: String) {
        guard let accIdx = accounts.firstIndex(where: { $0.id == accountId || $0.accountNumber == accountId }) else { return }
        accounts[accIdx].subAllocations.removeAll(where: { $0.id == subAllocationId })
        saveAccounts()
        syncSavingsGoalsWithTagesgeldAccounts()
        saveUserProfile()
    }
    
    public func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            try? encoded.write(to: accountsFileUrl, options: [.atomic])
        }
        broadcastFinanceTelemetry()
    }

    // MARK: - Transaction Deduplication Helper
    public func deduplicationKey(for tx: BankTransaction) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: tx.date)
        let dateStr = String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        let amtStr = String(format: "%.2f", tx.amount)
        let cleanPartner = tx.partnerName.lowercased().filter { $0.isLetter || $0.isNumber }
        let cleanPurpose = tx.purpose.lowercased().filter { $0.isLetter || $0.isNumber }
        return "\(dateStr)_\(amtStr)_\(cleanPartner.prefix(16))_\(cleanPurpose.prefix(16))"
    }

    public static let defaultContracts: [FinanceContractOrSubscription] = [
        FinanceContractOrSubscription(name: "Targobank Sondertilgung", type: .debtRate, monthlyAmount: 1000.00, billingCycle: "Monatlich", billingDayOfMonth: 1, category: .debtServicing, budgetCategory: .wohnkosten, necessity: .necessary, provider: "TARGOBANK"),
        FinanceContractOrSubscription(name: "Targobank Kreditrate", type: .debtRate, monthlyAmount: 274.70, billingCycle: "Monatlich", billingDayOfMonth: 1, category: .debtServicing, budgetCategory: .wohnkosten, necessity: .necessary, provider: "TARGOBANK"),
        FinanceContractOrSubscription(name: "Telefonica O2 Tarif", type: .contract, monthlyAmount: 95.05, billingCycle: "Monatlich", billingDayOfMonth: 20, category: .fixedContracts, budgetCategory: .nebenkosten, necessity: .necessary, provider: "Telefonica O2"),
        FinanceContractOrSubscription(name: "Telefonica Ratenplan 1", type: .contract, monthlyAmount: 22.50, billingCycle: "Monatlich", billingDayOfMonth: 26, category: .fixedContracts, budgetCategory: .nebenkosten, necessity: .necessary, provider: "Telefonica O2"),
        FinanceContractOrSubscription(name: "Telefonica Ratenplan 2", type: .contract, monthlyAmount: 8.00, billingCycle: "Monatlich", billingDayOfMonth: 27, category: .fixedContracts, budgetCategory: .nebenkosten, necessity: .necessary, provider: "Telefonica O2"),
        FinanceContractOrSubscription(name: "Google One Speicher", type: .subscription, monthlyAmount: 32.98, billingCycle: "Monatlich", billingDayOfMonth: 18, category: .fixedContracts, budgetCategory: .unterhaltung, necessity: .unnecessary, provider: "Google"),
        FinanceContractOrSubscription(name: "Netflix Streaming", type: .subscription, monthlyAmount: 19.99, billingCycle: "Monatlich", billingDayOfMonth: 2, category: .fixedContracts, budgetCategory: .unterhaltung, necessity: .unnecessary, provider: "Netflix"),
        FinanceContractOrSubscription(name: "Apple iCloud Speicher", type: .subscription, monthlyAmount: 2.99, billingCycle: "Monatlich", billingDayOfMonth: 15, category: .fixedContracts, budgetCategory: .nebenkosten, necessity: .necessary, provider: "Apple"),
        FinanceContractOrSubscription(name: "Bundeswehr Diensthaftpflicht", type: .insurance, monthlyAmount: 18.50, billingCycle: "Monatlich", billingDayOfMonth: 5, category: .fixedContracts, budgetCategory: .gesundheit, necessity: .necessary, provider: "Continentale"),
        FinanceContractOrSubscription(name: "Auslandskrankenversicherung", type: .insurance, monthlyAmount: 12.00, billingCycle: "Monatlich", billingDayOfMonth: 10, category: .fixedContracts, budgetCategory: .gesundheit, necessity: .necessary, provider: "Ergo")
    ]

    // MARK: - Persistence
    private func loadSavedData() {
        // 1. Accounts: Exclusively load and reconcile verified live Targobank accounts (Checking, 5 Tagesgelder, Online-Kredit)
        if let data = try? Data(contentsOf: accountsFileUrl),
           let saved = try? JSONDecoder().decode([BankAccount].self, from: data), !saved.isEmpty {
            var updatedLive = FinanceStore.liveTargobankAccounts
            for (idx, liveAcc) in updatedLive.enumerated() {
                if let savedMatch = saved.first(where: { $0.accountNumber == liveAcc.accountNumber }) {
                    if !savedMatch.name.isEmpty {
                        updatedLive[idx].name = savedMatch.name
                    }
                    if !savedMatch.subAllocations.isEmpty {
                        updatedLive[idx].subAllocations = savedMatch.subAllocations
                    }
                }
            }
            self.accounts = updatedLive
        } else {
            self.accounts = FinanceStore.liveTargobankAccounts
        }
        saveAccounts()
        
        // 2. Transactions: Load from disk and combine with seeds, strictly deduplicating
        var loadedTxs: [BankTransaction] = []
        if let data = try? Data(contentsOf: transactionsFileUrl),
           let saved = try? JSONDecoder().decode([BankTransaction].self, from: data) {
            loadedTxs = saved
        }
        
        let seeds = HaushaltsbuchCSVParser.seedTransactions
        let allCandidates = loadedTxs + seeds
        
        var dedupedList: [BankTransaction] = []
        for tx in allCandidates {
            let res = TransactionDeduplicationEngine.shared.findDuplicate(candidate: tx, in: dedupedList)
            if !res.isDuplicate {
                dedupedList.append(tx)
            }
        }
        
        self.transactions = dedupedList.sorted(by: { $0.date > $1.date })
        saveTransactions()
        
        // 3. Quarantine
        if let data = try? Data(contentsOf: quarantineFileUrl),
           let saved = try? JSONDecoder().decode([QuarantinedPurchase].self, from: data) {
            self.quarantinedPurchases = saved
        }
        
        // 4. Targobank Screenshots
        if let data = try? Data(contentsOf: screenshotsFileUrl),
           let saved = try? JSONDecoder().decode([TargobankScreenshotRecord].self, from: data) {
            self.screenshotRecords = saved
        }
        
        // 5. Daily Notes
        if let data = try? Data(contentsOf: dailyNotesFileUrl),
           let saved = try? JSONDecoder().decode([String: String].self, from: data) {
            self.dailyNotes = saved
        }

        // 6. User Profile (Synchronize savings goals directly with the 5 live Tagesgeld accounts)
        if let data = try? Data(contentsOf: profileFileUrl),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = saved
        } else {
            self.userProfile = UserProfile()
        }
        syncSavingsGoalsWithTagesgeldAccounts()
        saveUserProfile()

        // 7. Budgets (9 User Categories)
        if let data = try? Data(contentsOf: budgetsFileUrl),
           let saved = try? JSONDecoder().decode([CategoryBudget].self, from: data), !saved.isEmpty {
            self.budgets = saved
        } else {
            self.budgets = BudgetCategory.allCases.map {
                CategoryBudget(category: $0, monthlyLimit: $0.defaultMonthlyLimit)
            }
            saveBudgets()
        }

        // 8. Fixed Contracts & Subscriptions
        if let data = try? Data(contentsOf: contractsFileUrl),
           let saved = try? JSONDecoder().decode([FinanceContractOrSubscription].self, from: data), !saved.isEmpty {
            self.contracts = saved
        } else {
            self.contracts = Self.defaultContracts
            saveContracts()
        }
        
        // 9. Automated Financial Passes (Reconciliation, Cadence Scan, Envelope Rollovers)
        executeBackgroundFinancialPassesSync()

        // 10. Background Smart Engine Notification Scheduling
        DispatchQueue.main.async {
            FinanceNotificationService.shared.requestAuthorization()
        }
    }

    // MARK: - Automated Multi-Pass Background Engines
    public func executeBackgroundFinancialPasses() async {
        let currentTxs = self.transactions
        let currentContracts = self.contracts
        let currentBudgets = self.budgets

        // Execute Passes concurrently on background cooperative pools
        async let reconTask = TransferReconciliationEngine.shared.reconcile(transactions: currentTxs)
        async let cadencesTask = CadencePatternScanner.shared.scanCadences(transactions: currentTxs, registeredContracts: currentContracts)
        async let rolloverTask = EnvelopeRolloverEngine.shared.computeRolloverLedger(budgets: currentBudgets, transactions: currentTxs)

        let (recon, cadences, rollover) = await (reconTask, cadencesTask, rolloverTask)

        self.transactions = recon.reconciledTransactions
        if recon.matchedPairCount > 0 {
            self.transferReconciliationSummary = "\(recon.matchedPairCount) Umbuchungen bereinigt (\(String(format: "%.2f", recon.neutralizedVolume)) € neutralisiert)."
        } else {
            self.transferReconciliationSummary = nil
        }
        self.detectedCadences = cadences
        self.rolloverLedger = rollover
    }

    public func executeBackgroundFinancialPassesSync() {
        let recon = TransferReconciliationEngine.shared.reconcileSync(transactions: self.transactions)
        self.transactions = recon.reconciledTransactions
        if recon.matchedPairCount > 0 {
            self.transferReconciliationSummary = "\(recon.matchedPairCount) Umbuchungen bereinigt (\(String(format: "%.2f", recon.neutralizedVolume)) € neutralisiert)."
        } else {
            self.transferReconciliationSummary = nil
        }
        self.detectedCadences = CadencePatternScanner.shared.scanCadencesSync(
            transactions: self.transactions,
            registeredContracts: self.contracts
        )
        self.rolloverLedger = EnvelopeRolloverEngine.shared.computeRolloverLedgerSync(
            budgets: self.budgets,
            transactions: self.transactions
        )
    }
    
    // MARK: - Daily Notes & Calendar Support
    public static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    public func note(for date: Date) -> String {
        let key = Self.dateKey(for: date)
        return dailyNotes[key] ?? ""
    }

    public func setNote(_ text: String, for date: Date) {
        let key = Self.dateKey(for: date)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            dailyNotes.removeValue(forKey: key)
        } else {
            dailyNotes[key] = trimmed
        }
        saveDailyNotes()
    }

    private func saveDailyNotes() {
        if let encoded = try? JSONEncoder().encode(dailyNotes) {
            try? encoded.write(to: dailyNotesFileUrl, options: [.atomic])
        }
    }

    public func hasTransactions(on date: Date) -> Bool {
        let cal = Calendar.current
        return transactions.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    public func transactions(on date: Date) -> [BankTransaction] {
        let cal = Calendar.current
        return transactions.filter { cal.isDate($0.date, inSameDayAs: date) }.sorted(by: { $0.date > $1.date })
    }
    
    private func saveScreenshots() {
        if let encoded = try? JSONEncoder().encode(screenshotRecords) {
            try? encoded.write(to: screenshotsFileUrl, options: [.atomic])
        }
    }
    
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            try? encoded.write(to: transactionsFileUrl, options: [.atomic])
        }
        broadcastFinanceTelemetry()
    }
    
    private func broadcastFinanceTelemetry() {
        // Dynamic Food Budget calculation from Tier 1 (BWK Ulm Reha Nutrition)
        let hierarchy = hierarchyOfNeedsReport
        let netAvailableCash = plusKontoBalance - totalRemainingFixedCosts - 100.0
        let cal = Calendar.current
        let currentDay = cal.component(.day, from: Date())
        let totalDays = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
        let payDay = 28
        let daysRemaining = currentDay < payDay ? max(1, payDay - currentDay) : max(1, (totalDays - currentDay) + payDay)
        let dailyRate: Double
        if netAvailableCash < 100.0 {
            dailyRate = 7.50
        } else if netAvailableCash >= 350.0 {
            dailyRate = 9.50
        } else {
            dailyRate = 8.50
        }
        let neededGroceryRemaining = Double(daysRemaining) * dailyRate
        let grocerySpentThisMonth = transactions.filter {
            cal.isDate($0.date, equalTo: Date(), toGranularity: .month) &&
            cal.isDate($0.date, equalTo: Date(), toGranularity: .year) &&
            $0.isDebit && !$0.isInternalTransfer &&
            ($0.budgetCategory == .essen || smartEngine.categorize(partner: $0.partnerName, purpose: $0.purpose, amount: $0.amount) == .groceries)
        }.reduce(0.0) { $0 + abs($1.amount) }

        let dynamicMonthly = min(320.0, max(180.0, grocerySpentThisMonth + neededGroceryRemaining))
        let dynamicRemaining = max(0.0, min(neededGroceryRemaining, netAvailableCash))

        let payload = SharedFinancePayload(
            date: Date(),
            plusKontoBalance: plusKontoBalance,
            safeToSpend: safeToSpend,
            isDispoSafe: isDispoSafe,
            totalSavings: totalSavingsBalance,
            remainingLoan: abs(totalLoanBalance),
            foodLeakFreeStreakDays: foodLeakFreeStreakDays,
            savedLeakCapitalTotal: savedLeakCapitalTotal,
            lastDeliveryDetectedDate: nil,
            dynamicFoodBudgetMonthly: (dynamicMonthly * 100).rounded() / 100,
            dynamicFoodBudgetRemaining: (dynamicRemaining * 100).rounded() / 100,
            dailyFoodRate: dailyRate,
            lastUpdated: Date()
        )
        SharedMacrosBridge.shared.saveFinance(payload)

        // Telemetry persistence
    }
    
    private func saveQuarantine() {
        if let encoded = try? JSONEncoder().encode(quarantinedPurchases) {
            try? encoded.write(to: quarantineFileUrl, options: [.atomic])
        }
    }
    
    // MARK: - Water Bridge Sync
    private func setupWaterSynchronization() {
        let payload = SharedMacrosBridge.shared.loadWater(for: Date())
        self.currentWaterMl = payload.totalWaterMl
        self.targetWaterMl = payload.targetWaterMl
        
        DarwinNotificationCenter.observe(DarwinNotificationCenter.waterUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let updated = SharedMacrosBridge.shared.loadWater(for: Date())
                self.currentWaterMl = updated.totalWaterMl
                self.targetWaterMl = updated.targetWaterMl
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let updated = SharedMacrosBridge.shared.loadWater(for: Date())
                self.currentWaterMl = updated.totalWaterMl
                self.targetWaterMl = updated.targetWaterMl
            }
        }
    }

    // MARK: - Cross-Device Growcery Quittung Synchronization
    private func setupGroceryReceiptSynchronization() {
        syncGroceryReceiptsFromBridge()

        // 1. Observe Darwin local updates (same-device or testbed)
        DarwinNotificationCenter.observe(DarwinNotificationCenter.groceryReceiptsUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                self?.syncGroceryReceiptsFromBridge()
            }
        }

        // 2. Observe iCloud Ubiquitous Key-Value Store changes (across devices / no cables)
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncGroceryReceiptsFromBridge()
            }
        }
    }

    public func syncGroceryReceiptsFromBridge() {
        let ledger = GrowSuiteBridge.shared.loadGroceryReceipts()
        guard !ledger.receipts.isEmpty else { return }

        var insertedAny = false
        for receipt in ledger.receipts {
            // Check if already in ledger by ID or rawBookingText
            let alreadyExists = transactions.contains {
                $0.id == "receipt_\(receipt.id)" || $0.rawBookingText.contains(receipt.id) || $0.tags.contains(receipt.id)
            }
            if alreadyExists { continue }

            // Check deduplication engine against bank transactions
            let candidateTx = BankTransaction(
                id: "receipt_\(receipt.id)",
                date: receipt.date,
                recipientOrPurpose: "Lebensmitteleinkauf (Growcery Quittung)",
                amount: -abs(receipt.totalAmount),
                category: .groceries,
                accountIBAN: accounts.first(where: { $0.isMainAccount })?.iban ?? "DE28300209003201649568",
                rawBookingText: "Growcery Receipt ID: \(receipt.id)",
                isManual: true,
                partnerName: receipt.storeName.uppercased(),
                accountId: accounts.first(where: { $0.isMainAccount })?.id,
                tags: ["Quittung", "Growcery", "Lebensmittel", receipt.id],
                necessity: .necessary,
                budgetCategory: .essen,
                isInternalTransfer: false
            )

            let dedup = TransactionDeduplicationEngine.shared.findDuplicate(candidate: candidateTx, in: transactions)
            if dedup.isDuplicate {
                // Bank transaction already exists! Link receipt without creating duplicate
                if let matched = dedup.matchedTransaction, let idx = transactions.firstIndex(where: { $0.id == matched.id }) {
                    if !transactions[idx].tags.contains("Quittung") {
                        transactions[idx].tags.append("Quittung")
                    }
                    if !transactions[idx].tags.contains(receipt.id) {
                        transactions[idx].tags.append(receipt.id)
                    }
                }
                continue
            }

            if receipt.nonFoodAmount > 0.01 {
                // Split-Buchung: Food + Non-Food get separated cleanly into respective budgets!
                let mainIban = accounts.first(where: { $0.isMainAccount })?.iban ?? "DE28300209003201649568"
                let mainAccId = accounts.first(where: { $0.isMainAccount })?.id

                let foodTx = BankTransaction(
                    id: "receipt_\(receipt.id)_food",
                    date: receipt.date,
                    recipientOrPurpose: "Lebensmitteleinkauf (Growcery Quittung)",
                    amount: -abs(receipt.foodAmount),
                    category: .groceries,
                    accountIBAN: mainIban,
                    rawBookingText: "Growcery Receipt ID: \(receipt.id) (Lebensmittel-Anteil)",
                    isManual: true,
                    partnerName: receipt.storeName.uppercased(),
                    accountId: mainAccId,
                    tags: ["Quittung", "Growcery", "Lebensmittel", "Split-Buchung", receipt.id],
                    necessity: .necessary,
                    budgetCategory: .essen,
                    isInternalTransfer: false
                )

                let nonFoodSummary = receipt.nonFoodSummaries.joined(separator: ", ")
                let nonFoodTx = BankTransaction(
                    id: "receipt_\(receipt.id)_nonfood",
                    date: receipt.date,
                    recipientOrPurpose: nonFoodSummary.isEmpty ? "Haushaltsartikel (Growcery Quittung)" : "Haushalt / Anschaffung (\(nonFoodSummary))",
                    amount: -abs(receipt.nonFoodAmount),
                    category: .discretionary,
                    accountIBAN: mainIban,
                    rawBookingText: "Growcery Receipt ID: \(receipt.id) (Non-Food Anteil)",
                    isManual: true,
                    partnerName: receipt.storeName.uppercased(),
                    accountId: mainAccId,
                    tags: ["Quittung", "Growcery", "Non-Food", "Split-Buchung", receipt.id],
                    necessity: .neutral,
                    budgetCategory: .privat,
                    isInternalTransfer: false
                )

                transactions.insert(nonFoodTx, at: 0)
                transactions.insert(foodTx, at: 0)
                insertedAny = true
            } else {
                transactions.insert(candidateTx, at: 0)
                insertedAny = true
            }
        }

        if insertedAny {
            transactions.sort { $0.date > $1.date }
            saveTransactions()
            autoAllocateSubAllocationsInsideAccounts()
            Task {
                await self.executeBackgroundFinancialPasses()
            }
        }
    }

    // MARK: - Mathematical Background Sub-Allocation Balancing
    public func autoAllocateSubAllocationsInsideAccounts() {
        // Runs 100% in background without UI text.
        // Money moves STRICTLY inside its own account; each account retains the exact same total sum.
        var updatedAccounts = accounts
        for i in 0..<updatedAccounts.count {
            let totalAccountBalance = updatedAccounts[i].balance
            guard totalAccountBalance > 0, !updatedAccounts[i].subAllocations.isEmpty else {
                continue
            }

            var remaining = totalAccountBalance
            for j in 0..<updatedAccounts[i].subAllocations.count {
                let target = updatedAccounts[i].subAllocations[j].targetAmount
                if target > 0 {
                    let fill = min(target, remaining)
                    updatedAccounts[i].subAllocations[j].allocatedAmount = fill
                    remaining -= fill
                } else {
                    if j == updatedAccounts[i].subAllocations.count - 1 {
                        updatedAccounts[i].subAllocations[j].allocatedAmount = remaining
                        remaining = 0
                    } else {
                        updatedAccounts[i].subAllocations[j].allocatedAmount = 0
                    }
                }
            }

            // Leftover above targets stays in the primary sub-allocation
            if remaining > 0 && !updatedAccounts[i].subAllocations.isEmpty {
                updatedAccounts[i].subAllocations[0].allocatedAmount += remaining
            }
        }

        self.accounts = updatedAccounts
        if let encoded = try? JSONEncoder().encode(accounts) {
            try? encoded.write(to: accountsFileUrl, options: [.atomic])
        }
        syncSavingsGoalsWithTagesgeldAccounts()
    }
    
    public func addWater(amountMl: Double) {
        SharedMacrosBridge.shared.logWater(amountMl: amountMl, date: Date(), sourceApp: "GrowFinance")
        let updated = SharedMacrosBridge.shared.loadWater(for: Date())
        self.currentWaterMl = updated.totalWaterMl
    }
    
    public func resetWater() {
        SharedMacrosBridge.shared.resetWater(date: Date(), sourceApp: "GrowFinance")
        self.currentWaterMl = 0
    }

    // MARK: - Profile, Budgets & Contracts Mutations
    public func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            try? encoded.write(to: profileFileUrl, options: [.atomic])
        }
    }

    public func updateMonthlyIncome(base: Double) {
        userProfile.monthlyNetIncome = base
        userProfile.lastUpdated = Date()
        saveUserProfile()
    }

    public func addIncomeSource(name: String, amount: Double, recurrence: String = "Monatlich", isPrimary: Bool = false) {
        let newSource = IncomeSource(name: name, monthlyAmount: amount, recurrence: recurrence, isPrimary: isPrimary)
        userProfile.incomeSources.append(newSource)
        userProfile.monthlyNetIncome = userProfile.incomeSources.reduce(0.0) { $0 + $1.monthlyAmount }
        userProfile.lastUpdated = Date()
        saveUserProfile()
    }

    public func deleteIncomeSource(id: String) {
        userProfile.incomeSources.removeAll { $0.id == id }
        userProfile.monthlyNetIncome = userProfile.incomeSources.reduce(0.0) { $0 + $1.monthlyAmount }
        userProfile.lastUpdated = Date()
        saveUserProfile()
    }

    public func updateSavingsGoal(id: String, currentAmount: Double) {
        if let idx = userProfile.savingsGoals.firstIndex(where: { $0.id == id }) {
            userProfile.savingsGoals[idx].currentAmount = currentAmount
            userProfile.lastUpdated = Date()
            saveUserProfile()
        }
    }

    public func addSavingsGoal(title: String, targetAmount: Double, currentAmount: Double, icon: String = "target", notes: String = "") {
        let goal = SavingsGoal(title: title, targetAmount: targetAmount, currentAmount: currentAmount, notes: notes, icon: icon)
        userProfile.savingsGoals.append(goal)
        userProfile.lastUpdated = Date()
        saveUserProfile()
    }

    public func deleteSavingsGoal(id: String) {
        userProfile.savingsGoals.removeAll { $0.id == id }
        userProfile.lastUpdated = Date()
        saveUserProfile()
    }

    public func saveBudgets() {
        if let encoded = try? JSONEncoder().encode(budgets) {
            try? encoded.write(to: budgetsFileUrl, options: [.atomic])
        }
    }

    public func updateBudgetLimit(category: BudgetCategory, newLimit: Double) {
        if let idx = budgets.firstIndex(where: { $0.category == category }) {
            budgets[idx].monthlyLimit = newLimit
        } else {
            budgets.append(CategoryBudget(category: category, monthlyLimit: newLimit))
        }
        saveBudgets()
    }

    public func saveContracts() {
        if let encoded = try? JSONEncoder().encode(contracts) {
            try? encoded.write(to: contractsFileUrl, options: [.atomic])
        }
    }

    public func addContractOrSubscription(_ item: FinanceContractOrSubscription) {
        contracts.append(item)
        saveContracts()
    }

    public func toggleContractCancelled(id: String) {
        if let idx = contracts.firstIndex(where: { $0.id == id }) {
            contracts[idx].isCancelled.toggle()
            saveContracts()
        }
    }

    public func adoptDetectedCadenceAsContract(_ pattern: DetectedCadencePattern) {
        let monthlyEquiv: Double
        switch pattern.cadence {
        case .weekly: monthlyEquiv = pattern.latestAmount * 4.33
        case .biweekly: monthlyEquiv = pattern.latestAmount * 2.16
        case .monthly: monthlyEquiv = pattern.latestAmount
        case .quarterly: monthlyEquiv = pattern.latestAmount / 3.0
        case .annual: monthlyEquiv = pattern.latestAmount / 12.0
        case .irregular: monthlyEquiv = pattern.latestAmount
        }

        let billingDay = Calendar.current.component(.day, from: pattern.lastSeenDate)
        let newContract = FinanceContractOrSubscription(
            name: pattern.counterparty,
            type: pattern.recommendedType,
            monthlyAmount: monthlyEquiv,
            billingCycle: pattern.cadence.rawValue,
            billingDayOfMonth: billingDay,
            category: .fixedContracts,
            budgetCategory: pattern.recommendedBudgetCategory,
            necessity: .necessary,
            provider: pattern.counterparty,
            policyOrContractNumber: "",
            isCancelled: false,
            startDate: pattern.firstSeenDate,
            notes: "Automatisch vom Cadence Scanner übernommen (\(pattern.occurrenceCount) Buchungen, Ø \(String(format: "%.0f", pattern.averageIntervalDays)) Tage Intervall)."
        )

        contracts.append(newContract)
        saveContracts()
        Task {
            await self.executeBackgroundFinancialPasses()
        }
    }

    public func addAccount(_ account: BankAccount) {
        accounts.append(account)
        saveAccounts()
    }

    // MARK: - Book Scanned Draft
    @discardableResult
    public func bookScannedDraft(_ draft: UniversalScanDraft) -> (success: Bool, message: String) {
        let amount = -abs(draft.amount)
        var tags = draft.tags
        if !tags.contains("Quittung") { tags.append("Quittung") }
        if !tags.contains("Beleg") { tags.append("Beleg") }

        let candidateTx = BankTransaction(
            date: draft.date,
            recipientOrPurpose: draft.purpose,
            amount: amount,
            category: draft.category,
            accountIBAN: draft.targetAccountId.isEmpty ? "DE28300209003201649568" : draft.targetAccountId,
            rawBookingText: draft.rawText,
            isManual: true,
            partnerName: draft.partnerName,
            accountId: draft.targetAccountId.isEmpty ? accounts.first(where: { $0.isMainAccount })?.id : draft.targetAccountId,
            tags: tags,
            necessity: draft.necessity,
            budgetCategory: draft.budgetCategory
        )

        // Strict duplicate check against existing ledger
        let dedup = TransactionDeduplicationEngine.shared.findDuplicate(candidate: candidateTx, in: transactions)
        if dedup.isDuplicate {
            let reason = dedup.reason ?? "Diese Transaktion existiert bereits im Haushaltsbuch."
            return (false, "Duplikat verhindert: \(reason)")
        }

        transactions.insert(candidateTx, at: 0)
        Task {
            await self.executeBackgroundFinancialPasses()
        }
        saveTransactions()

        // Debit the target account balance
        let accId = candidateTx.accountId ?? accounts.first(where: { $0.isMainAccount })?.id
        if let targetId = accId, let idx = accounts.firstIndex(where: { $0.id == targetId }) {
            accounts[idx].balance += amount
            saveAccounts()
        }

        return (true, "Buchung erfolgreich übernommen.")
    }
}
