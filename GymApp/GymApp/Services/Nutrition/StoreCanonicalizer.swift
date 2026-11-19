import Foundation

// MARK: - Global Store Source Helper
public func localizedStoreName(_ key: String) -> String {
    StoreCanonicalizer.localizedStoreName(key)
}

public enum StoreCanonicalizer {

    // MARK: - Canonical Chain Taxonomy
    public struct ChainDefinition {
        public let canonical: String
        public let patterns: [String]
    }

    public static let knownChains: [ChainDefinition] = [
        ChainDefinition(canonical: "PENNY", patterns: [
            "PENNY", "PENNY-MARKT", "PENNY MARKT", "PENNY.DE", "PENNY APP", "PENNYMARKT"
        ]),
        ChainDefinition(canonical: "REWE", patterns: [
            "REWE", "REWE MARKT", "REWE CITY", "REWE CENTER", "REWE TO GO", "REWE DORTMUND", "REWE DIGITAL", "REWE.DE", "REWE GROUP"
        ]),
        ChainDefinition(canonical: "SPAR", patterns: [
            "SPAR", "INTERSPAR", "EUROSPAR", "SPAR EXPRESS", "SPAR GOURMET", "MAXIMARKT", "SPAR.AT", "SPAR ÖSTERREICH"
        ]),
        ChainDefinition(canonical: "ALDI", patterns: [
            "ALDI", "ALDI SÜD", "ALDI SUED", "ALDI NORD", "ALDI SE", "ALDI GMBH", "ALDI.DE"
        ]),
        ChainDefinition(canonical: "LIDL", patterns: [
            "LIDL", "LIDL PLUS", "LIDL DIENSTLEISTUNG", "LIDL GMBH", "LIDL.DE"
        ]),
        ChainDefinition(canonical: "EDEKA", patterns: [
            "EDEKA", "E-CENTER", "E CENTER", "EDEKA CENTER", "EDEKA AKTIV", "EDEKA MARKT", "EDEKA.DE", "ECENTER"
        ]),
        ChainDefinition(canonical: "HOFER", patterns: [
            "HOFER", "HOFER KG", "HOFER.AT"
        ]),
        ChainDefinition(canonical: "BILLA", patterns: [
            "BILLA", "BILLA PLUS", "BILLA CORSO", "BILLA AG", "BILLA.AT"
        ]),
        ChainDefinition(canonical: "BIPA", patterns: [
            "BIPA", "BIPA PARFÜMERIEN", "BIPA.AT"
        ]),
        ChainDefinition(canonical: "DM", patterns: [
            "DM-DROGERIE", "DM DROGERIE", "DM-DROGERIEMARKT", "DM DROGERIEMARKT", "DM MARKT", "DM.DE", "DM.AT", "DM-MARKT"
        ]),
        ChainDefinition(canonical: "ROSSMANN", patterns: [
            "ROSSMANN", "DIRK ROSSMANN", "ROSSMANN DROGERIEMARKT", "ROSSMANN.DE"
        ]),
        ChainDefinition(canonical: "MÜLLER", patterns: [
            "MÜLLER", "MUELLER", "MÜLLER DROGERIE", "MUELLER DROGERIE", "MÜLLER GROSSHANDELS", "MUELLER.DE"
        ]),
        ChainDefinition(canonical: "KAUFLAND", patterns: [
            "KAUFLAND", "KAUFLAND WARENHANDEL", "KAUFLAND.DE"
        ]),
        ChainDefinition(canonical: "NETTO", patterns: [
            "NETTO", "NETTO MARKEN-DISCOUNT", "NETTO CITY", "NETTO-ONLINE", "NETTO MARKT"
        ]),
        ChainDefinition(canonical: "NORMA", patterns: [
            "NORMA", "NORMA LEBENSMITTELFILIALBETRIEB", "NORMA-ONLINE"
        ]),
        ChainDefinition(canonical: "DENN'S", patterns: [
            "DENNS", "DENN'S", "DENNS BIOMARKT", "DENN'S BIOMARKT"
        ]),
        ChainDefinition(canonical: "ALNATURA", patterns: [
            "ALNATURA", "ALNATURA PRODUKTIONS", "ALNATURA BIOMARKT"
        ]),
        ChainDefinition(canonical: "UNIMARKT", patterns: [
            "UNIMARKT", "UNIMARKT GMBH"
        ]),
        ChainDefinition(canonical: "MPREIS", patterns: [
            "MPREIS", "MPREIS WARENVERTRIEB"
        ]),
        ChainDefinition(canonical: "SUTTERLÜTY", patterns: [
            "SUTTERLÜTY", "SUTTERLUETY"
        ]),
        ChainDefinition(canonical: "TEGUT", patterns: [
            "TEGUT", "TEGUT...", "TEGUT GUTE LEBENSMITTEL"
        ]),
        ChainDefinition(canonical: "GLOBUS", patterns: [
            "GLOBUS", "GLOBUS MARKT", "GLOBUS HANDELSHOF"
        ]),
        ChainDefinition(canonical: "FAMILA", patterns: [
            "FAMILA", "FAMILA NORDWEST", "FAMILA HANDELS"
        ]),
        ChainDefinition(canonical: "MARKTKAUF", patterns: [
            "MARKTKAUF"
        ]),
        ChainDefinition(canonical: "FENEBERG", patterns: [
            "FENEBERG", "FENEBERG LEBENSMITTEL"
        ]),
        ChainDefinition(canonical: "NAHKAUF", patterns: [
            "NAHKAUF"
        ]),
        ChainDefinition(canonical: "WASGAU", patterns: [
            "WASGAU"
        ]),
        ChainDefinition(canonical: "MIGROS", patterns: [
            "MIGROS", "MIGROS-GENOSSENSCHAFTS-BUND"
        ]),
        ChainDefinition(canonical: "COOP", patterns: [
            "COOP", "COOP GENOSSENSCHAFT"
        ]),
        ChainDefinition(canonical: "DENNER", patterns: [
            "DENNER", "DENNER AG"
        ]),
        ChainDefinition(canonical: "IKEA", patterns: [
            "IKEA", "IKEA EINRICHTUNGSHAUS"
        ]),
        ChainDefinition(canonical: "AMAZON", patterns: [
            "AMAZON", "AMAZON.DE", "AMAZON EU"
        ]),
        ChainDefinition(canonical: "ESN", patterns: [
            "ESN", "ELITE SPORTS NUTRITION", "FITMART"
        ]),
        ChainDefinition(canonical: "BODYLAB24", patterns: [
            "BODYLAB24", "BODYLAB"
        ]),
        ChainDefinition(canonical: "MYPROTEIN", patterns: [
            "MYPROTEIN"
        ]),
        ChainDefinition(canonical: "APOTHEKE", patterns: [
            "APOTHEKE", "DOCMORRIS", "SHOP-APOTHEKE"
        ])
    ]

    // MARK: - Canonicalize Main Entry Point
    public static func canonicalize(_ rawName: String, existingStores: [String] = []) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "PENNY" }

        // Special system sentinels
        let up = trimmed.uppercased()
        if up == "ALLE" || up == "SONSTIGE" { return up }

        // 1. Direct Known Chain Match
        if let chain = matchKnownChain(trimmed) {
            return chain
        }

        // 2. Direct Match with Existing Stores
        if let existing = matchExistingStore(trimmed, in: existingStores) {
            return existing
        }

        // 3. Clean Generic Store Name (Branch, Address, Legal Suffix Stripping)
        let cleaned = cleanGenericStoreName(trimmed)
        guard !cleaned.isEmpty else { return trimmed }

        // Re-check cleaned name against known chains
        if let chain = matchKnownChain(cleaned) {
            return chain
        }

        // Re-check cleaned name against existing stores
        if let existing = matchExistingStore(cleaned, in: existingStores) {
            return existing
        }

        return formatBrandName(cleaned)
    }

    // MARK: - Known Chain Matcher
    public static func matchKnownChain(_ text: String) -> String? {
        let upper = text.uppercased()
            .replacingOccurrences(of: "Ü", with: "UE")
            .replacingOccurrences(of: "Ö", with: "OE")
            .replacingOccurrences(of: "Ä", with: "AE")
            .replacingOccurrences(of: "ß", with: "SS")

        let originalUpper = text.uppercased()

        // Exact or whole-token checks
        for chain in knownChains {
            for pattern in chain.patterns {
                let pUpper = pattern.uppercased()
                let pNorm = pUpper
                    .replacingOccurrences(of: "Ü", with: "UE")
                    .replacingOccurrences(of: "Ö", with: "OE")
                    .replacingOccurrences(of: "Ä", with: "AE")
                    .replacingOccurrences(of: "ß", with: "SS")

                // Word boundary check
                if containsWord(pUpper, in: originalUpper) || containsWord(pNorm, in: upper) {
                    return chain.canonical
                }
            }
        }

        // DM specific check (avoid matching inside ADMIN, CMD, etc.)
        if originalUpper == "DM" || originalUpper.hasPrefix("DM ") || originalUpper.contains(" DM ") || originalUpper.hasSuffix(" DM") {
            return "DM"
        }

        // General APOTHEKE check (e.g. "Rathaus-Apotheke" -> if user wants general APOTHEKE, or keep brand)
        if originalUpper == "APOTHEKE" || originalUpper.hasPrefix("APOTHEKE ") || originalUpper.hasSuffix(" APOTHEKE") {
            return "APOTHEKE"
        }

        return nil
    }

    // MARK: - Existing Store Matcher (Deduplication)
    public static func matchExistingStore(_ candidate: String, in existingStores: [String]) -> String? {
        let cTrimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cTrimmed.isEmpty else { return nil }
        let cUpper = cTrimmed.uppercased()

        // 1. Exact case-insensitive match
        for s in existingStores {
            if s.uppercased() == cUpper {
                return s
            }
        }

        // 2. Canonical Chain equivalence
        if let cChain = matchKnownChain(cTrimmed) {
            for s in existingStores {
                if let sChain = matchKnownChain(s), sChain == cChain {
                    return sChain
                }
            }
            return cChain
        }

        // 3. Prefix & Substring Match for Brand Entities (length >= 4)
        for s in existingStores {
            let sUpper = s.uppercased()
            guard sUpper.count >= 4 else { continue }

            // Candidate contains existing store as word prefix (e.g. candidate "Bäckerei Schmidt Salzburg", existing "Bäckerei Schmidt")
            if cUpper.hasPrefix(sUpper) || cUpper.contains(" " + sUpper + " ") || cUpper.hasSuffix(" " + sUpper) {
                return s
            }

            // Existing contains candidate (e.g. existing "Bäckerei Schmidt Filiale", candidate "Bäckerei Schmidt")
            if cUpper.count >= 4 && (sUpper.hasPrefix(cUpper) || sUpper.contains(" " + cUpper + " ") || sUpper.hasSuffix(" " + cUpper)) {
                return s
            }
        }

        // 4. Token Overlap Match (Filtering out generic stop words)
        let stopTokens: Set<String> = [
            "MARKT", "STORE", "SHOP", "DER", "DIE", "DAS", "UND", "AND", "&", "BIO",
            "SUPERMARKT", "LEBENSMITTEL", "GMBH", "AG", "KG", "FILIALE", "CITY", "CENTER"
        ]

        let cTokens = Set(cUpper.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
            .filter { !stopTokens.contains($0) })

        if !cTokens.isEmpty {
            for s in existingStores {
                let sTokens = Set(s.uppercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { $0.count >= 3 }
                    .filter { !stopTokens.contains($0) })

                if !sTokens.isEmpty && cTokens == sTokens {
                    return s
                }
            }
        }

        return nil
    }

    // MARK: - Pre-compiled Regex Singletons for Zero-Allocation Execution
    private static let urlRegex = try! NSRegularExpression(pattern: #"https?://\S+|www\.\S+|\S+@\S+\.\S+"#)
    private static let taxPhoneRegex = try! NSRegularExpression(pattern: #"\b(UID|ATU\d+|DE\d{8,11}|ST\.?-?NR\.?:?|TEL\.?:?|FAX\.?:?)\s*[A-Z0-9/-]*\b"#)
    private static let greetingsRegex = try! NSRegularExpression(pattern: #"(?i)\b(HERZLICH\s+WILLKOMMEN|WILLKOMMEN|VIELEN\s+DANK(\s+F[UÜ]R\s+IHREN\s+EINKAUF)?|IHRE\s+FILIALE|KUNDENBELEG|KASSENBELEG|KASSENBON|KASSE|RECHNUNG|QUITTUNG|BELEG|BON)\b"#)
    private static let legalFormsRegex = try! NSRegularExpression(pattern: #"(?i)\b(GMBH\s*(&|\+|UND)?\s*(CO\.?|CO|COMP\.?)?\s*(KG|OHG)?|AG|KG|OHG|GBR|E\.?\s*K\.?|SE|LTD\.?|LIMITED|INC\.?|LLC|STIFTUNG(\s*(&|\+|UND)?\s*CO\.?\s*KG)?|GENOSSENSCHAFT|WARENHANDELS\s*AG|DIENSTLEISTUNG|VERTRIEBS\s*GMBH|HANDELS\s*GMBH|LEBENSMITTELFILIALBETRIEB)\b"#)
    private static let branchRegex = try! NSRegularExpression(pattern: #"(?i)\b(FILIALE|FIL\.?|BRANCH|STORE|SHOP|MARKT|STATION|STANDORT|ZWEIGSTELLE|OUTLET|KIOSK)\s*(#|NR\.?|NO\.?|NUMMER)?\s*\d*\b"#)
    private static let streetRegex = try! NSRegularExpression(pattern: #"(?i)\b[A-ZÄÖÜa-zäöüß]+(?:straße|strasse|str|weg|platz|gasse|allee|ring|chaussee|damm|pfad|zeile)\.?\s*(?:\d+[a-zA-Z]?)?"#)
    private static let postalRegex = try! NSRegularExpression(pattern: #"\b\d{4,5}\b"#)
    private static let isolatedDigitsRegex = try! NSRegularExpression(pattern: #"(?<=\s|^)\d+[a-zA-Z]?(?=\s|$)"#)
    private static let citiesRegex = try! NSRegularExpression(pattern: #"(?i)\b(BAD\s+REICHENHALL|SALZBURG|MÜNCHEN|MUENCHEN|BERLIN|HAMBURG|KÖLN|KOELN|FRANKFURT|STUTTGART|WIEN|INNSBRUCK|GRAZ|LINZ|FREILASSING|BERCHTESGADEN|PIDING|TRAUNSTEIN|ROSENHEIM|NÜRNBERG|NUERNBERG|DÜSSELDORF|DUESSELDORF|LEIPZIG|DRESDEN|HANNOVER|BREMEN|BONN|AUGSBURG|KASSEL)\b"#)
    private static let directionRegex = try! NSRegularExpression(pattern: #"(?i)\b(SÜD|SUED|NORD|OST|WEST|MITTE|ZENTRUM|STADT|CITY|AIRPORT|FLUGHAFEN|HAUPTBAHNHOF|BAHNHOF)\b"#)

    private static let wordRegexCache: [String: NSRegularExpression] = {
        var dict: [String: NSRegularExpression] = [:]
        for chain in knownChains {
            for pattern in chain.patterns {
                let pUpper = pattern.uppercased()
                let escaped = NSRegularExpression.escapedPattern(for: pUpper)
                if let regex = try? NSRegularExpression(pattern: "(?i)(^|[^A-Z0-9ÄÖÜß])" + escaped + "([^A-Z0-9ÄÖÜß]|$)") {
                    dict[pUpper] = regex
                }
            }
        }
        return dict
    }()

    private static func applyRegex(_ regex: NSRegularExpression, replacement: String, in text: String) -> String {
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }

    // MARK: - Generic Store Name Cleaner (Universal Branch & Address Stripper)
    public static func cleanGenericStoreName(_ raw: String) -> String {
        var str = raw
        str = applyRegex(urlRegex, replacement: "", in: str)
        str = applyRegex(taxPhoneRegex, replacement: "", in: str)
        str = applyRegex(greetingsRegex, replacement: "", in: str)
        str = applyRegex(legalFormsRegex, replacement: "", in: str)
        str = applyRegex(branchRegex, replacement: "", in: str)
        str = applyRegex(streetRegex, replacement: "", in: str)
        str = applyRegex(postalRegex, replacement: "", in: str)
        str = applyRegex(isolatedDigitsRegex, replacement: "", in: str)
        str = applyRegex(citiesRegex, replacement: "", in: str)
        str = applyRegex(directionRegex, replacement: "", in: str)

        let noiseSet = CharacterSet.alphanumerics.inverted
        var cleaned = str.trimmingCharacters(in: noiseSet)

        cleaned = cleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned
    }

    // MARK: - Brand Formatting Helper
    public static func localizedStoreName(_ key: String) -> String {
        switch key.uppercased() {
        case "ALLE": return "Alle Quellen"
        case "PENNY": return "Penny"
        case "REWE": return "Rewe"
        case "ALDI": return "Aldi"
        case "SPAR": return "SPAR"
        case "INTERSPAR": return "Interspar"
        case "EUROSPAR": return "Eurospar"
        case "HOFER": return "Hofer"
        case "BILLA": return "Billa"
        case "LIDL": return "Lidl"
        case "EDEKA": return "Edeka"
        case "KAUFLAND": return "Kaufland"
        case "NETTO": return "Netto"
        case "AMAZON": return "Amazon"
        case "APOTHEKE": return "Apotheke"
        case "DM": return "dm Drogerie"
        case "ESN": return "ESN Supplements"
        default: return key.capitalized
        }
    }

    public static func formatBrandName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "PENNY" }

        let up = trimmed.uppercased()
        let shortAcronyms: Set<String> = [
            "DM", "ESN", "SPAR", "REWE", "ALDI", "LIDL", "EDEKA", "BILLA", "BIPA", "NORMA", "NETTO", "HOFER", "IKEA", "COOP"
        ]
        if shortAcronyms.contains(up) {
            return up
        }

        let words = trimmed.components(separatedBy: " ")
        let capitalized = words.map { word -> String in
            guard !word.isEmpty else { return "" }
            if word.count <= 3 && word == word.uppercased() {
                return word
            }
            let first = word.prefix(1).uppercased()
            let rest = word.dropFirst().lowercased()
            return first + rest
        }.joined(separator: " ")

        return capitalized
    }

    private static func containsWord(_ word: String, in text: String) -> Bool {
        let key = word.uppercased()
        if let regex = wordRegexCache[key] {
            let range = NSRange(location: 0, length: text.utf16.count)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        }
        let escaped = NSRegularExpression.escapedPattern(for: word)
        guard let regex = try? NSRegularExpression(pattern: "(?i)(^|[^A-Z0-9ÄÖÜß])" + escaped + "([^A-Z0-9ÄÖÜß]|$)") else { return false }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}
