import Foundation

// MARK: - Algorithmic Smart Finance Engine
public final class SmartFinanceEngine {
    public static let shared = SmartFinanceEngine()
    
    // Mathematical constants & boundaries
    public let dispoBufferThreshold: Double = 100.00
    public let dailyFoodLeakSavingsTarget: Double = 12.00
    public let monthlyFoodLeakBaseline: Double = 360.00
    public let standardDispoInterestRate: Double = 0.1373 // 13.73% p.a.
    public let unapprovedDispoInterestRate: Double = 0.1673 // 16.73% p.a.
    public let targobankLoanMonthlyService: Double = 1274.70 // 1.000 € Sondertilgung + 274,70 € Rate
    
    private init() {}
    
    private func fmt(_ val: Double, decimals: Int = 2) -> String {
        return String(format: "%.\(decimals)f", val)
    }
    
    // MARK: - 1. Daily Cash Velocity & Safe Daily Allowance
    /// Calculates the maximum daily allowance until the next salary credit (typically 28th of month)
    public func calculateDailyAllowance(
        plusKontoBalance: Double,
        pendingFixedCosts: Double,
        currentDate: Date = Date()
    ) -> DailyAllowanceResult {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: currentDate)
        let totalDaysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
        
        // Target pay day is usually the 28th (Bundeswehr Sold)
        let payDay = 28
        let daysRemaining: Int
        if currentDay < payDay {
            daysRemaining = max(1, payDay - currentDay)
        } else {
            daysRemaining = max(1, (totalDaysInMonth - currentDay) + payDay)
        }
        
        let disposablePool = max(0.0, plusKontoBalance - dispoBufferThreshold - pendingFixedCosts)
        let dailyLimit = disposablePool / Double(daysRemaining)
        let isCritical = disposablePool <= 0 || dailyLimit < 5.0
        
        return DailyAllowanceResult(
            dailyLimitEur: dailyLimit,
            daysRemainingUntilSalary: daysRemaining,
            disposablePoolEur: disposablePool,
            isCriticalDispoWarning: isCritical
        )
    }
    
    // MARK: - Real-Time Dynamic Burn Rate & Pace Diagnostics
    public func calculateRealTimeVelocity(
        transactions: [BankTransaction],
        plusKontoBalance: Double,
        pendingFixedCosts: Double,
        currentDate: Date = Date()
    ) -> RealTimePaceDiagnostics {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: currentDate)
        let allowance = calculateDailyAllowance(plusKontoBalance: plusKontoBalance, pendingFixedCosts: pendingFixedCosts, currentDate: currentDate)
        
        // Filter out this month's discretionary/variable spend (excluding fixed costs and debt)
        let thisMonthTxs = transactions.filter {
            calendar.isDate($0.date, equalTo: currentDate, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: currentDate, toGranularity: .year) &&
            $0.amount < 0 &&
            !$0.isInternalTransfer &&
            $0.category != .debtServicing &&
            $0.category != .fixedContracts
        }
        
        let totalVariableSpent = thisMonthTxs.reduce(0.0) { $0 + abs($1.amount) }
        let effectiveDays = max(1, currentDay)
        let actualBurnRate = totalVariableSpent / Double(effectiveDays)
        let targetLimit = allowance.dailyLimitEur
        
        let isOverpacing = actualBurnRate > targetLimit && targetLimit > 0
        let paceVariance = actualBurnRate - targetLimit
        
        let liveAdvice: String
        if plusKontoBalance < dispoBufferThreshold {
            let def = String(format: "%.2f", dispoBufferThreshold - plusKontoBalance)
            liveAdvice = "Dispo-Alarm: Saldo ist \(def) EUR unter der 100 EUR Sicherheitslinie. Sofort Ausgaben einfrieren und Notfallpuffer uebertragen."
        } else if isOverpacing {
            let overStr = String(format: "%.2f", paceVariance)
            let burnStr = String(format: "%.2f", actualBurnRate)
            let limitStr = String(format: "%.2f", targetLimit)
            liveAdvice = "Echtzeit-Warnung: Burn-Rate (\(burnStr) EUR/Tag) liegt \(overStr) EUR/Tag ueber dem Limit (\(limitStr) EUR/Tag). Ausgaben umgehend drosseln."
        } else if targetLimit > 0 {
            let bufferStr = String(format: "%.2f", abs(paceVariance))
            let limitStr = String(format: "%.2f", targetLimit)
            let surplus = String(format: "%.2f", abs(paceVariance) * Double(allowance.daysRemainingUntilSalary))
            liveAdvice = "Ausgabenkontrolle stabil: Burn-Rate liegt \(bufferStr) EUR/Tag unter dem Limit (\(limitStr) EUR/Tag). Prognostizierter Ueberschuss: +\(surplus) EUR."
        } else {
            liveAdvice = "Kein freier Spielraum fuer variable Ausgaben vorhanden. 100 EUR Dispo-Schutz einhalten."
        }
        
        return RealTimePaceDiagnostics(
            actualBurnRatePerDay: actualBurnRate,
            targetDailyLimit: targetLimit,
            isOverpacing: isOverpacing,
            paceVariance: paceVariance,
            totalVariableSpentThisMonth: totalVariableSpent,
            daysPassed: currentDay,
            liveDirective: liveAdvice
        )
    }
    
    // MARK: - 2. Scenario Simulation (Monte Carlo & Stress Test)
    public func runScenarioAnalysis(
        plusKontoBalance: Double,
        dailyAllowance: Double,
        daysRemaining: Int,
        historicalMonthlyLeak: Double
    ) -> [FinanceScenario] {
        // Scenario A: Strict Discipline (Zero Leaks, 100% Truppenküche/Homecook)
        let disciplineProjectedPlus = plusKontoBalance + (Double(daysRemaining) * 12.00) - (Double(daysRemaining) * min(dailyAllowance, 15.0))
        let disciplineSavings = Double(daysRemaining) * 12.00
        let savingsStr = fmt(disciplineSavings, decimals: 1)
        let scenarioA = FinanceScenario(
            id: "discipline",
            title: "Disziplin-Szenario (Zero Leaks)",
            projectedMonthEndBalance: disciplineProjectedPlus,
            additionalDebtPayoffPossible: disciplineSavings,
            dispoRiskProbability: 0.0,
            directive: "Lieferdienste und Spontanausgaben strikt blockiert. Ersparnis beschleunigt Kreditabbau um " + savingsStr + " EUR."
        )
        
        // Scenario B: Status Quo (Past Velocity)
        let statusQuoDrainPerDay = max(15.0, dailyAllowance * 1.3)
        let statusQuoMonthEnd = plusKontoBalance - (Double(daysRemaining) * statusQuoDrainPerDay)
        let dispoRiskB = statusQuoMonthEnd < 100.0 ? 0.65 : 0.15
        let scenarioB = FinanceScenario(
            id: "status_quo",
            title: "Status-Quo-Szenario (Bisheriger Trend)",
            projectedMonthEndBalance: statusQuoMonthEnd,
            additionalDebtPayoffPossible: 0.0,
            dispoRiskProbability: dispoRiskB,
            directive: statusQuoMonthEnd < 100.0 ?
                "Achtung: Trend führt zum Unterschreiten des 100 EUR Puffers. Dispozinsen drohen!" :
                "Stabiler Verlauf, jedoch ohne zusätzliche Schuldentilgungs-Dynamik."
        )
        
        // Scenario C: Shock Scenario (Unforeseen 150 € charge)
        let shockMonthEnd = plusKontoBalance - 150.00 - (Double(daysRemaining) * dailyAllowance)
        let dispoRiskC = shockMonthEnd < 100.0 ? 0.95 : 0.30
        let scenarioC = FinanceScenario(
            id: "shock",
            title: "Stresstest (150 EUR Notfall-Belastung)",
            projectedMonthEndBalance: shockMonthEnd,
            additionalDebtPayoffPossible: 0.0,
            dispoRiskProbability: dispoRiskC,
            directive: "Gegenmaßnahme: Exakt 150 EUR aus Tagesgeld 5211...2413 liquidieren, um 16,73 % Überziehungszins abzuwehren."
        )
        
        return [scenarioA, scenarioB, scenarioC]
    }
    
    // MARK: - 3. Capital Allocation Directives (Where to direct money)
    public func generateDirectives(
        plusKonto: Double,
        safeToSpend: Double,
        totalSavings: Double,
        remainingLoan: Double,
        foodLeakStreak: Int
    ) -> [FinanceDirective] {
        var directives: [FinanceDirective] = []
        
        // 1. Dispo Defense
        let plusStr = fmt(plusKonto)
        let safeStr = fmt(safeToSpend)
        let loanStr = fmt(remainingLoan)
        let savedStreak = Double(foodLeakStreak) * dailyFoodLeakSavingsTarget
        let savedStreakStr = fmt(savedStreak)
        
        if plusKonto < dispoBufferThreshold {
            directives.append(FinanceDirective(
                priority: 1,
                title: "Dispo-Schild aktivieren",
                action: "Plus-Konto auffüllen",
                description: "Plus-Konto liegt unter 100 EUR (" + plusStr + " EUR). 100 EUR aus Tagesgeld 5211 übertragen, um 13,73 % Zinsen zu stoppen.",
                isUrgent: true
            ))
        } else {
            directives.append(FinanceDirective(
                priority: 1,
                title: "Plus-Konto geschützt",
                action: "Puffer halten",
                description: "100,00 EUR Notfallpuffer ist aktiv. Verfügbarer Spielraum: " + safeStr + " EUR.",
                isUrgent: false
            ))
        }
        
        // 2. Debt Servicing Priority
        directives.append(FinanceDirective(
            priority: 2,
            title: "Avalanche-Tilgung",
            action: "1.274,70 EUR/Monat sichern",
            description: "1.000 EUR Sondertilgung + 274,70 EUR Rate am 1. des Monats unverrückbar halten. Restschuld: " + loanStr + " EUR.",
            isUrgent: false
        ))
        
        // 3. Leak Interception
        directives.append(FinanceDirective(
            priority: 3,
            title: "360 EUR/Monat Food-Leak Radar",
            action: "Streak fortsetzen (\(foodLeakStreak) Tage)",
            description: "Durch Vermeidung von Lieferdiensten bisher " + savedStreakStr + " EUR vor Zinsverlust geschützt.",
            isUrgent: false
        ))
        
        // 4. Emergency Fund Lock
        directives.append(FinanceDirective(
            priority: 4,
            title: "Notfallfonds-Quarantäne",
            action: "6.000 EUR auf 5291 unangetastet lassen",
            description: "Das Tagesgeld 5291062407 sichert 3 Monatsgehälter absolute Existenzbasis. Keine Entnahmen für Konsum.",
            isUrgent: false
        ))
        
        return directives
    }
    
    // MARK: - 4. Monthly Report & Tactical Plan Generation
    public func generateMonthlyReport(
        date: Date = Date(),
        monthlyTransactions: [BankTransaction],
        totalSavings: Double,
        remainingLoan: Double
    ) -> MonthlyReportPlan {
        let monthName = date.formatted(.dateTime.month(.wide).year())
        
        var incomeTotal: Double = 0
        var fixedCostsTotal: Double = 0
        var debtServicingTotal: Double = 0
        var deliveryLeaksTotal: Double = 0
        var groceryTotal: Double = 0
        var mobilityTotal: Double = 0
        var discretionaryTotal: Double = 0
        
        for tx in monthlyTransactions {
            guard !tx.isInternalTransfer else { continue }
            if tx.amount > 0 {
                incomeTotal += tx.amount
            } else {
                let absAmt = abs(tx.amount)
                switch tx.category {
                case .besoldung, .incomeOther, .internalTransfer:
                    break
                case .debtServicing:
                    debtServicingTotal += absAmt
                case .deliveryLeak:
                    deliveryLeaksTotal += absAmt
                case .groceries:
                    groceryTotal += absAmt
                case .fixedContracts, .bankFees:
                    fixedCostsTotal += absAmt
                case .mobility:
                    mobilityTotal += absAmt
                case .discretionary, .other:
                    discretionaryTotal += absAmt
                }
            }
        }
        
        let totalExpenses = fixedCostsTotal + debtServicingTotal + deliveryLeaksTotal + groceryTotal + mobilityTotal + discretionaryTotal
        let netSavingsRate = incomeTotal > 0 ? ((incomeTotal - totalExpenses) / incomeTotal) * 100.0 : 0.0
        
        let tacticalActions = [
            "1. Lieferdienst-Sperre: 0,00 EUR Ausgaben für Lieferando & Takeaway halten (+360 EUR/Monat Tilgungskapital).",
            "2. Feste Abbuchungen: Am 1. des Monats 1.000 EUR Sondertilgung + 274,70 EUR Targobank-Rate verbuchen.",
            "3. Dispo-Schutz: Niemals unter 100 EUR Kontostand fallen lassen. Tagesbudget exakt einhalten."
        ]
        
        return MonthlyReportPlan(
            monthTitle: monthName,
            incomeTotal: incomeTotal,
            totalExpenses: totalExpenses,
            debtServiced: debtServicingTotal,
            foodLeaksTotal: deliveryLeaksTotal,
            netSavingsRatePercent: netSavingsRate,
            remainingLoanBalance: remainingLoan,
            tacticalActionItems: tacticalActions
        )
    }

    // MARK: - 7. Expense Necessity & Leak Finder
    public func analyzeExpensesNecessity(
        transactions: [BankTransaction]
    ) -> (necessary: Double, unnecessary: Double, leaksCount: Int, unnecessaryTxs: [BankTransaction]) {
        var necessaryTotal: Double = 0.0
        var unnecessaryTotal: Double = 0.0
        var unnecessaryList: [BankTransaction] = []

        for tx in transactions where tx.isDebit && !tx.isInternalTransfer {
            let amt = abs(tx.amount)
            let isUnnecessary: Bool
            if tx.necessity == .unnecessary {
                isUnnecessary = true
            } else if tx.necessity == .necessary {
                isUnnecessary = false
            } else {
                // Heuristic analysis: Food delivery, bank fees, gambling, excessive fast food are unnecessary
                let lower = "\(tx.partnerName) \(tx.recipientOrPurpose)".lowercased()
                if tx.category == .deliveryLeak || tx.category == .bankFees ||
                   lower.contains("lieferando") || lower.contains("uber eats") || lower.contains("mcdonald") ||
                   lower.contains("burger king") || lower.contains("steam") || lower.contains("playstation") {
                    isUnnecessary = true
                } else if tx.category == .besoldung || tx.category == .debtServicing || tx.category == .groceries ||
                            tx.category == .fixedContracts || lower.contains("bundeskasse") || lower.contains("targobank") ||
                            lower.contains("telekom") || lower.contains("telefonica") || lower.contains("apotheke") ||
                            lower.contains("stadtwerke") || lower.contains("rundfunk") {
                    isUnnecessary = false
                } else {
                    isUnnecessary = false
                }
            }

            if isUnnecessary {
                unnecessaryTotal += amt
                unnecessaryList.append(tx)
            } else {
                necessaryTotal += amt
            }
        }

        return (
            necessary: necessaryTotal,
            unnecessary: unnecessaryTotal,
            leaksCount: unnecessaryList.count,
            unnecessaryTxs: unnecessaryList
        )
    }

    // MARK: - 8. Budget Status & 6-Month Trajectory with Dynamic Calibration
    public func calculateBudgetStatuses(
        budgets: [CategoryBudget],
        transactions: [BankTransaction],
        plusKontoBalance: Double? = nil,
        pendingFixedCosts: Double? = nil,
        accounts: [BankAccount]? = nil,
        currentDate: Date = Date()
    ) -> [BudgetStatus] {
        let cal = Calendar.current
        let now = currentDate

        // Evaluate Hierarchy of Needs if balances and accounts are provided
        let hierarchyReport: HierarchyOfNeedsReport?
        if let balance = plusKontoBalance, let accs = accounts {
            hierarchyReport = evaluateHierarchyOfNeeds(
                plusKontoBalance: balance,
                pendingFixedCosts: pendingFixedCosts ?? 0.0,
                accounts: accs,
                transactions: transactions,
                currentDate: currentDate
            )
        } else {
            hierarchyReport = nil
        }

        // Generate past 6 months keys
        var monthKeys: [(key: String, label: String, start: Date, end: Date)] = []
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "de_DE")
        monthFormatter.dateFormat = "MMM"

        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM"

        for i in (0..<6).reversed() {
            if let targetMonth = cal.date(byAdding: .month, value: -i, to: now),
               let interval = cal.dateInterval(of: .month, for: targetMonth) {
                let key = keyFormatter.string(from: interval.start)
                let label = monthFormatter.string(from: interval.start)
                monthKeys.append((key: key, label: label, start: interval.start, end: interval.end))
            }
        }

        var results: [BudgetStatus] = []

        for b in budgets {
            // Find all matching transactions for this budget category
            let matchingTxs = transactions.filter { tx in
                guard tx.isDebit, !tx.isInternalTransfer else { return false }
                if let explicitB = tx.budgetCategory {
                    return explicitB == b.category
                }
                return mapToBudgetCategory(tx: tx) == b.category
            }

            // Spent this month
            let thisMonthTxs = matchingTxs.filter {
                cal.isDate($0.date, equalTo: now, toGranularity: .month) &&
                cal.isDate($0.date, equalTo: now, toGranularity: .year)
            }
            let spentThisMonth = thisMonthTxs.reduce(0.0) { $0 + abs($1.amount) }

            // 6-month historical graph
            var history: [(month: String, amount: Double)] = []
            for m in monthKeys {
                let monthSum = matchingTxs
                    .filter { $0.date >= m.start && $0.date <= m.end }
                    .reduce(0.0) { $0 + abs($1.amount) }
                history.append((month: m.label, amount: monthSum))
            }

            let sortedRecent = thisMonthTxs.sorted(by: { $0.date > $1.date })
            let latest = Array(sortedRecent.prefix(5))

            // Dynamic Mathematical Calibration
            let effectiveLimit: Double
            let isAutoAdjusted: Bool
            let dynamicDailyRate: Double?
            let dynamicRationale: String?

            if let report = hierarchyReport, b.category == .essen {
                effectiveLimit = report.dynamicGroceryMonthlyLimit
                isAutoAdjusted = true
                dynamicDailyRate = report.dynamicGroceryDailyRate
                dynamicRationale = "Mathematische Ernaehrungs-Norm: 160g Protein, 25-35g Ballaststoffe, BWK Ulm Reha."
            } else if let report = hierarchyReport, b.category == .unterhaltung {
                effectiveLimit = report.dynamicVacationMonthlyLimit
                isAutoAdjusted = true
                dynamicDailyRate = nil
                dynamicRationale = report.dynamicVacationMonthlyLimit == 0
                    ? "Puffer-Schutz: Auf 0,00 € reduziert, da Tilgung (Stufe 2) absolute Prioritaet hat."
                    : "Elastisches Budget: Gesteuert durch Ueberschuss nach Tilgung & Fixkosten."
            } else {
                effectiveLimit = b.monthlyLimit
                isAutoAdjusted = false
                dynamicDailyRate = nil
                dynamicRationale = nil
            }

            results.append(
                BudgetStatus(
                    budget: b,
                    spentThisMonth: spentThisMonth,
                    effectiveLimit: effectiveLimit,
                    isAutoAdjusted: isAutoAdjusted,
                    dynamicDailyRate: dynamicDailyRate,
                    dynamicRationale: dynamicRationale,
                    monthlyHistory: history,
                    latestTransactions: latest
                )
            )
        }

        return results
    }

    // MARK: - 9. Pure Mathematical Hierarchy of Needs & Dynamic Allocation
    public func evaluateHierarchyOfNeeds(
        plusKontoBalance: Double,
        pendingFixedCosts: Double,
        accounts: [BankAccount],
        transactions: [BankTransaction],
        currentDate: Date = Date()
    ) -> HierarchyOfNeedsReport {
        let cal = Calendar.current
        let currentDay = cal.component(.day, from: currentDate)
        let totalDays = cal.range(of: .day, in: .month, for: currentDate)?.count ?? 30
        let payDay = 28
        let daysRemaining: Int
        if currentDay < payDay {
            daysRemaining = max(1, payDay - currentDay)
        } else {
            daysRemaining = max(1, (totalDays - currentDay) + payDay)
        }

        let netAvailableCash = plusKontoBalance - pendingFixedCosts - dispoBufferThreshold

        // This month transactions
        let thisMonthTxs = transactions.filter {
            cal.isDate($0.date, equalTo: currentDate, toGranularity: .month) &&
            cal.isDate($0.date, equalTo: currentDate, toGranularity: .year) &&
            $0.isDebit && !$0.isInternalTransfer
        }

        let grocerySpentThisMonth = thisMonthTxs.filter { tx in
            tx.budgetCategory == .essen || categorize(partner: tx.partnerName, purpose: tx.purpose, amount: tx.amount) == .groceries
        }.reduce(0.0) { $0 + abs($1.amount) }

        let debtPaidThisMonth = thisMonthTxs.filter { tx in
            tx.budgetCategory == .wohnkosten && categorize(partner: tx.partnerName, purpose: tx.purpose, amount: tx.amount) == .debtServicing
        }.reduce(0.0) { $0 + abs($1.amount) }

        // Find Account balances
        let debtAccount = accounts.first(where: { $0.type == .loan })
        let loanRemaining = abs(debtAccount?.balance ?? 11333.21)

        let entschuldungAccount = accounts.first(where: { $0.accountNumber.contains("5211062413") || $0.name.contains("Entschuldung") })
        let entschuldungBalance = entschuldungAccount?.balance ?? 0.0

        let notfallAccount = accounts.first(where: { $0.accountNumber.contains("5291062407") || $0.name.contains("Notfall") })
        let notfallBalance = notfallAccount?.balance ?? 0.0

        let karriereAccount = accounts.first(where: { $0.accountNumber.contains("5231062411") || $0.name.contains("Karriere") || $0.name.contains("Bildung") })
        let karriereBalance = karriereAccount?.balance ?? 0.0

        let urlaubAccount = accounts.first(where: { $0.accountNumber.contains("5271062409") || $0.name.contains("Urlaub") })
        let urlaubBalance = urlaubAccount?.balance ?? 0.0

        let reserveAccount = accounts.first(where: { $0.accountNumber.contains("5221062404") || $0.name.contains("Reserve") })
        let reserveBalance = reserveAccount?.balance ?? 0.0

        // Tier 0: Existenz & Fixkosten
        let tier0Required = pendingFixedCosts + dispoBufferThreshold
        let tier0Funded = max(0.0, plusKontoBalance)
        let tier0Full = plusKontoBalance >= tier0Required
        let tier0Status = HierarchyTierStatus(
            tier: .tier0_survivalFixed,
            requiredAmount: tier0Required,
            fundedAmount: tier0Funded,
            isFullyFunded: tier0Full,
            statusMessage: tier0Full
                ? String(format: "Fixkosten (%.2f €) + 100 € Dispo-Puffer voll gedeckt.", pendingFixedCosts)
                : String(format: "Deckungslücke von %.2f €! 13,73%% Dispo-Gefahr.", tier0Required - plusKontoBalance)
        )

        // Tier 1: Notwendige Ernährung (BWK Ulm Reha: 160g Protein, 25-35g Ballaststoffe)
        let dailyGroceryRate: Double
        if netAvailableCash < 100.0 {
            dailyGroceryRate = 7.50
        } else if netAvailableCash >= 350.0 {
            dailyGroceryRate = 9.50
        } else {
            dailyGroceryRate = 8.50
        }
        let neededGroceryRemaining = Double(daysRemaining) * dailyGroceryRate
        let dynamicGroceryMonthly = min(320.00, grocerySpentThisMonth + neededGroceryRemaining)
        let tier1Required = neededGroceryRemaining
        let tier1Funded = max(0.0, min(neededGroceryRemaining, netAvailableCash))
        let tier1Full = netAvailableCash >= neededGroceryRemaining
        let tier1Status = HierarchyTierStatus(
            tier: .tier1_necessaryNutrition,
            requiredAmount: tier1Required,
            fundedAmount: tier1Funded,
            isFullyFunded: tier1Full,
            statusMessage: String(
                format: "Tagesrate %.2f €/Tag (noch %d Tage bis 28.). 160g Protein & Reha gesichert.",
                dailyGroceryRate, daysRemaining
            )
        )

        // Tier 2: Avalanche-Tilgung (Targobank & Entschuldung)
        let tier2Required = 1274.70
        let tier2Funded = debtPaidThisMonth + min(1000.0, entschuldungBalance)
        let tier2Full = tier2Funded >= tier2Required || (debtPaidThisMonth >= 274.70 && entschuldungBalance >= 1000.0)
        let tier2Status = HierarchyTierStatus(
            tier: .tier2_debtServicing,
            requiredAmount: tier2Required,
            fundedAmount: tier2Funded,
            isFullyFunded: tier2Full,
            statusMessage: tier2Full
                ? String(format: "Avalanche-Monatsziel (%.2f €) planmaessig hinterlegt / bedient.", tier2Required)
                : String(format: "Fehlbetrag zu 1.000 € Sondertilgung: %.2f €.", max(0.0, tier2Required - tier2Funded))
        )

        // Tier 3: Notfallreserve
        let tier3Required = 6000.00
        let tier3Funded = notfallBalance
        let tier3Full = notfallBalance >= 1500.00
        let tier3Status = HierarchyTierStatus(
            tier: .tier3_emergencyReserve,
            requiredAmount: tier3Required,
            fundedAmount: tier3Funded,
            isFullyFunded: tier3Full,
            statusMessage: String(format: "Tagesgeld Notfallfonds: %.2f € / %.2f € hinterlegt.", notfallBalance, tier3Required)
        )

        // Tier 4: Aktive Meilensteine (B-Führerschein & Matura)
        let tier4Required = 2500.00
        let tier4Funded = karriereBalance
        let tier4Full = karriereBalance >= 2500.00
        let tier4Status = HierarchyTierStatus(
            tier: .tier4_activeMilestones,
            requiredAmount: tier4Required,
            fundedAmount: tier4Funded,
            isFullyFunded: tier4Full,
            statusMessage: String(format: "B-Fuehrerschein & Matura: %.2f € von %.2f € angespart.", karriereBalance, tier4Required)
        )

        // Tier 5: Elastischer Urlaub & Freizeit
        let surplusAfterTiers0And1 = max(0.0, netAvailableCash - neededGroceryRemaining)
        let dynamicVacationLimit: Double
        let dynamicDiscretionaryLimit: Double
        if !tier0Full || !tier1Full || surplusAfterTiers0And1 <= 0 || (loanRemaining > 0 && debtPaidThisMonth < 274.70) {
            dynamicVacationLimit = 0.00
            dynamicDiscretionaryLimit = 25.00
        } else {
            dynamicVacationLimit = min(120.00, surplusAfterTiers0And1 * 0.15)
            dynamicDiscretionaryLimit = min(75.00, 25.00 + (surplusAfterTiers0And1 * 0.10))
        }
        let tier5Required = dynamicVacationLimit
        let tier5Funded = urlaubBalance
        let tier5Full = tier5Required == 0 || urlaubBalance >= dynamicVacationLimit
        let tier5Status = HierarchyTierStatus(
            tier: .tier5_elasticDiscretionary,
            requiredAmount: tier5Required,
            fundedAmount: tier5Funded,
            isFullyFunded: tier5Full,
            statusMessage: dynamicVacationLimit == 0
                ? "Auf 0,00 € reduziert: Liquiditaet dient zwingend Existenz & Avalanche-Tilgung."
                : String(format: "Elastisch freigegeben: %.2f € (15%% des freien Cash-Ueberschusses).", dynamicVacationLimit)
        )

        let allTiers = [tier0Status, tier1Status, tier2Status, tier3Status, tier4Status, tier5Status]

        // Deterministic Account Allocation Directives
        var directives: [AccountAllocationDirective] = []

        // 1. Dispo-Schutz-Direktive (Tier 0 Verletzung)
        if plusKontoBalance < tier0Required {
            let shortfall = tier0Required - plusKontoBalance
            if urlaubBalance > 0 {
                let transferAmt = min(shortfall, urlaubBalance)
                directives.append(
                    AccountAllocationDirective(
                        sourceAccountName: "TAGESGELDKONTO (Urlaub & Regeneration)",
                        targetAccountName: "PLUS-KONTO",
                        amount: transferAmt,
                        rationale: "Vermeidung von 13,73% Dispozinsen auf dem Plus-Konto. Existenz (Tier 0) dominiert Freizeit (Tier 5).",
                        priority: 1
                    )
                )
            } else if reserveBalance > 0 {
                let transferAmt = min(shortfall, reserveBalance)
                directives.append(
                    AccountAllocationDirective(
                        sourceAccountName: "TAGESGELDKONTO (Taktische Reserve)",
                        targetAccountName: "PLUS-KONTO",
                        amount: transferAmt,
                        rationale: "Ausgleich der Fixkosten-Deckungsluecke aus der taktischen Reserve.",
                        priority: 1
                    )
                )
            }
        }

        // 2. Vacation-Sweep-to-Debt Directive
        if urlaubBalance >= 10.0 && loanRemaining > 0 && debtPaidThisMonth < 1000.0 {
            directives.append(
                AccountAllocationDirective(
                    sourceAccountName: "TAGESGELDKONTO (Urlaub & Regeneration)",
                    targetAccountName: "TAGESGELDKONTO (Entschuldung & Tilgung)",
                    amount: urlaubBalance,
                    rationale: "Anti-Leak Sweep: Vorzeitige Entschuldung (Juni 2027) hat Vorrang vor Urlaubsruecklagen.",
                    priority: 2
                )
            )
        }

        // 3. Plus-Konto Liquiditaets-Ueberschuss -> Sondertilgung
        if netAvailableCash > (neededGroceryRemaining + 150.0) && debtPaidThisMonth < 1000.0 {
            let surplusForDebt = min(1000.0 - debtPaidThisMonth, netAvailableCash - (neededGroceryRemaining + 100.0))
            if surplusForDebt >= 20.0 {
                directives.append(
                    AccountAllocationDirective(
                        sourceAccountName: "PLUS-KONTO",
                        targetAccountName: "TAGESGELDKONTO (Entschuldung & Tilgung)",
                        amount: surplusForDebt,
                        rationale: "Reine Arithmetik: Ueberschusskapital sichert die 1.000 € Monats-Sondertilgung gegen Zinsverlust.",
                        priority: 3
                    )
                )
            }
        }

        // If no directives generated, provide equilibrium status directive
        if directives.isEmpty {
            directives.append(
                AccountAllocationDirective(
                    sourceAccountName: "PLUS-KONTO & TAGESGELDER",
                    targetAccountName: "KEINE UMSCHICHTUNG",
                    amount: 0.00,
                    rationale: "Kontenstruktur befindet sich im mathematischen Gleichgewicht gemaess Beduerfnishierarchie.",
                    priority: 4
                )
            )
        }

        return HierarchyOfNeedsReport(
            tierStatuses: allTiers,
            dynamicGroceryMonthlyLimit: dynamicGroceryMonthly,
            dynamicGroceryDailyRate: dailyGroceryRate,
            dynamicDiscretionaryMonthlyLimit: dynamicDiscretionaryLimit,
            dynamicVacationMonthlyLimit: dynamicVacationLimit,
            allocationDirectives: directives,
            daysRemainingUntilSalary: daysRemaining,
            netAvailableCash: netAvailableCash
        )
    }

    public func categorize(partner: String, purpose: String, amount: Double) -> TransactionCategory {
        let combo = "\(partner) \(purpose)".lowercased()
        if combo.contains("bundeskasse") || combo.contains("besoldung") || combo.contains("gehalt") || (amount > 2000.0 && combo.contains("bezüge")) {
            return .besoldung
        }
        if combo.contains("kredit") || combo.contains("darlehen") || combo.contains("sondertilgung") || combo.contains("rate") || combo.contains("targobank kredit") {
            return .debtServicing
        }
        if combo.contains("penny") || combo.contains("rewe") || combo.contains("edeka") || combo.contains("aldi") || combo.contains("lidl") || combo.contains("kaufland") || combo.contains("netto") || combo.contains("lebensmittel") {
            return .groceries
        }
        if combo.contains("lieferando") || combo.contains("uber eats") || combo.contains("wolt") || combo.contains("mcdonald") || combo.contains("burger king") || combo.contains("kebab") || combo.contains("pizza") {
            return .deliveryLeak
        }
        if combo.contains("telekom") || combo.contains("telefonica") || combo.contains("vodafone") || combo.contains("netflix") || combo.contains("apple") || combo.contains("google") {
            return .fixedContracts
        }
        if combo.contains("öbb") || combo.contains("oebb") || combo.contains("bahn") || combo.contains("db vertrieb") || combo.contains("ticket") || combo.contains("fahrkarte") || combo.contains("tankstelle") || combo.contains("shell") || combo.contains("aral") || combo.contains("taxi") || combo.contains("uber") {
            return .mobility
        }
        if combo.contains("zinsen") || combo.contains("entgelt") || combo.contains("dispo") || combo.contains("gebühr") {
            return .bankFees
        }
        if combo.contains("amazon") || combo.contains("zalando") || combo.contains("paypal") {
            return .discretionary
        }
        if amount > 0 {
            return .incomeOther
        }
        return .discretionary
    }

    public func mapToBudgetCategory(tx: BankTransaction) -> BudgetCategory {
        if let explicit = tx.budgetCategory { return explicit }
        let combo = "\(tx.partnerName) \(tx.recipientOrPurpose)".lowercased()

        if combo.contains("rewe") || combo.contains("penny") || combo.contains("edeka") ||
           combo.contains("aldi") || combo.contains("lidl") || combo.contains("kaufland") ||
           combo.contains("bäcker") || combo.contains("supermarkt") || combo.contains("lebensmittel") ||
           tx.category == .groceries {
            return .essen
        }
        if combo.contains("apotheke") || combo.contains("arzt") || combo.contains("sanität") ||
           combo.contains("bwk") || combo.contains("drogerie") || combo.contains("supplement") ||
           combo.contains("fitness") || combo.contains("gym") {
            return .gesundheit
        }
        if combo.contains("getränk") || combo.contains("bar") || combo.contains("café") ||
           combo.contains("coffee") || combo.contains("starbucks") || combo.contains("brauerei") {
            return .getraenke
        }
        if combo.contains("zalando") || combo.contains("h&m") || combo.contains("zara") ||
           combo.contains("ansons") || combo.contains("peek") || combo.contains("nike") ||
           combo.contains("adidas") || combo.contains("kleidung") || combo.contains("schuhe") {
            return .kleidung
        }
        if combo.contains("telekom") || combo.contains("telefonica") || combo.contains("o2") ||
           combo.contains("vodafone") || combo.contains("strom") || combo.contains("gas") ||
           combo.contains("wasser") || combo.contains("rundfunk") || combo.contains("stadtwerke") {
            return .nebenkosten
        }
        if combo.contains("öbb") || combo.contains("oebb") || combo.contains("bahn") ||
           combo.contains("db vertrieb") || combo.contains("tankstelle") || combo.contains("shell") ||
           combo.contains("aral") || combo.contains("esso") || combo.contains("uber") ||
           combo.contains("taxi") || combo.contains("sprit") || tx.category == .mobility {
            return .transport
        }
        if combo.contains("netflix") || combo.contains("spotify") || combo.contains("kino") ||
           combo.contains("steam") || combo.contains("playstation") || combo.contains("event") ||
           combo.contains("apple.com/bill") || combo.contains("google one") {
            return .unterhaltung
        }
        if combo.contains("kaserne") || combo.contains("miete") || combo.contains("wohnung") ||
           combo.contains("hausverwaltung") || combo.contains("kaution") {
            return .wohnkosten
        }
        return .privat
    }

    // MARK: - 9. Category Summaries (Full History of Each Category)
    public func calculateCategorySummaries(transactions: [BankTransaction]) -> [CategorySummary] {
        var groups: [TransactionCategory: [BankTransaction]] = [:]
        for tx in transactions where tx.isDebit && !tx.isInternalTransfer {
            groups[tx.category, default: []].append(tx)
        }

        let totalOutflow = transactions.filter { $0.isDebit && !$0.isInternalTransfer }.reduce(0.0) { $0 + abs($1.amount) }

        var summaries: [CategorySummary] = []
        for cat in TransactionCategory.allCases {
            guard cat != .internalTransfer else { continue }
            let list = groups[cat] ?? []
            let sum = list.reduce(0.0) { $0 + abs($1.amount) }
            let avg = list.isEmpty ? 0.0 : sum / Double(list.count)
            let pct = totalOutflow > 0 ? (sum / totalOutflow) * 100.0 : 0.0

            summaries.append(
                CategorySummary(
                    categoryName: cat.displayName,
                    totalAmount: sum,
                    transactionCount: list.count,
                    averageAmount: avg,
                    percentage: pct,
                    icon: cat.icon,
                    color: cat.color,
                    transactions: list.sorted(by: { $0.date > $1.date })
                )
            )
        }

        return summaries.sorted(by: { $0.totalAmount > $1.totalAmount })
    }

    // MARK: - 10. Top Categories Leaderboard
    public func calculateTopCategories(transactions: [BankTransaction], isExpense: Bool) -> [CategoryShare] {
        let filtered = transactions.filter {
            guard !$0.isInternalTransfer else { return false }
            return isExpense ? $0.isDebit : !$0.isDebit
        }
        let total = filtered.reduce(0.0) { $0 + abs($1.amount) }

        var sums: [TransactionCategory: Double] = [:]
        for tx in filtered {
            sums[tx.category, default: 0.0] += abs(tx.amount)
        }

        let shares: [CategoryShare] = sums.map { (cat, sum) in
            let pct = total > 0 ? (sum / total) * 100.0 : 0.0
            return CategoryShare(
                name: cat.displayName,
                amount: sum,
                percentage: pct,
                icon: cat.icon,
                color: cat.color
            )
        }

        return shares.sorted(by: { $0.amount > $1.amount })
    }

    // MARK: - 11. Subscription & Recurring Analysis
    public func calculateSubscriptionAnalytics(
        contracts: [FinanceContractOrSubscription],
        transactions: [BankTransaction]
    ) -> [SubscriptionMetric] {
        contracts.map { contract in
            let keyword = contract.name.lowercased()
            let providerKeyword = contract.provider.lowercased()

            let matchingTxs = transactions.filter { tx in
                guard tx.isDebit, !tx.isInternalTransfer else { return false }
                let combo = "\(tx.partnerName) \(tx.recipientOrPurpose)".lowercased()
                return (!keyword.isEmpty && combo.contains(keyword)) ||
                       (!providerKeyword.isEmpty && combo.contains(providerKeyword))
            }

            let totalPaid = matchingTxs.reduce(0.0) { $0 + abs($1.amount) }
            let yearlyCost = contract.monthlyAmount * 12.0

            return SubscriptionMetric(
                contract: contract,
                totalPaidHistorically: totalPaid > 0 ? totalPaid : contract.monthlyAmount * 6.0,
                monthlyRate: contract.monthlyAmount,
                yearlyProjectedCost: yearlyCost,
                paymentCount: max(1, matchingTxs.count)
            )
        }.sorted(by: { $0.monthlyRate > $1.monthlyRate })
    }

    // MARK: - 12. Annual Net Worth Projection
    public func calculateAnnualNetWorthProjection(
        currentNetWorth: Double,
        monthlyNetSavings: Double
    ) -> [MonthlyProjectionPoint] {
        let cal = Calendar.current
        let now = Date()
        let currentMonth = cal.component(.month, from: now) // 1...12

        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "MMMM"

        var points: [MonthlyProjectionPoint] = []
        var runningNetWorth = currentNetWorth

        for m in currentMonth...12 {
            var comps = DateComponents()
            comps.year = cal.component(.year, from: now)
            comps.month = m
            comps.day = 1
            let monthDate = cal.date(from: comps) ?? now
            let monthName = df.string(from: monthDate)
            let monthKey = String(format: "%d-%02d", comps.year ?? 2026, m)

            let delta = m == currentMonth ? 0.0 : monthlyNetSavings
            runningNetWorth += delta

            points.append(
                MonthlyProjectionPoint(
                    monthKey: monthKey,
                    monthName: monthName,
                    projectedNetWorth: runningNetWorth,
                    delta: delta
                )
            )
        }

        return points
    }

    // MARK: - 13. Income vs Expenses History
    public func calculateMonthlyIncomeVsExpenses(transactions: [BankTransaction]) -> [MonthlyComparisonPoint] {
        let cal = Calendar.current
        let dfMonth = DateFormatter()
        dfMonth.locale = Locale(identifier: "de_DE")
        dfMonth.dateFormat = "MMMM yyyy"

        let dfKey = DateFormatter()
        dfKey.dateFormat = "yyyy-MM"

        var buckets: [String: (income: Double, expenses: Double, date: Date)] = [:]

        for tx in transactions {
            guard !tx.isInternalTransfer else { continue }
            let key = dfKey.string(from: tx.date)
            var current = buckets[key] ?? (income: 0.0, expenses: 0.0, date: tx.date)
            if tx.isDebit {
                current.expenses += abs(tx.amount)
            } else {
                current.income += abs(tx.amount)
            }
            buckets[key] = current
        }

        let sortedKeys = buckets.keys.sorted(by: { $0 > $1 })
        return sortedKeys.prefix(12).map { key in
            let item = buckets[key]!
            let monthName = dfMonth.string(from: item.date)
            let net = item.income - item.expenses
            let rate = item.income > 0 ? (net / item.income) * 100.0 : 0.0

            return MonthlyComparisonPoint(
                monthKey: key,
                monthName: monthName,
                income: item.income,
                expenses: item.expenses,
                netSavings: net,
                savingsRate: rate
            )
        }
    }

    // MARK: - 14. Payees & Merchants Summary
    public func calculatePayees(transactions: [BankTransaction]) -> [PayeeSummary] {
        var groups: [String: [BankTransaction]] = [:]

        for tx in transactions where !tx.isInternalTransfer {
            let clean = tx.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = clean.isEmpty ? tx.recipientOrPurpose.prefix(24).trimmingCharacters(in: .whitespacesAndNewlines) : clean
            groups[String(key), default: []].append(tx)
        }

        var results: [PayeeSummary] = []
        for (payee, txs) in groups {
            let total = txs.reduce(0.0) { $0 + abs($1.amount) }
            let sorted = txs.sorted(by: { $0.date > $1.date })
            let latestDate = sorted.first?.date ?? Date()
            let dominantCategory = sorted.first?.category ?? .other

            results.append(
                PayeeSummary(
                    payeeName: payee,
                    totalAmount: total,
                    transactionCount: txs.count,
                    latestDate: latestDate,
                    category: dominantCategory,
                    transactions: sorted
                )
            )
        }

        return results.sorted(by: { $0.totalAmount > $1.totalAmount })
    }

    // MARK: - 15. Tags Summary
    public func calculateTags(transactions: [BankTransaction]) -> [TagSummary] {
        var tagMap: [String: [BankTransaction]] = [:]

        for tx in transactions where !tx.isInternalTransfer {
            for tag in tx.tags {
                let normalized = tag.hasPrefix("#") ? tag : "#\(tag)"
                tagMap[normalized, default: []].append(tx)
            }
        }

        // Add auto-generated tags if user tags are sparse
        if tagMap.isEmpty {
            for tx in transactions where !tx.isInternalTransfer {
                if tx.category == .besoldung {
                    tagMap["#bundeswehr", default: []].append(tx)
                } else if tx.category == .debtServicing {
                    tagMap["#targobank", default: []].append(tx)
                } else if tx.category == .deliveryLeak {
                    tagMap["#leak", default: []].append(tx)
                } else if tx.category == .groceries {
                    tagMap["#lebensmittel", default: []].append(tx)
                } else if tx.category == .fixedContracts {
                    tagMap["#fixkosten", default: []].append(tx)
                }
            }
        }

        var results: [TagSummary] = []
        for (tag, txs) in tagMap {
            let sum = txs.reduce(0.0) { $0 + abs($1.amount) }
            results.append(
                TagSummary(
                    tagName: tag,
                    totalAmount: sum,
                    count: txs.count,
                    transactions: txs.sorted(by: { $0.date > $1.date })
                )
            )
        }

        return results.sorted(by: { $0.totalAmount > $1.totalAmount })
    }

    // MARK: - 8. Empirical Predictive Trajectory & Collision Radar
    public func predictMonthlyTrajectory(
        currentBalance: Double,
        pendingFixedCosts: Double,
        transactions: [BankTransaction],
        currentDate: Date = Date()
    ) -> PredictiveTrajectoryResult {
        let velocity = calculateRealTimeVelocity(
            transactions: transactions,
            plusKontoBalance: currentBalance,
            pendingFixedCosts: pendingFixedCosts,
            currentDate: currentDate
        )
        let allowance = calculateDailyAllowance(
            plusKontoBalance: currentBalance,
            pendingFixedCosts: pendingFixedCosts,
            currentDate: currentDate
        )
        
        let daysLeft = Double(max(1, allowance.daysRemainingUntilSalary))
        let burnRate = max(5.0, velocity.actualBurnRatePerDay)
        let projectedOutflow = (burnRate * daysLeft) + pendingFixedCosts
        let projectedEndBalance = currentBalance - projectedOutflow
        
        let isCollision = projectedEndBalance < dispoBufferThreshold
        var collisionDay: Int? = nil
        if isCollision && burnRate > 0 {
            let availableRunway = max(0.0, currentBalance - dispoBufferThreshold - pendingFixedCosts)
            let daysUntilDepletion = Int(availableRunway / burnRate)
            let calendar = Calendar.current
            let curDay = calendar.component(.day, from: currentDate)
            collisionDay = min(28, curDay + daysUntilDepletion)
        }
        
        // Exact throttled rate needed to guarantee 100 EUR buffer on the 28th
        let safePool = max(0.0, currentBalance - dispoBufferThreshold - pendingFixedCosts)
        let adjustedAllowance = safePool / daysLeft
        
        return PredictiveTrajectoryResult(
            projectedBalanceAtMonthEnd: projectedEndBalance,
            isDispoCollisionProjected: isCollision,
            collisionDayOfMonth: collisionDay,
            dailyBurnRateEur: burnRate,
            recommendedAdjustedDailyAllowance: adjustedAllowance
        )
    }

    // MARK: - 9. Empirical Temporal Vulnerability Profiler
    public func analyzeTemporalVulnerability(
        transactions: [BankTransaction],
        currentDate: Date = Date()
    ) -> TemporalRiskProfile {
        let leakTxs = transactions.filter { tx in
            tx.isDebit && (
                tx.category == .deliveryLeak ||
                tx.category == .discretionary ||
                tx.category == .mobility
            )
        }
        
        guard !leakTxs.isEmpty else {
            return TemporalRiskProfile(
                isCurrentlyHighRisk: false,
                riskDescription: "Keine empirischen Verhaltens-Leaks erfasst.",
                peakWeekday: "Keiner",
                peakHourRange: "Stabil",
                historicalLeakCount: 0,
                historicalLeakVolumeEur: 0.0
            )
        }
        
        let cal = Calendar.current
        var weekdayCounts: [Int: Int] = [:]
        var weekdaySums: [Int: Double] = [:]
        var eveningLeakCount: Int = 0
        var totalLeakSum: Double = 0.0
        
        for tx in leakTxs {
            let w = cal.component(.weekday, from: tx.date)
            let h = cal.component(.hour, from: tx.date)
            let amt = abs(tx.amount)
            
            weekdayCounts[w, default: 0] += 1
            weekdaySums[w, default: 0.0] += amt
            totalLeakSum += amt
            
            if h >= 18 || h < 4 {
                eveningLeakCount += 1
            }
        }
        
        // Peak weekday
        let peakW = weekdayCounts.max(by: { $0.value < $1.value })?.key ?? 6
        let weekdayNames = ["", "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
        let peakDayName = peakW < weekdayNames.count ? weekdayNames[peakW] : "Freitag"
        
        // Current time check
        let curWeekday = cal.component(.weekday, from: currentDate)
        let curHour = cal.component(.hour, from: currentDate)
        let isEvening = curHour >= 18 || curHour < 4
        let isHighRiskDay = (curWeekday == peakW || curWeekday == 6 || curWeekday == 7 || curWeekday == 1)
        let isCurrentlyRisk = isHighRiskDay && isEvening
        
        let desc = isCurrentlyRisk
            ? "ACHTUNG: Aktuelles Zeitfenster (\(peakDayName) Abend) ist historischer Hotspot fuer Impulskaufe und Food-Delivery."
            : "Aktuell niedriges Verhaltens-Risiko. Naechstes empirisches Risikofenster: \(peakDayName) ab 18:00 Uhr."
        
        return TemporalRiskProfile(
            isCurrentlyHighRisk: isCurrentlyRisk,
            riskDescription: desc,
            peakWeekday: peakDayName,
            peakHourRange: "18:00 - 23:00 Uhr",
            historicalLeakCount: leakTxs.count,
            historicalLeakVolumeEur: totalLeakSum
        )
    }
}

// MARK: - Supporting Data Structures
public struct DailyAllowanceResult: Sendable {
    public let dailyLimitEur: Double
    public let daysRemainingUntilSalary: Int
    public let disposablePoolEur: Double
    public let isCriticalDispoWarning: Bool
}

public struct FinanceScenario: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let projectedMonthEndBalance: Double
    public let additionalDebtPayoffPossible: Double
    public let dispoRiskProbability: Double
    public let directive: String
}

public struct FinanceDirective: Identifiable, Sendable {
    public var id: String { "\(priority)_\(title)" }
    public let priority: Int
    public let title: String
    public let action: String
    public let description: String
    public let isUrgent: Bool
}

public struct MonthlyReportPlan: Identifiable, Sendable {
    public var id: String { monthTitle }
    public let monthTitle: String
    public let incomeTotal: Double
    public let totalExpenses: Double
    public let debtServiced: Double
    public let foodLeaksTotal: Double
    public let netSavingsRatePercent: Double
    public let remainingLoanBalance: Double
    public let tacticalActionItems: [String]
}

public struct RealTimePaceDiagnostics: Sendable {
    public let actualBurnRatePerDay: Double
    public let targetDailyLimit: Double
    public let isOverpacing: Bool
    public let paceVariance: Double
    public let totalVariableSpentThisMonth: Double
    public let daysPassed: Int
    public let liveDirective: String
}

