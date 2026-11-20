import Foundation

public struct DeduplicationResult: Sendable {
    public let isDuplicate: Bool
    public let matchedTransaction: BankTransaction?
    public let reason: String?

    public init(isDuplicate: Bool, matchedTransaction: BankTransaction? = nil, reason: String? = nil) {
        self.isDuplicate = isDuplicate
        self.matchedTransaction = matchedTransaction
        self.reason = reason
    }
}

public struct HaushaltsbuchImportReport: Identifiable, Sendable {
    public var id: String { "\(fileName)_\(timestamp.timeIntervalSince1970)" }
    public let fileName: String
    public let totalParsed: Int
    public let newTransactionsAdded: Int
    public let duplicatesSkipped: Int
    public let timestamp: Date

    public var summaryMessage: String {
        if newTransactionsAdded == 0 && duplicatesSkipped > 0 {
            return "Alle \(duplicatesSkipped) Buchungen in '\(fileName)' waren bereits lückenlos im System vorhanden. Keine Duplikate erzeugt."
        } else if duplicatesSkipped > 0 {
            return "\(newTransactionsAdded) neue Buchungen erfolgreich hinzugefügt. \(duplicatesSkipped) bestehende Duplikate sicher ignoriert."
        } else {
            return "\(newTransactionsAdded) neue Buchungen erfolgreich importiert."
        }
    }
}

public final class TransactionDeduplicationEngine {
    public static let shared = TransactionDeduplicationEngine()

    private let calendar = Calendar.current

    private init() {}

    /// Evaluates whether candidate is a duplicate of any transaction in the existing ledger.
    public func findDuplicate(
        candidate: BankTransaction,
        in existing: [BankTransaction],
        excludingIds: Set<String> = []
    ) -> DeduplicationResult {
        let candidateDate = calendar.startOfDay(for: candidate.date)
        let candidateAmt = abs(candidate.amount)
        let candidateTokens = extractCanonicalTokens(partner: candidate.partnerName, purpose: candidate.recipientOrPurpose)

        // 0. Split-Buchung Reconciliation Check:
        // If candidate matches the combined sum of split child transactions sharing a receipt ID
        let splitTransactions = existing.filter { $0.tags.contains("Split-Buchung") && !excludingIds.contains($0.id) }
        let splitGroups = Dictionary(grouping: splitTransactions) { tx -> String in
            tx.tags.first(where: { $0.starts(with: "receipt_") || ($0.count >= 32 && $0.contains("-")) }) ?? tx.id
        }

        for (_, groupTxs) in splitGroups {
            let groupSum = groupTxs.reduce(0.0) { $0 + abs($1.amount) }
            if abs(groupSum - candidateAmt) < 0.05 {
                if let firstTx = groupTxs.first {
                    let txDate = calendar.startOfDay(for: firstTx.date)
                    let dayDelta = abs(calendar.dateComponents([.day], from: candidateDate, to: txDate).day ?? 999)
                    let sameMonthAndYear = calendar.isDate(candidateDate, equalTo: txDate, toGranularity: .month) &&
                                          calendar.isDate(candidateDate, equalTo: txDate, toGranularity: .year)
                    if dayDelta <= (sameMonthAndYear ? 31 : 14) {
                        return DeduplicationResult(
                            isDuplicate: true,
                            matchedTransaction: firstTx,
                            reason: "Split-Buchung (\(groupTxs.count) Posten: \(String(format: "%.2f €", groupSum))) gleicht Bankbuchung ab [Growcery/Bank-Abgleich]"
                        )
                    }
                }
            }
        }

        for tx in existing {
            if excludingIds.contains(tx.id) { continue }

            // 1. Amount Equivalence Check (within 0.02 EUR tolerance to absorb rounding)
            let txAmt = abs(tx.amount)
            let amtDelta = abs(candidateAmt - txAmt)
            guard amtDelta < 0.02 else { continue }

            // 2. Flow Direction Check (both debit or both credit)
            if candidate.isDebit != tx.isDebit {
                continue
            }

            // 3. Temporal Proximity Check
            let txDate = calendar.startOfDay(for: tx.date)
            let dayDelta = abs(calendar.dateComponents([.day], from: candidateDate, to: txDate).day ?? 999)
            
            let isReceiptOrGrocery = candidate.id.starts(with: "receipt_") || tx.id.starts(with: "receipt_") ||
                                     candidate.isManual || tx.isManual ||
                                     candidate.recipientOrPurpose.contains("Growcery") || tx.recipientOrPurpose.contains("Growcery") ||
                                     candidate.rawBookingText.contains("Growcery") || tx.rawBookingText.contains("Growcery") ||
                                     candidate.tags.contains("Quittung") || tx.tags.contains("Quittung") ||
                                     candidate.tags.contains("Growcery") || tx.tags.contains("Growcery") ||
                                     candidate.budgetCategory == .essen || tx.budgetCategory == .essen ||
                                     candidate.category == .groceries || tx.category == .groceries
            
            // For standard bank-to-bank imports: exact day or +/- 1 day.
            // For Growcery Quittung <-> Haushaltsbuch Bank reconciliation:
            // The upload date of the CSV is completely independent of transaction reconciliation!
            // When the CSV is uploaded (even months or years later), its historical booking dates
            // are reconciled with the historical receipt dates across the same month (or 14 days over month boundaries).
            let maxAllowedDayDelta: Int
            if isReceiptOrGrocery {
                let sameMonthAndYear = calendar.isDate(candidateDate, equalTo: txDate, toGranularity: .month) &&
                                      calendar.isDate(candidateDate, equalTo: txDate, toGranularity: .year)
                maxAllowedDayDelta = sameMonthAndYear ? 31 : 14
            } else {
                maxAllowedDayDelta = 1
            }
            guard dayDelta <= maxAllowedDayDelta else { continue }

            // 4. Semantic Entity & Text Matching
            let txTokens = extractCanonicalTokens(partner: tx.partnerName, purpose: tx.recipientOrPurpose)
            let commonTokens = candidateTokens.intersection(txTokens)

            // Condition A: Exact raw text or purpose match on the same day
            if dayDelta == 0 && (candidate.recipientOrPurpose == tx.recipientOrPurpose || candidate.rawBookingText == tx.rawBookingText) {
                return DeduplicationResult(
                    isDuplicate: true,
                    matchedTransaction: tx,
                    reason: "Exakter Duplikat-Treffer am \(formatDate(tx.date)): '\(tx.displayRecipient)' (\(tx.formattedAmount))"
                )
            }

            // Condition B: Known canonical merchant/counterparty token overlap (e.g., penny, rewe, netflix, o2, telefonica, db, öbb, targobank)
            if !commonTokens.isEmpty {
                return DeduplicationResult(
                    isDuplicate: true,
                    matchedTransaction: tx,
                    reason: "Duplikat erkannt (Merchant: \(commonTokens.joined(separator: ", "))) am \(formatDate(tx.date)): \(tx.formattedAmount) [Delta: \(dayDelta) Tag(e)]"
                )
            }

            // Condition C: Substring containment between partner names
            let p1 = candidate.partnerName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let p2 = tx.partnerName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if (p1.count >= 4 && p2.contains(p1)) || (p2.count >= 4 && p1.contains(p2)) {
                return DeduplicationResult(
                    isDuplicate: true,
                    matchedTransaction: tx,
                    reason: "Namens-Duplikat ('\(tx.partnerName)') am \(formatDate(tx.date)): \(tx.formattedAmount) [Delta: \(dayDelta) Tag(e)]"
                )
            }

            // Condition D: Same or close day + same amount and compatible/grocery context
            if dayDelta <= (isReceiptOrGrocery ? 4 : 0) && candidateAmt >= 2.00 {
                let clean1 = p1.filter { $0.isLetter }
                let clean2 = p2.filter { $0.isLetter }
                if clean1.isEmpty || clean2.isEmpty || clean1.prefix(3) == clean2.prefix(3) || isReceiptOrGrocery {
                    return DeduplicationResult(
                        isDuplicate: true,
                        matchedTransaction: tx,
                        reason: "Identischer Betrag im Zeitfenster von \(dayDelta) Tag(en) bereits verbucht (\(tx.formattedAmount)) [Growcery/Bank-Abgleich]"
                    )
                }
            }
        }

        return DeduplicationResult(isDuplicate: false, matchedTransaction: nil, reason: nil)
    }

    /// Generates a normalized stable fingerprint key for fast set-based filtering.
    public func stableFingerprint(date: Date, amount: Double, partner: String, purpose: String) -> String {
        let dayStr = formatDate(date)
        let amtStr = String(format: "%.2f", abs(amount))
        let tokens = extractCanonicalTokens(partner: partner, purpose: purpose)
        let sortedTokens = tokens.sorted().prefix(3).joined(separator: "-")
        return "\(dayStr)_\(amtStr)_\(sortedTokens)"
    }

    private func extractCanonicalTokens(partner: String, purpose: String) -> Set<String> {
        let stopWords: Set<String> = [
            "kartenzahlung", "lastschrift", "gutschrift", "dauerauftrag", "kartennummer",
            "gmbh", "co", "kg", "se", "ag", "ohg", "ug", "ltd", "inc", "eur", "de",
            "per", "ihr", "einkauf", "bei", "bitte", "rückfragen", "angeben", "valuta",
            "datum", "uhr", "kauf", "umsatz", "beleg", "quittung", "transaktion", "iban",
            "bic", "konto", "kredit", "rate", "echtzeitüberweisung", "ueberweisung"
        ]

        let full = "\(partner) \(purpose)".lowercased()
        let words = full.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopWords.contains($0) && !($0.allSatisfy { $0.isNumber }) }

        return Set(words)
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
}

