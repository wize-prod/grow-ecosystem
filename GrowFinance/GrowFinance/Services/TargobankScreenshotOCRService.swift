import Foundation
import UIKit
import Vision

public struct ParsedTransactionDraft: Identifiable, Equatable {
    public let id: String = UUID().uuidString
    public var date: Date
    public var amount: Double
    public var partnerName: String
    public var purpose: String
    public var category: TransactionCategory
    public var targetAccountId: String
    public var rawText: String
    public var savedImageFilename: String
    public var isDuplicate: Bool
    public var duplicateReason: String?
    public var detectedPlatform: String

    public init(
        date: Date = Date(),
        amount: Double = 0.0,
        partnerName: String = "",
        purpose: String = "",
        category: TransactionCategory = .other,
        targetAccountId: String = "",
        rawText: String = "",
        savedImageFilename: String = "",
        isDuplicate: Bool = false,
        duplicateReason: String? = nil,
        detectedPlatform: String = "TARGOBANK"
    ) {
        self.date = date
        self.amount = amount
        self.partnerName = partnerName
        self.purpose = purpose
        self.category = category
        self.targetAccountId = targetAccountId
        self.rawText = rawText
        self.savedImageFilename = savedImageFilename
        self.isDuplicate = isDuplicate
        self.duplicateReason = duplicateReason
        self.detectedPlatform = detectedPlatform
    }
}

public struct TargobankOCRResult: Sendable {
    public let success: Bool
    public let record: TargobankScreenshotRecord?
    public let suggestedCategory: TransactionCategory
    public let isDuplicate: Bool
    public let duplicateReason: String?
    public let detectedPlatform: String

    public init(
        success: Bool,
        record: TargobankScreenshotRecord?,
        suggestedCategory: TransactionCategory,
        isDuplicate: Bool,
        duplicateReason: String?,
        detectedPlatform: String = "TARGOBANK"
    ) {
        self.success = success
        self.record = record
        self.suggestedCategory = suggestedCategory
        self.isDuplicate = isDuplicate
        self.duplicateReason = duplicateReason
        self.detectedPlatform = detectedPlatform
    }
}

// MARK: - UIImage Orientation Normalizer
extension UIImage {
    fileprivate func fixOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}

public final class TargobankScreenshotOCRService {
    public static let shared = TargobankScreenshotOCRService()

    private let screenshotsDirectoryURL: URL

    private init() {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.screenshotsDirectoryURL = docs.appendingPathComponent("TargobankScreenshots", isDirectory: true)

        if !fileManager.fileExists(atPath: screenshotsDirectoryURL.path) {
            try? fileManager.createDirectory(at: screenshotsDirectoryURL, withIntermediateDirectories: true)
        }
    }

    public func getScreenshotImage(filename: String) -> UIImage? {
        let fileURL = screenshotsDirectoryURL.appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }

    public func loadImage(filename: String) -> UIImage? {
        getScreenshotImage(filename: filename)
    }

    public func processScreenshot(
        image: UIImage,
        existingTransactions: [BankTransaction],
        existingScreenshots: [TargobankScreenshotRecord]
    ) async -> TargobankOCRResult {
        await withCheckedContinuation { continuation in
            parseScreenshot(image: image, existingTransactions: existingTransactions) { result in
                switch result {
                case .success(let draft):
                    var isDup = draft.isDuplicate
                    var dupReason = draft.duplicateReason

                    if !isDup {
                        for rec in existingScreenshots {
                            if let recAmt = rec.extractedAmount, abs(abs(recAmt) - abs(draft.amount)) < 0.05,
                               let recDate = rec.extractedDate, Calendar.current.isDate(recDate, inSameDayAs: draft.date) {
                                isDup = true
                                let df = DateFormatter()
                                df.dateFormat = "dd.MM.yyyy"
                                dupReason = "Screenshot-Duplikat: Bereits am \(df.string(from: rec.timestamp)) erfasst."
                                break
                            }
                        }
                    }

                    let record = TargobankScreenshotRecord(
                        id: draft.id,
                        filename: draft.savedImageFilename,
                        timestamp: Date(),
                        extractedDate: draft.date,
                        extractedAmount: draft.amount,
                        extractedPartner: draft.partnerName,
                        extractedPurpose: draft.purpose,
                        extractedAccount: draft.targetAccountId,
                        isBooked: false,
                        bookedTransactionId: nil,
                        isDuplicate: isDup,
                        duplicateReason: dupReason,
                        rawText: draft.rawText
                    )

                    let res = TargobankOCRResult(
                        success: abs(draft.amount) > 0.01,
                        record: record,
                        suggestedCategory: draft.category,
                        isDuplicate: isDup,
                        duplicateReason: dupReason,
                        detectedPlatform: draft.detectedPlatform
                    )
                    continuation.resume(returning: res)

                case .failure(let err):
                    let res = TargobankOCRResult(
                        success: false,
                        record: nil,
                        suggestedCategory: .other,
                        isDuplicate: false,
                        duplicateReason: err.localizedDescription,
                        detectedPlatform: "UNBEKANNT"
                    )
                    continuation.resume(returning: res)
                }
            }
        }
    }

    public func saveScreenshotImage(_ image: UIImage) -> String {
        let filename = "tb_scan_\(UUID().uuidString.prefix(8)).jpg"
        let fileURL = screenshotsDirectoryURL.appendingPathComponent(filename)
        if let jpeg = image.jpegData(compressionQuality: 0.85) {
            try? jpeg.write(to: fileURL, options: .atomic)
        }
        return filename
    }

    public func parseScreenshot(
        image: UIImage,
        existingTransactions: [BankTransaction],
        completion: @escaping (Result<ParsedTransactionDraft, Error>) -> Void
    ) {
        let normalized = image.fixOrientation()
        guard let cgImage = normalized.cgImage else {
            completion(.failure(NSError(domain: "TargobankOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungueltiges Bildformat"])))
            return
        }

        let savedFilename = saveScreenshotImage(normalized)

        let request = VNRecognizeTextRequest { [weak self] req, error in
            guard let self = self else { return }
            if let err = error {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }

            guard let observations = req.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                let fallback = ParsedTransactionDraft(
                    date: Date(),
                    amount: 0.0,
                    partnerName: "Buchung",
                    purpose: "Manuelle Ueberpruefung erforderlich",
                    category: .other,
                    rawText: "",
                    savedImageFilename: savedFilename,
                    isDuplicate: false,
                    detectedPlatform: "BELEG"
                )
                DispatchQueue.main.async { completion(.success(fallback)) }
                return
            }

            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = lines.joined(separator: "\n")

            let draft = self.extractTransaction(lines: lines, fullText: fullText, savedFilename: savedFilename, existingTransactions: existingTransactions)

            DispatchQueue.main.async {
                completion(.success(draft))
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Deterministic Multi-Platform Extraction Engine
    private func extractTransaction(
        lines: [String],
        fullText: String,
        savedFilename: String,
        existingTransactions: [BankTransaction]
    ) -> ParsedTransactionDraft {
        var detectedDate = Date()
        var detectedAmount: Double = 0.0
        var detectedPartner: String = ""
        var detectedPurpose: String = ""
        var targetAccountId: String = "3201649568"
        var detectedPlatform = "TARGOBANK"

        let lowerText = fullText.lowercased()

        // 1. Detect Platform / Source
        if lowerText.contains("genehmigt") || lowerText.contains("visa debitkarte") || lowerText.contains("apple pay") || lowerText.contains("karteninhaber") || lowerText.contains("saferpay") || lowerText.contains("wallet") {
            detectedPlatform = "APPLE WALLET"
            targetAccountId = "3201649568" // Plus-Konto Debitkarte
        } else if lowerText.contains("targobank") || lowerText.contains("plus-konto") || lowerText.contains("3201 6495 68") || lowerText.contains("de28 3002") {
            detectedPlatform = "TARGOBANK"
            if lowerText.contains("tagesgeld") {
                targetAccountId = "tagesgeld_2413"
            } else if lowerText.contains("kredit") || lowerText.contains("darlehen") {
                targetAccountId = "online_kredit"
            } else {
                targetAccountId = "3201649568"
            }
        } else {
            detectedPlatform = "BELEG"
            targetAccountId = "3201649568"
        }

        // 2. Parse Date
        // Matches e.g. "16.09.2026", "18.09.26, 16:32", "18.09.26"
        let dateRegex = try? NSRegularExpression(pattern: #"(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#)
        for line in lines {
            if let match = dateRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let r = Range(match.range, in: line) {
                    let dateStr = String(line[r])
                    let df = DateFormatter()
                    df.locale = Locale(identifier: "de_DE")
                    df.dateFormat = dateStr.count <= 8 ? "dd.MM.yy" : "dd.MM.yyyy"
                    if let parsed = df.date(from: dateStr) {
                        detectedDate = parsed
                        break
                    }
                }
            }
        }

        // 3. Parse Amount
        // Handles "- 29,99 €", "5,90 €", "1.000,00 EUR", "+ 2.500,00 €"
        let amountRegex = try? NSRegularExpression(pattern: #"([+-]?\s*\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:EUR|€)?"#)
        for line in lines {
            if let match = amountRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let r = Range(match.range(at: 1), in: line) {
                    var cleanStr = String(line[r]).replacingOccurrences(of: " ", with: "")
                    cleanStr = cleanStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                    if let val = Double(cleanStr), abs(val) > 0.01 {
                        if detectedPlatform == "APPLE WALLET" {
                            let isExplicitPlus = line.contains("+") || lowerText.contains("gutschrift") || lowerText.contains("erstattung")
                            detectedAmount = isExplicitPlus ? abs(val) : -abs(val)
                        } else {
                            let isNeg = line.contains("-") || val < 0 || lowerText.contains("lastschrift") || lowerText.contains("auszahlung")
                            detectedAmount = isNeg ? -abs(val) : abs(val)
                        }
                        break
                    }
                }
            }
        }

        // 4. Extract Partner & Purpose
        if detectedPlatform == "APPLE WALLET" {
            let walletBoilerplate = Set([
                "genehmigt", "abgeschlossen", "visa debitkarte plus", "visa debitkarte",
                "debitkarte", "apple pay", "karte", "transaktion", "transaktionsbetrag",
                "beleg", "saferpay", "www.saferpay.com", "karteninhaber", "status",
                "karte:", "datum:", "betrag:", "zahlungsmethode", "fertig", "zurück"
            ])

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.count < 2 { continue }
                let lower = trimmed.lowercased()
                if walletBoilerplate.contains(lower) { continue }
                if lower.contains("debitkarte") || lower.contains("saferpay") || lower.contains("genehmigt") { continue }
                if dateRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil && (lower.contains(":") || lower.contains(",")) {
                    continue
                }
                if amountRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil && (lower.contains("€") || lower.contains("eur")) {
                    continue
                }
                detectedPartner = trimmed
                break
            }
            if detectedPartner.isEmpty {
                detectedPartner = "Apple Pay Zahlung"
            }
            detectedPurpose = "Apple Pay Transaktion via Visa Debitkarte Plus"
        } else {
            let boilerplate = Set([
                "targobank", "umsatz", "umsätze", "buchungsdetails", "details", "betrag", "valuta",
                "buchung", "buchungstag", "verwendungszweck", "empfänger", "zahlungsempfänger",
                "auftraggeber", "iban", "bic", "plus-konto", "tagesgeld", "konto", "kontostand",
                "zurück", "teilen", "drucken", "kategorie", "saldo"
            ])

            var meaningfulLines: [String] = []
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.count < 3 { continue }
                let lower = trimmed.lowercased()
                if boilerplate.contains(lower) { continue }
                if lower.hasPrefix("de") && lower.count >= 20 { continue }
                if lower.contains("iban:") || lower.contains("bic:") { continue }
                if lower.contains("datum:") || lower.contains("valuta:") { continue }
                if lower.hasSuffix("eur") || lower.hasSuffix("€") { continue }
                meaningfulLines.append(trimmed)
            }

            if let first = meaningfulLines.first {
                detectedPartner = first
            }
            if meaningfulLines.count > 1 {
                detectedPurpose = meaningfulLines.dropFirst().prefix(2).joined(separator: " ")
            }

            if detectedPartner.isEmpty {
                detectedPartner = detectedPlatform == "TARGOBANK" ? "Targobank Umsatz" : "Beleg Buchung"
            }
        }

        // 5. Auto-Categorize
        let category = categorize(partner: detectedPartner, purpose: detectedPurpose, amount: detectedAmount)

        // 6. Duplicate Detection (Against Haushaltsbuch & SQLite Transactions)
        var isDuplicate = false
        var duplicateReason: String? = nil

        let calendar = Calendar.current
        for tx in existingTransactions {
            let sameDay = calendar.isDate(tx.date, inSameDayAs: detectedDate)
            let amountDiff = abs(abs(tx.amount) - abs(detectedAmount))
            let sameAmount = amountDiff < 0.05

            if sameDay && sameAmount {
                let p1 = tx.partnerName.lowercased()
                let p2 = detectedPartner.lowercased()
                let fuzzyMatch = p1.contains(p2) || p2.contains(p1) || p1.prefix(3) == p2.prefix(3)
                let commonExpense = p1.contains("paypal") || p2.contains("paypal") || p1.contains("öbb") || p2.contains("öbb")
                if fuzzyMatch || commonExpense || detectedPartner.count <= 4 {
                    isDuplicate = true
                    let df = DateFormatter()
                    df.dateFormat = "dd.MM.yyyy"
                    duplicateReason = "Bereits am \(df.string(from: tx.date)) als '\(tx.partnerName)' (\(String(format: "%.2f €", tx.amount))) im Haushaltsbuch verbucht."
                    break
                }
            }
        }

        return ParsedTransactionDraft(
            date: detectedDate,
            amount: detectedAmount,
            partnerName: detectedPartner,
            purpose: detectedPurpose.isEmpty ? "Umsatz via Screenshot erfasst" : detectedPurpose,
            category: category,
            targetAccountId: targetAccountId,
            rawText: fullText,
            savedImageFilename: savedFilename,
            isDuplicate: isDuplicate,
            duplicateReason: duplicateReason,
            detectedPlatform: detectedPlatform
        )
    }

    private func categorize(partner: String, purpose: String, amount: Double) -> TransactionCategory {
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
}
