import Foundation

// MARK: - Chore Frequency
public enum ChoreFrequency: String, CaseIterable, Codable, Identifiable {
    case daily = "Taeglich"
    case everyTwoDays = "Alle 2 Tage"
    case everyThreeDays = "Alle 3 Tage"
    case twiceAWeek = "2x pro Woche"
    case weekly = "Woechentlich"
    case biweekly = "Alle 2 Wochen"
    case monthly = "Monatlich"

    public var id: String { rawValue }

    public var descriptionText: String {
        switch self {
        case .daily: return "Jeden Tag zur festgelegten Uhrzeit"
        case .everyTwoDays: return "Alle 48 Stunden"
        case .everyThreeDays: return "Alle 72 Stunden (z. B. Di / Fr / Mo)"
        case .twiceAWeek: return "Dienstag und Freitag"
        case .weekly: return "Einmal woechentlich (Sonntag)"
        case .biweekly: return "Alle 14 Tage"
        case .monthly: return "Einmal monatlich (Monatsanfang)"
        }
    }
}

// MARK: - Chore Step
public struct ChoreStep: Identifiable, Hashable, Codable {
    public var id: String
    public var number: Int
    public var title: String
    public var instruction: String
    public var equipmentOrTool: String

    public init(
        id: String = UUID().uuidString,
        number: Int,
        title: String,
        instruction: String,
        equipmentOrTool: String
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.instruction = instruction
        self.equipmentOrTool = equipmentOrTool
    }
}

// MARK: - Chore Routine Item
public struct ChoreRoutineItem: Identifiable, Hashable, Codable {
    public var id: String
    public var title: String
    public var category: String
    public var icon: String
    public var defaultFrequency: ChoreFrequency
    public var reminderHour: Int
    public var reminderMinute: Int
    public var estimatedMinutes: Int
    public var rationale: String
    public var steps: [ChoreStep]
    public var isNotificationEnabled: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        category: String,
        icon: String = "checklist",
        defaultFrequency: ChoreFrequency = .weekly,
        reminderHour: Int = 17,
        reminderMinute: Int = 0,
        estimatedMinutes: Int = 15,
        rationale: String = "",
        steps: [ChoreStep] = [],
        isNotificationEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.icon = icon
        self.defaultFrequency = defaultFrequency
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.estimatedMinutes = estimatedMinutes
        self.rationale = rationale
        self.steps = steps
        self.isNotificationEnabled = isNotificationEnabled
    }

    public var shortTitle: String {
        switch id {
        case "chore_room_airing": return "Stube lueften"
        case "chore_mittag_lueften_klarschiff": return "Mittags-Lueften & Klarschiff"
        case "chore_muell_hygiene": return "Muell & Spind-Hygiene"
        case "chore_laundry_wash": return "Waesche waschen"
        case "chore_laundry_dry": return "Waesche & Spind"
        case "chore_stube_clean": return "Stube reinigen"
        case "chore_bed_sheet_change": return "Bettwaesche wechseln"
        case "chore_military_equipment": return "Ausruestung & Stiefel"
        default: return title
        }
    }
}

// MARK: - Chore Catalog Seed Data (Zero CPAP Desinfektion Architecture)
public enum ChoreCatalogData {
    public static let allChores: [ChoreRoutineItem] = [
        ChoreRoutineItem(
            id: "chore_room_airing",
            title: "Morgen-Stosslueften",
            category: "Stube & Raum",
            icon: "wind",
            defaultFrequency: .daily,
            reminderHour: 6,
            reminderMinute: 0,
            estimatedMinutes: 5,
            rationale: "Luftaustausch zur Senkung von Feuchtigkeit und CO2 direkt nach dem Aufstehen.",
            steps: [
                ChoreStep(number: 1, title: "Fenster ganz oeffnen", instruction: "Fenster fuer 5 bis 10 Minuten vollstaendig oeffnen (Stosslueften, kein Kippfenster).", equipmentOrTool: "Fenstergriff"),
                ChoreStep(number: 2, title: "Bett lueften", instruction: "Bettdecke zurueckschlagen, damit Feuchtigkeit aus Matratze und Bezug entweichen kann.", equipmentOrTool: "Bettdecke")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_mittag_lueften_klarschiff",
            title: "Mittags-Lueften & Schreibtisch-Klarschiff",
            category: "Stube & Raum",
            icon: "wind",
            defaultFrequency: .daily,
            reminderHour: 13,
            reminderMinute: 0,
            estimatedMinutes: 5,
            rationale: "Stosslueften zur Senkung des CO2-Pegels und Schreibtisch freiraeumen fuer klaren Arbeitsfokus.",
            steps: [
                ChoreStep(number: 1, title: "Fenster oeffnen", instruction: "5-10 Minuten Stosslueften.", equipmentOrTool: "Fenstergriff"),
                ChoreStep(number: 2, title: "Schreibtischklaerung", instruction: "Gebrauchte Notizen und Geraete ordnen.", equipmentOrTool: "Schreibtischablage")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_muell_hygiene",
            title: "Muellentsorgung & Spind-Hygiene",
            category: "Stube & Raum",
            icon: "trash.fill",
            defaultFrequency: .daily,
            reminderHour: 18,
            reminderMinute: 15,
            estimatedMinutes: 5,
            rationale: "Taegliche Leerung organischer und Restabfaelle zur Einhaltung der Kasernen-Stubenvorschrift.",
            steps: [
                ChoreStep(number: 1, title: "Muelleimer leeren", instruction: "Restmuellbeutel verknoten und zur Kasernen-Entsorgungsstation bringen.", equipmentOrTool: "Muellbeutel"),
                ChoreStep(number: 2, title: "Neuen Beutel einsetzen", instruction: "Eimer feucht auswischen und frischen Beutel einsetzen.", equipmentOrTool: "Frischer Abfallbeutel")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_military_equipment",
            title: "Militaerische Ausruestung & Kampfstiefel",
            category: "Militaer & Ausruestung",
            icon: "shield.fill",
            defaultFrequency: .weekly,
            reminderHour: 16,
            reminderMinute: 45,
            estimatedMinutes: 25,
            rationale: "Sichert Einsatzbereitschaft, Vollzaehligkeit und Materialerhalt gemaess Dienstvorschrift.",
            steps: [
                ChoreStep(number: 1, title: "Kampfstiefel reinigen & polieren", instruction: "Groben Schmutz abbuersten, Lederpflege einarbeiten und mit Glanzbuerste polieren.", equipmentOrTool: "Schuhputzzeug & Ledercreme"),
                ChoreStep(number: 2, title: "Tragesatz & Koppel pruefen", instruction: "Verschluesse, Taschen und Riemen auf Beschaedigungen und Vollstaendigkeit pruefen.", equipmentOrTool: "Koppel / Chestrig"),
                ChoreStep(number: 3, title: "Gefechtshelm & Brille saeubern", instruction: "Helmbezug richten, Schutzbrille mit Optiktuch staub- und fettfrei wischen.", equipmentOrTool: "Mikrofasertuch"),
                ChoreStep(number: 4, title: "Packordnung herstellen", instruction: "Dienstrucksack gemaess Alarmpackplan ordnen und griffbereit im Spind platzieren.", equipmentOrTool: "Einsatzrucksack")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_stube_clean",
            title: "Stubenboden & Flaechenreinigung",
            category: "Stube & Raum",
            icon: "sparkles",
            defaultFrequency: .twiceAWeek,
            reminderHour: 17,
            reminderMinute: 0,
            estimatedMinutes: 20,
            rationale: "Gruendliche Reinigung zur Vorbereitung auf die woechentliche Stubeninspektion durch den Spiess.",
            steps: [
                ChoreStep(number: 1, title: "Flaechen entstauben", instruction: "Schreibtisch, Fensterbank und Spindoberkanten mit nebelfeuchtem Tuch abwischen.", equipmentOrTool: "Mikrofasertuch & Allzweckreiniger"),
                ChoreStep(number: 2, title: "Boden fegen & saugen", instruction: "Groben Schmutz und Staub vollstaendig aufnehmen, insbesondere unter dem Bett.", equipmentOrTool: "Besen oder Staubsauger"),
                ChoreStep(number: 3, title: "Boden feucht wischen", instruction: "Mit Wischmop und Desinfektionsreiniger kantenrein wischen und trocknen lassen.", equipmentOrTool: "Bodenwischer & Eimer")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_laundry_wash",
            title: "Dienstwaesche & Sportbekleidung waschen",
            category: "Waesche & Spind",
            icon: "washer.fill",
            defaultFrequency: .twiceAWeek,
            reminderHour: 17,
            reminderMinute: 30,
            estimatedMinutes: 10,
            rationale: "Hygienische Reinigung schweissgetraenkter Trainingsbekleidung und Kasernenkleidung bei 60 Grad.",
            steps: [
                ChoreStep(number: 1, title: "Waesche sortieren", instruction: "Funktionskleidung und Baumwolle trennen, Waschtrommel befuellen.", equipmentOrTool: "Waeschekorb"),
                ChoreStep(number: 2, title: "Waschgang starten", instruction: "Waschmittel dosieren und 60-Grad-Hygieneprogramm starten.", equipmentOrTool: "Hygienewaschmittel")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_laundry_dry",
            title: "Waesche falten & Kantenreine Spindordnung",
            category: "Waesche & Spind",
            icon: "tshirt.fill",
            defaultFrequency: .twiceAWeek,
            reminderHour: 19,
            reminderMinute: 30,
            estimatedMinutes: 15,
            rationale: "Exakte Faltung der Dienstkleidung gemaess militaerischem Spind-Ordnungsplan.",
            steps: [
                ChoreStep(number: 1, title: "Trockner leeren", instruction: "Waesche direkt nach Programmende entnehmen, um Faltenbildung zu verhindern.", equipmentOrTool: "Waeschestapel"),
                ChoreStep(number: 2, title: "Kantenrein falten", instruction: "T-Shirts und Hosen auf DIN A4 Schablonenmass falten und bündig im Spind stapeln.", equipmentOrTool: "Faltschablone")
            ],
            isNotificationEnabled: true
        ),
        ChoreRoutineItem(
            id: "chore_bed_sheet_change",
            title: "Bettwaesche wechseln & Kantenreines Aufschlagen",
            category: "Stube & Raum",
            icon: "bed.double.fill",
            defaultFrequency: .weekly,
            reminderHour: 9,
            reminderMinute: 30,
            estimatedMinutes: 15,
            rationale: "Woechentlicher Wechsel von Kissen- und Deckenbezug zur Hausstaub- und Allergenreduktion.",
            steps: [
                ChoreStep(number: 1, title: "Alte Bezuege abziehen", instruction: "Kissen- und Bettdeckenbezug abziehen und in die Kochwaesche geben.", equipmentOrTool: "Alte Bettwaesche"),
                ChoreStep(number: 2, title: "Matratzenschoner lueften", instruction: "Matratzenauflage absaugen und Matratze wenden.", equipmentOrTool: "Staubsauger"),
                ChoreStep(number: 3, title: "Frische Bezuege aufziehen", instruction: "Spannbettlaken und frische Bezuege aufziehen, Bettdecke militaerisch kantenrein aufschlagen.", equipmentOrTool: "Frische Bezuege")
            ],
            isNotificationEnabled: true
        )
    ]

    public static func isChoreScheduled(_ chore: ChoreRoutineItem, on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch chore.id {
        case "chore_room_airing", "chore_mittag_lueften_klarschiff", "chore_muell_hygiene":
            return true
        case "chore_stube_clean":
            return weekday == 3 || weekday == 6 // Di, Fr
        case "chore_laundry_wash", "chore_laundry_dry":
            return weekday == 3 || weekday == 6 // Di, Fr
        case "chore_military_equipment":
            return weekday == 6 // Fr
        case "chore_bed_sheet_change":
            return weekday == 1 // So
        default:
            switch chore.defaultFrequency {
            case .daily: return true
            case .twiceAWeek: return weekday == 3 || weekday == 6
            case .everyTwoDays:
                let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
                return dayOfYear % 2 == 0
            case .everyThreeDays:
                let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
                return dayOfYear % 3 == 0
            case .weekly: return weekday == 1
            case .biweekly:
                let weekOfYear = Calendar.current.component(.weekOfYear, from: date)
                return weekOfYear % 2 == 0 && weekday == 1
            case .monthly: return Calendar.current.component(.day, from: date) == 1
            }
        }
    }
}

