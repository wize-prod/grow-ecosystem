import Foundation
import UIKit
import Vision

public struct ParsedReceiptDraft {
    public var storeName: String
    public var date: Date
    public var totalAmount: Double
    public var lines: [ReceiptLineItem]
    public var rawDetectedText: String
    public var savedImageFilename: String?
}

// MARK: - UIImage Orientation Helper
extension UIImage {
    public func fixOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

public final class ReceiptOCRService {
    public static let shared = ReceiptOCRService()

    private struct BoxToken {
        let text: String
        let rect: CGRect
        var midY: CGFloat { rect.midY }
        var minX: CGFloat { rect.minX }
        var maxX: CGFloat { rect.maxX }
        var height: CGFloat { rect.height }
    }

    private init() {}

    public func parseReceipt(image: UIImage, pantryCatalog: [PantryItem], knownStores: [String] = [], completion: @escaping (Result<ParsedReceiptDraft, Error>) -> Void) {
        // Step 1: Immediately dispatch off the calling/main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Step 2: Prepare downscaled (1800px max dimension) and oriented CGImage
            let (optimizedCG, uprightImage) = self.prepareOptimizedImage(from: image)

            // Step 3: Asynchronously persist the original full receipt image in the background (non-blocking)
            let savedFilename = "receipt_\(UUID().uuidString).jpg"
            let targetFolder = self.getReceiptsDirectory()
            let fileURL = targetFolder.appendingPathComponent(savedFilename)
            DispatchQueue.global(qos: .utility).async {
                if let data = uprightImage.jpegData(compressionQuality: 0.85) {
                    try? data.write(to: fileURL)
                }
            }

            // Step 4: Rapid orientation detection via lightweight probe
            let bestOrientation = self.detectBestOrientation(cgImage: optimizedCG, initialOrientation: .up)

            // Step 5: Execute accurate Vision OCR exactly ONCE on the optimized image
            let observations = self.performOCRRequest(cgImage: optimizedCG, orientation: bestOrientation)

            guard !observations.isEmpty else {
                DispatchQueue.main.async {
                    completion(.success(ParsedReceiptDraft(
                        storeName: "PENNY",
                        date: Date(),
                        totalAmount: 0.0,
                        lines: [],
                        rawDetectedText: "",
                        savedImageFilename: savedFilename
                    )))
                }
                return
            }

            let boxTokens: [BoxToken] = observations.compactMap { obs in
                guard let str = obs.topCandidates(1).first?.string, !str.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
                return BoxToken(text: str, rect: obs.boundingBox)
            }

            let allStrings = boxTokens.map { $0.text }
            let fullText = allStrings.joined(separator: "\n")

            let draft = self.processObservations(tokens: boxTokens, fullText: fullText, catalog: pantryCatalog, knownStores: knownStores, savedFilename: savedFilename)

            DispatchQueue.main.async {
                LocalStore.shared.registerStoreIfNeeded(draft.storeName)
                completion(.success(draft))
            }
        }
    }

    // MARK: - High-Performance Image Optimization & Orientation Probing
    private func prepareOptimizedImage(from image: UIImage) -> (cgImage: CGImage, upright: UIImage) {
        let fixed = image.fixOrientation()
        let maxDim: CGFloat = 1800.0
        let originalWidth = fixed.size.width
        let originalHeight = fixed.size.height

        guard max(originalWidth, originalHeight) > maxDim else {
            return (fixed.cgImage ?? image.cgImage!, fixed)
        }

        let scale = maxDim / max(originalWidth, originalHeight)
        let targetSize = CGSize(width: round(originalWidth * scale), height: round(originalHeight * scale))

        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        fixed.draw(in: CGRect(origin: .zero, size: targetSize))
        let downscaled = UIGraphicsGetImageFromCurrentImageContext() ?? fixed
        UIGraphicsEndImageContext()

        return (downscaled.cgImage ?? fixed.cgImage ?? image.cgImage!, fixed)
    }

    private func detectBestOrientation(cgImage: CGImage, initialOrientation: CGImagePropertyOrientation) -> CGImagePropertyOrientation {
        let count = performFastProbe(cgImage: cgImage, orientation: initialOrientation)
        if count >= 5 {
            return initialOrientation
        }

        var bestOri = initialOrientation
        var maxCount = count
        let alternatives: [CGImagePropertyOrientation] = [.right, .left, .down]
        for alt in alternatives {
            let altCount = performFastProbe(cgImage: cgImage, orientation: alt)
            if altCount > maxCount {
                maxCount = altCount
                bestOri = alt
                if altCount >= 8 { break }
            }
        }
        return bestOri
    }

    private func performFastProbe(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> Int {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try? handler.perform([request])
        return request.results?.count ?? 0
    }

    private func performOCRRequest(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> [VNRecognizedTextObservation] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            return request.results ?? []
        } catch {
            return []
        }
    }

    private func processObservations(tokens: [BoxToken], fullText: String, catalog: [PantryItem], knownStores: [String], savedFilename: String?) -> ParsedReceiptDraft {
        var detectedStore = "PENNY"
        var foundStore = false

        // 1. Detect Store Name (upper region midY > 0.70)
        let topTokens = tokens.filter { $0.midY > 0.70 }.sorted { $0.midY > $1.midY }

        // Phase 1: Direct token match against known chain taxonomy
        for b in topTokens {
            if let chain = StoreCanonicalizer.matchKnownChain(b.text) {
                detectedStore = chain
                foundStore = true
                break
            }
        }

        // Phase 2: Direct token match against existing stores (deduplication)
        if !foundStore {
            for b in topTokens {
                if let matched = StoreCanonicalizer.matchExistingStore(b.text, in: knownStores) {
                    detectedStore = matched
                    foundStore = true
                    break
                }
            }
        }

        // Phase 3: Check top header lines of full text against known chains or existing stores
        if !foundStore {
            let headerLines = fullText.components(separatedBy: .newlines).prefix(8)
            for line in headerLines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if let chain = StoreCanonicalizer.matchKnownChain(trimmed) {
                    detectedStore = chain
                    foundStore = true
                    break
                }
                if let matched = StoreCanonicalizer.matchExistingStore(trimmed, in: knownStores) {
                    detectedStore = matched
                    foundStore = true
                    break
                }
            }
        }

        // Phase 4: Universal Cleaner on top Vision tokens for any new/unindexed store
        if !foundStore {
            for b in topTokens where b.midY > 0.80 {
                let cleaned = StoreCanonicalizer.cleanGenericStoreName(b.text)
                if cleaned.count >= 3 && cleaned.count <= 35 {
                    detectedStore = StoreCanonicalizer.canonicalize(cleaned, existingStores: knownStores)
                    foundStore = true
                    break
                }
            }
        }

        // Phase 5: Universal Cleaner on full text header lines for any new store
        if !foundStore {
            let headerLines = fullText.components(separatedBy: .newlines).prefix(6)
            for line in headerLines {
                let cleaned = StoreCanonicalizer.cleanGenericStoreName(line)
                if cleaned.count >= 3 && cleaned.count <= 35 {
                    detectedStore = StoreCanonicalizer.canonicalize(cleaned, existingStores: knownStores)
                    foundStore = true
                    break
                }
            }
        }

        // Final pass: always run through canonicalizer to ensure brand unification
        detectedStore = StoreCanonicalizer.canonicalize(detectedStore, existingStores: knownStores)

        // 2. Detect Date with Context Scoring
        let detectedDate = extractReceiptDate(tokens: tokens, fullText: fullText)

        // 3. Locate Footer / Total Cutoff Anchor
        let footerKeywords = [
            "SUMME", "GESAMT", "ZU ZAHLEN", "TOTAL", "ENDSUMME", "RECHNUNGSBETRAG",
            "GEL", "GEGEBEN", "RÜCKGELD", "RUECKGELD",
            "ZAHLUNG", "KARTENZAHLUNG", "BAR", "VISA", "MASTERCARD", "EC-KARTE",
            "BRUTTO", "NETTO", "STEUER", "MWST", "GESI.BETRAG", "GESAMTBETRAG",
            "TSE-", "TSC-", "TSE", "SIGNATUR", "SERIENNUMMER", "KASSEN-ID", "KUNDENBELEG"
        ]

        var footerCutoffY: CGFloat = 0.0
        let footerMatches = tokens.filter { t in
            let up = t.text.uppercased()
            return footerKeywords.contains(where: { up.contains($0) }) && t.midY < 0.70
        }
        if !footerMatches.isEmpty {
            footerCutoffY = (footerMatches.map { $0.midY }.max() ?? 0.20) + 0.018
        } else {
            for b in tokens {
                let up = b.text.uppercased()
                if footerKeywords.contains(where: { up.contains($0) }) {
                    if b.midY > footerCutoffY && b.midY < 0.70 {
                        footerCutoffY = b.midY + 0.018
                    }
                }
            }
        }

        if footerCutoffY == 0.0 {
            footerCutoffY = 0.05
        }

        // 4. Extract Line Items in the item region (between header and footerCutoffY)
        let headerKeywords = [
            "UID", "ATU", "STEUER", "BON-NR", "KASSE", "BED.", "DATUM", "UHRZEIT",
            "TEL", "FAX", "TERMINAL-ID", "KUNDENBELEG", "HERZLICH", "WILLKOMMEN",
            "IHREN EINKAUF", "IHR EINKAUF", "PREIS EUR", "PREIS", "EUR A", "EUR B",
            "SCHWEDENDAMM", "RATHENOW"
        ]

        let itemBoxes = tokens.filter { b in
            guard b.midY > footerCutoffY + 0.005 && b.midY < 0.90 else { return false }
            let up = b.text.uppercased().trimmingCharacters(in: .whitespaces)
            if up.range(of: #"DE\d{8,10}"#, options: .regularExpression) != nil { return false }
            if up.range(of: #"\b\d{5}\b"#, options: .regularExpression) != nil && b.midY > 0.82 { return false }
            if headerKeywords.contains(where: { up.contains($0) }) { return false }
            if up == detectedStore || (up.contains(detectedStore) && b.midY > 0.82) { return false }
            if up.contains("EINKAUF") || up.contains("DATUM") { return false }
            if isAddressOrHeaderLine(b.text) && b.midY > 0.80 { return false }
            return true
        }

        // 2D Spatial Line Clustering:
        // Group tokens into visual line bands based on adaptive vertical Y-coordinate proximity.
        // Vision coordinates: midY is normalized 0.0 (bottom) to 1.0 (top).
        // Sorting by midY descending processes lines from top of the receipt to bottom.
        struct LineBand {
            var tokens: [BoxToken]
            var avgY: CGFloat
            var avgHeight: CGFloat
        }

        let sortedItemBoxes = itemBoxes.sorted { $0.midY > $1.midY }
        var lineBands: [LineBand] = []

        for token in sortedItemBoxes {
            var matchedIdx: Int? = nil
            var minDiff: CGFloat = 0.024

            for (idx, band) in lineBands.enumerated() {
                // Adaptive tolerance: right-column prices (minX >= 0.55) matching left-column text (minX < 0.60)
                // allow expanded vertical tolerance to accommodate crumpled, folded, or slightly tilted receipts
                let hasLeft = band.tokens.contains { $0.minX < 0.60 }
                let isRight = token.minX >= 0.55
                let dynamicTol: CGFloat
                if hasLeft && isRight {
                    dynamicTol = max(0.018, band.avgHeight * 0.95)
                } else {
                    dynamicTol = max(0.010, band.avgHeight * 0.72)
                }

                let diff = abs(token.midY - band.avgY)
                if diff <= dynamicTol && diff < minDiff {
                    minDiff = diff
                    matchedIdx = idx
                }
            }

            if let idx = matchedIdx {
                lineBands[idx].tokens.append(token)
                let count = CGFloat(lineBands[idx].tokens.count)
                lineBands[idx].avgY = lineBands[idx].tokens.reduce(0) { $0 + $1.midY } / count
                lineBands[idx].avgHeight = lineBands[idx].tokens.reduce(0) { $0 + $1.height } / count
            } else {
                lineBands.append(LineBand(tokens: [token], avgY: token.midY, avgHeight: token.height))
            }
        }

        // Sort bands strictly top-to-bottom
        lineBands.sort { $0.avgY > $1.avgY }

        // Sort tokens inside each band strictly from left to right
        for i in 0..<lineBands.count {
            lineBands[i].tokens.sort { $0.minX < $1.minX }
        }

        // State-Machine Intermediate Line Representation
        struct StructuredLine {
            var text: String
            var price: Double?
            var taxCode: String?
            var midY: CGFloat
            var qtyDescriptor: (count: Int, unitPrice: Double)?
            var isDiscount: Bool
            var discountAmount: Double?
            var isWeightLine: Bool
            var weightKg: Double?
            var pricePerKg: Double?
            var rawBand: String
        }

        var structuredLines: [StructuredLine] = []

        for band in lineBands {
            let fullStr = band.tokens.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let upper = fullStr.uppercased()

            // Skip pure header or standalone currency words
            if upper == "EUR" || upper == "EUR B" || upper == "EUR A" || upper == "EUR K" || upper == "PREIS" || upper == "ARTIKEL" {
                continue
            }

            var linePrice: Double? = nil
            var lineTaxCode: String? = nil
            var descTokens = band.tokens

            // Extract price and tax code from rightmost tokens
            if let last = descTokens.last {
                let lastText = last.text.trimmingCharacters(in: .whitespaces)
                let upperLast = lastText.uppercased()

                if (upperLast == "A" || upperLast == "B" || upperLast == "K" || upperLast == "EUR" || upperLast == "€") && descTokens.count >= 2 {
                    let candidateToken = descTokens[descTokens.count - 2].text
                    if let p = self.cleanPrice(from: candidateToken) {
                        linePrice = p
                        lineTaxCode = (upperLast == "A" || upperLast == "B") ? upperLast : nil
                        descTokens.removeLast(2)
                    }
                } else if let parsed = self.cleanPriceAndTax(from: lastText) {
                    linePrice = parsed.price
                    lineTaxCode = parsed.taxCode
                    descTokens.removeLast()
                } else if descTokens.count >= 2 {
                    let candidatePair = "\(descTokens[descTokens.count - 2].text) \(lastText)"
                    if let parsed = self.cleanPriceAndTax(from: candidatePair) {
                        linePrice = parsed.price
                        lineTaxCode = parsed.taxCode
                        descTokens.removeLast(2)
                    }
                }
            }

            // Fallback for lines where price was embedded without trailing spacing
            if linePrice == nil {
                if let p = self.cleanPrice(from: fullStr), !fullStr.contains(" ") || fullStr.range(of: #"[A-Za-z]{3,}"#, options: .regularExpression) == nil {
                    linePrice = p
                }
            }

            let descText = descTokens.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespaces)

            // Quantity and weight analysis
            let qtyDesc = self.parseQuantityDescriptor(from: descText.isEmpty ? fullStr : descText, linePrice: linePrice)
            let weightDesc = self.parseWeightDescriptor(from: fullStr)

            // Discount detection (including all Austrian & German discount patterns and negative price lines)
            var isDisc = false
            var discAmt: Double? = nil
            let upFull = fullStr.uppercased()
            let upDesc = descText.uppercased()
            let isDiscountKeyword = upDesc.contains("RABATT") || upDesc.contains("AKTION") || upDesc.contains("COUPON") ||
                upDesc.contains("SPAR-COUPON") || upDesc.contains("SOFORT-RABATT") || upDesc.contains("APP-RABATT") ||
                upDesc.contains("NACHLASS") || upDesc.contains("GUTSCHEIN") || upDesc.contains("BONUS") ||
                upDesc.contains("DISCOUNT") || upDesc.contains("-%") || upDesc.contains("RABAT") ||
                upFull.hasSuffix("-") || upFull.contains("- ")
            if (linePrice != nil && linePrice! < 0.0) || isDiscountKeyword {
                isDisc = true
                if let p = linePrice {
                    discAmt = abs(p)
                }
            }

            structuredLines.append(StructuredLine(
                text: descText.isEmpty ? fullStr : descText,
                price: linePrice,
                taxCode: lineTaxCode,
                midY: band.avgY,
                qtyDescriptor: qtyDesc,
                isDiscount: isDisc,
                discountAmount: discAmt,
                isWeightLine: weightDesc != nil,
                weightKg: weightDesc?.weightKg,
                pricePerKg: weightDesc?.pricePerKg,
                rawBand: fullStr
            ))
        }

        // 5. Assemble Products using State Machine (Handling single-line, Austrian 2-line, German prefix/postfix, weights & discounts)
        struct IntermediateProduct {
            var name: String
            var lineTotal: Double
            var unitPrice: Double
            var quantity: Int
            var isNonFood: Bool
            var note: String?
        }

        var products: [IntermediateProduct] = []
        var pendingQty: (count: Int, unitPrice: Double)? = nil
        var pendingWeight: (weightKg: Double, pricePerKg: Double)? = nil

        var i = 0
        while i < structuredLines.count {
            let current = structuredLines[i]

            // 1. Discount / Rabatt Line (Deduct from preceding product)
            if current.isDiscount {
                let amount = current.discountAmount ?? (current.price.map { abs($0) } ?? 0.0)
                if !products.isEmpty && amount > 0.0 {
                    let lastIdx = products.count - 1
                    let newTotal = max(0.01, ((products[lastIdx].lineTotal - amount) * 100.0).rounded() / 100.0)
                    products[lastIdx].lineTotal = newTotal
                    if products[lastIdx].quantity > 1 {
                        products[lastIdx].unitPrice = ((newTotal / Double(products[lastIdx].quantity)) * 100.0).rounded() / 100.0
                    } else {
                        products[lastIdx].unitPrice = newTotal
                    }
                    let discNote = "Rabatt -\(String(format: "%.2f €", amount)) abgezogen"
                    if let existingNote = products[lastIdx].note {
                        products[lastIdx].note = "\(existingNote), \(discNote)"
                    } else {
                        products[lastIdx].note = discNote
                    }
                }
                i += 1
                continue
            }

            // 2. Pfand / Leergut Line
            let upRaw = current.rawBand.uppercased()
            if upRaw.contains("PFAND") || upRaw.contains("LEERGUT") {
                let pfandPrice = current.price ?? 0.25
                let pfandQty = current.qtyDescriptor?.count ?? 1
                products.append(IntermediateProduct(
                    name: "Pfand (Dosen-/Flaschenpfand)",
                    lineTotal: pfandPrice,
                    unitPrice: pfandQty > 1 ? (pfandPrice / Double(pfandQty)) : pfandPrice,
                    quantity: pfandQty,
                    isNonFood: true,
                    note: "Pfandbetrag"
                ))
                i += 1
                continue
            }

            // 3. Weight Sub-line Handling (e.g. 0,642 kg x 2,49 EUR/kg)
            if current.isWeightLine, let w = current.weightKg, let pKg = current.pricePerKg {
                let note = "\(String(format: "%.3f kg", w)) x \(String(format: "%.2f €/kg", pKg))"
                if !products.isEmpty && (current.text.isEmpty || current.text.lowercased().contains("kg") || current.text.lowercased().contains("g ")) {
                    // Postfix weight line attaching to previous product
                    let lastIdx = products.count - 1
                    if let p = current.price, p > 0.0 {
                        products[lastIdx].lineTotal = p
                        products[lastIdx].unitPrice = p
                    }
                    products[lastIdx].note = note
                    i += 1
                    continue
                } else if i + 1 < structuredLines.count && structuredLines[i + 1].price != nil {
                    // Prefix weight line before item name
                    pendingWeight = (w, pKg)
                    i += 1
                    continue
                }
            }

            // 4. Prefix Quantity Line (e.g. "2 x 1,45" on separate line before item)
            if let q = current.qtyDescriptor, current.price == nil && current.text.range(of: #"[A-Za-z]{3,}"#, options: .regularExpression) == nil {
                pendingQty = q
                i += 1
                continue
            }

            // 5. Postfix Quantity Sub-line for Previous Product (e.g. "2 Stk x 1,45" after item)
            if let q = current.qtyDescriptor, !products.isEmpty && (current.price == nil || abs((current.price ?? 0.0) - products.last!.lineTotal) < 0.05) && current.text.range(of: #"[A-Za-z]{4,}"#, options: .regularExpression) == nil {
                let lastIdx = products.count - 1
                products[lastIdx].quantity = q.count
                products[lastIdx].unitPrice = q.unitPrice
                products[lastIdx].note = "\(q.count) Stk x \(String(format: "%.2f €", q.unitPrice)) (Gesamt: \(String(format: "%.2f €", products[lastIdx].lineTotal)))"
                i += 1
                continue
            }

            // 6. Austrian 2-Line Pattern (SPAR Salzburg / Hofer / Kaufland Multi-line)
            // Line 1: [Product Name] without price
            // Line 2: [Qty/Price/Tax] (e.g. "2 X 2,37   4,74 A" or just "1,99 B")
            if current.price == nil && !current.text.isEmpty {
                if i + 1 < structuredLines.count {
                    let next = structuredLines[i + 1]
                    if let nextPrice = next.price {
                        let qDesc = next.qtyDescriptor ?? self.parseQuantityDescriptor(from: next.text, linePrice: nextPrice)
                        let count = qDesc?.count ?? 1
                        let uPrice = qDesc?.unitPrice ?? (nextPrice / Double(count))
                        let note = count > 1 ? "\(count) Stk x \(String(format: "%.2f €", uPrice)) (Gesamt: \(String(format: "%.2f €", nextPrice)))" : nil
                        let cleanName = self.cleanProductOCRName(current.text)
                        let isNF = NonFoodClassifier.isNonFood(name: cleanName, taxCode: next.taxCode)

                        products.append(IntermediateProduct(
                            name: cleanName,
                            lineTotal: nextPrice,
                            unitPrice: uPrice,
                            quantity: count,
                            isNonFood: isNF,
                            note: note
                        ))
                        i += 2
                        continue
                    }
                }
            }

            // 7. Standard Single-Line Product with Price
            if let price = current.price, price > 0.0 {
                var name = current.text
                var quantity = 1
                var unitPrice = price
                var note: String? = nil

                // Check pending quantity from prior line
                if let pQ = pendingQty {
                    let expected = Double(pQ.count) * pQ.unitPrice
                    if abs(price - expected) < 0.06 || abs(price - pQ.unitPrice) < 0.06 {
                        quantity = pQ.count
                        unitPrice = pQ.unitPrice
                        note = "\(quantity) Stk x \(String(format: "%.2f €", unitPrice)) (Gesamt: \(String(format: "%.2f €", price)))"
                    }
                    pendingQty = nil
                } else if let pW = pendingWeight {
                    note = "\(String(format: "%.3f kg", pW.weightKg)) x \(String(format: "%.2f €/kg", pW.pricePerKg))"
                    pendingWeight = nil
                } else if let qDesc = current.qtyDescriptor ?? self.parseQuantityDescriptor(from: name, linePrice: price) {
                    quantity = qDesc.count
                    unitPrice = qDesc.unitPrice
                    note = "\(quantity) Stk x \(String(format: "%.2f €", unitPrice)) (Gesamt: \(String(format: "%.2f €", price)))"
                    name = name.replacingOccurrences(of: #"\d+\s*[\*xX]\s*[^\s]+"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
                }

                name = self.cleanProductOCRName(name)
                if name.isEmpty {
                    name = "Artikel \(products.count + 1)"
                }

                let isNF = NonFoodClassifier.isNonFood(name: name, taxCode: current.taxCode)

                products.append(IntermediateProduct(
                    name: name,
                    lineTotal: price,
                    unitPrice: unitPrice,
                    quantity: quantity,
                    isNonFood: isNF,
                    note: note
                ))
                i += 1
                continue
            }

            // Solitary numbers without product context - ignore
            let trimmed = current.text.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: #"^\d+([.,]\d{2})?$"#, options: .regularExpression) != nil {
                i += 1
                continue
            }

            // Fallback for wrapped multi-line text:
            if !current.text.isEmpty && i + 1 < structuredLines.count && structuredLines[i + 1].price != nil {
                structuredLines[i + 1].text = "\(current.text) \(structuredLines[i + 1].text)"
            }

            i += 1
        }

        // Anti-Total-Duplicate Guard:
        // If the last product or any product has name starting with "Artikel" or contains "Summe"/"Gesamt",
        // and its price is >= 30.0 or matches the sum of the remaining products within 2.00 EUR, drop it!
        if let lastProd = products.last, (lastProd.name.hasPrefix("Artikel") || lastProd.name.uppercased().contains("SUMME") || lastProd.name.uppercased().contains("GESAMT")) {
            let sumOthers = products.dropLast().reduce(0.0) { $0 + $1.lineTotal }
            if abs(lastProd.lineTotal - sumOthers) < 2.0 || lastProd.lineTotal >= 30.0 {
                products.removeLast()
            }
        }

        // 6. Match Products against Catalog and build ReceiptLineItems
        var lineItems: [ReceiptLineItem] = []

        for prod in products {
            var pName = prod.name.trimmingCharacters(in: .whitespaces)
            let unitPrice = prod.unitPrice
            let quantity = prod.quantity
            let qtyNote = prod.note
            let isNF = prod.isNonFood

            let upName = pName.uppercased()
            if upName.contains("PFAND") || upName.contains("LEERGUT") {
                pName = "Pfand (Dosen-/Flaschenpfand)"
                lineItems.append(ReceiptLineItem(
                    rawText: pName,
                    parsedPrice: unitPrice,
                    quantity: quantity,
                    quantityNote: qtyNote ?? "Pfandbetrag",
                    matchedPantryItemId: nil,
                    matchedPantryItemName: "Pfand / Leergut (Kein Vorratsposten)",
                    previousPrice: nil,
                    confidenceScore: 0.0,
                    isConfirmed: false,
                    isNonFood: true
                ))
                continue
            }

            if isNF {
                lineItems.append(ReceiptLineItem(
                    rawText: pName,
                    parsedPrice: unitPrice,
                    quantity: quantity,
                    quantityNote: qtyNote,
                    matchedPantryItemId: nil,
                    matchedPantryItemName: "Non-Food / Haushaltsware (Kein Vorratsposten)",
                    previousPrice: nil,
                    confidenceScore: 1.0,
                    isConfirmed: true,
                    isNonFood: true
                ))
                continue
            }

            let match = ReceiptMatchingEngine.shared.match(rawReceiptLine: pName, in: catalog, storeContext: detectedStore, linePrice: unitPrice)

            let isHighConfidence = match.confidence >= 0.60
            let matchedId = isHighConfidence ? match.item?.id : nil
            let matchedName = isHighConfidence ? match.item?.name : nil

            // Store-specific price awareness:
            // Only compare previous price against the historical price AT THIS SPECIFIC SUPERMARKET!
            // Different shops have different pricing structures for identical products.
            let prevPrice: Double?
            if isHighConfidence, let item = match.item {
                let normStore = detectedStore.trimmingCharacters(in: .whitespaces).uppercased()
                if let storeSpecific = item.storePrices?[normStore] {
                    prevPrice = storeSpecific
                } else if item.store.trimmingCharacters(in: .whitespaces).uppercased() == normStore {
                    prevPrice = item.defaultPrice
                } else {
                    // First time buying this item at this particular supermarket branch
                    prevPrice = nil
                }
            } else {
                prevPrice = nil
            }

            lineItems.append(ReceiptLineItem(
                rawText: pName,
                parsedPrice: unitPrice,
                quantity: quantity,
                quantityNote: qtyNote,
                matchedPantryItemId: matchedId,
                matchedPantryItemName: matchedName,
                previousPrice: prevPrice,
                confidenceScore: match.confidence,
                isConfirmed: isHighConfidence,
                isNonFood: false
            ))
        }

        // 7. Robust Total Reconciliation (Resilient to liquid, bleach, crease damage)
        let itemsSum = lineItems.reduce(0.0) { $0 + $1.lineTotalPrice }

        // Find candidate totals from footer region (at or below footerCutoffY)
        var candidateTotals: [Double] = []

        let footerTokens = tokens.filter { $0.midY <= footerCutoffY + 0.015 }
        for b in footerTokens {
            if let p = cleanPrice(from: b.text) {
                candidateTotals.append(p)
            }
        }

        var footerBands: [[BoxToken]] = []
        for t in footerTokens.sorted(by: { $0.midY > $1.midY }) {
            var matched = false
            for (idx, band) in footerBands.enumerated() {
                let avgY = band.map { $0.midY }.reduce(0, +) / CGFloat(band.count)
                if abs(t.midY - avgY) < 0.016 {
                    footerBands[idx].append(t)
                    matched = true
                    break
                }
            }
            if !matched {
                footerBands.append([t])
            }
        }

        for band in footerBands {
            let bandStr = band.sorted(by: { $0.minX < $1.minX }).map { $0.text }.joined(separator: " ")
            if let p = cleanPrice(from: bandStr) {
                candidateTotals.append(p)
            }
        }

        var resolvedTotal = itemsSum

        // Reconcile:
        // 1. If any candidate equals itemsSum (within 0.05), that is the confirmed total
        if let exactMatch = candidateTotals.first(where: { abs($0 - itemsSum) < 0.05 }) {
            resolvedTotal = exactMatch
        } else if !candidateTotals.isEmpty {
            if let closest = candidateTotals.first(where: { abs($0 - itemsSum) < 1.0 }) {
                resolvedTotal = closest
            } else if itemsSum > 0.50 {
                // If "SUMME" was obliterated by bleach or liquid, trust the sum of recognized items
                resolvedTotal = itemsSum
            } else if let maxCand = candidateTotals.filter({ $0 > 0.50 && $0 < 500.0 }).first {
                resolvedTotal = maxCand
            }
        }

        return ParsedReceiptDraft(
            storeName: detectedStore,
            date: detectedDate,
            totalAmount: resolvedTotal,
            lines: lineItems,
            rawDetectedText: fullText,
            savedImageFilename: savedFilename
        )
    }

    // MARK: - Text Pre-normalization
    private func preNormalizeText(_ raw: String) -> String {
        var s = raw.replacingOccurrences(of: "\u{0410}", with: "A") // Cyrillic A
                   .replacingOccurrences(of: "\u{0412}", with: "B") // Cyrillic B
                   .replacingOccurrences(of: "ą", with: "9")
                   .replacingOccurrences(of: "х", with: "x")
                   .replacingOccurrences(of: "Х", with: "x")
                   .replacingOccurrences(of: "*", with: "x")
        // Fix German receipt slash-for-7 typos e.g. "5,6/ B" -> "5,67 B"
        s = s.replacingOccurrences(of: #"(?<=[.,]\d)/"#, with: "7", options: .regularExpression)
        return s
    }

    // MARK: - Quantity and Unit Price Parsing Helpers
    private func parseQuantityDescriptor(from text: String, linePrice: Double? = nil) -> (count: Int, unitPrice: Double)? {
        let norm = preNormalizeText(text)
        let pattern = #"(\d+)\s*(?:stk\.?|stck\.?|pack\.?|fl\.?|ds\.?|x|à|a)?\s*(?:x|à|a)\s*(\d{1,4}[,.][0-9]{2})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let ns = norm as NSString
            if let match = regex.firstMatch(in: norm, range: NSRange(location: 0, length: ns.length)) {
                let countStr = ns.substring(with: match.range(at: 1))
                let priceStr = ns.substring(with: match.range(at: 2)).replacingOccurrences(of: ",", with: ".")
                if let c = Int(countStr), var p = Double(priceStr), c > 0, p > 0.0 {
                    // Mathematical reconciliation: If total line price is known, ensure unit price * count == total!
                    if let total = linePrice, total > 0.0, c > 1 {
                        let expected = Double(c) * p
                        if abs(expected - total) > 0.04 {
                            let candidate = (total / Double(c) * 100.0).rounded() / 100.0
                            if abs(Double(c) * candidate - total) < 0.04 {
                                p = candidate
                            }
                        }
                    }
                    return (c, p)
                }
            }
        }

        // Mathematical recovery for corrupted unit price (e.g. 3 * 0,6§š or 7 * 1,2ę or 3 * 1,1ą or 2 * 1,55)
        let fallbackPattern = #"(\d+)\s*x\s*([0-9]+[,\.][^\s]*)"#
        if let regex = try? NSRegularExpression(pattern: fallbackPattern, options: .caseInsensitive) {
            let ns = norm as NSString
            if let match = regex.firstMatch(in: norm, range: NSRange(location: 0, length: ns.length)) {
                let countStr = ns.substring(with: match.range(at: 1))
                if let c = Int(countStr), c > 1, let total = linePrice, total > 0.0 {
                    let candidateUnit = (total / Double(c) * 100.0).rounded() / 100.0
                    if abs(Double(c) * candidateUnit - total) < 0.04 {
                        return (c, candidateUnit)
                    }
                }
            }
        }

        let simpleCountPattern = #"^(\d+)\s*x"#
        if let regex = try? NSRegularExpression(pattern: simpleCountPattern, options: .caseInsensitive) {
            let ns = norm as NSString
            if let match = regex.firstMatch(in: norm, range: NSRange(location: 0, length: ns.length)) {
                let countStr = ns.substring(with: match.range(at: 1))
                if let c = Int(countStr), c > 1, let total = linePrice, total > 0.0 {
                    let candidateUnit = (total / Double(c) * 100.0).rounded() / 100.0
                    if abs(Double(c) * candidateUnit - total) < 0.04 {
                        return (c, candidateUnit)
                    }
                }
            }
        }

        return nil
    }

    private func cleanPriceAndTax(from raw: String) -> (price: Double, taxCode: String?)? {
        if raw.contains("%") { return nil }

        var s = preNormalizeText(raw)
        // Normalize split punctuation: "1, 75" -> "1,75"
        s = s.replacingOccurrences(of: #"(?<=\d)\s*([.,])\s*(?=\d{2}\b)"#, with: "$1", options: .regularExpression)

        var taxCode: String? = nil
        let trimmedUpper = s.uppercased().trimmingCharacters(in: .whitespaces)

        if trimmedUpper.hasSuffix(" A") || trimmedUpper.hasSuffix("A") || trimmedUpper.hasPrefix("A ") {
            taxCode = "A"
        } else if trimmedUpper.hasSuffix(" B") || trimmedUpper.hasSuffix("B") || trimmedUpper.hasPrefix("B ") {
            taxCode = "B"
        }

        guard let val = cleanPrice(from: s) else { return nil }
        return (val, taxCode)
    }

    private func isAddressOrHeaderLine(_ text: String) -> Bool {
        let up = text.uppercased()
        if up.contains("MEHRWEG") || up.contains("TASCHE") || up.contains("BEUTEL") {
            return false
        }
        let streetPattern = #"\b(?:straße|strasse|str\.|platz|allee|gasse)\b|\b\w+(?:straße|strasse|str\.|platz|allee|gasse)\b|\b\d{1,3}\s*weg\b|\bweg\s*\d{1,3}\b"#
        let hasStreet = text.range(of: streetPattern, options: [.regularExpression, .caseInsensitive]) != nil
        let cityKeywords = ["CELLE", "BERLIN", "MUENCHEN", "MÜNCHEN", "HAMBURG", "KOELN", "KÖLN", "FRANKFURT", "SALZBURG", "RATHENOW"]
        let hasCity = cityKeywords.contains(where: { up.contains($0) })
        let hasPostalCode = text.range(of: #"\b\d{4,5}\b"#, options: .regularExpression) != nil
        return hasStreet || hasCity || hasPostalCode
    }

    private func cleanPrice(from raw: String) -> Double? {
        if raw.contains("%") { return nil }

        // Reject explicit dates: 24.10.2026, 24.10., 2. 63.2026
        if raw.range(of: #"\b\d{1,2}\s*[./-]\s*\d{1,2}(?:\s*[./-]\s*\d{2,4})?\b"#, options: .regularExpression) != nil {
            if raw.range(of: #"\b\d{1,2}\.\d{1,2}\.\d{2,4}\b"#, options: .regularExpression) != nil ||
               raw.range(of: #"\b\d{1,2}\.\d{1,2}\.\b"#, options: .regularExpression) != nil {
                return nil
            }
        }

        // Reject times: 18:26, 19:05:02
        if raw.range(of: #"\b\d{1,2}:\d{2}\b"#, options: .regularExpression) != nil {
            return nil
        }

        var s = preNormalizeText(raw)
        s = s.replacingOccurrences(of: #"(?<=\d)\s*([.,])\s*(?=\d{2}\b)"#, with: "$1", options: .regularExpression)

        // Support trailing minus for discounts: e.g. "0,50-" -> "-0,50"
        let trimmedEnd = s.trimmingCharacters(in: .whitespaces)
        if trimmedEnd.hasSuffix("-") {
            s = "-" + trimmedEnd.dropLast()
        }

        // Match price format with optional tax letter prefix or suffix (e.g. B 9,03 or 2,49 B or 4,74 K or 21,29 EUR or 6,49 or -0,50 or 0,50-)
        let pattern = #"(?:EUR\s*|[A-Za-z]\s*)?(-?\d{1,4}[.,]\d{2})(?:\s*([A-Za-z€]|-))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = s as NSString
        guard let match = regex.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) else { return nil }
        var numStr = ns.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ".")
        if match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound {
            let suffix = ns.substring(with: match.range(at: 2))
            if suffix == "-" && !numStr.hasPrefix("-") {
                numStr = "-" + numStr
            }
        }
        guard let val = Double(numStr) else { return nil }
        if abs(val) < 0.01 || abs(val) > 1000.0 { return nil }
        return val
    }

    private func parseWeightDescriptor(from text: String) -> (weightKg: Double, pricePerKg: Double)? {
        let norm = preNormalizeText(text)
        let pattern = #"(\d+(?:[.,]\d+)?)\s*(kg|g)\s*(?:x|à|a|\*)\s*(\d+(?:[.,]\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let ns = norm as NSString
        guard let match = regex.firstMatch(in: norm, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let amountStr = ns.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ".")
        let unitStr = ns.substring(with: match.range(at: 2)).lowercased()
        let priceStr = ns.substring(with: match.range(at: 3)).replacingOccurrences(of: ",", with: ".")
        guard var amount = Double(amountStr), let price = Double(priceStr), amount > 0, price > 0 else { return nil }
        if unitStr == "g" {
            amount = amount / 1000.0
        }
        return (amount, price)
    }

    private func cleanProductOCRName(_ raw: String) -> String {
        var name = raw
        name = name.replacingOccurrences(of: "Kuchengabe in", with: "Kuchengabeln", options: .caseInsensitive)
                   .replacingOccurrences(of: "Kuchengabein", with: "Kuchengabeln", options: .caseInsensitive)
                   .replacingOccurrences(of: "Salzheringsf1 lets", with: "Salzheringsfilets", options: .caseInsensitive)
                   .replacingOccurrences(of: "Salzheringsf1lets", with: "Salzheringsfilets", options: .caseInsensitive)
                   .replacingOccurrences(of: "Alt. Ziegenkäse", with: "Alt.Ziegenkäse", options: .caseInsensitive)
                   .replacingOccurrences(of: "Teek .Bio", with: "Teek.Bio", options: .caseInsensitive)
                   .replacingOccurrences(of: "leek.B1o", with: "Teek.Bio", options: .caseInsensitive)
                   .replacingOccurrences(of: "1eek.B1o", with: "Teek.Bio", options: .caseInsensitive)
                   .replacingOccurrences(of: "1eek.", with: "Teek.", options: .caseInsensitive)
                   .replacingOccurrences(of: "Schüsse l", with: "Schüssel", options: .caseInsensitive)
                   .replacingOccurrences(of: "KLC. Ingw", with: "KLC.Ingw", options: .caseInsensitive)

        // Strip trailing solitary tax codes or isolated prices (e.g. "6,49 A", "1,99 B")
        name = name.replacingOccurrences(of: #"\s+(-?\d{1,4}[.,]\d{2})\s*[A-Za-z]?$"#, with: "", options: .regularExpression)
        name = name.replacingOccurrences(of: #"\s+[A-Za-z]$"#, with: "", options: .regularExpression)

        return name.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
    }

    // MARK: - Context-Aware Date Extraction
    private func extractReceiptDate(tokens: [BoxToken], fullText: String) -> Date {
        struct ScoredDate {
            let date: Date
            let score: Int
            let raw: String
        }

        var candidates: [ScoredDate] = []
        let currentYear = Calendar.current.component(.year, from: Date())

        let dfDMY = DateFormatter()
        dfDMY.locale = Locale(identifier: "de_DE")
        dfDMY.timeZone = TimeZone.current

        let datePatterns: [(pattern: String, type: Int)] = [
            (#"\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b"#, 1),
            (#"\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b"#, 2),
            (#"\b(20\d{2})-(\d{2})-(\d{2})T"#, 3)
        ]

        let penaltyWords = ["STEUER", "ST.-NR", "STNR", "UST", "UID", "DE2", "DE3", "HRB", "IBAN", "BIC", "TEL", "FAX", "BLZ", "KTO", "PLZ", "STRASSE", "STR."]
        let bonusWords = ["DATUM", "DATE", "BELEG", "BON", "KASSE", "BELEG-NR", "BON-NR", "UHRZEIT", "UHR", "TSE", "START", "ENDE", "AM "]
        let timeRegex = try? NSRegularExpression(pattern: #"\b\d{1,2}:\d{2}(:\d{2})?\b"#)

        for b in tokens {
            let up = b.text.uppercased()

            for item in datePatterns {
                guard let regex = try? NSRegularExpression(pattern: item.pattern) else { continue }
                let ns = b.text as NSString
                let matches = regex.matches(in: b.text, range: NSRange(location: 0, length: ns.length))

                for m in matches {
                    var parsedDate: Date? = nil
                    var yearNum = 0
                    var monthNum = 0
                    var dayNum = 0

                    if item.type == 1 {
                        let dStr = ns.substring(with: m.range(at: 1))
                        let mStr = ns.substring(with: m.range(at: 2))
                        var yStr = ns.substring(with: m.range(at: 3))
                        if yStr.count == 2 {
                            yStr = "20" + yStr
                        }
                        dayNum = Int(dStr) ?? 0
                        monthNum = Int(mStr) ?? 0
                        yearNum = Int(yStr) ?? 0
                        dfDMY.dateFormat = "d.M.yyyy"
                        parsedDate = dfDMY.date(from: "\(dayNum).\(monthNum).\(yearNum)")
                    } else if item.type == 2 || item.type == 3 {
                        let yStr = ns.substring(with: m.range(at: 1))
                        let mStr = ns.substring(with: m.range(at: 2))
                        let dStr = ns.substring(with: m.range(at: 3))
                        yearNum = Int(yStr) ?? 0
                        monthNum = Int(mStr) ?? 0
                        dayNum = Int(dStr) ?? 0
                        dfDMY.dateFormat = "yyyy-M-d"
                        parsedDate = dfDMY.date(from: "\(yearNum)-\(monthNum)-\(dayNum)")
                    }

                    guard let validDate = parsedDate,
                          dayNum >= 1, dayNum <= 31,
                          monthNum >= 1, monthNum <= 12,
                          yearNum >= 2024, yearNum <= 2028 else {
                        continue
                    }

                    var score = 20

                    if bonusWords.contains(where: { up.contains($0) }) {
                        score += 60
                    }

                    if let tReg = timeRegex, tReg.firstMatch(in: b.text, range: NSRange(location: 0, length: ns.length)) != nil {
                        score += 40
                    }

                    if yearNum == currentYear {
                        score += 25
                    } else if yearNum == currentYear - 1 || yearNum == currentYear + 1 {
                        score += 10
                    }

                    if b.midY < 0.65 && b.midY > 0.05 {
                        score += 15
                    }

                    if penaltyWords.contains(where: { up.contains($0) }) {
                        score -= 80
                    }

                    if b.midY > 0.85 && !up.contains("DATUM") && !up.contains("BON") {
                        score -= 30
                    }

                    candidates.append(ScoredDate(date: validDate, score: score, raw: b.text))
                }
            }
        }

        if let best = candidates.max(by: { $0.score < $1.score }), best.score > 0 {
            return best.date
        }

        return Date()
    }

    // MARK: - Image Persistence & Memory Cache
    private let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB max
        return cache
    }()

    public func saveReceiptImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let filename = "receipt_\(UUID().uuidString).jpg"
        let folder = getReceiptsDirectory()

        let fileURL = folder.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            imageCache.setObject(image, forKey: filename as NSString)
            return filename
        } catch {
            return nil
        }
    }

    public func getReceiptImage(filename: String) -> UIImage? {
        let key = filename as NSString
        if let cached = imageCache.object(forKey: key) {
            return cached
        }
        let fileURL = getReceiptsDirectory().appendingPathComponent(filename)
        if let image = UIImage(contentsOfFile: fileURL.path) {
            imageCache.setObject(image, forKey: key)
            return image
        }
        return nil
    }

    private func getReceiptsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("ReceiptImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
}
