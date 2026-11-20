//
//  EnvelopeRolloverEngine.swift
//  GrowFinance
//
//  Envelope Rollover & Sinking Fund Engine
//  Formalizes rollover rules:
//  1. Sinking Fund Accumulation for variable recurring budgets (Nebenkosten, Gesundheit, Kleidung, Transport, Wohnkosten).
//  2. Automated Sweep Rules for discretionary categories (Essen, Privat, Unterhaltung, Getränke) into Targobank Sondertilgung.
//

import Foundation

public actor EnvelopeRolloverEngine {
    public static let shared = EnvelopeRolloverEngine()

    // Sinking Fund categories (unspent amount accumulates for irregular / future peaks)
    public static let sinkingFundCategories: Set<BudgetCategory> = [
        .nebenkosten,
        .gesundheit,
        .kleidung,
        .transport,
        .wohnkosten
    ]

    // Discretionary sweep categories (surplus swept into debt repayment pool)
    public static let discretionarySweepCategories: Set<BudgetCategory> = [
        .essen,
        .privat,
        .unterhaltung,
        .getraenke
    ]

    public init() {}

    /// Computes the complete rollover ledger asynchronously on background cooperative pool
    public func computeRolloverLedger(
        budgets: [CategoryBudget],
        transactions: [BankTransaction],
        currentDate: Date = Date()
    ) -> EnvelopeRolloverLedger {
        return computeRolloverLedgerInternal(budgets: budgets, transactions: transactions, currentDate: currentDate)
    }

    /// Synchronous convenience accessor
    public nonisolated func computeRolloverLedgerSync(
        budgets: [CategoryBudget],
        transactions: [BankTransaction],
        currentDate: Date = Date()
    ) -> EnvelopeRolloverLedger {
        return computeRolloverLedgerInternal(budgets: budgets, transactions: transactions, currentDate: currentDate)
    }

    private nonisolated func computeRolloverLedgerInternal(
        budgets: [CategoryBudget],
        transactions: [BankTransaction],
        currentDate: Date = Date()
    ) -> EnvelopeRolloverLedger {
        let calendar = Calendar.current
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentDate)

        // Filter out internal transfers and income
        let operatingExpenses = transactions.filter { $0.amount < 0 && !$0.isInternalTransfer }

        // Group past transactions by (Year-Month, BudgetCategory)
        var historicalSpending: [String: [BudgetCategory: Double]] = [:]
        var currentMonthSpending: [BudgetCategory: Double] = [:]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"

        for tx in operatingExpenses {
            guard let cat = tx.budgetCategory ?? mapToBudgetCategory(tx.category) else {
                continue
            }
            let txComponents = calendar.dateComponents([.year, .month], from: tx.date)
            let absAmount = abs(tx.amount)

            if txComponents.year == currentMonthComponents.year && txComponents.month == currentMonthComponents.month {
                currentMonthSpending[cat, default: 0.0] += absAmount
            } else if let txDate = tx.date as Date? {
                let monthKey = dateFormatter.string(from: txDate)
                historicalSpending[monthKey, default: [:]][cat, default: 0.0] += absAmount
            }
        }

        var totalSinkingFundsAccumulated = 0.0
        var totalDebtSweepGenerated = 0.0
        var statuses: [CategoryRolloverStatus] = []

        for category in BudgetCategory.allCases {
            let limit = budgets.first(where: { $0.category == category })?.monthlyLimit ?? category.defaultMonthlyLimit
            let isSinking = Self.sinkingFundCategories.contains(category)
            let rolloverType: EnvelopeRolloverType = isSinking ? .sinkingFund : .debtRepaymentSweep

            var accumulatedSinking = 0.0
            var historicalSweep = 0.0

            // Evaluate past months in chronological order
            let pastMonths = historicalSpending.keys.sorted()
            for m in pastMonths {
                let spentInMonth = historicalSpending[m]?[category] ?? 0.0
                let monthlySurplus = limit - spentInMonth

                if isSinking {
                    // Sinking fund accumulates surplus or covers deficit
                    accumulatedSinking += monthlySurplus
                    if accumulatedSinking < 0 {
                        accumulatedSinking = 0.0 // reset at bottom
                    }
                } else {
                    // Discretionary surplus is swept into debt repayment
                    if monthlySurplus > 0 {
                        historicalSweep += monthlySurplus
                    }
                }
            }

            let spentThisMonth = currentMonthSpending[category] ?? 0.0

            if isSinking {
                totalSinkingFundsAccumulated += max(0.0, accumulatedSinking)
            } else {
                // Potential month-end sweep projected from remaining unspent budget
                let currentProjectedSweep = max(0.0, limit - spentThisMonth)
                totalDebtSweepGenerated += (historicalSweep + currentProjectedSweep)
            }

            let status = CategoryRolloverStatus(
                category: category,
                type: rolloverType,
                allocatedMonthlyBudget: limit,
                spentThisMonth: spentThisMonth,
                accumulatedSinkingBalance: max(0.0, accumulatedSinking),
                sweptToDebtAmount: isSinking ? 0.0 : (historicalSweep + max(0.0, limit - spentThisMonth))
            )
            statuses.append(status)
        }

        return EnvelopeRolloverLedger(
            lastUpdated: currentDate,
            totalSinkingFundsAccumulated: totalSinkingFundsAccumulated,
            totalDebtSweepGenerated: totalDebtSweepGenerated,
            categoryStatuses: statuses
        )
    }

    private nonisolated func mapToBudgetCategory(_ cat: TransactionCategory) -> BudgetCategory? {
        switch cat {
        case .groceries, .deliveryLeak:
            return .essen
        case .fixedContracts:
            return .nebenkosten
        case .mobility:
            return .transport
        case .discretionary:
            return .privat
        case .besoldung, .incomeOther, .debtServicing, .bankFees, .internalTransfer, .other:
            return nil
        }
    }
}
