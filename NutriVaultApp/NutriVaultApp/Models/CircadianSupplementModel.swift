import Foundation

public struct CircadianSupplementDose: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let dosage: String
    public let scheduledTime: String // e.g. "06:00"
    public let mechanism: String
    public let benefit: String
    public let targetArea: String
    public let instructions: String
    public let shortTermImpact: String
    public let longTermImpact: String
    public let noviceExplanation: String
    public let kcal: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let fiber: Double

    public init(
        id: String,
        name: String,
        dosage: String,
        scheduledTime: String,
        mechanism: String,
        benefit: String,
        targetArea: String,
        instructions: String,
        shortTermImpact: String = "",
        longTermImpact: String = "",
        noviceExplanation: String = "",
        kcal: Double = 0.0,
        protein: Double = 0.0,
        carbs: Double = 0.0,
        fat: Double = 0.0,
        fiber: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.scheduledTime = scheduledTime
        self.mechanism = mechanism
        self.benefit = benefit
        self.targetArea = targetArea
        self.instructions = instructions
        self.shortTermImpact = shortTermImpact
        self.longTermImpact = longTermImpact
        self.noviceExplanation = noviceExplanation
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
    }

    public var shortName: String {
        switch id {
        case "supp_rhodiola_0600": return "Rhodiola Rosea"
        case "supp_mg_malat_0630": return "Mg-Malat"
        case "supp_beta_alanin_1_0800": return "Beta-Alanin 1/4"
        case "supp_vit_d3_k2_1145": return "Vit D3 + K2"
        case "supp_beta_alanin_2_1200": return "Beta-Alanin 2/4"
        case "supp_rote_bete_1600": return "Rote Bete"
        case "supp_omega3_1645": return "Omega-3"
        case "supp_beta_alanin_3_1645": return "Beta-Alanin 3/4"
        case "supp_beta_alanin_4_2000": return "Beta-Alanin 4/4"
        case "supp_mg_bisglycinat_2100": return "Mg-Bisglycinat"
        default: return name
        }
    }
}

public struct CircadianSupplementProtocol {
    public static let dailySchedule: [CircadianSupplementDose] = [
        CircadianSupplementDose(
            id: "supp_rhodiola_0600",
            name: "Rhodiola Rosea (3% Salidrosid)",
            dosage: "500 mg",
            scheduledTime: "06:00",
            mechanism: "Moduliert Neurotransmitter (Dopamin/Serotonin) und senkt Cortisolspitzen",
            benefit: "Bekämpft morgendliche Trägheit und schützt vor mentaler Erschöpfung",
            targetArea: "Dopamin & Fokus",
            instructions: "30 Min. vor dem Frühstück auf nüchternen Magen mit stillem Wasser",
            shortTermImpact: "Wirkt nach ca. 30 bis 60 Minuten: Hemmt den Abbau von Dopamin und Serotonin im Gehirn. Du fühlst dich rascher wach, gedanklich klarer und fokussierter, ohne die zittrige Nervosität oder den Herzrasen-Effekt von hohem Koffeinkonsum.",
            longTermImpact: "Wirkt als kraftvolles pflanzliches Adaptogen über Wochen: Trainiert dein Stress-System (HPA-Achse). Dein Körper schüttet bei hoher mentaler oder körperlicher Belastung im Dienst weniger schädliches Cortisol aus. Schützt nachhaltig vor Burnout und chronischer Erschöpfung.",
            noviceExplanation: "Ein natürlicher Pflanzenextrakt aus den Bergen, der deine Laune und deinen Antrieb anschiebt. Morgens genommen, hilft er dir schnell in Schwung zu kommen und macht deinen Kopf widerstandsfähig gegen stressige Situationen.",
            kcal: 2.0,
            protein: 0.0,
            carbs: 0.4,
            fat: 0.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_mg_malat_0630",
            name: "Magnesium-Malat",
            dosage: "1.000 mg (150 mg elementar)",
            scheduledTime: "06:30",
            mechanism: "Apfelsäure (Malat) speist direkt den mitochondrialen Citratzyklus zur ATP-Bildung",
            benefit: "Liefert zelluläre Grundenergie am Morgen und entspannt die Muskulatur magenschonend",
            targetArea: "ATP-Synthese & Energie",
            instructions: "Direkt zum Frühstück mit stillem Wasser einnehmen",
            shortTermImpact: "Wird vom Magen-Darm-Trakt extrem schonend aufgenommen ohne abführende Wirkung. Die gebundene Apfelsäure (Malat) fließt direkt in deine Zellkraftwerke (Mitochondrien) und unterstützt die Umwandlung von Nahrung in sofort nutzbare Muskel- und Nervenenergie.",
            longTermImpact: "Füllt über Wochen deine geleerten intrazellulären Magnesiumspeicher in Muskeln, Nerven und Knochen auf. Normalisiert den Muskeltonus, verhindert quälende Wadenkrämpfe und stabilisiert den Blutzucker- und Energiestoffwechsel.",
            noviceExplanation: "Magnesium gebunden an natürliche Apfelsäure. Im Gegensatz zu billigem Brausetabletten-Magnesium schlägt es nicht auf den Magen, sondern schenkt deinen Muskeln und Organen frische Energie für den Dienst.",
            kcal: 2.0,
            protein: 0.0,
            carbs: 0.5,
            fat: 0.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_beta_alanin_1_0800",
            name: "Beta-Alanin (Dosis 1/4)",
            dosage: "1.500 mg",
            scheduledTime: "08:00",
            mechanism: "Baut intramuskuläres Carnosin auf und puffert saure Wasserstoff-Ionen (H+)",
            benefit: "Zögert Muskelübersäuerung und Brennen bei hoher Belastung hinaus",
            targetArea: "Muskel-Säurepuffer",
            instructions: "Mit mindestens 200 ml Wasser oder Tee einnehmen",
            shortTermImpact: "Wird innerhalb von 20 bis 40 Minuten ins Blut aufgenommen. Kann ein harmloses, leichtes Kribbeln unter der Haut (Parästhesie) erzeugen. Die Aminosäure wandert direkt in deine Skelettmuskeln, um für die Carnosin-Produktion bereitgestellt zu werden.",
            longTermImpact: "Kontinuierliche Einnahme über 4 bis 6 Wochen verdoppelt den Carnosin-Gehalt in deinen Muskelfasern. Dieser Carnosin-Puffer fängt die brennende Milchsäure bei Liegestützen, Sprints und Märschen ab: Du schaffst messbar 2 bis 4 Wiederholungen mehr, bevor der Muskel versagt.",
            noviceExplanation: "Ein körpereigener Baustein, der wie ein Feuerlöscher gegen das Brennen in den Muskeln wirkt. Bei harter Anstrengung übersäuern deine Muskeln viel langsamer.",
            kcal: 6.0,
            protein: 1.5,
            carbs: 0.0,
            fat: 0.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_vit_d3_k2_1145",
            name: "Vitamin D3 + K2 (MK-7)",
            dosage: "5.000 IE D3 + 200 mcg K2",
            scheduledTime: "11:45",
            mechanism: "D3 fördert enterale Calcium-Absorption; K2 aktiviert Osteocalcin für Knocheneinbau",
            benefit: "Maximale Gewebeheilung nach OP, stabile Knochendichte und robustes Immunsystem",
            targetArea: "Knochen & Gewebeschutz",
            instructions: "Strikte Einmalgabe zum Mittagessen mit gesunden Fetten zur optimalen Fettlöslichkeit",
            shortTermImpact: "Wird gemeinsam mit den Fetten des Mittagessens resorbiert. Reguliert innerhalb von Stunden die Genexpression für Entzündungshemmung und signalisiert den Darmzellen, Calcium optimal ins Blut aufzunehmen.",
            longTermImpact: "Vitamin D3 steuert über 1.000 Gene für Immunität, Testosteron und Muskelkraft. Vitamin K2 (in hochwertiger all-trans MK-7 Form) fungiert als biologischer Lotse: Es sorgt dafür, dass Calcium gezielt in die Knochen und Zähne wandert und sich NIEMALS als Plaque in den Arterienwänden ablagert.",
            noviceExplanation: "Das Sonnen-Vitamin im Doppelpack mit K2. Da wir die meiste Zeit in Kasernen oder Innenräumen verbringen, ist dieser Speicher oft leer. D3 stärkt deine Abwehrkräfte und Muskeln, während K2 dafür sorgt, dass deine Knochen bombenfest bleiben.",
            kcal: 9.0,
            protein: 0.0,
            carbs: 0.0,
            fat: 1.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_beta_alanin_2_1200",
            name: "Beta-Alanin (Dosis 2/4)",
            dosage: "1.500 mg",
            scheduledTime: "12:00",
            mechanism: "Aufrechterhaltung konstanter Aminosäurenspiegel im Blut zur Carnosin-Synthese",
            benefit: "Verteiltes Dosierungsschema verhindert Kribbeln und sichert maximale Muskelaufnahme",
            targetArea: "Muskel-Säurepuffer",
            instructions: "Direkt zum Mittagessen mit Flüssigkeit einnehmen",
            shortTermImpact: "Hält den Beta-Alanin-Spiegel im Blutkreislauf nach der Mittagsmahlzeit hoch. Durch die Aufteilung auf 4 Einzeldosen wird die Aufnahme in die Muskelzellen maximiert, ohne dass überschüssiges Beta-Alanin ungenutzt über die Nieren ausgeschieden wird.",
            longTermImpact: "Führt nach 2 bis 3 Wochen zur vollständigen Sättigung der Muskelspeicher. Deine Schnellkraft- und Kraftausdauerleistungen im Sport steigen kontinuierlich an.",
            noviceExplanation: "Die zweite Teilportion deines Muskelschutz-Bausteins. Durch die Aufteilung über den Tag verteilt nimmt dein Körper den Wirkstoff viel besser auf, als wenn du alles auf einmal schlucken würdest.",
            kcal: 6.0,
            protein: 1.5,
            carbs: 0.0,
            fat: 0.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_rote_bete_1600",
            name: "Rote-Bete-Saft (NO3- Booster)",
            dosage: "140 ml Konzentrat",
            scheduledTime: "16:00",
            mechanism: "Enterosalivaler Nitrat-Nitrit-NO-Zyklus führt zu gefäßerweiternder Vasodilation",
            benefit: "Erweitert Blutgefäße, senkt Blutdruck und steigert Sauerstoffaufnahme (VO2max)",
            targetArea: "Vasodilation & VO2max",
            instructions: "Ca. 2 Stunden vor dem Belastungsfenster oder Sport trinken; Mund nicht mit Mundspülung spülen",
            shortTermImpact: "Bakterien auf deiner Zunge wandeln das Nitrat in Nitrit um, das im Blut zu Stickstoffmonoxid (NO) wird. Nach 90 bis 120 Minuten weiten sich deine Blutgefäße spürbar: Mehr Blut, Sauerstoff und Nährstoffe strömen in die Muskeln. Du spürst einen kräftigen Pump beim Training und deine Herzfrequenz sinkt bei gleicher Belastung.",
            longTermImpact: "Erhöht deine maximale Sauerstoffaufnahme (VO2max) nachhaltig, weil deine Mitochondrien bei gleicher Watt- oder Laufleistung bis zu 5% weniger Sauerstoff verbrauchen. Unterstützt elastische, gesunde Gefäßwände und schützt Herz und Nieren.",
            noviceExplanation: "Ein natürlicher Powersaft für deine Blutbahnen. Er macht die Adern weit auf, damit dein Blut ungehindert strömen kann. Dein Herz muss weniger pumpen, und deine Muskeln bekommen viel mehr Sauerstoff beim Sport.",
            kcal: 78.0,
            protein: 2.2,
            carbs: 16.8,
            fat: 0.2,
            fiber: 1.4
        ),
        CircadianSupplementDose(
            id: "supp_beta_alanin_3_1600",
            name: "Beta-Alanin (Dosis 3/4)",
            dosage: "1.500 mg",
            scheduledTime: "16:00",
            mechanism: "Pre-Workout Vorbereitung: Erhöhte Bereitstellung von Substrat für die Muskelarbeit",
            benefit: "Optimaler Schutz vor anaerober Muskelerschöpfung im Nachmittags-Trainingsfenster",
            targetArea: "Muskel-Säurepuffer",
            instructions: "Zusammen mit dem Rote-Bete-Saft ca. 45 Min. vor dem Sport einnehmen",
            shortTermImpact: "Füllt die zellulären Puffer unmittelbar vor der anstehenden sportlichen Belastung auf, sodass der Muskel beim Krafttraining oder Intervalllauf sofort auf aktive Säurepuffer zugreifen kann.",
            longTermImpact: "Stabilisiert den Carnosingehalt in schnell zuckenden Muskelfasern (Typ II), die für Sprints und schwere Gewichte verantwortlich sind.",
            noviceExplanation: "Die dritte Portion vor dem Training. Sie sorgt dafür, dass deine Muskeln genau dann voll einsatzbereit sind, wenn du nach Dienstschluss ins Workout startest.",
            kcal: 6.0,
            protein: 1.5,
            carbs: 0.0,
            fat: 0.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_omega3_1645",
            name: "Omega-3 (EPA/DHA Triglycerid-Form)",
            dosage: "2.000 mg (hohe EPA/DHA Konzentration)",
            scheduledTime: "16:45",
            mechanism: "Einbau in Zellmembran-Phospholipide, Synthese von antientzündlichen Resolvinen",
            benefit: "Steigert Dopamin-Rezeptor-Dichte, hemmt stille Entzündungen und schützt Herz & Gehirn",
            targetArea: "Neuronale Membranen & Herz",
            instructions: "Direkt zum Abendessen mit fester Nahrung einnehmen",
            shortTermImpact: "Wird über das Lymphsystem resorbiert und hemmt akute Entzündungsbotenstoffe im Blut, die nach intensivem Training entstehen. Verhindert Gelenksteifigkeit und fördert die Erholung des Gewebes.",
            longTermImpact: "Die Fettsäuren EPA und DHA bauen sich direkt in die Doppelmembranen all deiner Gehirn- und Nervenzellen ein. Dies macht die Zellwände geschmeidig: Dopamin und Serotonin können viel besser an ihren Rezeptoren andocken (essentiell bei AuDHD für klaren Fokus). Zudem sinken schädliche Triglyceride im Blut drastisch.",
            noviceExplanation: "Hochwertiges Fischöl in reinster Form. Stell es dir wie frisches Schmieröl für dein Gehirn und deine Gelenke vor. Es beruhigt Entzündungen im Körper und hilft deinem Gehirn, Gedanken besser zu ordnen und konzentriert zu bleiben.",
            kcal: 18.0,
            protein: 0.0,
            carbs: 0.0,
            fat: 2.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_beta_alanin_4_2000",
            name: "Beta-Alanin (Dosis 4/4)",
            dosage: "1.500 mg",
            scheduledTime: "20:00",
            mechanism: "Abschluss der täglichen 6.000 mg Gesamtsättigungs-Dosis",
            benefit: "Vollständige Abdeckung des 24h-Bedarfs für maximale intramuskuläre Carnosin-Dichte",
            targetArea: "Muskel-Säurepuffer",
            instructions: "Mit einem Glas stillem Wasser am Abend einnehmen",
            shortTermImpact: "Sichert die nächtliche Regeneration der beanspruchten Muskeln, indem der Baustein für Reparatur- und Pufferprozesse im Schlaf bereitsteht.",
            longTermImpact: "Hält deine Carnosin-Werte dauerhaft am physiologischen Maximum. Dein Muskelermüdungs-Schwellenwert bleibt konstant auf Top-Niveau.",
            noviceExplanation: "Die letzte Portion des Tages. Damit hast du deine Tagesdosis von 6 Gramm komplett. Dein Körper nutzt die Nachtruhe, um deine Muskeln für den nächsten Tag komplett feuerfest zu machen.",
            kcal: 6.0,
            protein: 1.5,
            carbs: 0.0,
            fat: 0.0,
            fiber: 0.0
        ),
        CircadianSupplementDose(
            id: "supp_mg_bisglycinat_2100",
            name: "Magnesium-Bisglycinat",
            dosage: "1.500 mg (200 mg elementar)",
            scheduledTime: "21:00",
            mechanism: "Glycin fungiert als inhibitorischer Neurotransmitter am NMDA-Rezeptor im ZNS",
            benefit: "Beruhigt das vegetative Nervensystem, senkt Puls und vertieft REM- und Tiefschlafphasen",
            targetArea: "ZNS & Tiefer Schlaf",
            instructions: "60 Min. vor dem Zubettgehen mit 150 ml stillem Wasser (mind. 3h nach dem Abendessen)",
            shortTermImpact: "Das an Magnesium gebundene Glycin überwindet mühelos die Blut-Hirn-Schranke. Es dockt an beruhigende Rezeptoren im Gehirn an, senkt deine Körperkerntemperatur und dämpft kreisende Gedanken. Du wirst angenehm schwer und schläfst spürbar schneller und sanfter ein.",
            longTermImpact: "Verlängert messbar deine erholsamen Tiefschlaf- und REM-Schlafphasen. Dein Herz kann sich nachts im Parasympathikus vollständig erholen (stabile Sinusbradykardie), deine Muskeln entspannen und du wachst morgens ausgeruht ohne Müdigkeits-Kater auf.",
            noviceExplanation: "Magnesium gekoppelt an die beruhigende Aminosäure Glycin. Die ultimative Abend-Kombination: Sie schaltet den Stress deines Nervensystems ab, lässt deinen Herzschlag zur Ruhe kommen und schenkt dir tiefen, echten Erholungsschlaf.",
            kcal: 5.0,
            protein: 1.2,
            carbs: 0.0,
            fat: 0.0,
            fiber: 0.0
        )
    ]

    public static func minutesFromMidnight(timeString: String) -> Int {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }

    public static func isDoseInCurrentWindow(dose: CircadianSupplementDose, currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMins = hour * 60 + minute
        let doseMins = minutesFromMidnight(timeString: dose.scheduledTime)

        return doseMins >= (currentMins - 60) && doseMins <= (currentMins + 90)
    }

    public static func isDosePast(dose: CircadianSupplementDose, currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMins = hour * 60 + minute
        let doseMins = minutesFromMidnight(timeString: dose.scheduledTime)

        return doseMins < (currentMins - 60)
    }

    public static func isDoseMissed(dose: CircadianSupplementDose, currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMins = hour * 60 + minute
        let doseMins = minutesFromMidnight(timeString: dose.scheduledTime)

        // Verpasste Dosis: Wenn mehr als 45 Minuten nach dem geplanten Einnahmezeitpunkt vergangen sind
        return currentMins > (doseMins + 45)
    }

    public static func nextScheduledDose(from list: [CircadianSupplementDose]? = nil, currentTime: Date = Date()) -> CircadianSupplementDose? {
        let pool = list ?? dailySchedule
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMins = hour * 60 + minute

        let future = pool.filter { minutesFromMidnight(timeString: $0.scheduledTime) >= currentMins }
        return future.first ?? pool.first
    }
}
