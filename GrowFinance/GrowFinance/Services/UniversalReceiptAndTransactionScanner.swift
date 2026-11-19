import Foundation
import UIKit
import Vision

public struct UniversalScanDraft: Identifiable, Equatable {
    public let id: String = UUID().uuidString
    public var date: Date
    public var amount: Double
    public var partnerName: String
    public var purpose: String
    public var category: TransactionCategory
    public var budgetCategory: BudgetCategory
    public var necessity: ExpenseNecessity
    public var tags: [String]
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
        budgetCategory: BudgetCategory = .privat,
        necessity: ExpenseNecessity = .neutral,
        tags: [String] = [],
        targetAccountId: String = "",
        rawText: String = "",
        savedImageFilename: String = "",
        isDuplicate: Bool = false,
        duplicateReason: String? = nil,
        detectedPlatform: String = "Quittung"
    ) {
        self.date = date
        self.amount = amount
        self.partnerName = partnerName
        self.purpose = purpose
        self.category = category
        self.budgetCategory = budgetCategory
        self.necessity = necessity
        self.tags = tags
        self.targetAccountId = targetAccountId
        self.rawText = rawText
        self.savedImageFilename = savedImageFilename
        self.isDuplicate = isDuplicate
        self.duplicateReason = duplicateReason
        self.detectedPlatform = detectedPlatform
    }
}

public struct UniversalOCRResult: Sendable {
    public let success: Bool
    public let draft: UniversalScanDraft?
    public let errorMessage: String?

    public init(success: Bool, draft: UniversalScanDraft?, errorMessage: String? = nil) {
        self.success = success
        self.draft = draft
        self.errorMessage = errorMessage
    }
}

public final class UniversalReceiptAndTransactionScanner {
    public static let shared = UniversalReceiptAndTransactionScanner()

    private let documentsDirectoryURL: URL

    private init() {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.documentsDirectoryURL = docs.appendingPathComponent("UniversalScans", isDirectory: true)

        if !fileManager.fileExists(atPath: documentsDirectoryURL.path) {
            try? fileManager.createDirectory(at: documentsDirectoryURL, withIntermediateDirectories: true)
        }
    }

    public func scanImage(
        image: UIImage,
        existingTransactions: [BankTransaction]
    ) async -> UniversalOCRResult {
        guard let fixedImage = normalizeImageOrientation(image),
              let cgImage = fixedImage.cgImage else {
            return UniversalOCRResult(success: false, draft: nil, errorMessage: "Bild konnte nicht verarbeitet werden.")
        }

        // 1. Save scan image locally for audit trace
        let filename = "scan_\(UUID().uuidString.prefix(8))_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = documentsDirectoryURL.appendingPathComponent(filename)
        if let jpegData = fixedImage.jpegData(compressionQuality: 0.85) {
            try? jpegData.write(to: fileURL)
        }

        // 2. Perform Vision OCR
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] req, err in
                guard let self = self else { return }
                if let err = err {
                    continuation.resume(returning: UniversalOCRResult(success: false, draft: nil, errorMessage: err.localizedDescription))
                    return
                }

                guard let observations = req.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: UniversalOCRResult(success: false, draft: nil, errorMessage: "Kein Text auf dem Beleg erkannt."))
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let fullText = lines.joined(separator: "\n")

                let draft = self.parseExtractedText(
                    lines: lines,
                    fullText: fullText,
                    savedFilename: filename,
                    existingTransactions: existingTransactions
                )

                continuation.resume(returning: UniversalOCRResult(success: true, draft: draft))
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: UniversalOCRResult(success: false, draft: nil, errorMessage: error.localizedDescription))
            }
        }
    }

    private func normalizeImageOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized
    }

    private func parseExtractedText(
        lines: [String],
        fullText: String,
        savedFilename: String,
        existingTransactions: [BankTransaction]
    ) -> UniversalScanDraft {
        let lower = fullText.lowercased()

        // 1. Detect Platform / Source
        let platform: String
        var suggestedTags: [String] = []

        if lower.contains("apple pay") || lower.contains("mit touch id") || lower.contains("mit face id") || lower.contains("apple wallet") {
            platform = "Apple Pay"
            suggestedTags.append("#applepay")
        } else if lower.contains("paypal") || lower.contains("transaktionscode") || lower.contains("sie haben eine zahlung gesendet") {
            platform = "PayPal"
            suggestedTags.append("#paypal")
        } else if lower.contains("kassenzettel") || lower.contains("kassenbon") || lower.contains("mwst") || lower.contains("bar") || lower.contains("eur") || lower.contains("summe") {
            platform = "Quittung"
            suggestedTags.append("#quittung")
        } else if lower.contains("targobank") || lower.contains("kontoauszug") || lower.contains("iban") {
            platform = "Bank / Targobank"
            suggestedTags.append("#bank")
        } else if lower.contains("haushaltsbuch") || lower.contains("einnahmen") || lower.contains("ausgaben") {
            platform = "Haushaltsbuch"
            suggestedTags.append("#haushaltsbuch")
        } else {
            platform = "Beleg / Scan"
            suggestedTags.append("#beleg")
        }

        // 2. Extract Amount
        var detectedAmount: Double = 0.0
        let amountPatterns = [
            #"(?:summe|total|gesamt|betrag|endbetrag|zu\s*zahlen|bezahlt|eur|€)\s*[:=]?\s*([+-]?\s*\d{1,4}[.,]\d{2})"#,
            #"([+-]?\s*\d{1,4}[.,]\d{2})\s*(?:eur|€)"#,
            #"([+-]?\d{1,4}[.,]\d{2})\s*$"#
        ]

        for line in lines.reversed() {
            let lineLower = line.lowercased()
            var matchedAmt: Double? = nil

            for pattern in amountPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let nsString = lineLower as NSString
                    let results = regex.matches(in: lineLower, options: [], range: NSRange(location: 0, length: nsString.length))
                    if let match = results.first, match.numberOfRanges > 1 {
                        let matchRange = match.range(at: 1)
                        var str = nsString.substring(with: matchRange)
                        str = str.replacingOccurrences(of: " ", with: "")
                        str = str.replacingOccurrences(of: ",", with: ".")
                        if let d = Double(str), d > 0.01 && d < 10000.0 {
                            matchedAmt = d
                            break
                        }
                    }
                }
            }

            if let found = matchedAmt {
                detectedAmount = found
                break
            }
        }

        // 3. Extract Date
        var detectedDate = Date()
        let datePatterns = [
            #"(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})"#,
            #"(\d{4})[./-](\d{1,2})[./-](\d{1,2})"#
        ]

        for line in lines {
            for pattern in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let nsString = line as NSString
                    let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
                    if let match = matches.first {
                        let dateStr = nsString.substring(with: match.range)
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "de_DE")
                        for format in ["dd.MM.yyyy", "dd.MM.yy", "dd/MM/yyyy", "dd-MM-yyyy", "yyyy-MM-dd"] {
                            df.dateFormat = format
                            if let d = df.date(from: dateStr) {
                                detectedDate = d
                                break
                            }
                        }
                    }
                }
            }
        }

        // 4. Extract Merchant / Payee
        var detectedPartner = ""
        var detectedPurpose = ""

        let knownMerchants = [
            ("Penny", "Penny Markt"),
            ("Rewe", "REWE Supermarkt"),
            ("Edeka", "EDEKA"),
            ("Aldi", "ALDI Süd"),
            ("Lidl", "Lidl"),
            ("Kaufland", "Kaufland"),
            ("Dm-Drogerie", "dm-drogerie markt"),
            ("Rossmann", "Rossmann"),
            ("Apotheke", "Apotheke"),
            ("Lieferando", "Lieferando"),
            ("Uber Eats", "Uber Eats"),
            ("McDonald", "McDonald's"),
            ("Burger King", "Burger King"),
            ("Telekom", "Deutsche Telekom"),
            ("Telefonica", "Telefonica O2"),
            ("O2", "Telefonica O2"),
            ("Amazon", "Amazon"),
            ("Apple", "Apple Services"),
            ("Google", "Google Payment"),
            ("Netflix", "Netflix"),
            ("Spotify", "Spotify"),
            ("Shell", "Shell Tankstelle"),
            ("Aral", "Aral Tankstelle"),
            ("ÖBB", "ÖBB Personenverkehr"),
            ("DB", "Deutsche Bahn"),
            ("Targobank", "TARGOBANK")
        ]

        for (key, full) in knownMerchants {
            if lower.contains(key.lowercased()) {
                detectedPartner = full
                suggestedTags.append("#\(key.lowercased())")
                break
            }
        }

        if detectedPartner.isEmpty {
            // Pick highest prominent line that isn't a date or amount
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let l = trimmed.lowercased()
                if trimmed.count >= 3 && !l.contains("eur") && !l.contains("summe") &&
                   !l.contains("datum") && !l.contains("mwst") && !l.contains("uhr") {
                    detectedPartner = trimmed
                    break
                }
            }
        }

        if detectedPartner.isEmpty {
            detectedPartner = "\(platform) Buchung"
        }

        detectedPurpose = "\(platform) Transaktion vom \(DateFormatter.localizedString(from: detectedDate, dateStyle: .short, timeStyle: .none))"

        // 5. Categorize
        let category = SmartFinanceEngine.shared.categorize(partner: detectedPartner, purpose: detectedPurpose, amount: detectedAmount)
        let budgetCategory = SmartFinanceEngine.shared.mapToBudgetCategory(
            tx: BankTransaction(
                date: detectedDate,
                recipientOrPurpose: detectedPurpose,
                amount: -abs(detectedAmount),
                category: category,
                partnerName: detectedPartner
            )
        )

        // 6. Necessity Classification
        let necessity: ExpenseNecessity
        if category == .deliveryLeak || category == .bankFees ||
           lower.contains("lieferando") || lower.contains("uber eats") ||
           lower.contains("mcdonald") || lower.contains("burger king") {
            necessity = .unnecessary
            suggestedTags.append("#leak")
        } else if category == .groceries || category == .fixedContracts || category == .debtServicing ||
                    budgetCategory == .essen || budgetCategory == .gesundheit || budgetCategory == .wohnkosten {
            necessity = .necessary
            suggestedTags.append("#bedarf")
        } else {
            necessity = .neutral
        }

        // 7. Multi-Factor Duplicate Check
        let candidateDummy = BankTransaction(
            date: detectedDate,
            recipientOrPurpose: detectedPurpose,
            amount: -abs(detectedAmount),
            category: category,
            rawBookingText: fullText,
            partnerName: detectedPartner,
            tags: suggestedTags,
            necessity: necessity,
            budgetCategory: budgetCategory
        )

        let dedupResult = TransactionDeduplicationEngine.shared.findDuplicate(candidate: candidateDummy, in: existingTransactions)
        let isDuplicate = dedupResult.isDuplicate
        let duplicateReason = dedupResult.reason

        return UniversalScanDraft(
            date: detectedDate,
            amount: detectedAmount,
            partnerName: detectedPartner,
            purpose: detectedPurpose,
            category: category,
            budgetCategory: budgetCategory,
            necessity: necessity,
            tags: suggestedTags,
            targetAccountId: "",
            rawText: fullText,
            savedImageFilename: savedFilename,
            isDuplicate: isDuplicate,
            duplicateReason: duplicateReason,
            detectedPlatform: platform
        )
    }
}

