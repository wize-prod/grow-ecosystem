//
//  CadencePatternScanner.swift
//  GrowFinance
//
//  Unsupervised Cadence Pattern Scanner
//  Computes temporal deltas (ΔD), detects recurring subscriptions and contracts,
//  and flags stealth price hikes across historical transactions.
//

import Foundation

public actor CadencePatternScanner {
    public static let shared = CadencePatternScanner()

    public init() {}

    /// Analyzes the full list of transactions asynchronously on background cooperative pool
    public func scanCadences(
        transactions: [BankTransaction],
        registeredContracts: [FinanceContractOrSubscription]
    ) -> [DetectedCadencePattern] {
        return scanCadencesInternal(transactions: transactions, registeredContracts: registeredContracts)
    }

    /// Synchronous convenience accessor
    public nonisolated func scanCadencesSync(
        transactions: [BankTransaction],
        registeredContracts: [FinanceContractOrSubscription]
    ) -> [DetectedCadencePattern] {
        return scanCadencesInternal(transactions: transactions, registeredContracts: registeredContracts)
    }

    private nonisolated func scanCadencesInternal(
        transactions: [BankTransaction],
        registeredContracts: [FinanceContractOrSubscription]
    ) -> [DetectedCadencePattern] {
        // Exclude internal transfers and credit gains
        let debits = transactions.filter { $0.amount < 0 && !$0.isInternalTransfer }

        // Group transactions by canonical merchant name
        var grouped: [String: [BankTransaction]] = [:]
        for tx in debits {
            let key = canonicalizeMerchant(tx: tx)
            guard !key.isEmpty else { continue }
            grouped[key, default: []].append(tx)
        }

        var patterns: [DetectedCadencePattern] = []

        for (counterparty, txGroup) in grouped {
            // Need at least 2 occurrences to compute interval
            guard txGroup.count >= 2 else { continue }

            let sortedGroup = txGroup.sorted { $0.date < $1.date }
            let dates = sortedGroup.map { $0.date }

            // Compute delta days between consecutive occurrences
            var deltas: [Double] = []
            for i in 0..<(dates.count - 1) {
                let diffSeconds = dates[i + 1].timeIntervalSince(dates[i])
                let diffDays = diffSeconds / 86400.0
                deltas.append(diffDays)
            }

            guard !deltas.isEmpty else { continue }

            let meanDelta = deltas.reduce(0.0, +) / Double(deltas.count)
            let variance = deltas.reduce(0.0) { $0 + pow($1 - meanDelta, 2) } / Double(deltas.count)
            let stdDev = sqrt(variance)

            // Classify interval cadence
            let (cadence, confidence) = classifyCadence(meanDays: meanDelta, stdDev: stdDev, count: sortedGroup.count)
            guard cadence != .irregular else { continue }

            // Detect price adjustments
            let latestTx = sortedGroup.last!
            let latestAbsAmount = abs(latestTx.amount)

            var previousAbsAmount: Double? = nil
            var hasPriceHike = false
            var priceHikeDelta = 0.0

            if sortedGroup.count >= 2 {
                let prevTx = sortedGroup[sortedGroup.count - 2]
                let prevAmt = abs(prevTx.amount)
                previousAbsAmount = prevAmt

                if latestAbsAmount > prevAmt + 0.10 {
                    hasPriceHike = true
                    priceHikeDelta = latestAbsAmount - prevAmt
                }
            }

            // Check if registered in contracts
            let isRegistered = registeredContracts.contains { contract in
                let cName = contract.name.lowercased()
                let cProv = contract.provider.lowercased()
                let cpLower = counterparty.lowercased()
                return cName.contains(cpLower) || cpLower.contains(cName) ||
                       (!cProv.isEmpty && (cProv.contains(cpLower) || cpLower.contains(cProv)))
            }

            let firstTx = sortedGroup.first!
            let (recType, recBudget) = deduceRecommendation(
                counterparty: counterparty,
                sampleBookingText: latestTx.rawBookingText
            )

            let pattern = DetectedCadencePattern(
                counterparty: formatDisplayName(counterparty),
                averageIntervalDays: meanDelta,
                cadence: cadence,
                latestAmount: latestAbsAmount,
                previousAmount: previousAbsAmount,
                hasPriceHike: hasPriceHike,
                priceHikeDelta: priceHikeDelta,
                isRegisteredSubscription: isRegistered,
                transactionIds: sortedGroup.map { $0.id },
                confidenceScore: confidence,
                lastSeenDate: latestTx.date,
                firstSeenDate: firstTx.date,
                occurrenceCount: sortedGroup.count,
                recommendedType: recType,
                recommendedBudgetCategory: recBudget
            )

            patterns.append(pattern)
        }

        // Pass 2: Detect single/recent transactions with explicit recurring markers (Dauerauftrag / Folgelastschrift)
        for (counterparty, txGroup) in grouped {
            if txGroup.count == 1 {
                let tx = txGroup.first!
                let raw = "\(tx.partnerName) \(tx.recipientOrPurpose) \(tx.rawBookingText)".lowercased()
                let hasRecurringMarker = raw.contains("dauerauftrag") ||
                                         raw.contains("folgelastschrift") ||
                                         raw.contains("wiederkehrend") ||
                                         raw.contains("monatsbeitrag") ||
                                         raw.contains("mitgliedsbeitrag") ||
                                         raw.contains("rundfunkbeitrag") ||
                                         raw.contains("abo") ||
                                         raw.contains("subscription") ||
                                         raw.contains("apple.com/bill") ||
                                         raw.contains("google *") ||
                                         raw.contains("netflix") ||
                                         raw.contains("spotify")

                if hasRecurringMarker {
                    let isRegistered = registeredContracts.contains { contract in
                        let cName = contract.name.lowercased()
                        let cProv = contract.provider.lowercased()
                        let cpLower = counterparty.lowercased()
                        return cName.contains(cpLower) || cpLower.contains(cName) ||
                               (!cProv.isEmpty && (cProv.contains(cpLower) || cpLower.contains(cProv)))
                    }

                    let (recType, recBudget) = deduceRecommendation(
                        counterparty: counterparty,
                        sampleBookingText: tx.rawBookingText
                    )

                    let pattern = DetectedCadencePattern(
                        counterparty: formatDisplayName(counterparty),
                        averageIntervalDays: 30.0,
                        cadence: .monthly,
                        latestAmount: abs(tx.amount),
                        previousAmount: nil,
                        hasPriceHike: false,
                        priceHikeDelta: 0.0,
                        isRegisteredSubscription: isRegistered,
                        transactionIds: [tx.id],
                        confidenceScore: 0.75,
                        lastSeenDate: tx.date,
                        firstSeenDate: tx.date,
                        occurrenceCount: 1,
                        recommendedType: recType,
                        recommendedBudgetCategory: recBudget
                    )
                    patterns.append(pattern)
                }
            }
        }

        // Sort: unregistered new discoveries first, then stealth price hikes, then highest amount
        return patterns.sorted {
            if $0.isNewDiscovery != $1.isNewDiscovery {
                return $0.isNewDiscovery && !$1.isNewDiscovery
            }
            if $0.hasPriceHike != $1.hasPriceHike {
                return $0.hasPriceHike && !$1.hasPriceHike
            }
            return $0.latestAmount > $1.latestAmount
        }
    }

    private nonisolated func deduceRecommendation(counterparty: String, sampleBookingText: String) -> (FixedCostType, BudgetCategory) {
        let text = "\(counterparty) \(sampleBookingText)".lowercased()

        if text.contains("versicherung") || text.contains("continentale") || text.contains("huk") || text.contains("debeka") || text.contains("allianz") || text.contains("krankenkasse") || text.contains("barmenia") {
            return (.insurance, .gesundheit)
        }
        if text.contains("kaserne") || text.contains("miete") || text.contains("wohnung") || text.contains("stadtwerke") || text.contains("hausverwaltung") {
            return (.housing, .wohnkosten)
        }
        if text.contains("telekom") || text.contains("telefonica") || text.contains("o2") || text.contains("vodafone") || text.contains("rundfunk") || text.contains("beitragsservice") || text.contains("internet") {
            return (.contract, .nebenkosten)
        }
        if text.contains("kredit") || text.contains("darlehen") || text.contains("tilgung") || text.contains("rate") || text.contains("targobank") {
            return (.debtRate, .nebenkosten)
        }
        if text.contains("fitness") || text.contains("gym") || text.contains("mcfit") || text.contains("fitx") {
            return (.subscription, .gesundheit)
        }
        if text.contains("netflix") || text.contains("spotify") || text.contains("apple") || text.contains("google") || text.contains("disney") || text.contains("amazon prime") || text.contains("youtube") || text.contains("chatgpt") || text.contains("openai") || text.contains("icloud") {
            return (.subscription, .unterhaltung)
        }
        return (.subscription, .nebenkosten)
    }

    private nonisolated func classifyCadence(meanDays: Double, stdDev: Double, count: Int) -> (CadenceInterval, Double) {
        // High variance indicates non-cadenced transactions
        if stdDev > 8.0 && count < 4 {
            return (.irregular, 0.0)
        }

        let confidence: Double
        if stdDev <= 2.0 {
            confidence = 0.95
        } else if stdDev <= 4.0 {
            confidence = 0.80
        } else {
            confidence = 0.60
        }

        switch meanDays {
        case 5.5...9.0:
            return (.weekly, confidence)
        case 12.0...17.0:
            return (.biweekly, confidence)
        case 25.0...35.0:
            return (.monthly, confidence)
        case 80.0...105.0:
            return (.quarterly, confidence)
        case 340.0...390.0:
            return (.annual, confidence)
        default:
            return (.irregular, 0.0)
        }
    }

    private nonisolated func canonicalizeMerchant(tx: BankTransaction) -> String {
        var text = (tx.partnerName.isEmpty ? tx.recipientOrPurpose : tx.partnerName).lowercased()

        // Strip noise and banking prefixes
        let noisePrefixes = [
            "kartenzahlung",
            "basislastschrift",
            "folgelastschrift",
            "dauerauftrag",
            "überweisung",
            "ueberweisung",
            "gutschrift",
            "sepa-lastschrift",
            "sepa-elvr",
            "ec-karte"
        ]

        for p in noisePrefixes {
            if text.starts(with: p) {
                text = text.replacingOccurrences(of: p, with: "")
            }
        }

        // Remove dates like 20.08, 2024-08-01, numbers, reference keys
        let regexPatterns = [
            "\\b\\d{2}\\.\\d{2}\\.\\d{2,4}\\b",
            "\\b\\d{4}-\\d{2}-\\d{2}\\b",
            "\\bde\\d{20}\\b",
            "ref\\s*:[a-z0-9]+",
            "mandat\\s*:[a-z0-9]+"
        ]

        for pattern in regexPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            }
        }

        // Trim punctuation and spaces
        text = text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        // Known merchant alias standardization
        if text.contains("netflix") { return "netflix" }
        if text.contains("spotify") { return "spotify" }
        if text.contains("telekom") { return "telekom" }
        if text.contains("o2") || text.contains("telefonica") { return "o2 telefonica" }
        if text.contains("apple") || text.contains("itunes") { return "apple services" }
        if text.contains("google") { return "google" }
        if text.contains("amazon prime") || text.contains("amzn prime") { return "amazon prime" }
        if text.contains("fitness") || text.contains("mcfit") || text.contains("fitx") || text.contains("clever fit") { return "fitnessstudio" }
        if text.contains("rundfunk") || text.contains("beitragsservice") { return "ard zdf rundfunkbeitrag" }
        if text.contains("huk-coburg") || text.contains("huk coburg") { return "huk-coburg" }
        if text.contains("continentale") { return "continentale krankenversicherung" }
        if text.contains("targobank kredit") || text.contains("ratenkredit") { return "targobank online-kredit" }

        // Take the first 3 significant words
        let words: [String] = text.split(separator: " ").filter { $0.count > 1 }.map { String($0) }
        guard !words.isEmpty else { return text }
        let count = min(3, words.count)
        return words[0..<count].joined(separator: " ")
    }

    private nonisolated func formatDisplayName(_ key: String) -> String {
        key.capitalized
    }
}
