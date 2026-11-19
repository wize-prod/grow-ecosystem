//
//  TransferReconciliationEngine.swift
//  GrowFinance
//
//  Autonomous Two-Leg Internal Transfer Reconciliation Engine
//  Detects and neutralizes symmetrical debit/credit transfers across
//  Targobank checking, savings, and credit accounts to eliminate operating volume inflation.
//

import Foundation

public struct TransferReconciliationResult {
    public let reconciledTransactions: [BankTransaction]
    public let matchedPairCount: Int
    public let neutralizedVolume: Double
}

public actor TransferReconciliationEngine {
    public static let shared = TransferReconciliationEngine()

    // Known internal account identifiers (Targobank kontoführend)
    private nonisolated let internalAccountIdentifiers: Set<String> = [
        "3201649568", // PLUS-KONTO (Giro)
        "5211062413", // TAGESGELDKONTO 1
        "5291062407", // TAGESGELDKONTO 2
        "5221062404", // TAGESGELDKONTO 3
        "7203978276"  // ONLINE-KREDIT
    ]

    private nonisolated let transferKeywords: [String] = [
        "umbuchung",
        "uebertrag",
        "übertrag",
        "interner uebertrag",
        "interner übertrag",
        "tagesgeld",
        "plus-konto",
        "plus konto",
        "online-kredit",
        "online kredit",
        "sondertilgung",
        "kontoausgleich",
        "kreditrate targobank",
        "tilgung kredit",
        "sparruecklage",
        "eigenuebertrag",
        "eigenübertrag"
    ]

    private nonisolated let userSelfIdentifiers: [String] = [
        "parris-campbell nkembi",
        "parris campbell",
        "nkembi",
        "campbell nkembi"
    ]

    public init() {}

    /// Performs a two-pass reconciliation asynchronously on background cooperative pool
    public func reconcile(transactions: [BankTransaction]) -> TransferReconciliationResult {
        return reconcileInternal(transactions: transactions)
    }

    /// Synchronous convenience accessor
    public nonisolated func reconcileSync(transactions: [BankTransaction]) -> TransferReconciliationResult {
        return reconcileInternal(transactions: transactions)
    }

    private nonisolated func reconcileInternal(transactions: [BankTransaction]) -> TransferReconciliationResult {
        var mutableList = transactions
        var matchedIndices = Set<Int>()
        var matchedPairCount = 0
        var neutralizedVolume = 0.0

        let count = mutableList.count
        guard count > 1 else {
            return TransferReconciliationResult(
                reconciledTransactions: mutableList,
                matchedPairCount: 0,
                neutralizedVolume: 0.0
            )
        }

        // Sort by date ascending to evaluate chronologically
        let indexed = mutableList.enumerated().sorted { $0.element.date < $1.element.date }

        for i in 0..<indexed.count {
            let indexA = indexed[i].offset
            if matchedIndices.contains(indexA) { continue }

            let txA = mutableList[indexA]

            // Look for matching opposite transaction txB within 2.5 calendar days
            for j in (i + 1)..<indexed.count {
                let indexB = indexed[j].offset
                if matchedIndices.contains(indexB) { continue }

                let txB = mutableList[indexB]

                // Time difference in seconds
                let deltaSeconds = abs(txB.date.timeIntervalSince(txA.date))
                if deltaSeconds > (2.5 * 86400) {
                    // Beyond matching time window
                    break
                }

                // Check opposite signs and identical absolute amounts
                let amountSum = txA.amount + txB.amount
                if abs(amountSum) <= 0.02 && (txA.amount * txB.amount < 0) {
                    // Check if this pair qualifies as an internal transfer
                    if isTransferPair(txA: txA, txB: txB) {
                        matchedIndices.insert(indexA)
                        matchedIndices.insert(indexB)
                        matchedPairCount += 1
                        neutralizedVolume += abs(txA.amount)

                        // Update txA
                        mutableList[indexA].isInternalTransfer = true
                        mutableList[indexA].linkedTransferTransactionId = txB.id
                        mutableList[indexA].category = .internalTransfer

                        // Update txB
                        mutableList[indexB].isInternalTransfer = true
                        mutableList[indexB].linkedTransferTransactionId = txA.id
                        mutableList[indexB].category = .internalTransfer

                        break
                    }
                }
            }
        }

        // Second pass: single transactions explicitly marked as internal transfer or self-reallocation
        for idx in 0..<mutableList.count {
            if !matchedIndices.contains(idx) {
                let tx = mutableList[idx]
                if isExplicitStandaloneTransfer(tx: tx) {
                    mutableList[idx].isInternalTransfer = true
                    mutableList[idx].category = .internalTransfer
                }
            }
        }

        return TransferReconciliationResult(
            reconciledTransactions: mutableList,
            matchedPairCount: matchedPairCount,
            neutralizedVolume: neutralizedVolume
        )
    }

    private nonisolated func isTransferPair(txA: BankTransaction, txB: BankTransaction) -> Bool {
        // Condition 1: Category already marked internal transfer
        if txA.category == .internalTransfer || txB.category == .internalTransfer {
            return true
        }

        let textA = "\(txA.partnerName) \(txA.recipientOrPurpose) \(txA.rawBookingText)".lowercased()
        let textB = "\(txB.partnerName) \(txB.recipientOrPurpose) \(txB.rawBookingText)".lowercased()

        // Condition 2: Known internal account numbers
        for acc in internalAccountIdentifiers {
            if textA.contains(acc) || textB.contains(acc) ||
               txA.accountIBAN.contains(acc) || txB.accountIBAN.contains(acc) {
                return true
            }
        }

        // Condition 3: Explicit transfer keywords
        for keyword in transferKeywords {
            if textA.contains(keyword) || textB.contains(keyword) {
                return true
            }
        }

        // Condition 4: User self-transfers
        for selfId in userSelfIdentifiers {
            if textA.contains(selfId) && textB.contains(selfId) {
                return true
            }
        }

        return false
    }

    private nonisolated func isExplicitStandaloneTransfer(tx: BankTransaction) -> Bool {
        if tx.category == .internalTransfer {
            return true
        }
        let text = "\(tx.partnerName) \(tx.recipientOrPurpose) \(tx.rawBookingText)".lowercased()
        for keyword in ["umbuchung", "uebertrag", "übertrag", "tagesgeldkonto", "interner uebertrag"] {
            if text.contains(keyword) {
                return true
            }
        }
        return false
    }
}

