import Foundation

// MARK: - Care Zone
public enum CareZone: String, CaseIterable, Codable, Identifiable {
    case all = "Alle Zonen"
    case face = "Gesicht & Bart"
    case oral = "Zaehne & Mund"
    case hair = "Haare & Kopfhaut"
    case groin = "Leiste & Intim"
    case nails = "Naegel & Fuesse"
    case body = "Koerper & Rumpf"
    case chores = "Kaserne"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .face: return "face.smiling"
        case .oral: return "mouth"
        case .hair: return "comb.fill"
        case .groin: return "shield.lefthalf.filled"
        case .nails: return "hand.raised.fill"
        case .body: return "figure.stand"
        case .chores: return "checklist"
        }
    }

    public var shortLabel: String {
        switch self {
        case .all: return "Alle"
        case .face: return "Gesicht"
        case .oral: return "Zaehne"
        case .hair: return "Haare"
        case .groin: return "Leiste"
        case .nails: return "Naegel"
        case .body: return "Koerper"
        case .chores: return "Kaserne"
        }
    }
}

// MARK: - Routine Frequency
public enum RoutineFrequency: String, CaseIterable, Codable, Identifiable {
    case daily = "Taeglich"
    case twiceDaily = "2x taeglich"
    case threeTimesAWeek = "3x pro Woche"
    case weekly = "Woechentlich"
    case monthly = "Monatlich"

    public var id: String { rawValue }

    public var descriptionText: String {
        switch self {
        case .daily: return "Jeden Tag zur festgelegten Uhrzeit"
        case .twiceDaily: return "Morgens und abends"
        case .threeTimesAWeek: return "Mittwoch, Freitag, Sonntag"
        case .weekly: return "Einmal pro Woche (Sonntag)"
        case .monthly: return "Einmal zum Monatsanfang"
        }
    }
}

// MARK: - Care Routine Step
public struct CareRoutineStep: Identifiable, Hashable, Codable {
    public var id: String
    public var number: Int
    public var title: String
    public var instruction: String
    public var keyToolOrIngredient: String

    public init(
        id: String = UUID().uuidString,
        number: Int,
        title: String,
        instruction: String,
        keyToolOrIngredient: String
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.instruction = instruction
        self.keyToolOrIngredient = keyToolOrIngredient
    }
}

// MARK: - Care Product Model
public struct CareProduct: Identifiable, Hashable, Codable {
    public var id: String
    public var name: String
    public var brand: String
    public var price: Double
    public var category: String
    public var activeIngredients: String
    public var usageInstructions: String
    public var clinicalBenefit: String
    public var amazonUrl: String
    public var layeringWaitTime: String?
    public var zone: CareZone

    public init(
        id: String,
        name: String,
        brand: String,
        price: Double,
        category: String,
        activeIngredients: String,
        usageInstructions: String,
        clinicalBenefit: String,
        amazonUrl: String,
        layeringWaitTime: String? = nil,
        zone: CareZone = .face
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.price = price
        self.category = category
        self.activeIngredients = activeIngredients
        self.usageInstructions = usageInstructions
        self.clinicalBenefit = clinicalBenefit
        self.amazonUrl = amazonUrl
        self.layeringWaitTime = layeringWaitTime
        self.zone = zone
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, price, category, activeIngredients, usageInstructions, clinicalBenefit, amazonUrl, layeringWaitTime, zone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.brand = try container.decode(String.self, forKey: .brand)
        self.price = try container.decode(Double.self, forKey: .price)
        self.category = try container.decode(String.self, forKey: .category)
        self.activeIngredients = try container.decode(String.self, forKey: .activeIngredients)
        self.usageInstructions = try container.decode(String.self, forKey: .usageInstructions)
        self.clinicalBenefit = try container.decode(String.self, forKey: .clinicalBenefit)
        self.amazonUrl = try container.decode(String.self, forKey: .amazonUrl)
        self.layeringWaitTime = try container.decodeIfPresent(String.self, forKey: .layeringWaitTime)
        if let decodedZone = try container.decodeIfPresent(CareZone.self, forKey: .zone) {
            self.zone = decodedZone
        } else {
            let cat = category.lowercased()
            let i = id.lowercased()
            if cat.contains("zahn") || cat.contains("mund") || i.contains("tooth") || i.contains("floss") {
                self.zone = .oral
            } else if cat.contains("haar") || cat.contains("scalp") || i.contains("mielle") || i.contains("cantu") || i.contains("durag") {
                self.zone = .hair
            } else if cat.contains("intim") || cat.contains("chafing") || i.contains("sebamed") || i.contains("glide") || i.contains("panthenol") {
                self.zone = .groin
            } else if cat.contains("nagel") || cat.contains("fuss") || i.contains("clipper") || i.contains("urea") || i.contains("file") {
                self.zone = .nails
            } else if cat.contains("koerper") || cat.contains("body") {
                self.zone = .body
            } else {
                self.zone = .face
            }
        }
    }

    public var calculatedWaitTime: String {
        if let explicit = layeringWaitTime, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return explicit
        }
        let lowerCat = category.lowercased()
        let lowerAct = activeIngredients.lowercased()
        if lowerCat.contains("peeling") || lowerAct.contains("bha") || lowerAct.contains("salicyl") {
            return "10 - 15 Min"
        }
        if lowerAct.contains("azelain") || lowerAct.contains("azelaic") {
            return "5 - 10 Min"
        }
        if lowerCat.contains("serum") {
            return "3 - 5 Min"
        }
        if lowerCat.contains("feuchtigkeit") || lowerCat.contains("creme") {
            return "2 - 3 Min"
        }
        if lowerCat.contains("sonnenschutz") || lowerCat.contains("spf") {
            return "Vollstaendig einziehen lassen"
        }
        return "1 - 2 Min"
    }
}

// MARK: - Care Routine Item
public struct CareRoutineItem: Identifiable, Hashable, Codable {
    public var id: String
    public var title: String
    public var category: String
    public var defaultFrequency: RoutineFrequency
    public var defaultHour: Int
    public var defaultMinute: Int
    public var estimatedMinutes: Int
    public var clinicalRationale: String
    public var steps: [CareRoutineStep]
    public var products: [CareProduct]
    public var isNotificationEnabled: Bool
    public var zone: CareZone

    public init(
        id: String,
        title: String,
        category: String,
        defaultFrequency: RoutineFrequency,
        defaultHour: Int,
        defaultMinute: Int,
        estimatedMinutes: Int,
        clinicalRationale: String,
        steps: [CareRoutineStep],
        products: [CareProduct],
        isNotificationEnabled: Bool = true,
        zone: CareZone = .face
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.defaultFrequency = defaultFrequency
        self.defaultHour = defaultHour
        self.defaultMinute = defaultMinute
        self.estimatedMinutes = estimatedMinutes
        self.clinicalRationale = clinicalRationale
        self.steps = steps
        self.products = products
        self.isNotificationEnabled = isNotificationEnabled
        self.zone = zone
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, defaultFrequency, defaultHour, defaultMinute, estimatedMinutes, clinicalRationale, steps, products, isNotificationEnabled, zone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.category = try container.decode(String.self, forKey: .category)
        self.defaultFrequency = try container.decode(RoutineFrequency.self, forKey: .defaultFrequency)
        self.defaultHour = try container.decode(Int.self, forKey: .defaultHour)
        self.defaultMinute = try container.decode(Int.self, forKey: .defaultMinute)
        self.estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        self.clinicalRationale = try container.decode(String.self, forKey: .clinicalRationale)
        self.steps = try container.decode([CareRoutineStep].self, forKey: .steps)
        self.products = try container.decode([CareProduct].self, forKey: .products)
        self.isNotificationEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isNotificationEnabled)) ?? true
        if let decodedZone = try container.decodeIfPresent(CareZone.self, forKey: .zone) {
            self.zone = decodedZone
        } else {
            let lower = id.lowercased() + " " + category.lowercased()
            if lower.contains("zahn") || lower.contains("mund") {
                self.zone = .oral
            } else if lower.contains("haar") {
                self.zone = .hair
            } else if lower.contains("intim") || lower.contains("leiste") {
                self.zone = .groin
            } else if lower.contains("nagel") || lower.contains("fuss") {
                self.zone = .nails
            } else if lower.contains("koerper") {
                self.zone = .body
            } else if lower.contains("kaserne") || lower.contains("kulturbeutel") {
                self.zone = .chores
            } else {
                self.zone = .face
            }
        }
    }

    public var shortTitle: String {
        switch id {
        case "routine_morgen": return "Morgen-Pflege & SPF"
        case "routine_mittag_uv_frische": return "20s UV-Spind-Schutz"
        case "routine_post_dienst_reset": return "Post-Dienst Reset"
        case "routine_post_shower_hydration": return "Barriere-Repair"
        case "routine_abend_trimmtag": return "Abend-Pflege (Trimmtag)"
        case "routine_abend_rasurfrei", "routine_abend": return "Abend-BHA & Regeneration"
        case "routine_bart_pseudofolliculitis": return "4C Bart-Trimm (JRL)"
        case "routine_haare_4c": return "4C Haarpflege (LOC)"
        case "routine_zahnpflege_morgen": return "Morgen-Zahnpflege"
        case "routine_zahnpflege_abend": return "Abend-Zahn & Interdental"
        case "routine_intimpflege_postdienst": return "Leisten- & Intimbarriere"
        case "routine_nagel_fusspflege_woche": return "Nagel- & Fusspflege"
        case "routine_haare_4c_washday": return "4C Wash Day & Tiefenpflege"
        case "routine_koerper_tactical_reset": return "Ganzkoerper-Reset"
        case "routine_kulturbeutel": return "Dienst-Kulturbeutel"
        default:
            if title.contains("Zahn") || title.contains("Mund") { return "Zahnpflege" }
            if title.contains("Intim") || title.contains("Leiste") { return "Intimpflege" }
            if title.contains("Nagel") || title.contains("Fuss") { return "Nagelpflege" }
            if title.contains("Koerper") { return "Koerperpflege" }
            if title.contains("Morgen") { return "Morgen-Pflege" }
            if title.contains("Abend") { return "Abend-Pflege" }
            if title.contains("Bart") { return "Bartpflege" }
            if title.contains("Haar") { return "Haarpflege" }
            return title
        }
    }
}

// MARK: - Care Catalog Seed Data
public enum CareCatalogData {
    // MARK: Face & Beard Products
    public static let ceraveCleanser = CareProduct(
        id: "prod_cerave_cleanser",
        name: "Feuchtigkeitsspendende Reinigungslotion",
        brand: "CeraVe",
        price: 11.95,
        category: "Reinigung",
        activeIngredients: "3 essenzielle Ceramide, Hyaluronsaeure, MVE-Technologie",
        usageInstructions: "Morgens und abends auf angefeuchtete Haut auftragen, 30 Sekunden sanft einmassieren und mit lauwarmem Wasser abspuelen.",
        clinicalBenefit: "Bewahrt die natuerliche Hautbarriere, nicht komedogen, parfuemfrei, schuetzt vor Austrocknung.",
        amazonUrl: "https://www.amazon.de/dp/B07C5V894J",
        zone: .face
    )

    public static let ceraveCream = CareProduct(
        id: "prod_cerave_cream",
        name: "Feuchtigkeitscreme mit Ceramiden",
        brand: "CeraVe",
        price: 14.50,
        category: "Feuchtigkeitspflege",
        activeIngredients: "Ceramide 1, 3, 6-II, Hyaluron, Phytosphingosin",
        usageInstructions: "Nach der Reinigung oder Wirkstoffaufnahme gleichmaessig auf Gesicht, Hals und Rumpf auftragen.",
        clinicalBenefit: "Restrukturiert die epidermale Lipidbarriere nach chemischen Peelings und Rasurvorgaengen.",
        amazonUrl: "https://www.amazon.de/dp/B07C5T648C",
        zone: .face
    )

    public static let lrpSunscreen = CareProduct(
        id: "prod_lrp_sunscreen",
        name: "Anthelios UVMune 400 Invisible Fluid SPF 50+",
        brand: "La Roche-Posay",
        price: 19.90,
        category: "Sonnenschutz",
        activeIngredients: "Mexoryl 400 Breitband-UV-Filter, Netlock-Technologie",
        usageInstructions: "Morgens als finaler Pflegeschritt grosszuegig auftragen. Zieht rueckstandslos ein, brennt nicht in den Augen.",
        clinicalBenefit: "Schuetzt vor ultralangen UVA-Strahlen (380-400nm), verhindert postinflammatorische Hyperpigmentierung.",
        amazonUrl: "https://www.amazon.de/dp/B09V7N7KLR",
        zone: .face
    )

    public static let paulasChoiceBHA = CareProduct(
        id: "prod_paula_bha",
        name: "Skin Perfecting 2% BHA Liquid Peeling",
        brand: "Paula's Choice",
        price: 39.00,
        category: "Wirkstoff-Peeling",
        activeIngredients: "2% Salicylsaeure (Beta-Hydroxysaeure), Gruentee-Extrakt, pH 3.2-3.8",
        usageInstructions: "Abends nach der Reinigung mit den Haenden sanft einklopfen. 10 bis 15 Minuten einziehen lassen vor naechsten Schritten.",
        clinicalBenefit: "Dringt tief in die Poren ein, loest Talg, verhindert Pseudofolliculitis Barbae (eingewachsene Barthaare).",
        amazonUrl: "https://www.amazon.de/dp/B00949CTQQ",
        zone: .face
    )

    public static let azelaicAcid = CareProduct(
        id: "prod_azelaic_acid",
        name: "Azelaic Acid Suspension 10%",
        brand: "The Ordinary",
        price: 12.80,
        category: "Wirkstoff-Serum",
        activeIngredients: "10% hochreine Azelainsaeure",
        usageInstructions: "Abends nach dem BHA-Peeling gleichmaessig auftragen. Augen- und Mundpartie aussparen.",
        clinicalBenefit: "Reduziert bakterielle Besiedlung, daempft Entzuendungsreaktionen, glaettet den Teint ohne Schaeleffekt.",
        amazonUrl: "https://www.amazon.de/dp/B01MT293Q3",
        zone: .face
    )

    public static let jrlTrimmer = CareProduct(
        id: "prod_jrl_trimmer",
        name: "FreshFade 2025T Diamante Trimmer",
        brand: "JRL Professional",
        price: 149.00,
        category: "Rasur-Equipment",
        activeIngredients: "Titan-Carbon Klinge, 7.200 U/Min Motor, Cool-Blade Technologie",
        usageInstructions: "Ausschliesslich fuer Trockenschnitt verwenden. Schnittlaenge 0.5 bis 1.0 mm, parallel zur Wuchsrichtung.",
        clinicalBenefit: "Verhindert Haarenden-Abschraegung unter der Hautoberflaeche. Goldstandard gegen Rasurbrand.",
        amazonUrl: "https://www.amazon.de/dp/B0C4M4Q97S",
        zone: .face
    )

    public static let tendSkin = CareProduct(
        id: "prod_tend_skin",
        name: "After Shave Post-Shave Solution",
        brand: "Tend Skin",
        price: 24.50,
        category: "Aftershave",
        activeIngredients: "Acetylsalicylsaeure, Isopropanol, Glyzerin",
        usageInstructions: "Zwingend 24h-Patch-Test vor Erstgebrauch durchfuehren. Kontraindiziert bei Aspirin-Allergie. Ausschliesslich punktuell mit Pad/Wattestaebchen auf frisch getrimmte Areale tupfen (nicht reiben). Niemals am selben Tag mit BHA-Peelings kombinieren.",
        clinicalBenefit: "Bekaempft Rasurbrand und Follikelentzuendungen. Erfordert strikte Vermeidung zusaetzlicher chemischer Peelings.",
        amazonUrl: "https://www.amazon.de/dp/B0002CAQ6G",
        zone: .face
    )

    // MARK: Hair & Scalp Products
    public static let mielleOil = CareProduct(
        id: "prod_mielle_oil",
        name: "Rosemary Mint Scalp & Hair Strengthening Oil",
        brand: "Mielle",
        price: 13.99,
        category: "Haarpflege",
        activeIngredients: "Rosmarinoel, Pfefferminzoel, Biotin, Sojaoel",
        usageInstructions: "Auf die Kopfhaut und Haarspitzen traeufeln, 2 bis 3 Minuten einmassieren. Nicht ausspuelen.",
        clinicalBenefit: "Stimuliert die Mikrozirkulation der Follikel, versiegelt die Cuticula bei 4C Haar.",
        amazonUrl: "https://www.amazon.de/dp/B07N7PK9QK",
        zone: .hair
    )

    public static let cantuLeaveIn = CareProduct(
        id: "prod_cantu_leavein",
        name: "Shea Butter Leave-In Conditioning Repair Cream",
        brand: "Cantu",
        price: 8.95,
        category: "Haarpflege",
        activeIngredients: "Reine Sheabutter, Rizinusoel, Canola-Oel",
        usageInstructions: "In feuchtes 4C-Haar einarbeiten. Bildet die Cream-Stufe der LOC-Methode.",
        clinicalBenefit: "Spendet langanhaltende Feuchtigkeit und verhindert Haarbruch bei hoher Porositaet.",
        amazonUrl: "https://www.amazon.de/dp/B00449W35S",
        zone: .hair
    )

    public static let sheaMoistureCastor = CareProduct(
        id: "prod_shea_castor",
        name: "Jamaican Black Castor Oil Strengthen & Restore",
        brand: "SheaMoisture",
        price: 15.49,
        category: "Haarpflege",
        activeIngredients: "Schwarzes Jamaika-Rizinusoel, Pfefferminze, Apfelessig",
        usageInstructions: "Als abschliessende Versiegelung der Haarspitzen verwenden.",
        clinicalBenefit: "Staerkung der Haarschaft-Integritaet gegen mechanische Belastung (Muetzen, Helme).",
        amazonUrl: "https://www.amazon.de/dp/B00MY351Q8",
        zone: .hair
    )

    public static let satinDurag = CareProduct(
        id: "prod_premium_satin_durag",
        name: "Seiden-Satin Durag & Kompressionshaube",
        brand: "SlickGorilla Care",
        price: 11.99,
        category: "Haarpflege",
        activeIngredients: "100% hochdichte Satinfasern, reibungsarme Webung",
        usageInstructions: "Jeden Abend vor dem Schlafengehen nach der Haarpflege anlegen. Schuetzt vor Feuchtigkeitsverlust auf Baumwollkissen.",
        clinicalBenefit: "Verhindert Scherkraefte und Faserbruch bei 4C-Haar waehrend der Nachtruhe.",
        amazonUrl: "https://www.amazon.de/dp/B08DFW9XZ3",
        zone: .hair
    )

    public static let sulfateFreeShampoo = CareProduct(
        id: "prod_mielle_shampoo",
        name: "Pomegranate & Honey Detangling Shampoo",
        brand: "Mielle Organics",
        price: 14.99,
        category: "Haarpflege",
        activeIngredients: "Sulfatfreie Tenside, Granatapfel, Honig, Babassuoel",
        usageInstructions: "Am woechentlichen Wash Day (Sonntag) sanft in die Kopfhaut einmassieren und gruendlich mit lauwarmem Wasser ausspuelen.",
        clinicalBenefit: "Tiefenreinigung von Schwaeche und Sebum ohne Denaturierung der Haarfaser.",
        amazonUrl: "https://www.amazon.de/dp/B0784T5Q21",
        zone: .hair
    )

    public static let deepConditionerMasque = CareProduct(
        id: "prod_sheamoisture_masque",
        name: "Manuka Honey & Mafura Oil Intensive Hydration Masque",
        brand: "SheaMoisture",
        price: 16.50,
        category: "Haarpflege",
        activeIngredients: "Manuka-Honig, Mafura-Oel, zertifizierte Sheabutter",
        usageInstructions: "Nach dem Shampoonieren grosszuegig im Haar verteilen. 10 bis 15 Minuten einwirken lassen, dann gruendlich ausspuelen.",
        clinicalBenefit: "Restrukturiert thermo- und helmgeschaedigte Schuppenschichten bei Afro 4C Haar.",
        amazonUrl: "https://www.amazon.de/dp/B00M850J9M",
        zone: .hair
    )

    // MARK: Oral Care Products
    public static let sonicToothbrush = CareProduct(
        id: "prod_oral_b_io",
        name: "iO Series Elektrische Schallzahnbuerste",
        brand: "Oral-B",
        price: 69.99,
        category: "Zahnpflege",
        activeIngredients: "Mikrovibrationen, 2-Minuten Quadranten-Timer, Andruckkontrolle",
        usageInstructions: "Morgens und abends 2 Minuten verwenden. 45-Grad-Winkel zum Sulkus halten, Druckkontrollanzeige beachten.",
        clinicalBenefit: "Entfernt 100% mehr Plaque als manuelle Buersten, schuetzt den Schmelz vor Abrasionsschaeden.",
        amazonUrl: "https://www.amazon.de/dp/B09TDQNZ6V",
        zone: .oral
    )

    public static let remineralizingToothpaste = CareProduct(
        id: "prod_elmex_toothpaste",
        name: "Kariesschutz Zahnpasta mit Aminfluorid",
        brand: "Elmex",
        price: 3.49,
        category: "Zahnpflege",
        activeIngredients: "1400 ppm Olaflur (Aminfluorid)",
        usageInstructions: "Erbsengrosse Menge auftragen. 2 Minuten putzen, ausspucken, danach NICHT mit Wasser nachspuelen.",
        clinicalBenefit: "Bildet sofort ein homogenes Calciumfluorid-Depot, remineralisiert Schmelzlaesionen und neutralisiert Refluxsaeuren.",
        amazonUrl: "https://www.amazon.de/dp/B00E4M89FE",
        zone: .oral
    )

    public static let tepeTongueCleaner = CareProduct(
        id: "prod_tepe_tongue_cleaner",
        name: "Good Zungenschaber (Bio-basiert)",
        brand: "TePe",
        price: 4.29,
        category: "Zahnpflege",
        activeIngredients: "Drei anatomische Reinigungslamellen",
        usageInstructions: "Zunge herausstrecken, Schaber hinten ansetzen und 2 bis 3 Mal sanft nach vorne ziehen. Unter fliessendem Wasser abspuelen.",
        clinicalBenefit: "Senkt Zungenbakterien und fluechtige Schwefelverbindungen um bis zu 75%, reduziert Halitosis und Plaquebesiedlung.",
        amazonUrl: "https://www.amazon.de/dp/B07P7N6J8S",
        zone: .oral
    )

    public static let dentalFloss = CareProduct(
        id: "prod_curaprox_floss",
        name: "DF 834 Gewachste Zahnseide & Interdental",
        brand: "Curaprox",
        price: 5.95,
        category: "Zahnpflege",
        activeIngredients: "Gewachste PTFE/Mikrofaser-Faeden",
        usageInstructions: "Jeden Abend vor dem Zaehneputzen sanft in jeden Interdentalraum gleiten lassen und Plaque aufwaerts abstreifen.",
        clinicalBenefit: "Reinigt 40% der Zahnoberflaeche, die von Buersten nicht erreicht wird. Beugt Interdentalkaries und Parodontitis vor.",
        amazonUrl: "https://www.amazon.de/dp/B002ZCH1H6",
        zone: .oral
    )

    public static let antisepticMouthwash = CareProduct(
        id: "prod_chlorhexamed_mouthwash",
        name: "Sensodyne Cool Mint Alkoholfreie Mundspuelung",
        brand: "Sensodyne",
        price: 4.99,
        category: "Zahnpflege",
        activeIngredients: "Natriumfluorid (250 ppm), Cetylpyridiniumchlorid (CPC)",
        usageInstructions: "Abends nach der Reinigung 10-15 ml 30 Sekunden im Mund spuelen. Nicht schlucken, danach 30 Minuten nichts trinken.",
        clinicalBenefit: "Alkoholfreie Formel brennt nicht bei Stillem Reflux (LPR) und bewaeltigt Biofilme ueber Nacht ohne Schleimhautaustrocknung.",
        amazonUrl: "https://www.amazon.de/dp/B01B79555M",
        zone: .oral
    )

    // MARK: Groin & Pelvic / Visceral Products
    public static let sebamedIntimate = CareProduct(
        id: "prod_sebamed_intimate",
        name: "Intim-Waschlotion pH 3.8 / pH 5.5",
        brand: "Sebamed",
        price: 4.75,
        category: "Intimpflege",
        activeIngredients: "Alpha-Bisabolol, Aloe Vera, natuerliche Milchsaeure",
        usageInstructions: "Taeglich beim Duschen sparsam auf Leisten- und Perianalbereich auftragen und gruendlich mit lauwarmem Wasser abspuelen.",
        clinicalBenefit: "Stabilisiert den physiologischen Saeureschutzmantel, schuetzt vor Intertrigo und schont nach viszeraler OP (BWK Ulm).",
        amazonUrl: "https://www.amazon.de/dp/B000KU95LM",
        zone: .groin
    )

    public static let antiChafingBalm = CareProduct(
        id: "prod_bodyglide_antichafing",
        name: "Body Glide Original Anti-Chafing Balm Stick",
        brand: "Body Glide",
        price: 14.99,
        category: "Intimpflege",
        activeIngredients: "Allantoin, pflanzliche Schutzwachse, Vitamin E",
        usageInstructions: "Vor Dienst, Maerschen und Training direkt auf Leistenfalten und Oberschenkelinnenseiten auftragen.",
        clinicalBenefit: "Verhindert Wolfgelaufen, Scheuerstellen und Follikelreizungen unter Bundeswehr-Uniform und Ausruestung.",
        amazonUrl: "https://www.amazon.de/dp/B00288L2N6",
        zone: .groin
    )

    public static let panthenolBarrierCream = CareProduct(
        id: "prod_bepanthen_wound_cream",
        name: "Wund- und Heilsalbe mit 5% Dexpanthenol",
        brand: "Bepanthen",
        price: 8.95,
        category: "Intimpflege",
        activeIngredients: "5% Dexpanthenol, Wollwachsalkohole",
        usageInstructions: "Bei Rötungen, Druckstellen oder post-defaekatorischer Reizung duenn auf das perianale Areal tupfen.",
        clinicalBenefit: "Unterstuetzt die Epithelisierung und schuetzt die mukokutane Grenzzone vor Verdauungsenzymen (Reha BWK Ulm).",
        amazonUrl: "https://www.amazon.de/dp/B00E671GZ4",
        zone: .groin
    )

    // MARK: Nails & Combat Boot Feet Products
    public static let glassNailFile = CareProduct(
        id: "prod_mont_bleu_glass_file",
        name: "Gehaertete Glasnagelfeile",
        brand: "Mont Bleu",
        price: 9.99,
        category: "Nagel- & Fusspflege",
        activeIngredients: "Tschechisches Hartglas, mikroskopische Schleifflaeche",
        usageInstructions: "In eine Richtung von aussen nach innen feilen. Regelmaessig unter heissem Wasser reinigen.",
        clinicalBenefit: "Versiegelt Keratinschichten, verhindert Absplitterungen und Einreissen in Diensthandschuhen.",
        amazonUrl: "https://www.amazon.de/dp/B00537I0TU",
        zone: .nails
    )

    public static let nailClipperSet = CareProduct(
        id: "prod_victorinox_nail_clipper",
        name: "Edelstahl Nagelknipser mit gerader Schneide",
        brand: "Victorinox",
        price: 12.50,
        category: "Nagel- & Fusspflege",
        activeIngredients: "Chirurgen-Edelstahl, gerade Schneidekante",
        usageInstructions: "Zehennaegel strikt gerade schneiden, Kanten niemals tief abrunden. 1 mm Ueberstand belassen.",
        clinicalBenefit: "Goldstandard zur Verhinderung von Unguis incarnatus (eingewachsenen Naegeln) im Kampfstiefel.",
        amazonUrl: "https://www.amazon.de/dp/B07N4T49R4",
        zone: .nails
    )

    public static let ureaFootCream = CareProduct(
        id: "prod_eucerin_urea_foot",
        name: "UreaRepair PLUS Fusscreme 10% - 15%",
        brand: "Eucerin",
        price: 12.90,
        category: "Nagel- & Fusspflege",
        activeIngredients: "10-15% Urea, Ceramide, Natural Moisturizing Factors",
        usageInstructions: "Woechentlich nach dem Fussbad oder vor dem Schlafen grosszuegig auf Fersen und Ballen einmassieren.",
        clinicalBenefit: "Keratolytische Loesung von Hyperkeratosen (Hornhaut), beugt tiefen Marschrhagaden und Blasenbildung vor.",
        amazonUrl: "https://www.amazon.de/dp/B00V4L7J58",
        zone: .nails
    )

    public static let nailCuticleOil = CareProduct(
        id: "prod_sally_hansen_cuticle_oil",
        name: "Vitamin E Nail & Cuticle Oil",
        brand: "Sally Hansen",
        price: 7.95,
        category: "Nagel- & Fusspflege",
        activeIngredients: "Jojobaoel, Weizenkeimoel, Vitamin E",
        usageInstructions: "Einen Tropfen auf die Nagelfalz geben und sanft einmassieren.",
        clinicalBenefit: "Verhindert schmerzhafte Niednaegel und Risse durch Kaelte und Waffenreinigungsloesungsmittel.",
        amazonUrl: "https://www.amazon.de/dp/B000AA5VD6",
        zone: .nails
    )

    // MARK: Equipment / Travel
    public static let travelBottles = CareProduct(
        id: "prod_travel_bottles",
        name: "Silikon Reiseflaschen Set 100ml (TSA Konform)",
        brand: "Grooming Travel",
        price: 12.99,
        category: "Reise-Equipment",
        activeIngredients: "BPA-freies Silikon, auslaufsicherer Dreifach-Verschluss",
        usageInstructions: "Fuer CeraVe Cleanser, Feuchtigkeitscreme und Shampoo abfuellen.",
        clinicalBenefit: "Ermoeglicht lueckenlose Einhaltung der Pflegeroutine im Kasernendienst und auf Reisen.",
        amazonUrl: "https://www.amazon.de/dp/B07W8P8M82",
        zone: .chores
    )

    public static let allProducts: [CareProduct] = [
        ceraveCleanser,
        ceraveCream,
        lrpSunscreen,
        paulasChoiceBHA,
        azelaicAcid,
        jrlTrimmer,
        tendSkin,
        mielleOil,
        cantuLeaveIn,
        sheaMoistureCastor,
        satinDurag,
        sulfateFreeShampoo,
        deepConditionerMasque,
        sonicToothbrush,
        remineralizingToothpaste,
        tepeTongueCleaner,
        dentalFloss,
        antisepticMouthwash,
        sebamedIntimate,
        antiChafingBalm,
        panthenolBarrierCream,
        glassNailFile,
        nailClipperSet,
        ureaFootCream,
        nailCuticleOil,
        travelBottles
    ]

    public static let allRoutines: [CareRoutineItem] = [
        // MARK: Face & Shaving Routines
        CareRoutineItem(
            id: "routine_morgen",
            title: "Morgenroutine Gesicht & Sonnenschutz",
            category: "Morgen",
            defaultFrequency: .daily,
            defaultHour: 6,
            defaultMinute: 15,
            estimatedMinutes: 5,
            clinicalRationale: "Morgendliche Reinigung von naechtlichem Talg, Wiederherstellung der Ceramid-Barriere und 8-stuendiger Breitband-UV-Schutz vor Dienstantritt.",
            steps: [
                CareRoutineStep(number: 1, title: "Gesichtsreinigung", instruction: "Gesicht mit lauwarmem Wasser benetzen. Einen Pumpstoss CeraVe Reinigungslotion 30 Sekunden sanft einmassieren und abspuelen.", keyToolOrIngredient: "CeraVe Hydrating Cleanser"),
                CareRoutineStep(number: 2, title: "Feuchtigkeitsbarriere", instruction: "Eine haselnussgrosse Menge Feuchtigkeitscreme gleichmaessig auf Gesicht und Hals verteilen.", keyToolOrIngredient: "CeraVe Feuchtigkeitscreme"),
                CareRoutineStep(number: 3, title: "UV-Schutz SPF 50+", instruction: "La Roche-Posay Fluid gut schuetteln. Grosszuegig auf Gesicht, Ohren und Nacken auftragen.", keyToolOrIngredient: "LRP Anthelios SPF 50+")
            ],
            products: [ceraveCleanser, ceraveCream, lrpSunscreen],
            zone: .face
        ),
        CareRoutineItem(
            id: "routine_mittag_uv_frische",
            title: "20-Sekunden Hals- & UV-Direktapplikation",
            category: "Mittag",
            defaultFrequency: .daily,
            defaultHour: 12,
            defaultMinute: 45,
            estimatedMinutes: 1,
            clinicalRationale: "Direkte Tyrosinase-Hemmung und Unterbindung von UV-induzierter Hyperpigmentierung (PIH). Kein vorheriges Waschen erforderlich: 20 Sekunden Direktauftrag aus dem Spind schuetzt vor Melanozyten-Aktivierung.",
            steps: [
                CareRoutineStep(number: 1, title: "Fluid schuetteln & dosieren", instruction: "LRP Anthelios Fluid kurz schuetteln. 1 Fingerlaenge entnehmen (Spind-Depot).", keyToolOrIngredient: "LRP Anthelios SPF 50+"),
                CareRoutineStep(number: 2, title: "Gezielter Hals- & Unterkieferauftrag", instruction: "Ohne vorheriges Waschen direkt und grosszuegig auf den vorderen Hals und Unterkiefer auftragen.", keyToolOrIngredient: "LRP Anthelios SPF 50+")
            ],
            products: [lrpSunscreen],
            zone: .face
        ),
        CareRoutineItem(
            id: "routine_post_dienst_reset",
            title: "Post-Dienst Somatischer Reset",
            category: "Nachmittag",
            defaultFrequency: .daily,
            defaultHour: 16,
            defaultMinute: 30,
            estimatedMinutes: 5,
            clinicalRationale: "Uebergang vom Dienstbetrieb (Dienstschluss 16:30 Uhr). Kasernenkleidung ablegen, Haende waschen, Stube lueften zur Vorbereitung auf Sport und Erholung.",
            steps: [
                CareRoutineStep(number: 1, title: "Dienstkleidung ablegen & Lueften", instruction: "Dienstkleidung ablegen, Fenster oeffnen, Sportbekleidung anlegen.", keyToolOrIngredient: "Frische Sportbekleidung"),
                CareRoutineStep(number: 2, title: "Haende & Gesicht erfrischen", instruction: "Mit lauwarmem Wasser den Staub des Dienstbetriebs abspuelen.", keyToolOrIngredient: "Frisches Wasser")
            ],
            products: [],
            zone: .face
        ),
        CareRoutineItem(
            id: "routine_post_shower_hydration",
            title: "Post-Workout Barriere-Repair",
            category: "Nachmittag",
            defaultFrequency: .daily,
            defaultHour: 17,
            defaultMinute: 45,
            estimatedMinutes: 5,
            clinicalRationale: "Eindaemmung des transepidermalen Wasserverlusts (TEWL) nach dem Duschen. Ceramide restrukturieren die Barriereschicht.",
            steps: [
                CareRoutineStep(number: 1, title: "Sanfte Reinigung", instruction: "Unter der Dusche Gesicht mit CeraVe Cleanser reinigen, nicht reiben.", keyToolOrIngredient: "CeraVe Hydrating Cleanser"),
                CareRoutineStep(number: 2, title: "Feuchtigkeitsversiegelung", instruction: "Auf die noch leicht feuchte Haut sofort CeraVe Feuchtigkeitscreme auftragen.", keyToolOrIngredient: "CeraVe Feuchtigkeitscreme")
            ],
            products: [ceraveCleanser, ceraveCream],
            zone: .face
        ),
        CareRoutineItem(
            id: "routine_bart_pseudofolliculitis",
            title: "4C Bart-Trockenschnitt & Antiseptik",
            category: "Bart & Haut",
            defaultFrequency: .threeTimesAWeek,
            defaultHour: 18,
            defaultMinute: 0,
            estimatedMinutes: 10,
            clinicalRationale: "Strikte PFB- und PIH-Praevention bei 4C-Haar. JRL Trimmer niemals aufpressen (0.5 mm Stoppelrest schuetzt vor subkutanem Einwachsen). Tend Skin nur tupfen, nicht reiben. 24h-Sperre fuer BHA am Abend.",
            steps: [
                CareRoutineStep(number: 1, title: "Trockenschnitt (0.5 mm Stoppeln)", instruction: "Trockenschnitt mit JRL Diamante Trimmer ausschliesslich in Wuchsrichtung. Klinge niemals fest aufdruecken.", keyToolOrIngredient: "JRL FreshFade 2025T Trimmer"),
                CareRoutineStep(number: 2, title: "Tend Skin Antiseptikphase", instruction: "Etwas Tend Skin auf Wattepad geben. Nur punktuell auf Unterkiefer und Hals tupfen (nicht reiben!).", keyToolOrIngredient: "Tend Skin Post-Shave Solution"),
                CareRoutineStep(number: 3, title: "Barriere-Schutz", instruction: "Tend Skin 1 bis 2 Minuten trocknen lassen, danach grosszuegig CeraVe Feuchtigkeitscreme auftragen.", keyToolOrIngredient: "CeraVe Feuchtigkeitscreme")
            ],
            products: [jrlTrimmer, tendSkin, ceraveCream],
            zone: .face
        ),
        CareRoutineItem(
            id: "routine_abend_trimmtag",
            title: "Abendroutine an Trimmtagen (Kein BHA)",
            category: "Abend",
            defaultFrequency: .threeTimesAWeek,
            defaultHour: 21,
            defaultMinute: 30,
            estimatedMinutes: 10,
            clinicalRationale: "Post-Rasur Regeneration. BHA strikt weglassen wegen Tend Skin-Anwendung um 18:00 Uhr. Azelainsaeure 10% gezielt gegen PIH-Pigmentflecken.",
            steps: [
                CareRoutineStep(number: 1, title: "Sanfte Reinigung", instruction: "CeraVe Cleanser (waescht Schweiss und Sonnenschutz ab).", keyToolOrIngredient: "CeraVe Hydrating Cleanser"),
                CareRoutineStep(number: 2, title: "BHA weglassen!", instruction: "BHA weglassen! (Da um 18:00 Uhr bereits Tend Skin genutzt wurde).", keyToolOrIngredient: "24h-Saeuren-Sperre"),
                CareRoutineStep(number: 3, title: "Azelainsaeure 10%", instruction: "Eine erbsengrosse Menge Azelaic Acid 10% auf die dunklen Stellen am Unterkiefer und Hals auftragen.", keyToolOrIngredient: "Azelaic Acid 10%"),
                CareRoutineStep(number: 4, title: "Okklusive Feuchtigkeit", instruction: "CeraVe Feuchtigkeitscreme als Abschluss auftragen.", keyToolOrIngredient: "CeraVe Feuchtigkeitscreme")
            ],
            products: [ceraveCleanser, azelaicAcid, ceraveCream],
            zone: .face
        ),
        CareRoutineItem(
            id: "routine_abend_rasurfrei",
            title: "Abendroutine an rasurfreien Tagen (BHA-Peeling)",
            category: "Abend",
            defaultFrequency: .daily,
            defaultHour: 21,
            defaultMinute: 30,
            estimatedMinutes: 15,
            clinicalRationale: "Follikel-Tiefenreinigung und PIH-Behandlung an den 4 rasurfreien Abenden (Mo, Di, Do, Sa). 2% BHA klaert die Follikel, Azelainsaeure hemmt Melaninbildung.",
            steps: [
                CareRoutineStep(number: 1, title: "Sanfte Vorreinigung", instruction: "CeraVe Hydrating Cleanser auftragen, sanft einmassieren und abspuelen. Trocken tupfen.", keyToolOrIngredient: "CeraVe Hydrating Cleanser"),
                CareRoutineStep(number: 2, title: "BHA 2% Peeling", instruction: "Paula's Choice 2% BHA sanft einklopfen, 10 Minuten einziehen lassen.", keyToolOrIngredient: "Paula's Choice 2% BHA"),
                CareRoutineStep(number: 3, title: "Azelainsaeure 10%", instruction: "Eine erbsengrosse Menge Azelaic Acid 10% auf Wangen, Kiefer und Hals auftragen.", keyToolOrIngredient: "Azelaic Acid 10%"),
                CareRoutineStep(number: 4, title: "Okklusive Nachtpflege", instruction: "CeraVe Feuchtigkeitscreme als Barriere-Abschluss auftragen.", keyToolOrIngredient: "CeraVe Feuchtigkeitscreme")
            ],
            products: [ceraveCleanser, paulasChoiceBHA, azelaicAcid, ceraveCream],
            zone: .face
        ),

        // MARK: Oral Care Routines (Zahnhygiene)
        CareRoutineItem(
            id: "routine_zahnpflege_morgen",
            title: "Mund- & Zahnpflege (Morgen)",
            category: "Zahnpflege",
            defaultFrequency: .daily,
            defaultHour: 6,
            defaultMinute: 20,
            estimatedMinutes: 4,
            clinicalRationale: "Beseitigung des naechtlichen Biofilms und Neutralisation saurer Refluxrueckstaende. Zungenschaber senkt anaerobe Bakterien um 75%. Schallzahnbuerste schont bei Andruckkontrolle Zahnschmelz und Zahnfleischrand.",
            steps: [
                CareRoutineStep(number: 1, title: "Zungenreinigung (TePe Schaber)", instruction: "Zunge herausstrecken, Schaber hinten ansetzen und mit sanftem Zug 2-3 Mal nach vorne fuehren. Unter Wasser reinigen.", keyToolOrIngredient: "TePe Zungenschaber"),
                CareRoutineStep(number: 2, title: "Schallzahnbuerste (2 Minuten)", instruction: "Erbsengrosse Menge Elmex Aminfluorid auftragen. 4 Quadranten je 30 Sekunden im 45-Grad-Winkel ohne Druck reinigen.", keyToolOrIngredient: "Oral-B iO & Elmex Zahnpasta"),
                CareRoutineStep(number: 3, title: "Spucken ohne Wasserspuelung", instruction: "Zahnpasta ausspucken, Schmelz NICHT mit Wasser nachspuelen, um den Fluorid-Depoteffekt zu erhalten.", keyToolOrIngredient: "Aminfluorid-Depot")
            ],
            products: [tepeTongueCleaner, sonicToothbrush, remineralizingToothpaste],
            zone: .oral
        ),
        CareRoutineItem(
            id: "routine_zahnpflege_abend",
            title: "Mund- & Interdental-Tiefenreinigung (Abend)",
            category: "Zahnpflege",
            defaultFrequency: .daily,
            defaultHour: 21,
            defaultMinute: 45,
            estimatedMinutes: 6,
            clinicalRationale: "Gruendliche Plaquebeseitigung in den Interdentalraeumen vor der Nachtruhe. Verhindert Saeureerosionen bei stillem Reflux und schuetzt vor Karies an schwer zugaenglichen Zahnkontaktpunkten.",
            steps: [
                CareRoutineStep(number: 1, title: "Zahnseide / Interdentalreinigung", instruction: "Mit gewachster Zahnseide jeden Zahnzwischenraum vorsichtig c-foermig umschliessen und Plaque aufwaerts abstreifen.", keyToolOrIngredient: "Curaprox Dental Floss"),
                CareRoutineStep(number: 2, title: "Schallzahnbuerste (2 Minuten)", instruction: "Alle Aussen-, Innen- und Kauflaechen systematisch mit Schallvibrationen putzen.", keyToolOrIngredient: "Oral-B iO & Elmex Zahnpasta"),
                CareRoutineStep(number: 3, title: "Alkoholfreie Mundspuelung (30s)", instruction: "10 ml fluoridierte Spuelung 30 Sekunden kraeftig im Mund bewegen. Alkoholfrei schuetzt vor Schleimhautreizung.", keyToolOrIngredient: "Sensodyne Alkoholfreie Mundspuelung")
            ],
            products: [dentalFloss, sonicToothbrush, remineralizingToothpaste, antisepticMouthwash],
            zone: .oral
        ),

        // MARK: Groin & Pelvic Care (Leiste & Intimbereich)
        CareRoutineItem(
            id: "routine_intimpflege_postdienst",
            title: "Leisten- & Intimbarriere (Post-Dienst / Marsch)",
            category: "Intimpflege",
            defaultFrequency: .daily,
            defaultHour: 17,
            defaultMinute: 0,
            estimatedMinutes: 5,
            clinicalRationale: "Praevention von Intertrigo (Wolfgelaufen) unter schwerer Dienstbekleidung. Postoperative Analhygiene (BWK Ulm): Sanftes Abduschen/Bidet statt mechanischem Reiben. Saure Waschlotion (pH 3.8-5.5) schuetzt vor Pilzinfektionen.",
            steps: [
                CareRoutineStep(number: 1, title: "Sanftes Abspuelen (Wasser / Bidet)", instruction: "Leisten- und Perianalbereich mit lauwarmem Wasser schonend abspuelen. Reiben strikt vermeiden, nur sanft mit sauberem Tuch trocken tupfen.", keyToolOrIngredient: "Lauwarmes Wasser"),
                CareRoutineStep(number: 2, title: "Milde Waschlotion (pH 3.8 / 5.5)", instruction: "Sebamed Intimwaschlotion sparsam in den Leistenfalten aufschäumen und rueckstandslos abspuelen.", keyToolOrIngredient: "Sebamed Intim-Waschlotion"),
                CareRoutineStep(number: 3, title: "Anti-Chafing / Wundschutzbarriere", instruction: "Vor langen Maerschen oder bei Reizungen BodyGlide Stick oder duenn Panthenol auftragen.", keyToolOrIngredient: "BodyGlide Balm / Bepanthen"),
                CareRoutineStep(number: 4, title: "Atmungsaktive Unterwaesche", instruction: "Frische, lockere Baumwollunterwaesche anziehen, um Feuchtigkeitsstau zu vermeiden.", keyToolOrIngredient: "100% Baumwollwaesche")
            ],
            products: [sebamedIntimate, antiChafingBalm, panthenolBarrierCream],
            zone: .groin
        ),

        // MARK: Nails & Combat Boot Feet (Naegel & Fuesse)
        CareRoutineItem(
            id: "routine_nagel_fusspflege_woche",
            title: "Nagel- & Fussdrill (Bundeswehr Marschschutz)",
            category: "Nagel- & Fusspflege",
            defaultFrequency: .weekly,
            defaultHour: 19,
            defaultMinute: 30,
            estimatedMinutes: 10,
            clinicalRationale: "Strikte Verhinderung von Unguis incarnatus (eingewachsenen Zehennaegeln) und Tinea pedis (Fusspilz) im Kampfstiefel. Zehennaegel muessen gerade geschnitten werden. Urea 10-15% loest Verhornungen schmerzfrei auf.",
            steps: [
                CareRoutineStep(number: 1, title: "Zehennaegel gerade kuerzen", instruction: "Zehennaegel mit dem Edelstahl-Knipser strikt gerade kuerzen. Ecken NIEMALS rund ausschneiden!", keyToolOrIngredient: "Victorinox Edelstahl Knipser"),
                CareRoutineStep(number: 2, title: "Kanten mit Glasfeile versiegeln", instruction: "Mit der Glasnagelfeile feine Grate und Kanten sanft glaetten, um Reibung an Socken zu eliminieren.", keyToolOrIngredient: "Mont Bleu Glasnagelfeile"),
                CareRoutineStep(number: 3, title: "Fingernaegel formen & Nagelbett-Oel", instruction: "Fingernaegel militaerisch kurz und sauber feilen. Einen Tropfen Vitamin-E Oel auf die Nagelfalz einmassieren.", keyToolOrIngredient: "Sally Hansen Cuticle Oil"),
                CareRoutineStep(number: 4, title: "Urea 15% Hornhautpflege", instruction: "UreaRepair Fusscreme grosszuegig auf Fersen und Fussballen einmassieren, um Marschblasen vorzubeugen.", keyToolOrIngredient: "Eucerin Urea 15% Fussbalsam")
            ],
            products: [nailClipperSet, glassNailFile, nailCuticleOil, ureaFootCream],
            zone: .nails
        ),

        // MARK: Hair & Scalp Routines (Haarpflege)
        CareRoutineItem(
            id: "routine_haare_4c",
            title: "Afro 4C Haarpflege (LOC-Methode)",
            category: "Haare",
            defaultFrequency: .threeTimesAWeek,
            defaultHour: 20,
            defaultMinute: 0,
            estimatedMinutes: 12,
            clinicalRationale: "Gezielte Hydratation fuer hochporoeses 4C-Haar. Die LOC-Methode bindet Feuchtigkeit dauerhaft und verhindert mechanischen Haarbruch unter Helmen und Muetzen.",
            steps: [
                CareRoutineStep(number: 1, title: "Liquid (Feuchtigkeit)", instruction: "Haare mit lauwarmem Wasser oder Aloe-Vera-Wasser leicht einspruehen.", keyToolOrIngredient: "Feuchtigkeitsspray"),
                CareRoutineStep(number: 2, title: "Oil (Kopfhaut-Versiegelung)", instruction: "Mielle Rosemary Mint Oel direkt auf die Kopfhaut geben und 2 Minuten einmassieren.", keyToolOrIngredient: "Mielle Rosemary Mint Oil"),
                CareRoutineStep(number: 3, title: "Cream (Schaftversiegelung)", instruction: "Cantu Leave-in Creme im Haar verteilen und an den Spitzen mit Jamaican Castor Oil versiegeln.", keyToolOrIngredient: "Cantu Leave-In & Castor Oil"),
                CareRoutineStep(number: 4, title: "Satin Durag anlegen", instruction: "Vor der Nachtruhe Seiden-Satin Durag anlegen, um Reibungsentzug auf Kissen zu verhindern.", keyToolOrIngredient: "Satin Durag")
            ],
            products: [mielleOil, cantuLeaveIn, sheaMoistureCastor, satinDurag],
            zone: .hair
        ),
        CareRoutineItem(
            id: "routine_haare_4c_washday",
            title: "4C Scalp Detox & Tiefenpflege (Wash Day)",
            category: "Haare",
            defaultFrequency: .weekly,
            defaultHour: 19,
            defaultMinute: 0,
            estimatedMinutes: 20,
            clinicalRationale: "Woechentliche Tiefenreinigung der 4C-Kopfhaut von Talg, Schweiss und Oelablagerungen. Sulfatfreies Shampoo schuetzt die Feuchtigkeitsbarriere, Tiefenmaske restrukturiert die Schuppenschicht.",
            steps: [
                CareRoutineStep(number: 1, title: "Sulfatfreie Kopfhautreinigung", instruction: "Mielle Shampoo sanft mit den Fingerbeeren kreisend in die Kopfhaut einmassieren und gruendlich ausspuelen.", keyToolOrIngredient: "Mielle Detangling Shampoo"),
                CareRoutineStep(number: 2, title: "Intensive Tiefenmaske (10 Min)", instruction: "SheaMoisture Masque von den Wurzeln bis in die Spitzen verteilen. 10 Minuten unter Duschhaube einwirken lassen.", keyToolOrIngredient: "SheaMoisture Manuka Masque"),
                CareRoutineStep(number: 3, title: "Kalt/Lauwarm ausspuelen", instruction: "Maske gruendlich ausspuelen, um die Schuppenschicht zu schliessen.", keyToolOrIngredient: "Lauwarmes Wasser"),
                CareRoutineStep(number: 4, title: "LOC-Versiegelung & Durag", instruction: "Unmittelbar Liquid, Mielle Oel und Leave-In auftragen, danach Durag anlegen.", keyToolOrIngredient: "LOC-Produkte & Satin Durag")
            ],
            products: [sulfateFreeShampoo, deepConditionerMasque, mielleOil, cantuLeaveIn, satinDurag],
            zone: .hair
        ),

        // MARK: Body & Tactical Gear Reset
        CareRoutineItem(
            id: "routine_koerper_tactical_reset",
            title: "Ganzkoerper Dusch- & Follikelschutz",
            category: "Koerperpflege",
            defaultFrequency: .daily,
            defaultHour: 17,
            defaultMinute: 15,
            estimatedMinutes: 8,
            clinicalRationale: "Verhinderung von Acne Mechanica und Rumpf-Follikulitis durch schwere Trageausruestung, Plattentraeger und Rucksaecke. Schnelle Entfernung von getrocknetem Salz und Schweiss schuetzt die Follikeloeffnungen.",
            steps: [
                CareRoutineStep(number: 1, title: "Schweisssalze abspuelen", instruction: "Nach Dienst und Sport lauwarm duschen, heisses Wasser zur Vermeidung von TEWL vermeiden.", keyToolOrIngredient: "Lauwarmes Wasser"),
                CareRoutineStep(number: 2, title: "Milde Waschlotion auf Schultern & Ruecken", instruction: "CeraVe Reinigungslotion sanft ueber Schultern, Ruecken und Brust verteilen und abspuelen.", keyToolOrIngredient: "CeraVe Hydrating Cleanser"),
                CareRoutineStep(number: 3, title: "Sanftes Trockentupfen", instruction: "Mit frischem Handtuch trocken tupfen, kein aggressives Scheuern an beanspruchten Stellen.", keyToolOrIngredient: "Sauberes Handtuch")
            ],
            products: [ceraveCleanser, ceraveCream],
            zone: .body
        ),

        // MARK: Equipment / Kasernen Routine
        CareRoutineItem(
            id: "routine_kulturbeutel",
            title: "Dienst- & Reise-Kulturbeutel",
            category: "Kulturbeutel",
            defaultFrequency: .weekly,
            defaultHour: 19,
            defaultMinute: 0,
            estimatedMinutes: 5,
            clinicalRationale: "Vollstaendigkeit der Pflegeartikel fuer Uebungsplatz, Kaserne und Spind. Sicherstellung eines permanenten Spind-Depots fuer La Roche-Posay SPF 50+.",
            steps: [
                CareRoutineStep(number: 1, title: "Reisebehaelter pruefen", instruction: "Fuellstand der 100ml Silikonflaschen mit CeraVe Cleanser und Feuchtigkeitscreme kontrollieren.", keyToolOrIngredient: "100ml Silikonflaschen"),
                CareRoutineStep(number: 2, title: "Equipment-Check", instruction: "JRL Diamante Trimmer auf volle Akkuladung und Reinigung der Klingen pruefen.", keyToolOrIngredient: "JRL Trimmer & Ladekabel"),
                CareRoutineStep(number: 3, title: "Spind-Depot & Wirkstoff-Check", instruction: "1 Flasche LRP Anthelios SPF 50+ dauerhaft im Kasernenspind/Uniformtasche deponieren.", keyToolOrIngredient: "LRP Anthelios SPF 50+ Spind-Depot")
            ],
            products: [travelBottles, jrlTrimmer, paulasChoiceBHA, lrpSunscreen],
            zone: .chores
        )
    ]

    public static func isRoutineScheduled(_ routine: CareRoutineItem, on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch routine.id {
        case "routine_bart_pseudofolliculitis":
            return weekday == 4 || weekday == 6 || weekday == 1 // Mi, Fr, So
        case "routine_abend_trimmtag":
            return weekday == 4 || weekday == 6 || weekday == 1 // Mi, Fr, So
        case "routine_abend_rasurfrei":
            return weekday == 2 || weekday == 3 || weekday == 5 || weekday == 7 // Mo, Di, Do, Sa
        case "routine_haare_4c":
            return weekday == 4 || weekday == 6 || weekday == 1 // Mi, Fr, So
        case "routine_haare_4c_washday":
            return weekday == 1 // Sonntag
        case "routine_nagel_fusspflege_woche":
            return weekday == 1 // Sonntag
        case "routine_kulturbeutel":
            return weekday == 1 // Sonntag
        case "routine_zahnpflege_morgen", "routine_zahnpflege_abend":
            return true
        case "routine_intimpflege_postdienst", "routine_koerper_tactical_reset":
            return true
        default:
            switch routine.defaultFrequency {
            case .daily, .twiceDaily: return true
            case .threeTimesAWeek: return weekday == 4 || weekday == 6 || weekday == 1
            case .weekly: return weekday == 1
            case .monthly: return Calendar.current.component(.day, from: date) == 1
            }
        }
    }
}
