import Foundation

public final class HaushaltsbuchCSVParser {
    public static let shared = HaushaltsbuchCSVParser()

    public static var seedTransactions: [BankTransaction] {
        shared.parse(csvContent: defaultCSVData())
    }

    public static func parse(csvString: String) -> [BankTransaction] {
        shared.parse(csvContent: csvString)
    }

    public static func parse(csvContent: String) -> [BankTransaction] {
        shared.parse(csvContent: csvContent)
    }

    private let dateFormats = ["dd.MM.yyyy", "yyyy-MM-dd", "dd/MM/yyyy", "dd.MM.yy", "MM/dd/yyyy"]

    public func parse(csvContent: String) -> [BankTransaction] {
        var results: [BankTransaction] = []
        let rawLines = csvContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawLines.isEmpty else { return [] }

        // 1. Detect Delimiter (count ;, ,, \t in candidate lines)
        let delimiter = detectDelimiter(from: rawLines)

        // 2. Detect Header Row & Column Mapping
        var dateCol = 0
        var purposeCol = 1
        var amountCol = 2
        var partnerCol: Int? = nil
        var ibanCol: Int? = nil
        var sollCol: Int? = nil
        var habenCol: Int? = nil
        var startIndex = 0

        if let firstLine = rawLines.first {
            let tokens = splitLine(firstLine, delimiter: delimiter)
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

            var hasHeaderMatch = false
            for (idx, token) in tokens.enumerated() {
                if token.contains("datum") || token.contains("date") || token.contains("buchungstag") || token.contains("valuta") {
                    dateCol = idx
                    hasHeaderMatch = true
                } else if token.contains("partner") || token.contains("empfänger") || token.contains("begünstigter") || token.contains("name") {
                    partnerCol = idx
                    hasHeaderMatch = true
                } else if token.contains("zweck") || token.contains("verwendungszweck") || token.contains("beschreibung") || token.contains("vorgang") || token.contains("text") {
                    purposeCol = idx
                    hasHeaderMatch = true
                } else if token == "soll" || token.contains("ausgabe") || token.contains("debit") {
                    sollCol = idx
                    hasHeaderMatch = true
                } else if token == "haben" || token.contains("einnahme") || token.contains("credit") {
                    habenCol = idx
                    hasHeaderMatch = true
                } else if token.contains("betrag") || token.contains("amount") || token.contains("summe") || token.contains("wert") {
                    amountCol = idx
                    hasHeaderMatch = true
                } else if token.contains("iban") || token.contains("konto") {
                    ibanCol = idx
                    hasHeaderMatch = true
                }
            }

            if hasHeaderMatch {
                startIndex = 1
            }
        }

        // 3. Parse Data Lines
        for line in rawLines.dropFirst(startIndex) {
            let parts = splitLine(line, delimiter: delimiter)
            guard parts.count >= 2 else { continue }

            // Extract Date
            guard dateCol < parts.count, let date = parseDate(parts[dateCol]) else {
                continue
            }

            // Extract Amount (support single column or Soll/Haben split)
            var amount: Double = 0.0
            if let sCol = sollCol, let hCol = habenCol, sCol < parts.count, hCol < parts.count {
                if let sollVal = parseAmount(parts[sCol]), sollVal != 0 {
                    amount = -abs(sollVal)
                } else if let habenVal = parseAmount(parts[hCol]), habenVal != 0 {
                    amount = abs(habenVal)
                }
            } else if amountCol < parts.count, let val = parseAmount(parts[amountCol]) {
                amount = val
            } else if parts.count > 2, let val = parseAmount(parts[2]) {
                amount = val
            } else if parts.count > 3, let val = parseAmount(parts[3]) {
                amount = val
            } else {
                continue
            }

            // Extract Purpose & Partner
            let purpose = purposeCol < parts.count ? parts[purposeCol].trimmingCharacters(in: .whitespaces) : (parts.count > 1 ? parts[1] : "")
            var partner = partnerCol != nil && partnerCol! < parts.count ? parts[partnerCol!].trimmingCharacters(in: .whitespaces) : ""
            if partner.isEmpty {
                partner = cleanPurpose(purpose)
            }

            // Extract IBAN
            var accountIban: String? = nil
            if let iCol = ibanCol, iCol < parts.count {
                let raw = parts[iCol].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "'", with: "")
                if !raw.isEmpty { accountIban = raw }
            } else if parts.count >= 7 {
                let rawIban = parts[6].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "'", with: "")
                if !rawIban.isEmpty { accountIban = rawIban }
            } else if let last = parts.last {
                let cleanLast = last.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "'", with: "")
                if cleanLast.starts(with: "DE") { accountIban = cleanLast }
            }

            let category = categorize(purpose: "\(partner) \(purpose)", amount: amount)
            let dummyTx = BankTransaction(date: date, recipientOrPurpose: purpose, amount: amount, category: category, partnerName: partner)
            let budgetCategory = SmartFinanceEngine.shared.mapToBudgetCategory(tx: dummyTx)

            let necessity: ExpenseNecessity
            if category.isLeak || partner.lowercased().contains("lieferando") || partner.lowercased().contains("uber eats") {
                necessity = .unnecessary
            } else if category == .groceries || category == .fixedContracts || category == .debtServicing || category == .besoldung {
                necessity = .necessary
            } else {
                necessity = .neutral
            }

            let tx = BankTransaction(
                date: date,
                recipientOrPurpose: purpose,
                amount: amount,
                category: category,
                accountIBAN: accountIban ?? "DE28300209003201649568",
                rawBookingText: line,
                isManual: false,
                partnerName: partner,
                tags: ["#haushaltsbuch"],
                necessity: necessity,
                budgetCategory: budgetCategory
            )
            results.append(tx)
        }

        return results.sorted(by: { $0.date > $1.date })
    }

    private func detectDelimiter(from lines: [String]) -> String {
        var semicolonCount = 0
        var commaCount = 0
        var tabCount = 0

        for line in lines.prefix(10) {
            semicolonCount += line.filter { $0 == ";" }.count
            commaCount += line.filter { $0 == "," }.count
            tabCount += line.filter { $0 == "\t" }.count
        }

        if tabCount > semicolonCount && tabCount > commaCount {
            return "\t"
        } else if semicolonCount >= commaCount {
            return ";"
        } else {
            return ","
        }
    }

    private func splitLine(_ line: String, delimiter: String) -> [String] {
        if delimiter == "\t" {
            return line.components(separatedBy: "\t")
        } else if delimiter == ";" {
            return line.components(separatedBy: ";")
        } else {
            // Comma split with basic quote handling
            var tokens: [String] = []
            var current = ""
            var inQuotes = false
            for ch in line {
                if ch == "\"" {
                    inQuotes.toggle()
                } else if ch == "," && !inQuotes {
                    tokens.append(current)
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            tokens.append(current)
            return tokens
        }
    }

    private func parseDate(_ str: String) -> Date? {
        let clean = str.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        for format in dateFormats {
            df.dateFormat = format
            if let d = df.date(from: clean) {
                return d
            }
        }
        return nil
    }

    private func parseAmount(_ str: String) -> Double? {
        var clean = str.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "EUR", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !clean.isEmpty else { return nil }

        var isSoll = false
        var isHaben = false
        if clean.hasSuffix("S") || clean.hasSuffix("s") {
            isSoll = true
            clean = String(clean.dropLast()).trimmingCharacters(in: .whitespaces)
        } else if clean.hasSuffix("H") || clean.hasSuffix("h") {
            isHaben = true
            clean = String(clean.dropLast()).trimmingCharacters(in: .whitespaces)
        }

        // Check if German format (comma decimal like 1.234,56 or 45,72)
        if clean.contains(",") {
            clean = clean.replacingOccurrences(of: ".", with: "") // remove thousands separators
            clean = clean.replacingOccurrences(of: ",", with: ".") // comma to dot
        }

        guard let val = Double(clean) else { return nil }
        if isSoll {
            return -abs(val)
        } else if isHaben {
            return abs(val)
        }
        return val
    }

    public func categorize(purpose: String, amount: Double) -> TransactionCategory {
        let lower = purpose.lowercased()

        // 1. Besoldung & Income
        if lower.contains("besoldung") || lower.contains("bundeskasse") || lower.contains("zahltag") {
            return .besoldung
        }
        if amount > 0 && !lower.contains("rückgabe") && !lower.contains("gutschrift karteneinsatz") {
            return .incomeOther
        }

        // 2. Debt Servicing (Targobank loan & Sondertilgung)
        if lower.contains("sondertilgung") || lower.contains("kreditrate") || lower.contains("targobank") || lower.contains("kredit 00007203978276") {
            return .debtServicing
        }

        // 3. Bank Fees, Dispo & Rejections
        if lower.contains("entgelt") || lower.contains("ablehnung lastschrift") || lower.contains("rückgabe lastschrift") || lower.contains("zinssätze") {
            return .bankFees
        }

        // 4. Food Delivery & Fast Food Leaks
        if lower.contains("lieferando") || lower.contains("takeaway") || lower.contains("mcdonalds") || lower.contains("burger king") ||
           lower.contains("linh vy quan") || lower.contains("niso grill") || lower.contains("yorma") || lower.contains("asiahung") || lower.contains("danilo") {
            return .deliveryLeak
        }

        // 5. Groceries (Supermarkets)
        if lower.contains("penny") || lower.contains("edeka") || lower.contains("spar") || lower.contains("rewe") ||
           lower.contains("aldi") || lower.contains("lidl") || lower.contains("oekoekost") || lower.contains("bäckerei") || lower.contains("baeckerei") || lower.contains("schuhbeck") {
            return .groceries
        }

        // 6. Fixed Contracts & Insurances
        if lower.contains("telefonica") || lower.contains("hansemerkur") || lower.contains("netflix") || lower.contains("google one") || lower.contains("google payment") {
            return .fixedContracts
        }

        // 7. Mobility & Taxis
        if lower.contains("taxi") || lower.contains("sumup *taxi") || lower.contains("db vertrieb") || lower.contains("oebb") || lower.contains("metronom") || lower.contains("uestra") || lower.contains("aral") || lower.contains("shell") {
            return .mobility
        }

        // 8. Discretionary & Impulse
        if lower.contains("amazon") || lower.contains("steam") || lower.contains("apple com/bill") || lower.contains("new yorker") || lower.contains("tedi") || lower.contains("city beats") || lower.contains("rossmann") || lower.contains("mueller") {
            return .discretionary
        }

        return .other
    }

    private func cleanPurpose(_ raw: String) -> String {
        var clean = raw
        while clean.contains("  ") {
            clean = clean.replacingOccurrences(of: "  ", with: " ")
        }
        return clean.trimmingCharacters(in: .whitespaces)
    }

    // Pre-seeded master dataset spanning 2025 and 2026 across all accounts
    public static func defaultCSVData() -> String {
        return """
28.04.2025;Umbuchung   3201649568   Am 28.04.2025 um 19:55;-100;;;;'DE44300209005221062404'
02.05.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  NOTFALLFONDS;300;;;;'DE34300209005231062411'
02.05.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  ETF-SPARPLAN;100;;;;'DE28300209005271062409'
02.06.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  NOTFALLFONDS;300;;;;'DE34300209005231062411'
02.06.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  ETF-SPARPLAN;100;;;;'DE28300209005271062409'
01.07.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  NOTFALLFONDS;300;;;;'DE34300209005231062411'
01.07.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  ETF-SPARPLAN;100;;;;'DE28300209005271062409'
01.08.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  NOTFALLFONDS;300;;;;'DE34300209005231062411'
01.08.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  ETF-SPARPLAN;100;;;;'DE28300209005271062409'
01.09.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  NOTFALLFONDS;300;;;;'DE34300209005231062411'
01.09.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  ETF-SPARPLAN;100;;;;'DE28300209005271062409'
03.09.2025;Gutschrift   5231062411;2100;;;;'DE44300209005221062404'
03.09.2025;Gutschrift   5271062409;500;;;;'DE44300209005221062404'
03.09.2025;Umbuchung   5221062404   Am 03.09.2025 um 14:41;-2100;;;;'DE34300209005231062411'
03.09.2025;Umbuchung   5221062404   Am 03.09.2025 um 14:42;-500;;;;'DE28300209005271062409'
01.10.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  NOTGROSCHEN;700;;;;'DE44300209005221062404'
20.10.2025;Gutschrift   3201649568;1000;;;;'DE44300209005221062404'
23.10.2025;Gutschrift   5221062404;200;;;;'DE10300209005211062413'
23.10.2025;Umbuchung   5211062413   Am 23.10.2025 um 17:39;-200;;;;'DE44300209005221062404'
03.11.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;1000;;;;'DE10300209005211062413'
26.11.2025;Kartentransaktion   PAYPAL *hoffmannl514   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-8,4;;;;'DE28300209003201649568'
28.11.2025;Gutschrift Lohn, Gehalt, Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 12-2025 03142616-2025-06012711-043682   03142616-2025-06012711-043682;2723,56;;;;'DE28300209003201649568'
28.11.2025;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE16700202700005713153   Kd-Nr.: 6096729734, Rg-Nr.: 1416627220/8, Ihr Ratenplan   3204500380680001416627220008RCUR   DE9700000000142462   T0010001B000006096729734;-8;;;;'DE28300209003201649568'
01.12.2025;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000;;;;'DE28300209003201649568'
01.12.2025;Kreditrate   7203978276   KREDIT 00007203978276 PER 01.12;-274,7;;;;'DE28300209003201649568'
01.12.2025;Dauerauftrag   RIVERTY SERVICES GMBH   DE34662400020115517500   COBADEFFXXX  S.25.4113674.01.4;-150;;;;'DE28300209003201649568'
01.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046504004801/PP.4081.PP/. Flaconi GmbH, Ihr Einkauf bei Flaconi GmbH   1046504004801   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-46,79;;;;'DE28300209003201649568'
01.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046511861732/. Niso Grill Bahnhofstr, Ihr Einkauf bei Niso Grill Bahnhofstr   1046511861732   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-9,4;;;;'DE28300209003201649568'
01.12.2025;Gutschrift Echtzeitüberweisung   Valentine Ngulefac Nkengas   Valentine ngulefac;250;;;;'DE28300209003201649568'
01.12.2025;Nicht ausgeführter Dauerauftrag   AUFTRAGSNUMM ER 0300001 RIVERTY SERVICES GMBH BIC:COBADEFFXXX IBAN:DE34662400020115517500 S.25.4113674.01.4 AUSFÜHRUNGSZEIT 00.23.12;0;;;;'DE28300209003201649568'
01.12.2025;Entgelt Ablehnung Überweisung;-1,88;;;;'DE28300209003201649568'
01.12.2025;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;1000;;;;'DE10300209005211062413'
02.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046562126968/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046562126968   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-33,57;;;;'DE28300209003201649568'
02.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046562126770/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046562126770   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-0,59;;;;'DE28300209003201649568'
02.12.2025;Kartentransaktion   PAYPAL *koehler.samuel   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-32;;;;'DE28300209003201649568'
02.12.2025;Kartenzahlung   PAYPAL *NETFLIX.COM   35314369001   Kartennummer: 439556XXXXXX290X;-19,99;;;;'DE28300209003201649568'
02.12.2025;Storno Entgelt Ablehnung einer Abbuchung;1,88;;;;'DE28300209003201649568'
02.12.2025;Storno;150;;;;'DE28300209003201649568'
03.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046622838996/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046622838996   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-13,77;;;;'DE28300209003201649568'
04.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046648658745/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046648658745   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-16,98;;;;'DE28300209003201649568'
04.12.2025;Kartenzahlung   UKVI ETAMOB00000909336   WWW.GOV.UK/BR   Kartennummer: 439556XXXXXX290X;-18,95;;;;'DE28300209003201649568'
05.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046672656036/. Niso Grill Bahnhofstr, Ihr Einkauf bei Niso Grill Bahnhofstr   1046672656036   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-15,8;;;;'DE28300209003201649568'
08.12.2025;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-14,99;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046723606324/. Burgerista Salzburg, Ihr Einkauf bei Burgerista Salzburg   1046723606324   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-16,8;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046747317681/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046747317681   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-14,1;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal (Europe) S.a r.l. et Cie, S.C.A.   DE88500700100175526303   1046745391214 . Mr Wen, Ihr Einkauf bei Mr Wen   1046745391214 PAYPAL   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-10,9;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046745391195/. Mr Wen, Ihr Einkauf bei Mr Wen   1046745391195   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-9,5;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046747186270/. Spar Dankt 2386, Ihr Einkauf bei Spar Dankt 2386   1046747186270   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,37;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046723741373/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046723741373   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-2,76;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046747317749/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046747317749   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-0,59;;;;'DE28300209003201649568'
09.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046747187592/. Spar Dankt 2386, Ihr Einkauf bei Spar Dankt 2386   1046747187592   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-0,18;;;;'DE28300209003201649568'
10.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046794672307/. Spar Dankt 2386, Ihr Einkauf bei Spar Dankt 2386   1046794672307   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-34,48;;;;'DE28300209003201649568'
12.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046842748378/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046842748378   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-28,52;;;;'DE28300209003201649568'
15.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046865290281/. Mr Wen, Ihr Einkauf bei Mr Wen   1046865290281   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-9,5;;;;'DE28300209003201649568'
15.12.2025;Kartentransaktion   PAYPAL *diorsebastien   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-703,99;;;;'DE28300209003201649568'
15.12.2025;Kartentransaktion   PAYPAL *diorsebastien   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-265,68;;;;'DE28300209003201649568'
15.12.2025;Kartenzahlung   AMAZON* ZE1QZ2374   LUXEMBOURG   Kartennummer: 439556XXXXXX290X;-148,99;;;;'DE28300209003201649568'
15.12.2025;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-16,99;;;;'DE28300209003201649568'
15.12.2025;Kartenzahlung   APPLE.COM/BILL   CORK   Kartennummer: 439556XXXXXX290X;-12,99;;;;'DE28300209003201649568'
15.12.2025;Kartentransaktion   PAYPAL *diorsebastien   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-12,85;;;;'DE28300209003201649568'
15.12.2025;Kartentransaktion   PAYPAL *diorsebastien   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-11,68;;;;'DE28300209003201649568'
15.12.2025;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-5,99;;;;'DE28300209003201649568'
15.12.2025;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-2,99;;;;'DE28300209003201649568'
15.12.2025;Wichtige Kundeninformation   Für die Einhaltung gesetzlicher Vorgaben und für eine optimale Kundenbetreuung ist es für uns erforderlich, persönliche Daten immer aktuell zu halten. Daher bitten wir Sie, uns jederzeit über Veränderungen Ihrer Daten zu informieren. Vielen Dank!;0;;;;'DE52300209005291062407'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046915436739/. Hoflinger 10017, Ihr Einkauf bei Hoflinger 10017   1046915436739   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,7;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046916413341/. PundB 509, Ihr Einkauf bei PundB 509   1046916413341   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-4,08;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046892543428/. Interspar Dankt 8500, Ihr Einkauf bei Interspar Dankt 8500   1046892543428   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-3,68;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046915516168/. C&A Store 0038, Ihr Einkauf bei C&A Store 0038   1046915516168   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-103,21;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046915516125/. C&A Store 0038, Ihr Einkauf bei C&A Store 0038   1046915516125   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-12,99;;;;'DE28300209003201649568'
16.12.2025;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-22,99;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046915515949/. DEICHMANN Salzburg 018, Ihr Einkauf bei DEICHMANN Salzburg 018   1046915515949   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-48,98;;;;'DE28300209003201649568'
16.12.2025;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046915515949/. DEICHMANN Salzburg 018, Ihr Einkauf bei DEICHMANN Salzburg 018   046915515949   LU96ZZZ0000000000000000058   55C22253VQ6AQ;48,98;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046916202282/. Niso Grill Bahnhofstr, Ihr Einkauf bei Niso Grill Bahnhofstr   1046916202282   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-17,8;;;;'DE28300209003201649568'
16.12.2025;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046916202282/. Niso Grill Bahnhofstr, Ihr Einkauf bei Niso Grill Bahnhofstr   046916202282   LU96ZZZ0000000000000000058   55C22253VQ6AQ;17,8;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   AMAZON PAYMENTS EUROPE S.C.A.   DE87300308801908262006   302-0120187-4747532 AMZN Mktp DE 6IZZNK0T0VGXR9OM   6IZZNK0T0VGXR9OM   DE94ZZZ00000561653   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;-10,95;;;;'DE28300209003201649568'
16.12.2025;Rückgabe Lastschrift Fehlende Deckung   AMAZON PAYMENTS EUROPE S.C.A.   DE87300308801908262006   302-0120187-4747532 AMZN Mktp DE 6IZZNK0T0VGXR9OM   IZZNK0T0VGXR9OM   DE94ZZZ00000561653   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;10,95;;;;'DE28300209003201649568'
16.12.2025;Lastschrift   AMAZON EU S.A R.L., NIEDERLASSUNG DEUTSCHLAND   DE93300308800013441006   D01-3516389-3243802 AMZNPrime DE 2VI7KQDR4N60SJXC   2VI7KQDR4N60SJXC   DE24ZZZ00000561652   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;-8,99;;;;'DE28300209003201649568'
16.12.2025;Rückgabe Lastschrift Fehlende Deckung   AMAZON EU S.A R.L., NIEDERLASSUNG DEUTSCHLAND   DE93300308800013441006   D01-3516389-3243802 AMZNPrime DE 2VI7KQDR4N60SJXC   VI7KQDR4N60SJXC   DE24ZZZ00000561652   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;8,99;;;;'DE28300209003201649568'
16.12.2025;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
17.12.2025;Lastschrift   AMAZON PAYMENTS EUROPE S.C.A.   DE87300308801908262006   306-3732567-3253950 AMZN Mktp DE 39BJSXX0YRQZ0R7E   39BJSXX0YRQZ0R7E   DE94ZZZ00000561653   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;-28,04;;;;'DE28300209003201649568'
17.12.2025;Rückgabe Lastschrift Fehlende Deckung   AMAZON PAYMENTS EUROPE S.C.A.   DE87300308801908262006   306-3732567-3253950 AMZN Mktp DE 39BJSXX0YRQZ0R7E   9BJSXX0YRQZ0R7E   DE94ZZZ00000561653   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;28,04;;;;'DE28300209003201649568'
17.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046964572488/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   1046964572488   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-27,95;;;;'DE28300209003201649568'
17.12.2025;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1046964572488/. Penny Bad Reichenhall, Ihr Einkauf bei Penny Bad Reichenhall   046964572488   LU96ZZZ0000000000000000058   55C22253VQ6AQ;27,95;;;;'DE28300209003201649568'
17.12.2025;Lastschrift   AMAZON PAYMENTS EUROPE S.C.A.   DE87300308801908262006   302-0120187-4747532 AMZN Mktp DE 1ZMTIT2HDG0ID5JR   1ZMTIT2HDG0ID5JR   DE94ZZZ00000561653   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;-96;;;;'DE28300209003201649568'
17.12.2025;Rückgabe Lastschrift Fehlende Deckung   AMAZON PAYMENTS EUROPE S.C.A.   DE87300308801908262006   302-0120187-4747532 AMZN Mktp DE 1ZMTIT2HDG0ID5JR   ZMTIT2HDG0ID5JR   DE94ZZZ00000561653   Ghy0h0aJJ-7fyknyyHxNh9vWrROVWb;96;;;;'DE28300209003201649568'
17.12.2025;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
18.12.2025;Gutschrift   DE44300209005221062404;1000;;;;'DE28300209003201649568'
18.12.2025;Umbuchung   DE28300209003201649568   Am 18.12.2025 um 10:50;-1000;;;;'DE44300209005221062404'
19.12.2025;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE16700202700005713153   Kd-Nr.: 6108760409, Rg-Nr.: 1432947798/8, Ihre Tarifrechnung   3304636881940001432947798008RCUR   DE9700000000142462   T0010001B000006108760409;-95,35;;;;'DE28300209003201649568'
19.12.2025;Kartenzahlung   Baeckerei Stefan Neume   Bad Reichenha 61777346   Kartennummer: 439556XXXXXX290X;-10,3;;;;'DE28300209003201649568'
19.12.2025;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX290X;-5,7;;;;'DE28300209003201649568'
22.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047031838764/., Ihr Einkauf bei   1047031838764   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-50,86;;;;'DE28300209003201649568'
22.12.2025;Lastschrift   PayPal (Europe) S.a r.l. et Cie, S.C.A.   DE88500700100175526303   1047031544347 ., Ihr Einkauf bei   1047031544347 PAYPAL   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-19,68;;;;'DE28300209003201649568'
22.12.2025;Kartenzahlung   MATALAN STORE 282   VISA-Kurs   BRIDGWATER 38160739   Kartennummer: 439556XXXXXX290X;-222,06;;;;'DE28300209003201649568'
22.12.2025;Auslandseinsatzentgelt   MATALAN STORE 282 FÜR EINSATZ AM 19.12.2025;-4,11;;;;'DE28300209003201649568'
24.12.2025;Kartenzahlung   PAYPAL *TAKEAWAYCOM   35314369001   Kartennummer: 439556XXXXXX290X;-31,79;;;;'DE28300209003201649568'
29.12.2025;Gutschrift Echtzeitüberweisung   Valentine Ngulefac Nkengas   Valentine ngulefac rest ruckzahlung;2650;;;;'DE28300209003201649568'
29.12.2025;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE16700202700005713153   Kd-Nr.: 6082661329, Rg-Nr.: 1440995554/8, Ihr Ratenplan   3304642699970001440995554008RCUR   DE9700000000142462   T0010001B000006082661329;-22,5;;;;'DE28300209003201649568'
29.12.2025;Gutschrift Karteneinsatz   PAYPAL*NKEMBI PARRIS-CAMP   Luxembourg   Kartennummer: 439556XXXXXX290X;9,92;;;;'DE28300209003201649568'
29.12.2025;Kartenzahlung   FewoDirekt HA733350890   EXPEDIA.IE   Kartennummer: 439556XXXXXX290X;-85,05;;;;'DE28300209003201649568'
29.12.2025;Kartentransaktion   PAYPAL *Nkembi Parris-Cam   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-30;;;;'DE28300209003201649568'
29.12.2025;Kartentransaktion   PAYPAL *Nkembi Parris-Cam   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-10;;;;'DE28300209003201649568'
29.12.2025;Kartentransaktion   PAYPAL *clarisse-njingo   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-2,19;;;;'DE28300209003201649568'
30.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047185028458/PP.4081.PP/., Ihr Einkauf bei   1047185028458   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-601,89;;;;'DE28300209003201649568'
30.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047197182876/. Babyboo Fashion Pty Ltd, Ihr Einkauf bei Babyboo Fashion Pty Ltd   1047197182876   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-218,33;;;;'DE28300209003201649568'
30.12.2025;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047182472109/., Ihr Einkauf bei   1047182472109   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-29,83;;;;'DE28300209003201649568'
30.12.2025;Gutschrift Lohn, Gehalt, Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 01-2026 03142616-2026-06012912-042212   03142616-2026-06012912-042212;2485,42;;;;'DE28300209003201649568'
30.12.2025;Umbuchung   DE44300209005221062404   Am 30.12.2025 um 19:39;-1000;;;;'DE28300209003201649568'
30.12.2025;Gutschrift   DE28300209003201649568;1000;;;;'DE44300209005221062404'
31.12.2025;Sollzinsen   RECHNUNGSABSCHLUSS! BITTE BEACHTEN SIE DIE HIN-WEISE AUF IHREM FINANZSTATUS ODER QUARTALSKONTOAUSZUG!GUTHABEN NACH KONTOABRECHNUNG: 3.696,61;-0,01;;;;'DE28300209003201649568'
31.12.2025;Information Zinssätze   SOLLZINSSÄTZE: FÜR VEREINBARTE DISPOSITIONSKREDITE BIS 50,00 EUR: 0.00 % P.A. UEBER 50,00 EUR: 13.73 % P.A. (FÜR DIE GESAMTE INANSPRUCHNAHME) SOLLZINSSATZ FÜR GEDULDETE ÜBERZIEHUNG: 16.73 % P.A.;0;;;;'DE28300209003201649568'
31.12.2025;Habenzinsen;1,75;;;;'DE10300209005211062413'
31.12.2025;Kapitalertragsteuer;-0,43;;;;'DE10300209005211062413'
31.12.2025;Solidaritätszuschlag   berechnet auf Basis KEST;-0,02;;;;'DE10300209005211062413'
31.12.2025;Kirchensteuer   berechnet auf Basis KEST;-0,03;;;;'DE10300209005211062413'
31.12.2025;Habenzinsen;13,57;;;;'DE44300209005221062404'
31.12.2025;Kapitalertragsteuer;-3,32;;;;'DE44300209005221062404'
31.12.2025;Solidaritätszuschlag   berechnet auf Basis KEST;-0,18;;;;'DE44300209005221062404'
31.12.2025;Kirchensteuer   berechnet auf Basis KEST;-0,29;;;;'DE44300209005221062404'
31.12.2025;Habenzinsen;3,25;;;;'DE34300209005231062411'
31.12.2025;Kapitalertragsteuer;-0,79;;;;'DE34300209005231062411'
31.12.2025;Solidaritätszuschlag   berechnet auf Basis KEST;-0,04;;;;'DE34300209005231062411'
31.12.2025;Kirchensteuer   berechnet auf Basis KEST;-0,07;;;;'DE34300209005231062411'
31.12.2025;Habenzinsen;0,64;;;;'DE28300209005271062409'
31.12.2025;Kapitalertragsteuer;-0,16;;;;'DE28300209005271062409'
31.12.2025;Solidaritätszuschlag   berechnet auf Basis KEST;0;;;;'DE28300209005271062409'
31.12.2025;Kirchensteuer   berechnet auf Basis KEST;-0,01;;;;'DE28300209005271062409'
02.01.2026;Dauerauftrag   RIVERTY SERVICES GMBH   DE34662400020115517500   COBADEFFXXX  S.25.4113674.01.4;-150;;;;'DE28300209003201649568'
02.01.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000;;;;'DE28300209003201649568'
02.01.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01.01;-274,7;;;;'DE28300209003201649568'
02.01.2026;Kartenzahlung   PAYPAL *NETFLIX.COM   35314369001   Kartennummer: 439556XXXXXX290X;-19,99;;;;'DE28300209003201649568'
02.01.2026;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;1000;;;;'DE10300209005211062413'
05.01.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6096729734, Rg-Nr.: 1442580975/8, Ihr Ratenplan   3204523343990001442580975008RCUR   DE9700000000142462   T0010001B000006096729734;-8;;;;'DE28300209003201649568'
05.01.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX290X;-5,9;;;;'DE28300209003201649568'
06.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047404351663/. WH Smith Stansted, Ihr Einkauf bei WH Smith Stansted   1047404351663   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-5,79;;;;'DE28300209003201649568'
07.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047427039586/. Hoflinger 10017, Ihr Einkauf bei Hoflinger 10017   1047427039586   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-21,45;;;;'DE28300209003201649568'
07.01.2026;Kartenzahlung   Limehome GmbH   Munich   Kartennummer: 439556XXXXXX290X;-66,15;;;;'DE28300209003201649568'
07.01.2026;Kartenzahlung   MUeLLER BAD REICHENHALL   Bad Reichenha 69508823   Kartennummer: 439556XXXXXX290X;-1;;;;'DE28300209003201649568'
08.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047450904783/. MUeLLER BAD REICHENHAL, Ihr Einkauf bei MUeLLER BAD REICHENHAL   1047450904783   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-39,05;;;;'DE28300209003201649568'
08.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047448833541/. UZR.CEM Gastro GmbH Ca, Ihr Einkauf bei UZR.CEM Gastro GmbH Ca   1047448833541   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-18,45;;;;'DE28300209003201649568'
08.01.2026;Kartenzahlung   Limehome GmbH RDHZNDVH-1   Munich   Kartennummer: 439556XXXXXX290X;-66,15;;;;'DE28300209003201649568'
08.01.2026;Kartenzahlung   PAYPAL *DBVERTRIEBG A-NR.   302970   Kartennummer: 439556XXXXXX290X;-5,5;;;;'DE28300209003201649568'
09.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047472949514/. McDonalds 01446, Ihr Einkauf bei McDonalds 01446   1047472949514   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-24,99;;;;'DE28300209003201649568'
12.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047478197609/PP.4081.PP/., Ihr Einkauf bei   1047478197609   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-50;;;;'DE28300209003201649568'
12.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047478248214/PP.4081.PP/., Ihr Einkauf bei   1047478248214   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-21;;;;'DE28300209003201649568'
12.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047493301955/. NYA.Hering Sanikonzept, Ihr Einkauf bei NYA.Hering Sanikonzept   1047493301955   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-1,5;;;;'DE28300209003201649568'
12.01.2026;Kartentransaktion   PAYPAL *Nkembi Parris-Cam   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-100;;;;'DE28300209003201649568'
12.01.2026;Kartenzahlung   PAYPAL *DBVERTRIEBG A-NR.   302970   Kartennummer: 439556XXXXXX290X;-5,5;;;;'DE28300209003201649568'
13.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047537197850/. Spar Dankt 2386, Ihr Einkauf bei Spar Dankt 2386   1047537197850   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-34,65;;;;'DE28300209003201649568'
13.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047537199441/. Burgerista Salzburg, Ihr Einkauf bei Burgerista Salzburg   1047537199441   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-18,89;;;;'DE28300209003201649568'
13.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047559126532/PP.4081.PP/., Ihr Einkauf bei   1047559126532   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,4;;;;'DE28300209003201649568'
13.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047516088403/. Hoflinger 10017, Ihr Einkauf bei Hoflinger 10017   1047516088403   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-7,65;;;;'DE28300209003201649568'
13.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047496097800/PP.4081.PP/., Ihr Einkauf bei   1047496097800   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-3,5;;;;'DE28300209003201649568'
13.01.2026;Kartentransaktion   PAYPAL *Nkembi Parris-Cam   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX290X;-100;;;;'DE28300209003201649568'
14.01.2026;Umbuchung   DE10300209005211062413   Am 14.01.2026 um 19:46;-1000;;;;'DE28300209003201649568'
14.01.2026;Gutschrift   DE28300209003201649568;1000;;;;'DE10300209005211062413'
15.01.2026;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-16,99;;;;'DE28300209003201649568'
15.01.2026;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-2,99;;;;'DE28300209003201649568'
16.01.2026;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-22,99;;;;'DE28300209003201649568'
19.01.2026;Kartenzahlung   BKG*HOTEL AT BOOKING.C   (888)850-3958   Kartennummer: 439556XXXXXX290X;-84;;;;'DE28300209003201649568'
19.01.2026;Kartenzahlung   Hotel at Booking.com   Amsterdam   Kartennummer: 439556XXXXXX290X;-75,65;;;;'DE28300209003201649568'
19.01.2026;Kartenzahlung   Google One   Dublin   Kartennummer: 439556XXXXXX290X;-32,98;;;;'DE28300209003201649568'
19.01.2026;Kartenzahlung   AMZN Mktp DE*RX3DZ5S95   AMZN.COM/BILL   Kartennummer: 439556XXXXXX290X;-31,04;;;;'DE28300209003201649568'
19.01.2026;Kartenzahlung   PAYPAL *DBVERTRIEBG A-NR.   302970   Kartennummer: 439556XXXXXX290X;-5,5;;;;'DE28300209003201649568'
19.01.2026;Kartenzahlung   APPLE.COM/BILL   08006645451   Kartennummer: 439556XXXXXX290X;-3,99;;;;'DE28300209003201649568'
20.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047669968050/. Hotel TYROS, Ihr Einkauf bei Hotel TYROS   1047669968050   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8;;;;'DE28300209003201649568'
20.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047692385596/. Netto Marken-Discount, Ihr Einkauf bei Netto Marken-Discount   1047692385596   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-5,42;;;;'DE28300209003201649568'
20.01.2026;Änderung persönliche Daten   NAMENS-/ADRESSÄNDERUNG: PARRIS-CAMPBELL NKENGASONG NKEMBI BULTSTR. 53 29221 CELLE GERMANY;0;;;;'DE28300209003201649568'
20.01.2026;Kartensperre   Kartennr. (439556XXXXXX290X) Gültig bis (09/26) (Diebstahl / Verlust);0;;;;'DE28300209003201649568'
20.01.2026;Bestellung Debitkarte   PARRIS-CAMPBELL NKENGASON NKEMBI Kartennr. (439556XXXXXX910X) Gültig bis (01/30) Tageslimit: 2.500 EUR;0;;;;'DE28300209003201649568'
20.01.2026;Änderung Telefonnummer   IHRE NEUE TELEFONNUMMER LAUTET: 49-017681234400 Die von Ihnen ausgewählten mobilen Dienste (mTAN/Konto-SMS-Service) nutzen diese Mobilfunknummer.;0;;;;'DE28300209003201649568'
20.01.2026;Kartenzahlung   PAYPAL *DBVERTRIEBG A-NR.   302970   Kartennummer: 439556XXXXXX290X;-5,5;;;;'DE28300209003201649568'
20.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047712035751/. Booking.com BV, Ihr Einkauf bei Booking.com BV   1047712035751   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-408,24;;;;'DE28300209003201649568'
20.01.2026;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047712035751/. Booking.com BV, Ihr Einkauf bei Booking.com BV   047712035751   LU96ZZZ0000000000000000058   55C22253VQ6AQ;408,24;;;;'DE28300209003201649568'
20.01.2026;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
20.01.2026;Entgelt Ersatz-Debitkarte   Entgelt Debitkarte Kartennummer (439556XXXXXX910X) Gültig bis (01/30);-5,5;;;;'DE28300209003201649568'
20.01.2026;Umbuchung   DE97300209000000720397   UMBUCHUNG;-200;;;;'DE10300209005211062413'
21.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047729458961/. MS. APARTHOTELLENAU, Ihr Einkauf bei MS. APARTHOTELLENAU   1047729458961   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-36;;;;'DE28300209003201649568'
21.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047730973244/. Hoflinger 10136, Ihr Einkauf bei Hoflinger 10136   1047730973244   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-22,05;;;;'DE28300209003201649568'
22.01.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6108760409, Rg-Nr.: 1458451936/8, Ihre Tarifrechnung   3304660932540001458451936008RCUR   DE9700000000142462   T0010001B000006108760409;-94,96;;;;'DE28300209003201649568'
22.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047754187052/. McDonalds 01446, Ihr Einkauf bei McDonalds 01446   1047754187052   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-27,09;;;;'DE28300209003201649568'
22.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047754186972/. McDonalds 01446, Ihr Einkauf bei McDonalds 01446   1047754186972   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-23,94;;;;'DE28300209003201649568'
22.01.2026;Kartenzahlung   PAYPAL *DBVERTRIEBG A-NR.   302970   Kartennummer: 439556XXXXXX290X;-5,5;;;;'DE28300209003201649568'
23.01.2026;Gutschrift   DE44300209005221062404;600;;;;'DE28300209003201649568'
23.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047775106157/. MUeLLER CELLE KASSE 2, Ihr Einkauf bei MUeLLER CELLE KASSE 2   1047775106157   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-45,09;;;;'DE28300209003201649568'
23.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047774956329/. Saray GmbH, Ihr Einkauf bei Saray GmbH   1047774956329   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-35,58;;;;'DE28300209003201649568'
23.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047770863119/. REWE Jennifer Biniek o, Ihr Einkauf bei REWE Jennifer Biniek o   1047770863119   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-15,92;;;;'DE28300209003201649568'
23.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047772823656/. Chaaban, Ihr Einkauf bei Chaaban   1047772823656   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-3;;;;'DE28300209003201649568'
23.01.2026;Gutschrift   DE44300209005221062404;200;;;;'DE28300209003201649568'
23.01.2026;Umbuchung   DE28300209003201649568   Am 22.01.2026 um 23:12;-600;;;;'DE44300209005221062404'
23.01.2026;Umbuchung   DE28300209003201649568   Am 23.01.2026 um 09:09;-200;;;;'DE44300209005221062404'
26.01.2026;Gutschrift   DE10300209005211062413;1000;;;;'DE28300209003201649568'
26.01.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047792617686/., Ihr Einkauf bei   1047792617686   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-410,12;;;;'DE28300209003201649568'
26.01.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6082661329, Rg-Nr.: 1466577128/8, Ihr Ratenplan   3304667079100001466577128008RCUR   DE9700000000142462   T0010001B000006082661329;-22,5;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   Superfly Hannover   Butzbach   Kartennummer: 439556XXXXXX910X;-99,96;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   Noosou Hannover   Hannover 65488906   Kartennummer: 439556XXXXXX910X;-62,2;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54221351   Kartennummer: 439556XXXXXX910X;-24,99;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   metronom Eisenbahngesells   Uelzen 55727693   Kartennummer: 439556XXXXXX910X;-23,8;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239941   Kartennummer: 439556XXXXXX910X;-22,74;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   EDEKA 2185   HANNOVER 64090285   Kartennummer: 439556XXXXXX910X;-22,06;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   Lidl sagt Danke   Hannover 60198555   Kartennummer: 439556XXXXXX910X;-12,5;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   Rossmann 2800   Hannover 60356514   Kartennummer: 439556XXXXXX910X;-7,9;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,5;;;;'DE28300209003201649568'
26.01.2026;Kartenzahlung   Rossmann 1670   Hannover 60301062   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
26.01.2026;Umbuchung   DE28300209003201649568   Am 24.01.2026 um 14:47;-1000;;;;'DE10300209005211062413'
27.01.2026;Gutschrift   PayPal Europe S.a.r.l. et Cie S.C.A   . Babyboo Fashion Pty Ltd, Ihr Einkauf bei Babyboo Fashion Pty Ltd/ABBUCHUNG VOM PAYPAL-KONTO   YYW1047866332084;218,33;;;;'DE28300209003201649568'
27.01.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-36,46;;;;'DE28300209003201649568'
27.01.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508239   Kartennummer: 439556XXXXXX910X;-34,24;;;;'DE28300209003201649568'
27.01.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54526278   Kartennummer: 439556XXXXXX910X;-4,15;;;;'DE28300209003201649568'
27.01.2026;Umbuchung   DE34300209005231062411   Am 27.01.2026 um 16:52;-200;;;;'DE28300209003201649568'
27.01.2026;Gutschrift   DE28300209003201649568;200;;;;'DE34300209005231062411'
28.01.2026;Gutschrift Echtzeitüberweisung   Sebastien Nkembi Njingo   Bill;300;;;;'DE28300209003201649568'
28.01.2026;Umbuchung   DE44300209005221062404   Am 28.01.2026 um 14:14;-300;;;;'DE28300209003201649568'
28.01.2026;Gutschrift   DE28300209003201649568;300;;;;'DE44300209005221062404'
29.01.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE16700202700005713153   Kd-Nr.: 6096729734, Rg-Nr.: 1467848592/8, Ihr Ratenplan   3204545548630001467848592008RCUR   DE9700000000142462   T0010001B000006096729734;-8;;;;'DE28300209003201649568'
29.01.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013315   Kartennummer: 439556XXXXXX910X;-25,2;;;;'DE28300209003201649568'
30.01.2026;Gutschrift Lohn, Gehalt, Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 02-2026 03142616-2026-06012901-041994   03142616-2026-06012901-041994;2440,9;;;;'DE28300209003201649568'
02.02.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000;;;;'DE28300209003201649568'
02.02.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01.02;-74,7;;;;'DE28300209003201649568'
02.02.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047931820384/PP.4081.PP/., Ihr Einkauf bei   1047931820384   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-6;;;;'DE28300209003201649568'
02.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-40,16;;;;'DE28300209003201649568'
02.02.2026;Kartenzahlung   DHL*XC5K2UUK7TKV   BONN   Kartennummer: 439556XXXXXX910X;-7,18;;;;'DE28300209003201649568'
02.02.2026;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;1000;;;;'DE10300209005211062413'
03.02.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1047986121208/PP.4081.PP/. Netflix.com, Ihr Einkauf bei Netflix.com   1047986121208   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-19,99;;;;'DE28300209003201649568'
03.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-23,62;;;;'DE28300209003201649568'
04.02.2026;Kartenzahlung   NISO GRILL BAHNHOFSTR   BAD REICHENHA 64013657   Kartennummer: 439556XXXXXX910X;-9,9;;;;'DE28300209003201649568'
04.02.2026;Kartenzahlung   Spar Dankt 2386   Salzburg 23613565   Kartennummer: 439556XXXXXX910X;-4,95;;;;'DE28300209003201649568'
04.02.2026;Umbuchung   DE44300209005221062404   Am 04.02.2026 um 19:54;-1000;;;;'DE28300209003201649568'
04.02.2026;Umbuchung   DE44300209005221062404   Am 04.02.2026 um 19:56;-500;;;;'DE28300209003201649568'
04.02.2026;Gutschrift   DE28300209003201649568;1000;;;;'DE44300209005221062404'
04.02.2026;Gutschrift   DE28300209003201649568;500;;;;'DE44300209005221062404'
09.02.2026;Kartenzahlung   Limehome GmbH   Munich   Kartennummer: 439556XXXXXX910X;-131,82;;;;'DE28300209003201649568'
09.02.2026;Kartenzahlung   SP CHERRY BLOSSOM   LEIPZIG   Kartennummer: 439556XXXXXX910X;-79,95;;;;'DE28300209003201649568'
09.02.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34;;;;'DE28300209003201649568'
09.02.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-31;;;;'DE28300209003201649568'
09.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-13,24;;;;'DE28300209003201649568'
10.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-1,07;;;;'DE28300209003201649568'
10.02.2026;Kartenzahlung   Drexler Frischmarkt   Bad Reichenha 69700559   Kartennummer: 439556XXXXXX910X;-12,76;;;;'DE28300209003201649568'
11.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-19,72;;;;'DE28300209003201649568'
11.02.2026;Gutschrift   DE44300209005221062404;1700;;;;'DE28300209003201649568'
11.02.2026;Umbuchung   DE28300209003201649568   Am 11.02.2026 um 18:48;-1700;;;;'DE44300209005221062404'
12.02.2026;Kartenzahlung   MEDIA MARKT   INGOLSTADT   Kartennummer: 439556XXXXXX910X;-899;;;;'DE28300209003201649568'
13.02.2026;Kartenzahlung   NISO GRILL BAHNHOFSTR   BAD REICHENHA 64013657   Kartennummer: 439556XXXXXX910X;-17,8;;;;'DE28300209003201649568'
13.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-6,94;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   H&M DE0623   HANNOVER 54353620   Kartennummer: 439556XXXXXX910X;-210,19;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   Lieferando.de KBFD7J   Amsterdam   Kartennummer: 439556XXXXXX910X;-72,81;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   UZR*Astor Hannover   Hannover 54341491   Kartennummer: 439556XXXXXX910X;-60;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   MUeLLER BAD REICHENHALL   Bad Reichenha 69508825   Kartennummer: 439556XXXXXX910X;-41,34;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239941   Kartennummer: 439556XXXXXX910X;-24,99;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   UZR*Astor Hannover   Hannover 54341516   Kartennummer: 439556XXXXXX910X;-23,6;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   NISO GRILL BAHNHOFSTR   BAD REICHENHA 64013657   Kartennummer: 439556XXXXXX910X;-17,8;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   KAUFLAND HANNOVER MITTE 6   HANNOVER 61345972   Kartennummer: 439556XXXXXX910X;-17,43;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   Hoflinger 10017   Bad Reichenha 68275205   Kartennummer: 439556XXXXXX910X;-11,6;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   Lagardere Fil. 440   Celle 69701456   Kartennummer: 439556XXXXXX910X;-10;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,5;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   DTV BUCH GANTER 3 MOVE   Freilassing 69714386   Kartennummer: 439556XXXXXX910X;-5,3;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   SELECTA DEUTSCHLAND GM   KELSTERBACH SP006WDJ   Kartennummer: 439556XXXXXX910X;-3,3;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   NYX*zoellsdeGmbH   Muenchen NY65PASH   Kartennummer: 439556XXXXXX910X;-3;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   APPLE.COM/BILL   CORK   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
16.02.2026;Kartenzahlung   SELECTA DEUTSCHLAND GM   KELSTERBACH SP006WDJ   Kartennummer: 439556XXXXXX910X;-2,8;;;;'DE28300209003201649568'
17.02.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2602167174709 - Bitte bei Rückfragen angeben.;-137;;;;'DE28300209003201649568'
17.02.2026;Kartenzahlung   NISO GRILL BAHNHOFSTR   BAD REICHENHA 64013657   Kartennummer: 439556XXXXXX910X;-17,8;;;;'DE28300209003201649568'
18.02.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1048330569464/PP.4081.PP/., Ihr Einkauf bei   1048330569464   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-6,1;;;;'DE28300209003201649568'
18.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013314   Kartennummer: 439556XXXXXX910X;-44,23;;;;'DE28300209003201649568'
18.02.2026;Kartenzahlung   Google One   Dublin   Kartennummer: 439556XXXXXX910X;-32,98;;;;'DE28300209003201649568'
19.02.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1048356790163/PP.4081.PP/., Ihr Einkauf bei   1048356790163   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-12;;;;'DE28300209003201649568'
19.02.2026;Kartenzahlung   ALDI SUeD   Bad Reichenha 65151792   Kartennummer: 439556XXXXXX910X;-33,4;;;;'DE28300209003201649568'
19.02.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  EMERGENCY   HBKIN2602197499756 - Bitte bei Rückfragen angeben.;-50;;;;'DE28300209003201649568'
20.02.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE16700202700005713153   Kd-Nr.: 6108760409, Rg-Nr.: 1484254765/8, Ihre Tarifrechnung   3304684499300001484254765008RCUR   DE9700000000142462   T0010001B000006108760409;-94,96;;;;'DE28300209003201649568'
20.02.2026;Gutschrift   DE10300209005211062413;400;;;;'DE28300209003201649568'
20.02.2026;Echtzeitüberweisung   RIVERTY SERVICES GMBH   DE36660100750025403755   PBNKDEFFXXX  S.25.1062237.01.2   HBKIN2602207574451 - Bitte bei Rückfragen angeben.;-246,94;;;;'DE28300209003201649568'
20.02.2026;Gutschrift   DE44300209005221062404;1000;;;;'DE28300209003201649568'
20.02.2026;Umbuchung   DE28300209003201649568   Am 20.02.2026 um 09:29;-400;;;;'DE10300209005211062413'
20.02.2026;Umbuchung   DE28300209003201649568   Am 20.02.2026 um 14:05;-1000;;;;'DE44300209005221062404'
23.02.2026;Gutschrift Karteneinsatz   MEDIA MARKT   INGOLSTADT   Kartennummer: 439556XXXXXX910X;899;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508239   Kartennummer: 439556XXXXXX910X;-26,35;;;;'DE28300209003201649568'
23.02.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-20;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   GENTA Backerei   Salzburg 23729118   Kartennummer: 439556XXXXXX910X;-15,7;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   SUBWAY 70-777 Griesgasse   Salzburg 31516467   Kartennummer: 439556XXXXXX910X;-10,39;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   Niso Markt   Bad Reichenha 55794395   Kartennummer: 439556XXXXXX910X;-7,75;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   APPLE.COM/BILL   ITUNES.COM   Kartennummer: 439556XXXXXX910X;-4,99;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   SUBWAY 70-777 Griesgasse   Salzburg 31516467   Kartennummer: 439556XXXXXX910X;-2,38;;;;'DE28300209003201649568'
23.02.2026;Kartenzahlung   Media Markt   Salzburg 31430019   Kartennummer: 439556XXXXXX910X;-959;;;;'DE28300209003201649568'
23.02.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-100;;;;'DE28300209003201649568'
23.02.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
24.02.2026;Kartenzahlung   GENTA Backerei   Salzburg 23729118   Kartennummer: 439556XXXXXX910X;-12,1;;;;'DE28300209003201649568'
25.02.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508243   Kartennummer: 439556XXXXXX910X;-26,18;;;;'DE28300209003201649568'
26.02.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6082661329, Rg-Nr.: 1492209901/8, Ihr Ratenplan   3304690677510001492209901008RCUR   DE9700000000142462   T0010001B000006082661329;-22,5;;;;'DE28300209003201649568'
26.02.2026;Kartenzahlung   Drexler Frischmarkt   Bad Reichenha 69700559   Kartennummer: 439556XXXXXX910X;-10,78;;;;'DE28300209003201649568'
26.02.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
26.02.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-4;;;;'DE28300209003201649568'
27.02.2026;Gutschrift Lohn, Gehalt, Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 03-2026 03142616-2026-06012602-041932   03142616-2026-06012602-041932;2443,66;;;;'DE28300209003201649568'
27.02.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6096729734, Rg-Nr.: 1493563564/8, Ihr Ratenplan   3204568017140001493563564008RCUR   DE9700000000142462   T0010001B000006096729734;-8;;;;'DE28300209003201649568'
27.02.2026;Entgelt Kontaklosfunktion Debitkarte   Kartennummer: 439556XXXXXX910X;-10;;;;'DE28300209003201649568'
02.03.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000;;;;'DE28300209003201649568'
02.03.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01.03;-274,7;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508239   Kartennummer: 439556XXXXXX910X;-25,52;;;;'DE28300209003201649568'
02.03.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-20;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   IGNANZ Grill & Pizza Haus   Salzburg 31558958   Kartennummer: 439556XXXXXX910X;-12,7;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   Aral Station 191399104   Bad Reichenha 71113356   Kartennummer: 439556XXXXXX910X;-9,75;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   Alis Golden Bite   Salzburg AH603420   Kartennummer: 439556XXXXXX910X;-9,5;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-6,76;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613405   Kartennummer: 439556XXXXXX910X;-3,68;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   Alis Golden Bite   Salzburg AH603420   Kartennummer: 439556XXXXXX910X;-3,3;;;;'DE28300209003201649568'
02.03.2026;Kartenzahlung   McDonalds 176   Salzburg 23610109   Kartennummer: 439556XXXXXX910X;-33,4;;;;'DE28300209003201649568'
02.03.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
02.03.2026;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;1000;;;;'DE10300209005211062413'
03.03.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-6,55;;;;'DE28300209003201649568'
03.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
03.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613405   Kartennummer: 439556XXXXXX910X;-1,24;;;;'DE28300209003201649568'
04.03.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508241   Kartennummer: 439556XXXXXX910X;-97,68;;;;'DE28300209003201649568'
04.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
05.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
09.03.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1048719308887/PP.4081.PP/., Ihr Einkauf bei   1048719308887   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-12;;;;'DE28300209003201649568'
09.03.2026;Gutschrift Karteneinsatz   Hotel at Booking.com   Amsterdam   Kartennummer: 439556XXXXXX910X;62,1;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   Hotel at Booking.com   Amsterdam   Kartennummer: 439556XXXXXX910X;-62,1;;;;'DE28300209003201649568'
09.03.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-50;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   McDonalds 173   Wals 23610093   Kartennummer: 439556XXXXXX910X;-35,5;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508240   Kartennummer: 439556XXXXXX910X;-26,71;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   MCDONALDS 0382   FREILASSING 54246499   Kartennummer: 439556XXXXXX910X;-18,3;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-16,44;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   IGNANZ Grill & Pizza Haus   Salzburg 31558958   Kartennummer: 439556XXXXXX910X;-11,5;;;;'DE28300209003201649568'
09.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
09.03.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
10.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-10,07;;;;'DE28300209003201649568'
10.03.2026;Kartenzahlung   NYX*ZweckverbandBergerleb   Berchtesgaden NX431953   Kartennummer: 439556XXXXXX910X;-2,9;;;;'DE28300209003201649568'
10.03.2026;Kartenzahlung   NYX*ZweckverbandBergerleb   Berchtesgaden NX429385   Kartennummer: 439556XXXXXX910X;-2,5;;;;'DE28300209003201649568'
10.03.2026;Kartenzahlung   NYX*ZweckverbandBergerleb   Berchtesgaden NX429385   Kartennummer: 439556XXXXXX910X;-1,5;;;;'DE28300209003201649568'
10.03.2026;Kartenzahlung   NYX*ZweckverbandBergerleb   Berchtesgaden NX429385   Kartennummer: 439556XXXXXX910X;-1;;;;'DE28300209003201649568'
11.03.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508241   Kartennummer: 439556XXXXXX910X;-18,21;;;;'DE28300209003201649568'
12.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
12.03.2026;Kartenzahlung   MUeLLER BAD REICHENHALL   Bad Reichenha 69508824   Kartennummer: 439556XXXXXX910X;-42,42;;;;'DE28300209003201649568'
13.03.2026;Kartenzahlung   ALDI SUED   Bad Reichenha 65151038   Kartennummer: 439556XXXXXX910X;-24,75;;;;'DE28300209003201649568'
13.03.2026;Kartenzahlung   Niso Grill   Bad Reichenh R0161024   Kartennummer: 439556XXXXXX910X;-16,59;;;;'DE28300209003201649568'
16.03.2026;Kartenzahlung   Limehome GmbH   Munich   Kartennummer: 439556XXXXXX910X;-240,96;;;;'DE28300209003201649568'
16.03.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-50;;;;'DE28300209003201649568'
16.03.2026;Kartenzahlung   McDonalds 101   Salzburg 23625514   Kartennummer: 439556XXXXXX910X;-24,2;;;;'DE28300209003201649568'
16.03.2026;Kartenzahlung   Aral Station 191399104   Bad Reichenha 71113356   Kartennummer: 439556XXXXXX910X;-14,35;;;;'DE28300209003201649568'
16.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-7,27;;;;'DE28300209003201649568'
16.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613405   Kartennummer: 439556XXXXXX910X;-3,64;;;;'DE28300209003201649568'
16.03.2026;Kartenzahlung   APPLE.COM/BILL   ITUNES.COM   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
16.03.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
17.03.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2603171072088 - Bitte bei Rückfragen angeben.;-200;;;;'DE28300209003201649568'
17.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
17.03.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2603171167021 - Bitte bei Rückfragen angeben.;-50;;;;'DE28300209003201649568'
17.03.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2603171072088 - Bitte bei Rückfragen angeben ;-200,00;;;;'DE28300209003201649568'
17.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
17.03.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2603171167021 - Bitte bei Rückfragen angeben ;-50,00;;;;'DE28300209003201649568'
18.03.2026;Kartenzahlung   Google One   Dublin   Kartennummer: 439556XXXXXX910X;-32,98;;;;'DE28300209003201649568'
20.03.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6108760409, Rg-Nr.: 1509972386/8, Ihre Tarifrechnung   3304708717640001509972386008RCUR   DE9700000000142462   T0010001B000006108760409;-95,05;;;;'DE28300209003201649568'
20.03.2026;Kartenzahlung   YORMA'S MUENCHEN CONTA   MUENCHEN 54012493   Kartennummer: 439556XXXXXX910X;-17,5;;;;'DE28300209003201649568'
20.03.2026;Kartenzahlung   NYX*zoellsdeGmbH   Langenzenn NX432048   Kartennummer: 439556XXXXXX910X;-2,5;;;;'DE28300209003201649568'
20.03.2026;Kartenzahlung   YORMA'S MUENCHEN CONTA   MUENCHEN 54012493   Kartennummer: 439556XXXXXX910X;-17,50;;;;'DE28300209003201649568'
20.03.2026;Kartenzahlung   NYX*zoellsdeGmbH   Langenzenn NX432048   Kartennummer: 439556XXXXXX910X;-2,50;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-14;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-11,4;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-7;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   NEW YORKER RETAIL HANN   HANNOVER 54246162   Kartennummer: 439556XXXXXX910X;-128,89;;;;'DE28300209003201649568'
23.03.2026;Auszahlung Geldautomat   REISEBANK FRANKFURT ATM/HANNOVER   Kartennummer: 439556XXXXXX910X;-50;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Tedi Fil. 6374   Hannover 61751558   Kartennummer: 439556XXXXXX910X;-45;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Lieferando.de lieferservi   Amsterdam   Kartennummer: 439556XXXXXX910X;-39,78;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   LEINE APOTHEKE IM HAUP   HANNOVER 54196011   Kartennummer: 439556XXXXXX910X;-35,94;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239941   Kartennummer: 439556XXXXXX910X;-32,19;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   OEKOEKOST DER BIOFACHM   CELLE 65485397   Kartennummer: 439556XXXXXX910X;-24,17;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   metronom Eisenbahngesells   Uelzen 55727693   Kartennummer: 439556XXXXXX910X;-23,8;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Lieferando.de lieferservi   Amsterdam   Kartennummer: 439556XXXXXX910X;-21,61;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   UESTRA HANNOV. VERKEHR   HANNOVER   Kartennummer: 439556XXXXXX910X;-20,4;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239941   Kartennummer: 439556XXXXXX910X;-20,29;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Lieferando.de lieferservi   Amsterdam   Kartennummer: 439556XXXXXX910X;-17,85;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Niso Grill   Bad Reichenh R0161024   Kartennummer: 439556XXXXXX910X;-17,8;;;;'DE28300209003201649568'
23.03.2026;Entgelt Auszahlung   REISEBANK FRANKFURT ATM;-3,95;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-14,00;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-11,40;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-7,00;;;;'DE28300209003201649568'
23.03.2026;Auszahlung Geldautomat   REISEBANK FRANKFURT ATM/HANNOVER   Kartennummer: 439556XXXXXX910X;-50,00;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Tedi Fil  6374   Hannover 61751558   Kartennummer: 439556XXXXXX910X;-45,00;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   metronom Eisenbahngesells   Uelzen 55727693   Kartennummer: 439556XXXXXX910X;-23,80;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   UESTRA HANNOV  VERKEHR   HANNOVER   Kartennummer: 439556XXXXXX910X;-20,40;;;;'DE28300209003201649568'
23.03.2026;Kartenzahlung   Niso Grill   Bad Reichenh R0161024   Kartennummer: 439556XXXXXX910X;-17,80;;;;'DE28300209003201649568'
24.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-12,83;;;;'DE28300209003201649568'
26.03.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6082661329, Rg-Nr.: 1518014187/8, Ihr Ratenplan   3304714512990001518014187008RCUR   DE9700000000142462   T0010001B000006082661329;-22,5;;;;'DE28300209003201649568'
26.03.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-11,5;;;;'DE28300209003201649568'
26.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
26.03.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6082661329  Rg-Nr : 1518014187/8  Ihr Ratenplan   3304714512990001518014187008RCUR   DE9700000000142462   T0010001B000006082661329;-22,50;;;;'DE28300209003201649568'
26.03.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-11,50;;;;'DE28300209003201649568'
26.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
27.03.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE49700400410225563601   Kd-Nr.: 6096729734, Rg-Nr.: 1519454890/8, Ihr Ratenplan   3204590660570001519454890008RCUR   DE9700000000142462   T0010001B000006096729734;-8;;;;'DE28300209003201649568'
27.03.2026;Echtzeitüberweisung   RIVERTY SERVICES GMBH   DE34662400020115517500   COBADEFFXXX  S.26.0567934.01.3   HBKIN2603272237235 - Bitte bei Rückfragen angeben.;-170,14;;;;'DE28300209003201649568'
27.03.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-31;;;;'DE28300209003201649568'
27.03.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6096729734  Rg-Nr : 1519454890/8  Ihr Ratenplan   3204590660570001519454890008RCUR   DE9700000000142462   T0010001B000006096729734;-8,00;;;;'DE28300209003201649568'
27.03.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-31,00;;;;'DE28300209003201649568'
30.03.2026;Gutschrift   DE34300209005231062411;100;;;;'DE28300209003201649568'
30.03.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-70,21;;;;'DE28300209003201649568'
30.03.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-20;;;;'DE28300209003201649568'
30.03.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-11,65;;;;'DE28300209003201649568'
30.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,9;;;;'DE28300209003201649568'
30.03.2026;Kartenzahlung   RESTAURANT JETON   BAD REICHENHA 64017943   Kartennummer: 439556XXXXXX910X;-4,1;;;;'DE28300209003201649568'
30.03.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
30.03.2026;Umbuchung   DE28300209003201649568   Am 30.03.2026 um 00:08;-100;;;;'DE34300209005231062411'
30.03.2026;Gutschrift   DE34300209005231062411;;100,00;;;'DE28300209003201649568'
30.03.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-20,00;;;;'DE28300209003201649568'
30.03.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
30.03.2026;Kartenzahlung   RESTAURANT JETON   BAD REICHENHA 64017943   Kartennummer: 439556XXXXXX910X;-4,10;;;;'DE28300209003201649568'
31.03.2026;Gutschrift Lohn, Gehalt, Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 04-2026 03142616-2026-06013003-041445   03142616-2026-06013003-041445;2443,66;;;;'DE28300209003201649568'
31.03.2026;Information Zinssätze   SOLLZINSSÄTZE: FÜR VEREINBARTE DISPOSITIONSKREDITE BIS 50,00 EUR: 0.00 % P.A. UEBER 50,00 EUR: 13.73 % P.A. (FÜR DIE GESAMTE INANSPRUCHNAHME) SOLLZINSSATZ FÜR GEDULDETE ÜBERZIEHUNG: 16.73 % P.A.;0;;;;'DE28300209003201649568'
31.03.2026;Gutschrift Lohn  Gehalt  Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 04-2026 03142616-2026-06013003-041445   03142616-2026-06013003-041445;;2443,66;;;'DE28300209003201649568'
31.03.2026;Information Zinssätze   SOLLZINSSÄTZE: FÜR VEREINBARTE DISPOSITIONSKREDITE BIS 50 00 EUR: 0 00 % P A  UEBER 50 00 EUR: 13 73 % P A  (FÜR DIE GESAMTE INANSPRUCHNAHME) SOLLZINSSATZ FÜR GEDULDETE ÜBERZIEHUNG: 16 73 % P A ;;0,00;;;'DE28300209003201649568'
01.04.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000;;;;'DE28300209003201649568'
01.04.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01.04;-274,7;;;;'DE28300209003201649568'
01.04.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1049287905499/PP.4081.PP/., Ihr Einkauf bei   1049287905499   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,4;;;;'DE28300209003201649568'
01.04.2026;Kartenzahlung   Aral Tankstelle 19073800   Bad Reichenha 71112919   Kartennummer: 439556XXXXXX910X;-32,2;;;;'DE28300209003201649568'
01.04.2026;Kartenzahlung   Lieferando.de lieferservi   Amsterdam   Kartennummer: 439556XXXXXX910X;-29,59;;;;'DE28300209003201649568'
01.04.2026;Gutschrift   DE28300209003201649568   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;1000;;;;'DE10300209005211062413'
01.04.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000,00;;;;'DE28300209003201649568'
01.04.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01 04;-274,70;;;;'DE28300209003201649568'
01.04.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1049287905499/PP 4081 PP/   Ihr Einkauf bei   1049287905499   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,40;;;;'DE28300209003201649568'
01.04.2026;Kartenzahlung   Aral Tankstelle 19073800   Bad Reichenha 71112919   Kartennummer: 439556XXXXXX910X;-32,20;;;;'DE28300209003201649568'
02.04.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1049306797645/PP.4081.PP/. Netflix.com, Ihr Einkauf bei Netflix.com   1049306797645   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-14,88;;;;'DE28300209003201649568'
07.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34;;;;'DE28300209003201649568'
07.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-31;;;;'DE28300209003201649568'
07.04.2026;Kartenzahlung   Lieferando.de lieferservi   Amsterdam   Kartennummer: 439556XXXXXX910X;-29,59;;;;'DE28300209003201649568'
07.04.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-29,46;;;;'DE28300209003201649568'
07.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34,00;;;;'DE28300209003201649568'
07.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-31,00;;;;'DE28300209003201649568'
08.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34;;;;'DE28300209003201649568'
08.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34,00;;;;'DE28300209003201649568'
09.04.2026;Gutschrift   DE44300209005221062404;397,15;;;;'DE10300209005211062413'
09.04.2026;Gutschrift   DE44300209005221062404;3912,63;;;;'DE10300209005211062413'
09.04.2026;Umbuchung   DE52300209005291062407   Am 09.04.2026 um 17:08;-6000;;;;'DE10300209005211062413'
09.04.2026;Umbuchung   DE10300209005211062413   Am 09.04.2026 um 17:07;-397,15;;;;'DE44300209005221062404'
09.04.2026;Umbuchung   DE10300209005211062413   Am 09.04.2026 um 17:08;-3912,63;;;;'DE44300209005221062404'
09.04.2026;Gutschrift   DE10300209005211062413;6000;;;;'DE52300209005291062407'
10.04.2026;Echtzeitüberweisung   RIVERTY SERVICES GMBH   DE34662400020115517500   COBADEFFXXX  S.25.4113674.01.4   HBKIN2604094236850 - Bitte bei Rückfragen angeben.;-482,54;;;;'DE28300209003201649568'
10.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34;;;;'DE28300209003201649568'
10.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613406   Kartennummer: 439556XXXXXX910X;-14,68;;;;'DE28300209003201649568'
10.04.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34,00;;;;'DE28300209003201649568'
13.04.2026;Echtzeitüberweisung   METRONOM EISENBAHNGESELLSCHAFT MBH   DE26662400020115512600   COBADEFFXXX  1611426100161   HBKIN2604124503055 - Bitte bei Rückfragen angeben.;-60;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508239   Kartennummer: 439556XXXXXX910X;-78,5;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   BURGER KING 12425 SOT   PIDING 58049720   Kartennummer: 439556XXXXXX910X;-37,32;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-15,09;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   Mr Wen   Salzburg AH137767   Kartennummer: 439556XXXXXX910X;-13,9;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-11,8;;;;'DE28300209003201649568'
13.04.2026;Echtzeitüberweisung   METRONOM EISENBAHNGESELLSCHAFT MBH   DE26662400020115512600   COBADEFFXXX  1611426100161   HBKIN2604124503055 - Bitte bei Rückfragen angeben ;-60,00;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508239   Kartennummer: 439556XXXXXX910X;-78,50;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   Mr Wen   Salzburg AH137767   Kartennummer: 439556XXXXXX910X;-13,90;;;;'DE28300209003201649568'
13.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-11,80;;;;'DE28300209003201649568'
14.04.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  GROCERY   HBKIN2604144740860 - Bitte bei Rückfragen angeben.;-10;;;;'DE28300209003201649568'
14.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613405   Kartennummer: 439556XXXXXX910X;-25,87;;;;'DE28300209003201649568'
14.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613408   Kartennummer: 439556XXXXXX910X;-1,98;;;;'DE28300209003201649568'
14.04.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  GROCERY   HBKIN2604144740860 - Bitte bei Rückfragen angeben ;-10,00;;;;'DE28300209003201649568'
15.04.2026;Kartenzahlung   APPLE.COM/BILL   ITUNES.COM   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
15.04.2026;Kartenzahlung   APPLE COM/BILL   ITUNES COM   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
16.04.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-16,2;;;;'DE28300209003201649568'
16.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-11,8;;;;'DE28300209003201649568'
16.04.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-16,20;;;;'DE28300209003201649568'
16.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-11,80;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   SumUp *Danilo_s Burger   Bischofswiese MX01KPQ6   Kartennummer: 439556XXXXXX910X;-43,34;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Kramerei Lofer   Lofer AH152341   Kartennummer: 439556XXXXXX910X;-38,5;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Eat&Drink   St Martin be 23711061   Kartennummer: 439556XXXXXX910X;-23,1;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2218   Lofer 23613353   Kartennummer: 439556XXXXXX910X;-21,22;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   SHELL LOFER 4287   LOFER 08428711   Kartennummer: 439556XXXXXX910X;-20,7;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   McDonalds 101   Salzburg 23625513   Kartennummer: 439556XXXXXX910X;-19,9;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613407   Kartennummer: 439556XXXXXX910X;-12,3;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-11,8;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-10,7;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613407   Kartennummer: 439556XXXXXX910X;-6,69;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2218   Lofer 23613352   Kartennummer: 439556XXXXXX910X;-4,4;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Kramerei Lofer   Lofer AH152341   Kartennummer: 439556XXXXXX910X;-38,50;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Eat-Drink   St Martin be 23711061   Kartennummer: 439556XXXXXX910X;-23,10;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   SHELL LOFER 4287   LOFER 08428711   Kartennummer: 439556XXXXXX910X;-20,70;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   McDonalds 101   Salzburg 23625513   Kartennummer: 439556XXXXXX910X;-19,90;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613407   Kartennummer: 439556XXXXXX910X;-12,30;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-11,80;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-10,70;;;;'DE28300209003201649568'
20.04.2026;Kartenzahlung   Spar Dankt 2218   Lofer 23613352   Kartennummer: 439556XXXXXX910X;-4,40;;;;'DE28300209003201649568'
21.04.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1049675381115/PP.4081.PP/. Google Payment Ireland Limited, Ihr Einkauf bei Google Payment Ireland Limited   1049675381115   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-32,98;;;;'DE28300209003201649568'
22.04.2026;Gutschrift   DE10300209005211062413;200;;;;'DE28300209003201649568'
22.04.2026;Umbuchung   DE28300209003201649568   Am 22.04.2026 um 17:07;-200;;;;'DE10300209005211062413'
22.04.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
23.04.2026;Lastschrift   Telefonica Germany GmbH + Co. OHG   DE16700202700005713153   Kd-Nr.: 6108760409, Rg-Nr.: 1535803057/8, Ihre Tarifrechnung   3304732231590001535803057008RCUR   DE9700000000142462   T0010001B000006108760409;-94,96;;;;'DE28300209003201649568'
23.04.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1049779118366/PP.4081.PP/., Ihr Einkauf bei   1049779118366   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-10;;;;'DE28300209003201649568'
23.04.2026;Kartenzahlung   Spar Dankt 2386   Salzburg 23613566   Kartennummer: 439556XXXXXX910X;-38,01;;;;'DE28300209003201649568'
23.04.2026;Lastschrift   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1049763239795/PP.4081.PP/., Ihr Einkauf bei   1049763239795   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-22;;;;'DE28300209003201649568'
23.04.2026;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S.a.r.l. et Cie S.C.A   LU89751000135104200E   1049763239795/PP.4081.PP/., Ihr Einkauf bei   049763239795   LU96ZZZ0000000000000000058   55C22253VQ6AQ;22;;;;'DE28300209003201649568'
23.04.2026;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
23.04.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1049779118366/PP 4081 PP/   Ihr Einkauf bei   1049779118366   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-10,00;;;;'DE28300209003201649568'
23.04.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1049763239795/PP 4081 PP/   Ihr Einkauf bei   1049763239795   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-22,00;;;;'DE28300209003201649568'
23.04.2026;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1049763239795/PP 4081 PP/   Ihr Einkauf bei   049763239795   LU96ZZZ0000000000000000058   55C22253VQ6AQ;;22,00;;;'DE28300209003201649568'
24.04.2026;Gutschrift   DE10300209005211062413;200;;;;'DE28300209003201649568'
24.04.2026;Gutschrift   DE10300209005211062413;100;;;;'DE28300209003201649568'
24.04.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  HAPPY BIRTHDAYYY   HBKIN2604245982691 - Bitte bei Rückfragen angeben.;-100;;;;'DE28300209003201649568'
24.04.2026;Kartenzahlung   APPLE.COM/BILL   ITUNES.COM   Kartennummer: 439556XXXXXX910X;-39,99;;;;'DE28300209003201649568'
24.04.2026;Umbuchung   DE28300209003201649568   Am 24.04.2026 um 02:57;-200;;;;'DE10300209005211062413'
24.04.2026;Umbuchung   DE28300209003201649568   Am 24.04.2026 um 02:57;-100;;;;'DE10300209005211062413'
24.04.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
24.04.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  HAPPY BIRTHDAYYY   HBKIN2604245982691 - Bitte bei Rückfragen angeben ;-100,00;;;;'DE28300209003201649568'
24.04.2026;Kartenzahlung   APPLE COM/BILL   ITUNES COM   Kartennummer: 439556XXXXXX910X;-39,99;;;;'DE28300209003201649568'
27.04.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  BIRTHDAY   HBKIN2604246090485 - Bitte bei Rückfragen angeben ;-75,00;;;;'DE28300209003201649568'
27.04.2026;Gutschrift   DE10300209005211062413;;120,00;;;'DE28300209003201649568'
27.04.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE16700202700005713153   Kd-Nr : 6082661329  Rg-Nr : 1544008981/8  Ihr Ratenplan   3304738277420001544008981008RCUR   DE9700000000142462   T0010001B000006082661329;-22,50;;;;'DE28300209003201649568'
27.04.2026;Kartenzahlung   Aral Station 191399104   Bad Reichenha 71113356   Kartennummer: 439556XXXXXX910X;-9,75;;;;'DE28300209003201649568'
27.04.2026;Kartenzahlung   PAYPAL *OEBB PV AG OEBB T   35314369001   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
27.04.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC REICHE   Kartennummer: 439556XXXXXX910X;-100,00;;;;'DE28300209003201649568'
27.04.2026;Kartenzahlung   EDEKA MICHAEL DORRER   BAD REICHENHA 54508239   Kartennummer: 439556XXXXXX910X;-68,62;;;;'DE28300209003201649568'
27.04.2026;Kartentransaktion   PAYPAL **  Ihr Einkauf b   Visa Direct // CNP TX   Kartennummer: 439556XXXXXX910X;-22,00;;;;'DE28300209003201649568'
27.04.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
28.04.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013315   Kartennummer: 439556XXXXXX910X;-25,49;;;;'DE28300209003201649568'
29.04.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE16700202700005713153   Kd-Nr : 6096729734  Rg-Nr : 1545444332/8  Ihr Ratenplan   3204613191100001545444332008RCUR   DE9700000000142462   T0010001B000006096729734;-8,00;;;;'DE28300209003201649568'
29.04.2026;Gutschrift Echtzeitüberweisung   Sebastien Nkembi Njingo   Bill;;108,00;;;'DE28300209003201649568'
30.04.2026;Gutschrift Lohn  Gehalt  Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 05-2026 03142616-2026-06012904-041478   03142616-2026-06012904-041478;;1781,78;;;'DE28300209003201649568'
04.05.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000,00;;;;'DE28300209003201649568'
04.05.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01 05;-274,70;;;;'DE28300209003201649568'
05.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1049976004279/PP 4081 PP/  Netflix com  Ihr Einkauf bei Netflix com   1049976004279   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-14,44;;;;'DE28300209003201649568'
08.05.2026;Kartenzahlung   APPLE COM/BILL   ITUNES COM   Kartennummer: 439556XXXXXX910X;-39,99;;;;'DE28300209003201649568'
08.05.2026;Kartenzahlung   Koeschinger Forst West VG   Hepberg 55802725   Kartennummer: 439556XXXXXX910X;-1,00;;;;'DE28300209003201649568'
11.05.2026;Auszahlung Geldautomat   VB RB OBERBAYERN SUEDO/REICHENHAL   Kartennummer: 439556XXXXXX910X;-100,00;;;;'DE28300209003201649568'
11.05.2026;Auszahlung Geldautomat   51049 Griesgasse/Salzburg   Kartennummer: 439556XXXXXX910X;-74,95;;;;'DE28300209003201649568'
11.05.2026;Kartenzahlung   CIIIB City Beats   Salzburg U3568972   Kartennummer: 439556XXXXXX910X;-21,10;;;;'DE28300209003201649568'
11.05.2026;Kartenzahlung   CIIIB City Beats   Salzburg U3566124   Kartennummer: 439556XXXXXX910X;-20,80;;;;'DE28300209003201649568'
11.05.2026;Kartenzahlung   OEBB 536000000266185793   Wien   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
11.05.2026;Kartenzahlung   Agip Service-Station   Hepberg 00000000   Kartennummer: 439556XXXXXX910X;-4,99;;;;'DE28300209003201649568'
11.05.2026;Entgelt Auszahlung   VB RB OBERBAYERN SUEDO;-3,95;;;;'DE28300209003201649568'
11.05.2026;Entgelt Auszahlung   51049 Griesgasse;-3,95;;;;'DE28300209003201649568'
12.05.2026;Gutschrift   DE10300209005211062413;;400,00;;;'DE28300209003201649568'
12.05.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2605118582695 - Bitte bei Rückfragen angeben ;-400,00;;;;'DE28300209003201649568'
12.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050215577727/PP 4081 PP/   Ihr Einkauf bei   1050215577727   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,00;;;;'DE28300209003201649568'
14.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050249189045/PP 4081 PP/   Ihr Einkauf bei   1050249189045   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-36,00;;;;'DE28300209003201649568'
14.05.2026;Kartenzahlung   Aktiv Optik GmbH   Bad Reichenha 55766121   Kartennummer: 439556XXXXXX910X;-147,70;;;;'DE28300209003201649568'
14.05.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-33,43;;;;'DE28300209003201649568'
15.05.2026;Kartenzahlung   APPLE COM/BILL   08006645451   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
15.05.2026;Kartenzahlung   MUeLLER BAD REICHENHALL   Bad Reichenha 69508823   Kartennummer: 439556XXXXXX910X;-18,50;;;;'DE28300209003201649568'
18.05.2026;Gutschrift   DE10300209005211062413;;80,00;;;'DE28300209003201649568'
18.05.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2605169220818 - Bitte bei Rückfragen angeben ;-80,00;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-30,02;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   BURGER KING 12425 SOT   PIDING 58049721   Kartennummer: 439556XXXXXX910X;-22,93;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   McDonalds 173   Wals 23610093   Kartennummer: 439556XXXXXX910X;-22,30;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   Aral Tankstelle 19073800   Bad Reichenha 71112919   Kartennummer: 439556XXXXXX910X;-15,66;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613408   Kartennummer: 439556XXXXXX910X;-12,73;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613407   Kartennummer: 439556XXXXXX910X;-5,80;;;;'DE28300209003201649568'
18.05.2026;Kartenzahlung   TNT 365   Salzburg 32503142   Kartennummer: 439556XXXXXX910X;-4,00;;;;'DE28300209003201649568'
18.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050306490331/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1050306490331   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-39,99;;;;'DE28300209003201649568'
18.05.2026;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050306490331/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   050306490331   LU96ZZZ0000000000000000058   55C22253VQ6AQ;;39,99;;;'DE28300209003201649568'
18.05.2026;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
19.05.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613405   Kartennummer: 439556XXXXXX910X;-11,46;;;;'DE28300209003201649568'
19.05.2026;Kartenzahlung   OEBB 536000000267925947   Wien   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
19.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050356672609/PP 4081 PP/  Google Payment Ireland Ltd   Ihr Einkauf bei Google Payment Ireland Ltd    1050356672609   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-32,98;;;;'DE28300209003201649568'
19.05.2026;Rückgabe Lastschrift Fehlende Deckung   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050356672609/PP 4081 PP/  Google Payment Ireland Ltd   Ihr Einkauf bei Google Payment Ireland Ltd    050356672609   LU96ZZZ0000000000000000058   55C22253VQ6AQ;;32,98;;;'DE28300209003201649568'
19.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050338445635/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1050338445635   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-24,50;;;;'DE28300209003201649568'
19.05.2026;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
21.05.2026;Gutschrift   DE10300209005211062413;;100,00;;;'DE28300209003201649568'
21.05.2026;Kartenzahlung   OEBB 536000000268200297   Wien   Kartennummer: 439556XXXXXX910X;-5,90;;;;'DE28300209003201649568'
22.05.2026;Kartenzahlung   SumUp *Taxi Schwarzenlan   Traunstein MEFAL6E7   Kartennummer: 439556XXXXXX910X;-92,80;;;;'DE28300209003201649568'
22.05.2026;Auszahlung Geldautomat   VB RB OBERBAYERN SUEDO/SIEGSDORF   Kartennummer: 439556XXXXXX910X;-50,00;;;;'DE28300209003201649568'
22.05.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-9,07;;;;'DE28300209003201649568'
22.05.2026;Kartenzahlung   Pizzeria La Pala   Siegsdorf AH353491   Kartennummer: 439556XXXXXX910X;-9,00;;;;'DE28300209003201649568'
22.05.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6108760409  Rg-Nr : 1561896039/8  Ihre Tarifrechnung   3304756164950001561896039008RCUR   DE9700000000142462   T0010001B000006108760409;-94,96;;;;'DE28300209003201649568'
22.05.2026;Rückgabe Lastschrift Fehlende Deckung   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6108760409  Rg-Nr : 1561896039/8  Ihre Tarifrechnung   304756164950001561896039008RCUR   DE9700000000142462   T0010001B000006108760409;;94,96;;;'DE28300209003201649568'
22.05.2026;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
22.05.2026;Entgelt Auszahlung   VB RB OBERBAYERN SUEDO;-3,95;;;;'DE28300209003201649568'
25.05.2026;Gutschrift   DE10300209005211062413;;100,00;;;'DE28300209003201649568'
25.05.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050457738473/   Ihr Einkauf bei   1050457738473   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-41,94;;;;'DE28300209003201649568'
25.05.2026;Kartenzahlung   REWE Bolte oHG   Langenhagen 56019846   Kartennummer: 439556XXXXXX910X;-26,58;;;;'DE28300209003201649568'
25.05.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-11,07;;;;'DE28300209003201649568'
25.05.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
25.05.2026;Lastschrift   PayPal (Europe) S a r l  et Cie  S C A    DE88500700100175526303   1050447290545 ADD TO BALANCE   1050447290545 PAYPAL   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-100,00;;;;'DE28300209003201649568'
26.05.2026;Kartenzahlung   LEINE APOTHEKE IM HAUP   HANNOVER 54196011   Kartennummer: 439556XXXXXX910X;-36,97;;;;'DE28300209003201649568'
26.05.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239944   Kartennummer: 439556XXXXXX910X;-27,59;;;;'DE28300209003201649568'
26.05.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239950   Kartennummer: 439556XXXXXX910X;-26,09;;;;'DE28300209003201649568'
26.05.2026;Kartenzahlung   Rossmann 2800   Hannover 60356518   Kartennummer: 439556XXXXXX910X;-18,15;;;;'DE28300209003201649568'
26.05.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
26.05.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6082661329  Rg-Nr : 1569869933/8  Ihr Ratenplan   3304762074880001569869933008RCUR   DE9700000000142462   T0010001B000006082661329;-22,50;;;;'DE28300209003201649568'
26.05.2026;Rückgabe Lastschrift Fehlende Deckung   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6082661329  Rg-Nr : 1569869933/8  Ihr Ratenplan   304762074880001569869933008RCUR   DE9700000000142462   T0010001B000006082661329;;22,50;;;'DE28300209003201649568'
26.05.2026;Entgelt Ablehnung Lastschrift;-1,88;;;;'DE28300209003201649568'
27.05.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
27.05.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-34,00;;;;'DE28300209003201649568'
28.05.2026;Kartenzahlung   AMAZON* NQ7GT7394   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-21,77;;;;'DE28300209003201649568'
28.05.2026;Kartenzahlung   DTV BUCH GANTER 3 MOVE   Freilassing 69714386   Kartennummer: 439556XXXXXX910X;-5,40;;;;'DE28300209003201649568'
29.05.2026;Gutschrift Lohn  Gehalt  Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 06-2026 03142616-2026-06012805-041360   03142616-2026-06012805-041360;;1842,94;;;'DE28300209003201649568'
01.06.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
01.06.2026;Gutschrift Echtzeitüberweisung   Sebastien Nkembi Njingo   Bill;;100,00;;;'DE28300209003201649568'
01.06.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000,00;;;;'DE28300209003201649568'
01.06.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01 06;-274,70;;;;'DE28300209003201649568'
01.06.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE16700202700005713153   Kd-Nr : 6096729734  Rg-Nr : 1571703679/8  Ihr Ratenplan   3204635620860001571703679008RCUR   DE9700000000142462   T0010001B000006096729734;-8,00;;;;'DE28300209003201649568'
01.06.2026;Kartenzahlung   CIIIB City Beats   Salzburg U3566118   Kartennummer: 439556XXXXXX910X;-23,21;;;;'DE28300209003201649568'
01.06.2026;Kartenzahlung   Spar Dankt 2272   Salzburg 23613403   Kartennummer: 439556XXXXXX910X;-16,31;;;;'DE28300209003201649568'
01.06.2026;Kartenzahlung   CIIIB City Beats   Salzburg U3566200   Kartennummer: 439556XXXXXX910X;-15,00;;;;'DE28300209003201649568'
01.06.2026;Kartenzahlung   Mr Wen   Salzburg AH137767   Kartennummer: 439556XXXXXX910X;-13,90;;;;'DE28300209003201649568'
01.06.2026;Kartenzahlung   DRB   Salzburg 23707550   Kartennummer: 439556XXXXXX910X;-11,80;;;;'DE28300209003201649568'
02.06.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AUNTY   HBKIN2606021580872 - Bitte bei Rückfragen angeben ;-20,00;;;;'DE28300209003201649568'
02.06.2026;Kartenzahlung   Hotel at Booking com   Amsterdam   Kartennummer: 439556XXXXXX910X;-350,09;;;;'DE28300209003201649568'
02.06.2026;Kartenzahlung   Aral Station 191399104   Bad Reichenha 71113356   Kartennummer: 439556XXXXXX910X;-13,55;;;;'DE28300209003201649568'
02.06.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-9,16;;;;'DE28300209003201649568'
03.06.2026;Gutschrift   DE10300209005211062413;;300,00;;;'DE28300209003201649568'
03.06.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
04.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050732567370/PP 4081 PP/   Ihr Einkauf bei   1050732567370   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,00;;;;'DE28300209003201649568'
04.06.2026;Gutschrift   DE10300209005211062413;;800,00;;;'DE28300209003201649568'
04.06.2026;Kartenzahlung   AMAZON* N30UA3PX4   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-34,98;;;;'DE28300209003201649568'
05.06.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  SWIMMING   HBKIN2606052023318 - Bitte bei Rückfragen angeben ;-30,00;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   AMAZON* N34BX28K4   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-466,90;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   AMAZON* N322X0B04   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-125,99;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   SPC*Yakamoz Restaurant   Isernhagen 68430815   Kartennummer: 439556XXXXXX910X;-112,50;;;;'DE28300209003201649568'
05.06.2026;Auszahlung Geldautomat   REISEBANK FRANKFURT ATM/HANNOVER   Kartennummer: 439556XXXXXX910X;-100,00;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   SPC*Ressos   Hannover 69631308   Kartennummer: 439556XXXXXX910X;-51,00;;;;'DE28300209003201649568'
05.06.2026;Auszahlung Geldautomat   REISEBANK FRANKFURT ATM/HANNOVER   Kartennummer: 439556XXXXXX910X;-50,00;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   SumUp *Taxi6015   Garbsen MDPZMCTN   Kartennummer: 439556XXXXXX910X;-42,00;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54221397   Kartennummer: 439556XXXXXX910X;-28,39;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   Simbarashe Mawere   Hannover 99999999   Kartennummer: 439556XXXXXX910X;-20,00;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   BLUMEN WOLF   HANNOVER DC900512   Kartennummer: 439556XXXXXX910X;-16,00;;;;'DE28300209003201649568'
05.06.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-14,00;;;;'DE28300209003201649568'
05.06.2026;Entgelt Auszahlung   REISEBANK FRANKFURT ATM;-3,95;;;;'DE28300209003201649568'
08.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050760313557/PP 4081 PP/  Pham Hoang Thi  Ihr Einkauf bei Pham Hoang Thi   1050760313557   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-26,28;;;;'DE28300209003201649568'
08.06.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2606082274979 - Bitte bei Rückfragen angeben ;-20,00;;;;'DE28300209003201649568'
08.06.2026;Gutschrift Karteneinsatz   AMAZON* N34BX28K4   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;;2,64;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   Rossmann 1670   Hannover 60399470   Kartennummer: 439556XXXXXX910X;-2,69;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   Wasserwelt Langenhagen   Langenhagen 60386748   Kartennummer: 439556XXXXXX910X;-32,91;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239941   Kartennummer: 439556XXXXXX910X;-32,76;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   EDEKA ASLAN   HANNOVER 58021681   Kartennummer: 439556XXXXXX910X;-22,14;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-14,00;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   BAECKEREI RAUTE GMBH -   GARBSEN 69042371   Kartennummer: 439556XXXXXX910X;-13,97;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   Wasserwelt Langenhagen   Langenhagen 60386748   Kartennummer: 439556XXXXXX910X;-12,00;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   Lidl sagt Danke   Hannover 60198542   Kartennummer: 439556XXXXXX910X;-8,94;;;;'DE28300209003201649568'
08.06.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
08.06.2026;Gutschrift   DE10300209005211062413;;300,00;;;'DE28300209003201649568'
09.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050792041833/PP 4081 PP/  Takeaway com Payments B V   Ihr Einkauf bei Takeaway com Payments B V    1050792041833   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-38,39;;;;'DE28300209003201649568'
09.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050791552299/PP 4081 PP/  Takeaway com Payments B V   Ihr Einkauf bei Takeaway com Payments B V    1050791552299   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-27,39;;;;'DE28300209003201649568'
09.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050837737272/PP 4081 PP/  Takeaway com Payments B V   Ihr Einkauf bei Takeaway com Payments B V    1050837737272   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-20,82;;;;'DE28300209003201649568'
09.06.2026;Kartenzahlung   FAHRDIENST MM   MINDELHEIM 80452174   Kartennummer: 439556XXXXXX910X;-260,00;;;;'DE28300209003201649568'
09.06.2026;Kartenzahlung   REWE 305 (950) Son   Sonthofen 56058234   Kartennummer: 439556XXXXXX910X;-38,01;;;;'DE28300209003201649568'
11.06.2026;Kartenzahlung   REWE 305 (950) Son   Sonthofen 56058232   Kartennummer: 439556XXXXXX910X;-18,61;;;;'DE28300209003201649568'
12.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-2,25;;;;'DE28300209003201649568'
12.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-0,90;;;;'DE28300209003201649568'
15.06.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  FOOD   HBKIN2606153214878 - Bitte bei Rückfragen angeben ;-15,00;;;;'DE28300209003201649568'
15.06.2026;Kartenzahlung   APPLE COM/BILL   08006645451   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
16.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050949725180/PP 4081 PP/  Takeaway com Payments B V   Ihr Einkauf bei Takeaway com Payments B V    1050949725180   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-24,99;;;;'DE28300209003201649568'
16.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050974266126/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1050974266126   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-19,83;;;;'DE28300209003201649568'
16.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1050949651664/PP 4081 PP/  Takeaway com Payments B V   Ihr Einkauf bei Takeaway com Payments B V    1050949651664   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-17,69;;;;'DE28300209003201649568'
16.06.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   3060988548   Kartennummer: 439556XXXXXX910X;-33,79;;;;'DE28300209003201649568'
16.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,50;;;;'DE28300209003201649568'
16.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,20;;;;'DE28300209003201649568'
17.06.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-33,79;;;;'DE28300209003201649568'
17.06.2026;Kartenzahlung   MCDONALDS 00454   SONTHOFEN 54239117   Kartennummer: 439556XXXXXX910X;-33,48;;;;'DE28300209003201649568'
17.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,50;;;;'DE28300209003201649568'
17.06.2026;Gutschrift   DE10300209005211062413;;400,00;;;'DE28300209003201649568'
18.06.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2606183666040 - Bitte bei Rückfragen angeben ;-10,00;;;;'DE28300209003201649568'
18.06.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-33,79;;;;'DE28300209003201649568'
18.06.2026;Kartenzahlung   MCDONALDS 00454   SONTHOFEN 54239117   Kartennummer: 439556XXXXXX910X;-30,29;;;;'DE28300209003201649568'
18.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,50;;;;'DE28300209003201649568'
18.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,20;;;;'DE28300209003201649568'
19.06.2026;Lastschrift   PayPal (Europe) S a r l  et Cie  S C A    DE88500700100175526303   1051058263742 PP 4081 PP   Google Payment Ireland Limited  Ihr Einkauf bei Google Payment Ireland Limited   1051058263742 PP 4081 PP PAYPAL   LU96ZZZ0000000000000000058   55C22253VQ 6AQ;-32,98;;;;'DE28300209003201649568'
19.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,50;;;;'DE28300209003201649568'
19.06.2026;Kartenzahlung   INTCoffee friends   Betzigau IN025291   Kartennummer: 439556XXXXXX910X;-1,00;;;;'DE28300209003201649568'
22.06.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  AMAZON   HBKIN2606213955646 - Bitte bei Rückfragen angeben ;-30,00;;;;'DE28300209003201649568'
22.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051088275171/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1051088275171   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-5,99;;;;'DE28300209003201649568'
22.06.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-49,69;;;;'DE28300209003201649568'
22.06.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-17,32;;;;'DE28300209003201649568'
22.06.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
26.06.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE16700202700005713153   Kd-Nr : 6082661329  Rg-Nr : 1596143566/8  Ihr Ratenplan   3304785767350001596143566008RCUR   DE9700000000142462   T0010001B000006082661329;-50,20;;;;'DE28300209003201649568'
26.06.2026;Kartenzahlung   Niso Grill   Bad Reichenh R0161024   Kartennummer: 439556XXXXXX910X;-10,40;;;;'DE28300209003201649568'
26.06.2026;Kartenzahlung   Niso Grill   Bad Reichenh R0161024   Kartennummer: 439556XXXXXX910X;-7,90;;;;'DE28300209003201649568'
26.06.2026;Kartenzahlung   EDEKA BAD REICHENH   BAD REICHENHA 54520685   Kartennummer: 439556XXXXXX910X;-7,07;;;;'DE28300209003201649568'
29.06.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE16700202700005713153   Kd-Nr : 6096729734  Rg-Nr : 1597958135/8  Ihr Ratenplan   3204658090280001597958135008RCUR   DE9700000000142462   T0010001B000006096729734;-8,00;;;;'DE28300209003201649568'
29.06.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013314   Kartennummer: 439556XXXXXX910X;-17,65;;;;'DE28300209003201649568'
30.06.2026;Gutschrift Lohn  Gehalt  Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 07-2026 03142616-2026-06012906-040970   03142616-2026-06012906-040970;;1804,46;;;'DE28300209003201649568'
30.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051280757662/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1051280757662   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-18,13;;;;'DE28300209003201649568'
30.06.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051319844948/PP 4081 PP/   Ihr Einkauf bei   1051319844948   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,40;;;;'DE28300209003201649568'
30.06.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-42,94;;;;'DE28300209003201649568'
30.06.2026;Information Zinssätze   SOLLZINSSÄTZE: FÜR VEREINBARTE DISPOSITIONSKREDITE BIS 50 00 EUR: 0 00 % P A  UEBER 50 00 EUR: 13 73 % P A  (FÜR DIE GESAMTE INANSPRUCHNAHME) SOLLZINSSATZ FÜR GEDULDETE ÜBERZIEHUNG: 16 73 % P A ;;0,00;;;'DE28300209003201649568'
01.07.2026;Gutschrift Echtzeitüberweisung   Sebastien Nkembi Njingo   Bill;;100,00;;;'DE28300209003201649568'
01.07.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000,00;;;;'DE28300209003201649568'
01.07.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01 07;-274,70;;;;'DE28300209003201649568'
02.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051364484562/PP 4081 PP/  Netflix com  Ihr Einkauf bei Netflix com   1051364484562   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-19,99;;;;'DE28300209003201649568'
06.07.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  LIBERIA   HBKIN2607046067835 - Bitte bei Rückfragen angeben ;-100,00;;;;'DE28300209003201649568'
06.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051409700235/PP 4081 PP/   Ihr Einkauf bei   1051409700235   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-10,00;;;;'DE28300209003201649568'
06.07.2026;Kartenzahlung   Google CLOUD 6TBF9T   Dublin   Kartennummer: 439556XXXXXX910X;-25,00;;;;'DE28300209003201649568'
06.07.2026;Kartenzahlung   NYA*B 306 - Originals   4921619162019 20407910   Kartennummer: 439556XXXXXX910X;-21,00;;;;'DE28300209003201649568'
07.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051460804770/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1051460804770   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-14,99;;;;'DE28300209003201649568'
07.07.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-54,91;;;;'DE28300209003201649568'
08.07.2026;Kartenzahlung   AMAZON* QG2895I75   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-193,64;;;;'DE28300209003201649568'
09.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051531281139/PP 4081 PP/   Ihr Einkauf bei   1051531281139   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-3,00;;;;'DE28300209003201649568'
09.07.2026;Kartenzahlung   AMAZON* W71YX5SC5   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-52,00;;;;'DE28300209003201649568'
09.07.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-15,70;;;;'DE28300209003201649568'
10.07.2026;Kartenzahlung   Niso Grill   Bad Reichenh R0161024   Kartennummer: 439556XXXXXX910X;-17,80;;;;'DE28300209003201649568'
10.07.2026;Kartenzahlung   Der Baecker Schuhbeck   Ruhpolding 61762458   Kartennummer: 439556XXXXXX910X;-8,25;;;;'DE28300209003201649568'
10.07.2026;Kartenzahlung   Der Baecker Schuhbeck   Ruhpolding 61762458   Kartennummer: 439556XXXXXX910X;-2,45;;;;'DE28300209003201649568'
13.07.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
13.07.2026;Echtzeitüberweisung   TELEFONICA GERMANY GMBH   DE16700202700005713153   HYVEDEMMXXX  6108760409   HBKIN2607137092345 - Bitte bei Rückfragen angeben ;-195,12;;;;'DE28300209003201649568'
13.07.2026;Kartenzahlung   Limehome GmbH   Munich   Kartennummer: 439556XXXXXX910X;-68,03;;;;'DE28300209003201649568'
13.07.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54206072   Kartennummer: 439556XXXXXX910X;-28,69;;;;'DE28300209003201649568'
13.07.2026;Kartenzahlung   SARAY GMBH   HANNOVER 54256896   Kartennummer: 439556XXXXXX910X;-11,07;;;;'DE28300209003201649568'
13.07.2026;Kartenzahlung   DB Vertrieb GmbH   Berlin   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
13.07.2026;Kartenzahlung   BRONCOS   HANNOVER 86888537   Kartennummer: 439556XXXXXX910X;-5,00;;;;'DE28300209003201649568'
13.07.2026;Kartenzahlung   NYA*SnackKing Freilass   17627497705 23164430   Kartennummer: 439556XXXXXX910X;-2,50;;;;'DE28300209003201649568'
14.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051614598923/PP 4081 PP/   Ihr Einkauf bei   1051614598923   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-34,00;;;;'DE28300209003201649568'
14.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051580695382/PP 4081 PP/   Ihr Einkauf bei   1051580695382   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-8,00;;;;'DE28300209003201649568'
14.07.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
14.07.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-17,86;;;;'DE28300209003201649568'
15.07.2026;Kartenzahlung   B?ckerei Stefan Neumeier   Bad Reichenh 61777346   Kartennummer: 439556XXXXXX910X;-8,80;;;;'DE28300209003201649568'
15.07.2026;Kartenzahlung   APPLE COM/BILL   08006645451   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
20.07.2026;Kartenzahlung   GOOGLE*GOOGLE PHOTOS   INTERNET   Kartennummer: 439556XXXXXX910X;-51,22;;;;'DE28300209003201649568'
20.07.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-41,73;;;;'DE28300209003201649568'
20.07.2026;Kartenzahlung   APPLE COM/BILL   08006645451   Kartennummer: 439556XXXXXX910X;-15,00;;;;'DE28300209003201649568'
21.07.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1051740325585/PP 4081 PP/  Google Payment Ireland Limited  Ihr Einkauf bei Google Payment Ireland Limited   1051740325585   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-21,98;;;;'DE28300209003201649568'
24.07.2026;Gutschrift   DE10300209005211062413;;205,21;;;'DE28300209003201649568'
24.07.2026;Echtzeitüberweisung   GEORGINA FORSTINA PANTO   DE78251900010419206000   VOHADE2HXXX  LIBERIA INDEPENDENCE   HBKIN2607248479565 - Bitte bei Rückfragen angeben ;-220,00;;;;'DE28300209003201649568'
28.07.2026;Kartenzahlung   SPC*Linh Vy Quan Restaura   Bad Reichenha 68422200   Kartennummer: 439556XXXXXX910X;-36,00;;;;'DE28300209003201649568'
28.07.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-30,22;;;;'DE28300209003201649568'
29.07.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6096729734  Rg-Nr : 1624054277/8  Ihr Ratenplan   3204680592100001624054277008RCUR   DE9700000000142462   T0010001B000006096729734;-8,00;;;;'DE28300209003201649568'
29.07.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013314   Kartennummer: 439556XXXXXX910X;-3,68;;;;'DE28300209003201649568'
31.07.2026;Gutschrift Lohn  Gehalt  Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 08-2026 03142616-2026-06013007-040936   03142616-2026-06013007-040936;;1804,46;;;'DE28300209003201649568'
31.07.2026;Kartenzahlung   DB Vertrieb GmbH   441476831325   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
03.08.2026;Gutschrift Echtzeitüberweisung   Sebastien Nkembi Njingo   Bill;;100,00;;;'DE28300209003201649568'
03.08.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000,00;;;;'DE28300209003201649568'
03.08.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01 08;-274,70;;;;'DE28300209003201649568'
03.08.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1052023442003/PP 4081 PP/  www steampowered com  Ihr Einkauf bei www steampowered com   1052023442003   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-27,99;;;;'DE28300209003201649568'
03.08.2026;Lastschrift   HanseMerkur Speziale Krankenversicherung AG   DE65200100200845103206   Nulltarifversicherung Fielmann  Praemie 08/2026 bis 07/2027  Vers -Nr  000157868380  Nkembi Parris-Campbell   000157868380   DE73ZZZ00000062190   000157868380000;-10,00;;;;'DE28300209003201649568'
03.08.2026;Kartenzahlung   EDEKA DURASIN ALTENCE   CELLE 58019461   Kartennummer: 439556XXXXXX910X;-90,14;;;;'DE28300209003201649568'
03.08.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-26,39;;;;'DE28300209003201649568'
03.08.2026;Kartenzahlung   Hoflinger 10136   Munchen 68275341   Kartennummer: 439556XXXXXX910X;-21,55;;;;'DE28300209003201649568'
03.08.2026;Kartenzahlung   tedox KG   Celle 65492827   Kartennummer: 439556XXXXXX910X;-19,00;;;;'DE28300209003201649568'
03.08.2026;Kartenzahlung   ALDI NORD   CELLE 54406603   Kartennummer: 439556XXXXXX910X;-7,98;;;;'DE28300209003201649568'
03.08.2026;Kartenzahlung   EDEKA DURASIN ALTENCE   CELLE 58019465   Kartennummer: 439556XXXXXX910X;-6,12;;;;'DE28300209003201649568'
04.08.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1052057712499/PP 4081 PP/  Netflix com  Ihr Einkauf bei Netflix com   1052057712499   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-19,99;;;;'DE28300209003201649568'
04.08.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-79,84;;;;'DE28300209003201649568'
04.08.2026;Kartenzahlung   ASIAHUNG AUTHENTIC   HANNOVER 69111386   Kartennummer: 439556XXXXXX910X;-24,00;;;;'DE28300209003201649568'
04.08.2026;Kartenzahlung   DB Vertrieb GmbH   788695478222   Kartennummer: 439556XXXXXX910X;-7,00;;;;'DE28300209003201649568'
04.08.2026;Kartenzahlung   DB Vertrieb GmbH   311894941007   Kartennummer: 439556XXXXXX910X;-1,40;;;;'DE28300209003201649568'
07.08.2026;Kartenzahlung   EDEKA DURASIN ALTENCE   CELLE 58019457   Kartennummer: 439556XXXXXX910X;-35,61;;;;'DE28300209003201649568'
07.08.2026;Kartenzahlung   PAYPAL *ZENDOCS 8FR1G   4029357733   Kartennummer: 439556XXXXXX910X;-0,50;;;;'DE28300209003201649568'
11.08.2026;Kartenzahlung   Lidl sagt Danke   Hannover 60198552   Kartennummer: 439556XXXXXX910X;-57,41;;;;'DE28300209003201649568'
11.08.2026;Kartenzahlung   MCDONALDS 01446   WUNSTORF 54239944   Kartennummer: 439556XXXXXX910X;-26,99;;;;'DE28300209003201649568'
11.08.2026;Kartenzahlung   Rossmann 1670   Hannover 60301062   Kartennummer: 439556XXXXXX910X;-19,98;;;;'DE28300209003201649568'
11.08.2026;Kartenzahlung   DB Vertrieb GmbH   250400663742   Kartennummer: 439556XXXXXX910X;-7,00;;;;'DE28300209003201649568'
12.08.2026;Kartenzahlung   PAYPAL *ZENDOCS 3YMIB   4029357733   Kartennummer: 439556XXXXXX910X;-0,50;;;;'DE28300209003201649568'
14.08.2026;Gutschrift   DE10300209005211062413;;500,00;;;'DE28300209003201649568'
17.08.2026;Kartenzahlung   AMAZON* QW47K8GO5   LUXEMBOURG   Kartennummer: 439556XXXXXX910X;-415,04;;;;'DE28300209003201649568'
17.08.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-71,19;;;;'DE28300209003201649568'
17.08.2026;Kartenzahlung   PAYPAL *TAKEAWAYCOM   4029357733   Kartennummer: 439556XXXXXX910X;-68,09;;;;'DE28300209003201649568'
17.08.2026;Kartenzahlung   Hoflinger 10136   Munchen 68275341   Kartennummer: 439556XXXXXX910X;-19,95;;;;'DE28300209003201649568'
17.08.2026;Kartenzahlung   DB Vertrieb GmbH   280484731584   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
17.08.2026;Kartenzahlung   APPLE COM/BILL   08006645451   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
19.08.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1052427514104/PP 4081 PP/  Google Payment Ireland Limited  Ihr Einkauf bei Google Payment Ireland Limited   1052427514104   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-32,98;;;;'DE28300209003201649568'
19.08.2026;Kartenzahlung   PAYPAL *ZENDOCS Q1TKY   4029357733   Kartennummer: 439556XXXXXX910X;-29,99;;;;'DE28300209003201649568'
21.08.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
24.08.2026;Kartenzahlung   Afro Cafe   Salzburg 24191483   Kartennummer: 439556XXXXXX910X;-49,60;;;;'DE28300209003201649568'
24.08.2026;Kartenzahlung   Hoflinger 10136   Munchen 68275341   Kartennummer: 439556XXXXXX910X;-17,20;;;;'DE28300209003201649568'
24.08.2026;Kartenzahlung   Hoflinger 10136   Munchen 68275341   Kartennummer: 439556XXXXXX910X;-6,70;;;;'DE28300209003201649568'
24.08.2026;Kartenzahlung   DB Vertrieb GmbH   830014742531   Kartennummer: 439556XXXXXX910X;-5,50;;;;'DE28300209003201649568'
28.08.2026;Lastschrift   Telefonica Germany GmbH + Co  OHG   DE49700400410225563601   Kd-Nr : 6096729734  Rg-Nr : 1650519629/8  Ihr Ratenplan   3204702916840001650519629008RCUR   DE9700000000142462   T0010001B000006096729734;-8,00;;;;'DE28300209003201649568'
31.08.2026;Gutschrift Lohn  Gehalt  Rente   Bundeskasse - Dienstort Weiden -   Zahltag Besoldung 09-2026 03142616-2026-06012808-040714   03142616-2026-06012808-040714;;1804,46;;;'DE28300209003201649568'
31.08.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-45,72;;;;'DE28300209003201649568'
01.09.2026;Dauerauftrag   EUR TAGESGELDKONTO   DE10300209005211062413   CMCIDEDDXXX  SONDERTILGUNG - TARGOBANK;-1000,00;;;;'DE28300209003201649568'
01.09.2026;Kreditrate   7203978276   KREDIT 00007203978276 PER 01 09;-274,70;;;;'DE28300209003201649568'
02.09.2026;Lastschrift   PayPal Europe S a r l  et Cie S C A   LU89751000135104200E   1052748261763/PP 4081 PP/  Netflix com  Ihr Einkauf bei Netflix com   1052748261763   LU96ZZZ0000000000000000058   55C22253VQ6AQ;-19,99;;;;'DE28300209003201649568'
02.09.2026;Kartenzahlung   Darwins Gastronomie   Salzburg U3516348   Kartennummer: 439556XXXXXX910X;-59,00;;;;'DE28300209003201649568'
07.09.2026;Gutschrift Echtzeitüberweisung   Sebastien Nkembi Njingo   Bill;;100,00;;;'DE28300209003201649568'
07.09.2026;Kartenzahlung   SUMUP *BATUUN TAXI   SALZBURG MXRT2PEQ   Kartennummer: 439556XXXXXX910X;-66,00;;;;'DE28300209003201649568'
07.09.2026;Kartenzahlung   DB Vertrieb GmbH   710485979648   Kartennummer: 439556XXXXXX910X;-10,30;;;;'DE28300209003201649568'
07.09.2026;Kartenzahlung   E-Kiosk Salzburg   Salzburg 42537003   Kartennummer: 439556XXXXXX910X;-5,60;;;;'DE28300209003201649568'
08.09.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013313   Kartennummer: 439556XXXXXX910X;-33,48;;;;'DE28300209003201649568'
09.09.2026;Kartenzahlung   MUeLLER BAD REICHENHALL   Bad Reichenha 69508824   Kartennummer: 439556XXXXXX910X;-108,44;;;;'DE28300209003201649568'
14.09.2026;Kartenzahlung   SUMUP *TAXI KOSE UYGUR   SALZBURG MCCNXS57   Kartennummer: 439556XXXXXX910X;-72,20;;;;'DE28300209003201649568'
14.09.2026;Auszahlung Geldautomat   SPK BERCHTESGADENER LAN/REC KARLST   Kartennummer: 439556XXXXXX910X;-50,00;;;;'DE28300209003201649568'
14.09.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013315   Kartennummer: 439556XXXXXX910X;-28,79;;;;'DE28300209003201649568'
14.09.2026;Kartenzahlung   Darwins Gastronomie   Salzburg U3516347   Kartennummer: 439556XXXXXX910X;-12,70;;;;'DE28300209003201649568'
14.09.2026;Entgelt Auszahlung   SPK BERCHTESGADENER LAN;-3,95;;;;'DE28300209003201649568'
15.09.2026;Kartenzahlung   APPLE COM/BILL   08006645451   Kartennummer: 439556XXXXXX910X;-2,99;;;;'DE28300209003201649568'
16.09.2026;Echtzeitüberweisung   TELEFONICA GERMANY GMBH   DE16700202700005713153   HYVEDEMMXXX  6108760409   HBKIN2609154182537 - Bitte bei Rückfragen angeben ;-197,69;;;;'DE28300209003201649568'
16.09.2026;Kartenzahlung   Penny Bad Reichenhall   Bad Reichenha 56013315   Kartennummer: 439556XXXXXX910X;-27,54;;;;'DE28300209003201649568'
16.09.2026;Echtzeitüberweisung   DB VERTRIEB GMBH   DE02662400020115507600   COBADEFFXXX  4026044841006   HBKIN2609164274629 - Bitte bei Rückfragen angeben ;-66,60;;;;'DE28300209003201649568'
16.09.2026;Gutschrift   DE10300209005211062413;;200,00;;;'DE28300209003201649568'
16.09.2026;Kartenzahlung   PAYPAL *ZENDOCS L6I8M   4029357733   Kartennummer: 439556XXXXXX910X;-29,99;;;;'DE28300209003201649568'
"""
    }
}
