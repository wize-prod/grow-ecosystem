import Foundation
import SwiftUI

// MARK: - Program Disziplin Bloecke (Das 6-Saeulen-System fuer physische Exzellenz)
public enum ProgramBlock: String, CaseIterable, Codable, Identifiable {
    case kraftHypertrophie = "Kraft"
    case calisthenicsGoetter = "Calisthenics"
    case ausdauerRunning = "Ausdauer"
    case bundeswehrMilFit = "MilFit"
    case aesthetikSymmetrie = "Aesthetik"
    case mobilitaetReha = "Mobilitaet"

    public var id: String { rawValue }

    public var fullTitle: String {
        switch self {
        case .kraftHypertrophie: return "Kraft & Hypertrophie"
        case .calisthenicsGoetter: return "Calisthenics & Goetter-Module"
        case .ausdauerRunning: return "Ausdauer & Running"
        case .bundeswehrMilFit: return "MilFit & Bundeswehr-Dienstsport"
        case .aesthetikSymmetrie: return "Aesthetik & Symmetrie (V-Taper)"
        case .mobilitaetReha: return "Mobilitaet, Prehab & Dekompression"
        }
    }

    public var subtitle: String {
        switch self {
        case .kraftHypertrophie:
            return "Mechanische Spannung, Myofibrillen & Progressive Overload"
        case .calisthenicsGoetter:
            return "Mythologische Goetter-Module (Zeus, Apollo, Ares, Prometheus)"
        case .ausdauerRunning:
            return "VDOT, 80/20 Polarized & Schwellen-Ausdauer"
        case .bundeswehrMilFit:
            return "BFT Bestwerte, 1000m Sprint & Taktische Konditionierung"
        case .aesthetikSymmetrie:
            return "Goldener Schnitt, 3D-Schultern, schmale Taille & Symmetrie"
        case .mobilitaetReha:
            return "BWK-Ulm Dekompression, Faszien-Release & Vagus-Aktivierung"
        }
    }

    public var detailedDescription: String {
        switch self {
        case .kraftHypertrophie:
            return "Schwerpunkt auf myofibrillaere Hypertrophie und Maximalkraftsteigerung ueber klassische Grund- und Verbunduebungen. Verwendet RPE/RIR-basierte Periodisierung zur Maximierung der mechanischen Spannung."
        case .calisthenicsGoetter:
            return "Ganzheitliche Koerperbeherrschung ohne Gewichte oder an Turnringen/Stangen, strukturiert nach griechischen Goetter-Archetypen (Zeus, Apollo, Ares, Prometheus, Hermes, Poseidon, Hercules). Schulen relative Maximalkraft und Tiefenstabilitaet."
        case .ausdauerRunning:
            return "Kardiovaskulaere Leistungsfaehigkeit nach der Jack Daniels Running Formula. Steigert VDOT, mitochondriale Dichte und aerobe Schwellenleistung (Zone 2 Dauerlaeufe & Schwellen-Intervalle)."
        case .bundeswehrMilFit:
            return "Dienstsportliche Bestwerte gemaess Bundeswehr ZDv 3/10 (Basis-Fitness-Test BFT). Gezieltes Training fuer den 11x10m Sprinttest, Klimmhang und den 1000m-Lauf unter Einsatzbedingungen."
        case .aesthetikSymmetrie:
            return "Gezieltes Hypertrophietraining zur Optimierung klassischer Proportionen (Adonis-Index, V-Taper). Priorisiert seitliche Schulterkoepfe, oberen Latissimus, Nacken und Waden bei striktem Erhalt einer schlanken Taille."
        case .mobilitaetReha:
            return "Medizinisch fundiertes Prehab- und Reha-System nach den Vorgaben des Bundeswehrkrankenhauses (BWK) Ulm. Null Crunches/Sit-ups; Fokus auf isometrische Rumpfstabilisation, LWS-Dekompression, Beckenboden-Schonung und Gelenkbeweglichkeit."
        }
    }

    public var primaryTargetMuscles: [String] {
        switch self {
        case .kraftHypertrophie:
            return ["Pectoralis Major", "Latissimus Dorsi", "Quadrizeps", "Hamstrings", "Gluteus Maximus", "Trizeps/Bizeps"]
        case .calisthenicsGoetter:
            return ["Serratus Anterior", "Scapular-Retraktoren", "Transversus Abdominis", "Latissimus", "Rhomboidei", "Unterarme"]
        case .ausdauerRunning:
            return ["Soleus & Gastrocnemius", "Quadrizeps (Typ-I Fasern)", "Myokard (Herzschlagvolumen)", "Interkostalmuskulatur"]
        case .bundeswehrMilFit:
            return ["Griffkraft-Flexoren", "Trapezius Pars Descendens", "Gastrocnemius", "Antritts-Hüftbeuger & Gluteus"]
        case .aesthetikSymmetrie:
            return ["Deltoideus Lateralis (Seitliche Schulter)", "Oberer Latissimus", "Trapezius Pars Transversa", "Waden"]
        case .mobilitaetReha:
            return ["Multifidi (Tiefe Wirbelsaeulenstabilisatoren)", "Transversus Abdominis", "Gluteus Medius", "Piriformis", "Rotatorenmanschette"]
        }
    }

    public var clinicalSafetyNotes: String {
        switch self {
        case .kraftHypertrophie:
            return "Valsalva-Manöver kontrollieren; keine extremen Pressatmungs-Spitzen zur Vermeidung von intraabdominalen Druckkrisen."
        case .calisthenicsGoetter:
            return "Alle Rumpfuebungen sind anti-flexorisch gestaltet; keine dynamische Wirbelsaeulenbeugung."
        case .ausdauerRunning:
            return "Orthopaedische Sehnenadaption vor Pace-Erhoehung beachten; aerobe Zone 2 schont das neurovegetative System."
        case .bundeswehrMilFit:
            return "Aufwaermphasen vor 11x10m Sprints strikt einhalten zur Schonung der Adduktoren und Ischios."
        case .aesthetikSymmetrie:
            return "Vermeidung von schwerem seitlichen Rumpfbeugen zur Praevention von Taillenverbreiterung."
        case .mobilitaetReha:
            return "Strikt konform mit den post-operativen Vorgaben des BWK Ulm: Isometrische Zuggurtung, kein intraabdominaler Druck."
        }
    }

    public var systemImage: String {
        switch self {
        case .kraftHypertrophie: return "dumbbell.fill"
        case .calisthenicsGoetter: return "figure.core.training"
        case .ausdauerRunning: return "figure.run"
        case .bundeswehrMilFit: return "star.square.fill"
        case .aesthetikSymmetrie: return "crown.fill"
        case .mobilitaetReha: return "shield.checkered"
        }
    }

    public var accentColor: Color {
        switch self {
        case .kraftHypertrophie:
            return GymTheme.strongBlue
        case .calisthenicsGoetter:
            return Color(hex: "00B4D8")
        case .ausdauerRunning:
            return GymTheme.sageGreen
        case .bundeswehrMilFit:
            return Color(hex: "E0A96D")
        case .aesthetikSymmetrie:
            return Color(hex: "F39C12")
        case .mobilitaetReha:
            return Color(hex: "2ECC71")
        }
    }

    public var defaultPillarGoals: [GoalItem] {
        switch self {
        case .kraftHypertrophie:
            return [
                GoalItem(level: .pillar, title: "1RM Bankdruecken (1.0x Koerpergewicht)", targetMetricDescription: "Relatives Maximalkraft-Fundament fuer den Oberkoerper", targetValue: 80.0, unit: "kg", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "1RM Kniebeuge (1.25x Koerpergewicht)", targetMetricDescription: "Symmetrische Beinkraft und Kniestabilitaet", targetValue: 100.0, unit: "kg", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "1RM Kreuzheben (1.50x Koerpergewicht)", targetMetricDescription: "Posteriore Kette und Griffkraft", targetValue: 120.0, unit: "kg", tierRequired: .advancedAmateur)
            ]
        case .calisthenicsGoetter:
            return [
                GoalItem(level: .pillar, title: "10 Saubere Klimmzuege (Dead Hang)", targetMetricDescription: "Relative Zugkraft und Scapula-Retraktion", targetValue: 10.0, unit: "Wdh", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "25 Saubere Liegestuetze", targetMetricDescription: "Koerperbeherrschung und Schulterblatt-Fuehrung", targetValue: 25.0, unit: "Wdh", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "60s Statischer Unterarmstuetz (Plank)", targetMetricDescription: "Anti-Extensions-Stabilitaet der LWS ohne Durchhaengen", targetValue: 60.0, unit: "s", tierRequired: .advancedAmateur, clinicalSafetyNotes: "BWK-Ulm konform: Strikte Bauch- und Gesaessspannung")
            ]
        case .ausdauerRunning:
            return [
                GoalItem(level: .pillar, title: "5 km Dauerlauf unter 28:00 min", targetMetricDescription: "Grundlegendes aerobes Leistungsvermoegen", targetValue: 28.0, unit: "min", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "10 km Dauerlauf unter 58:00 min", targetMetricDescription: "Aerobe Ausdauer und Sehnen-Adaption", targetValue: 58.0, unit: "min", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "Aerobe Zone 2 Basis (45 min Dauerlauf)", targetMetricDescription: "Mitochondriendichte und Fettstoffwechsel ohne Laktatanstieg", targetValue: 45.0, unit: "min", tierRequired: .advancedAmateur)
            ]
        case .bundeswehrMilFit:
            return [
                GoalItem(level: .pillar, title: "BFT Sprinttest 11x10m (< 45,0 s)", targetMetricDescription: "Antrittskraft, Beschleunigung und rasches Aufstehen", targetValue: 45.0, unit: "s", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "BFT Klimmhang statisch (> 45,0 s)", targetMetricDescription: "Statische Haltekraft und Schulterblattstabilitaet", targetValue: 45.0, unit: "s", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "BFT 1000m Lauf (< 3:45 min)", targetMetricDescription: "Anaerobe Laktattoleranz und Tempohaerte", targetValue: 3.75, unit: "min", tierRequired: .advancedAmateur)
            ]
        case .aesthetikSymmetrie:
            return [
                GoalItem(level: .pillar, title: "Schulter-zu-Taille-Ratio (V-Taper >= 1.40)", targetMetricDescription: "Klassischer Adonis-Index fuer proportionale Aesthetik", targetValue: 1.40, unit: "Ratio", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "Tiefenmuskel-Symmetrie-Score >= 80/100", targetMetricDescription: "Ausgeglichene Entwicklung aller 11 Koerperregionen", targetValue: 80.0, unit: "Score", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "Taillenumfang strikt stabil (< 82 cm)", targetMetricDescription: "Vermeidung von Hypertrophie der seitlichen Bauchwand", targetValue: 82.0, unit: "cm", tierRequired: .basicFunctional)
            ]
        case .mobilitaetReha:
            return [
                GoalItem(level: .pillar, title: "3x 45s Planks & Bird-Dog ohne Druckanstieg", targetMetricDescription: "Post-OP Rumpfstabilitaet und Analprolaps-Schutz (BWK Ulm)", targetValue: 100.0, unit: "%", tierRequired: .basicFunctional, clinicalSafetyNotes: "Absolutes Crunches-Verbot"),
                GoalItem(level: .pillar, title: "Aktive Beckenboden- & Transversus-Vorspannung", targetMetricDescription: "Isometrische Zuggurtung vor jeder Lastaufnahme", targetValue: 100.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "Thorakale Aufrichtung & Scapula-Depression", targetMetricDescription: "Beseitigung von Rundruecken und HWS-Fehlstellungen", targetValue: 100.0, unit: "%", tierRequired: .advancedAmateur)
            ]
        }
    }

    public var systemicContrastAgainstOthers: [(targetBlock: String, distinction: String)] {
        switch self {
        case .kraftHypertrophie:
            return [
                ("Calisthenics", "Externe Lasten (Hanteln/Kabel) mit kontinuierlicher linearer Ueberlastung (kg-Steigerung) statt Verlagerung des Koerperschwerpunkts; isolierte Hypertrophie ohne limitierende relative Griffkraft."),
                ("Ausdauer & Running", "Anaerob-alaktazide Reize zur myofibrillaeren Proteinsynthese statt mitochondrialer Biogenese und Laktat-Clearance."),
                ("MilFit Bundeswehr", "Maximale Hypertrophie und absolute Kraft ohne taktische Erschoepfungskomponenten oder Schlafdefizit-Toleranz."),
                ("Aesthetik (V-Taper)", "Konzentration auf Grunduebungen und absolute Kraftwerte statt feingliedriger Symmetrie- und Schwachstellen-Modellierung."),
                ("Mobilitaet & Reha", "Hohe Lastakkumulation und konzentrisch-exzentrische Muskelkontraktion statt faszialer Dehnung und Gelenkendgradigkeit.")
            ]
        case .calisthenicsGoetter:
            return [
                ("Kraft & Hypertrophie", "Relative Koerperkraft, Hebelmechanik und neuromuskulaere Ganzkoerper-Koordination (Koerperspannung) statt isolierter externer Gewichte."),
                ("Ausdauer & Running", "Hochintensive anaerobe Dichte (Freeletics-Archetypen) zur maximalen Calisthenics-Kraftausdauer statt rein aerobem Steady-State."),
                ("MilFit Bundeswehr", "Zirkulaere funktionelle Eigengewichtsmuster statt schwerer Marsch- und Tragelasten."),
                ("Aesthetik (V-Taper)", "Funktionelle Bewegungsausfuehrung (Planche, Muscle-Ups, Handstand) hat Vorrang vor reinem Muskelquerschnitt."),
                ("Mobilitaet & Reha", "Aktive Koerperspannung unter Hebelbelastung statt passiver Gelenkmobilisation.")
            ]
        case .ausdauerRunning:
            return [
                ("Kraft & Hypertrophie", "Kardiovaskulaere Ausdauer, VO2max, Laktatschwelle (VT1/VT2) und aerobe Effizienz statt maximaler mechanischer Gewebespannung."),
                ("Calisthenics", "Zyklische aerobe Grundlagenausdauer (80/20 Polarized) statt statischer oder isometrischer Hebelarbeit."),
                ("MilFit Bundeswehr", "Standardisierte Schwellenlaeufe nach VDOT und Tempokontrolle statt unberechenbarer militaerischer Lageanforderungen."),
                ("Aesthetik (V-Taper)", "Substratnutzung (Fett- und Kohlenhydratoxidation) und Pacing statt visueller Muskelpumps."),
                ("Mobilitaet & Reha", "Hohe kardiorespiratorische Belastung statt regenerativer LWS-Entlastung.")
            ]
        case .bundeswehrMilFit:
            return [
                ("Kraft & Hypertrophie", "Taktische Gefechtstauglichkeit, Tragekapazitaet unter Last (Marschgepaeck) und metabolische Robustheit statt steriler Studio-Lastkurven."),
                ("Calisthenics", "Belastung mit externem Ausruestungs- und Schutzkörpergewicht statt reiner Koerperaesthetik."),
                ("Ausdauer & Running", "Rucksackmaersche, Intervall-Sprints und funktionelles Kriechen/Heben statt reinem Dauerlauf."),
                ("Aesthetik (V-Taper)", "Widerstandskraft gegen psychophysische Erschoepfung nach Dienstvorschrift statt optischer Symmetrie."),
                ("Mobilitaet & Reha", "Gefechtsnahe Leistungsueberpruefung (BFT) statt rein dekomprimierender Reha.")
            ]
        case .aesthetikSymmetrie:
            return [
                ("Kraft & Hypertrophie", "Gezielte Isolation, Mind-Muscle-Connection und visuelle Proportionen (V-Taper, laterale Schultern, obere Brust) statt maximalem 1RM-Gewicht auf der Stange."),
                ("Calisthenics", "Praezise Winkelanpassung an Kabelzuegen zur Ausschaltung synergistischer Muskeln statt erzwungener Ganzkoerper-Stabilisation."),
                ("Ausdauer & Running", "Muskelschutz und Faserpraezision ohne katabole Belastungsspitzen."),
                ("MilFit Bundeswehr", "Klassische Koerperproportionen und Taillenschonung statt taktischer Kampfkonditionierung."),
                ("Mobilitaet & Reha", "Muskelquerschnittserhalt und Muskeldefinition bei kontrollierter Bewegungsamplitude.")
            ]
        case .mobilitaetReha:
            return [
                ("Kraft, Calisthenics & Ausdauer", "Zero-Tonnage, aktive Entspannung, Dekompression der Wirbelsaeule, fasziale Regeneration und Gelenkgesundheit (BWK-Ulm Reha-Standard) statt Erschoepfungsakkumulation."),
                ("MilFit Bundeswehr", "Wiederherstellung physiologischer Bewegungsvektoren und Reduktion intraabdominalen Drucks."),
                ("Aesthetik (V-Taper)", "Gelenkfreiheit und Nervendekompression statt gezieltem Muskelpump.")
            ]
        }
    }
}

// MARK: - Zyklus-Typen (Periodisierungs-Schleifen)
public enum ProgramCycleType: String, Codable, CaseIterable {
    case finiteLinear = "Linear (Endet nach N Wochen)"
    case cyclicalRolling = "Periodische Zyklen (Mesozyklus-Schleife)"
    case continuousLifestyle = "Fortlaufend (Rolling Lifestyle)"

    public var subtitle: String {
        switch self {
        case .finiteLinear: return "Festes Start- und Enddatum (z.B. 6-8 Wochen Testvorbereitung)"
        case .cyclicalRolling: return "Automatische Wiederholung mit Deloads und Leistungssteigerung"
        case .continuousLifestyle: return "Dauerhafte taegliche/woechentliche Basis-Gewohnheit"
        }
    }
}

// MARK: - Historischer Zyklus-Abschluss
public struct CycleCompletionRecord: Identifiable, Codable, Equatable {
    public var id: UUID
    public var cycleIndex: Int
    public var completedAt: Date
    public var totalTonnageKg: Double
    public var sessionsCount: Int
    public var notes: String

    public init(
        id: UUID = UUID(),
        cycleIndex: Int,
        completedAt: Date = Date(),
        totalTonnageKg: Double = 0.0,
        sessionsCount: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.cycleIndex = cycleIndex
        self.completedAt = completedAt
        self.totalTonnageKg = totalTonnageKg
        self.sessionsCount = sessionsCount
        self.notes = notes
    }
}

// MARK: - Program Modalitaet
public enum ProgramModality: String, Codable, CaseIterable {
    case strength = "Kraft"
    case running = "Ausdauer / Lauf"
    case calisthenics = "Bodyweight / Goetter"
    case hybrid = "Hybrid"
    case mobility = "Mobilitaet / Reha"

    public var systemImage: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .running: return "figure.run"
        case .calisthenics: return "figure.core.training"
        case .hybrid: return "bolt.fill"
        case .mobility: return "figure.flexibility"
        }
    }
}

// MARK: - Safe Return Aktionen (Verletzungsprophylaxe)
public enum SafeReturnAction: String, Codable, CaseIterable {
    case normalProgression = "Regulaere Progression"
    case holdStep = "Wiederholung / Hold"
    case minorRegression = "1 Woche Rueckstufung"
    case moderateRegression = "Phasen-Rueckstufung"
    case phaseReset = "Basisphasen-Reset"
    case fullProgramReset = "Vollstaendiger Neustart"

    public var badgeColorHex: String {
        switch self {
        case .normalProgression: return "2ECC71"
        case .holdStep: return "3498DB"
        case .minorRegression: return "F39C12"
        case .moderateRegression: return "E67E22"
        case .phaseReset: return "E74C3C"
        case .fullProgramReset: return "C0392B"
        }
    }
}

// MARK: - Safe Return Evaluierungsergebnis
public struct SafeReturnEvaluation: Codable, Equatable {
    public var action: SafeReturnAction
    public var daysSinceLastSession: Int
    public var recommendedWeek: Int
    public var recommendedSessionIndex: Int
    public var loadReductionPercent: Int
    public var volumeAdjustmentNotes: String
    public var clinicalRationale: String
    public var statusTitle: String

    public init(
        action: SafeReturnAction,
        daysSinceLastSession: Int,
        recommendedWeek: Int,
        recommendedSessionIndex: Int,
        loadReductionPercent: Int,
        volumeAdjustmentNotes: String,
        clinicalRationale: String,
        statusTitle: String
    ) {
        self.action = action
        self.daysSinceLastSession = daysSinceLastSession
        self.recommendedWeek = recommendedWeek
        self.recommendedSessionIndex = recommendedSessionIndex
        self.loadReductionPercent = loadReductionPercent
        self.volumeAdjustmentNotes = volumeAdjustmentNotes
        self.clinicalRationale = clinicalRationale
        self.statusTitle = statusTitle
    }
}

// MARK: - Uebung im gefuehrten Programm
public struct ProgramExerciseItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var targetSets: Int
    public var targetReps: String
    public var targetWeightKg: Double
    public var rpeTarget: String
    public var restSeconds: Int
    public var techniqueNotes: String
    public var isBWKCoreRehaSafe: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        targetSets: Int = 3,
        targetReps: String = "8-12",
        targetWeightKg: Double = 0.0,
        rpeTarget: String = "RIR 2",
        restSeconds: Int = 90,
        techniqueNotes: String = "",
        isBWKCoreRehaSafe: Bool = true
    ) {
        self.id = id
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.rpeTarget = rpeTarget
        self.restSeconds = restSeconds
        self.techniqueNotes = techniqueNotes
        self.isBWKCoreRehaSafe = isBWKCoreRehaSafe
    }
}

// MARK: - Lauf- und Intervallvorgabe
public struct ProgramRunningInterval: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var distanceMeters: Int?
    public var durationSeconds: Int?
    public var targetPaceMinKm: String?
    public var heartRateZone: String?

    public init(
        id: UUID = UUID(),
        title: String,
        distanceMeters: Int? = nil,
        durationSeconds: Int? = nil,
        targetPaceMinKm: String? = nil,
        heartRateZone: String? = nil
    ) {
        self.id = id
        self.title = title
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.targetPaceMinKm = targetPaceMinKm
        self.heartRateZone = heartRateZone
    }
}

// MARK: - Gefuehrte Trainingseinheit (Session)
public struct ProgramSession: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var dayNumber: Int
    public var title: String
    public var modality: ProgramModality
    public var estimatedMinutes: Int
    public var summary: String
    public var exercises: [ProgramExerciseItem]
    public var runningIntervals: [ProgramRunningInterval]
    public var goals: [GoalItem]

    public init(
        id: UUID = UUID(),
        dayNumber: Int,
        title: String,
        modality: ProgramModality = .strength,
        estimatedMinutes: Int = 45,
        summary: String = "",
        exercises: [ProgramExerciseItem] = [],
        runningIntervals: [ProgramRunningInterval] = [],
        goals: [GoalItem]? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.modality = modality
        self.estimatedMinutes = estimatedMinutes
        self.summary = summary
        self.exercises = exercises
        self.runningIntervals = runningIntervals
        self.goals = goals ?? [
            GoalItem(level: .session, title: "Volumen- & Lasten-Integritaet", targetMetricDescription: "Alle geplanten Saetze sauber absolvieren", targetValue: 100.0, unit: "%", tierRequired: .basicFunctional),
            GoalItem(level: .session, title: "RPE- & Flow-Disziplin (RIR 1-3)", targetMetricDescription: "Strikte Vermeidung von vorzeitigem Muskelversagen vor dem Peak", targetValue: 100.0, unit: "%", tierRequired: .basicFunctional),
            GoalItem(level: .session, title: "Somatischer Schutz & Haltung (BWK-Ulm)", targetMetricDescription: "Intraabdominelle Druckkontrolle ohne Pressatmung", targetValue: 100.0, unit: "%", tierRequired: .basicFunctional, clinicalSafetyNotes: "BWK-Standard: Ausatmung bei Belastung")
        ]
    }

    public var exerciseNames: [String] {
        exercises.map { $0.name }
    }
}

// MARK: - Programmwoche (Microcycle)
public struct ProgramWeek: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var weekNumber: Int
    public var title: String
    public var focus: String
    public var sessions: [ProgramSession]

    public init(
        id: UUID = UUID(),
        weekNumber: Int,
        title: String,
        focus: String = "",
        sessions: [ProgramSession] = []
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.title = title
        self.focus = focus
        self.sessions = sessions
    }
}

// MARK: - Programmphase (Mesocycle)
public struct ProgramPhase: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var phaseNumber: Int
    public var name: String
    public var focus: String
    public var weeks: [ProgramWeek]

    public init(
        id: UUID = UUID(),
        phaseNumber: Int,
        name: String,
        focus: String = "",
        weeks: [ProgramWeek] = []
    ) {
        self.id = id
        self.phaseNumber = phaseNumber
        self.name = name
        self.focus = focus
        self.weeks = weeks
    }
}

// MARK: - Hauptmodell: TrainingProgram
public struct TrainingProgram: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var block: ProgramBlock
    public var summary: String
    public var methodology: String
    public var cycleType: ProgramCycleType
    public var totalWeeks: Int
    public var targetDurationText: String
    public var daysPerWeek: Int
    public var difficulty: String
    public var isBWKCoreCompliant: Bool
    public var calisthenicArchetype: CalisthenicArchetype?
    public var phases: [ProgramPhase]
    public var goals: [GoalItem]
    public var createdDate: Date

    // Smart Workout Summary & Description (User Directive)
    public var mainGoal: String?
    public var workoutType: String?
    public var targetTier: AthleticStandardTier?
    public var equipmentRequired: [String]?
    public var designedFor: String?
    public var workoutNotes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        block: ProgramBlock,
        summary: String,
        methodology: String = "Evidenzbasierte Sportwissenschaft",
        cycleType: ProgramCycleType = .cyclicalRolling,
        totalWeeks: Int = 8,
        targetDurationText: String = "8 Wochen",
        daysPerWeek: Int = 3,
        difficulty: String = "Mittel",
        isBWKCoreCompliant: Bool = true,
        calisthenicArchetype: CalisthenicArchetype? = nil,
        phases: [ProgramPhase] = [],
        goals: [GoalItem]? = nil,
        createdDate: Date = Date(),
        mainGoal: String? = nil,
        workoutType: String? = nil,
        targetTier: AthleticStandardTier? = nil,
        equipmentRequired: [String]? = nil,
        designedFor: String? = nil,
        workoutNotes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.block = block
        self.summary = summary
        self.methodology = methodology
        self.cycleType = cycleType
        self.totalWeeks = totalWeeks
        self.targetDurationText = targetDurationText
        self.daysPerWeek = daysPerWeek
        self.difficulty = difficulty
        self.isBWKCoreCompliant = isBWKCoreCompliant
        self.calisthenicArchetype = calisthenicArchetype
        self.phases = phases
        self.goals = goals ?? [
            GoalItem(level: .program, title: "Mesozyklus-Konsistenz (>= 90 % Einheiten)", targetMetricDescription: "Lueckenlose Absolvierung aller Wochen-Mikrozyklen", targetValue: 90.0, unit: "%", tierRequired: .basicFunctional),
            GoalItem(level: .program, title: "Progressive Reiz-Adaption", targetMetricDescription: "Messbarer Last-, Wiederholungs- oder Pace-Zuwachs ueber die Zyklen", targetValue: 100.0, unit: "%", tierRequired: .advancedAmateur),
            GoalItem(level: .program, title: "Regenerative Resensibilisierung (Deload)", targetMetricDescription: "Aktive Erholung zur ZNS- und Sehnen-Superkompensation", targetValue: 100.0, unit: "%", tierRequired: .basicFunctional)
        ]
        self.createdDate = createdDate
        self.mainGoal = mainGoal
        self.workoutType = workoutType
        self.targetTier = targetTier
        self.equipmentRequired = equipmentRequired
        self.designedFor = designedFor
        self.workoutNotes = workoutNotes
    }

    public var effectiveMainGoal: String {
        if let g = mainGoal, !g.isEmpty { return g }
        return summary
    }

    public var effectiveWorkoutType: String {
        if let t = workoutType, !t.isEmpty { return t }
        return block.fullTitle
    }

    public var effectiveTargetTier: AthleticStandardTier {
        if let t = targetTier { return t }
        let diff = difficulty.lowercased()
        if diff.contains("god") || diff.contains("elite") || diff.contains("profi") {
            return .professionalElite
        } else if diff.contains("fortgeschritten") || diff.contains("schwer") || diff.contains("amateur") {
            return .advancedAmateur
        } else {
            return .basicFunctional
        }
    }

    public var effectiveEquipmentRequired: [String] {
        if let eq = equipmentRequired, !eq.isEmpty { return eq }
        if let god = calisthenicArchetype {
            switch god.equipmentRequirement {
            case .pureFloorNoGear: return ["Kein Equipment / Stuben-Boden"]
            case .pullUpBarOnly: return ["Klimmzugstange / Trimm-Dich-Stange"]
            case .parallettesAndFloor: return ["Parallettes / Barren", "Bodenmatte"]
            case .ringsAndBar: return ["Turnringe (Rings)", "Klimmzugstange"]
            case .fullCalisthenicsPark: return ["Klimmzugstange", "Turnringe", "Barren", "Minibaender"]
            }
        }
        switch block {
        case .kraftHypertrophie: return ["Langhantel", "Kurzhanteln", "Hantelbank", "Kabelzug"]
        case .calisthenicsGoetter: return ["Klimmzugstange", "Turnringe / Barren", "Matte"]
        case .ausdauerRunning: return ["Laufschuhe", "GPS-/Pulsuhr", "Laufbahn / Wald"]
        case .bundeswehrMilFit: return ["Dienstanzug / Sportzeug", "Klimmhang-Stange", "Stoppuhr"]
        case .aesthetikSymmetrie: return ["Kurzhanteln", "Kabelzug", "Klimmzugstange"]
        case .mobilitaetReha: return ["Gymnastikmatte", "Faszienrolle", "Minibaender"]
        }
    }

    public var effectiveDesignedFor: String {
        if let d = designedFor, !d.isEmpty { return d }
        return block.detailedDescription
    }

    public var effectiveWorkoutNotes: String {
        if let n = workoutNotes, !n.isEmpty { return n }
        return "RPE/RIR-Vorgaben strikt einhalten. \(block.clinicalSafetyNotes)"
    }

    public var allSessions: [ProgramSession] {
        phases.flatMap { $0.weeks.flatMap { $0.sessions } }
    }

    public var totalSessionsCount: Int {
        allSessions.count
    }

    public func session(byId id: UUID) -> ProgramSession? {
        allSessions.first(where: { $0.id == id })
    }

    public func findSessionLocation(id: UUID) -> (phaseIndex: Int, weekIndex: Int, sessionIndex: Int)? {
        for (pIdx, phase) in phases.enumerated() {
            for (wIdx, week) in phase.weeks.enumerated() {
                for (sIdx, sess) in week.sessions.enumerated() {
                    if sess.id == id {
                        return (pIdx, wIdx, sIdx)
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - ProgramEnrollment & Adaptive SafeReturn Engine
public struct ProgramEnrollment: Identifiable, Codable, Equatable {
    public var id: UUID
    public var programId: UUID
    public var block: ProgramBlock
    public var enrolledAt: Date
    public var lastCompletedAt: Date?
    public var currentCycle: Int
    public var currentWeek: Int
    public var currentSessionIndex: Int
    public var completedSessionIds: [UUID]
    public var cycleHistory: [CycleCompletionRecord]
    public var flowTuningOffsetPercent: Double
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        programId: UUID,
        block: ProgramBlock,
        enrolledAt: Date = Date(),
        lastCompletedAt: Date? = nil,
        currentCycle: Int = 1,
        currentWeek: Int = 1,
        currentSessionIndex: Int = 0,
        completedSessionIds: [UUID] = [],
        cycleHistory: [CycleCompletionRecord] = [],
        flowTuningOffsetPercent: Double = 0.0,
        isActive: Bool = true
    ) {
        self.id = id
        self.programId = programId
        self.block = block
        self.enrolledAt = enrolledAt
        self.lastCompletedAt = lastCompletedAt
        self.currentCycle = currentCycle
        self.currentWeek = currentWeek
        self.currentSessionIndex = currentSessionIndex
        self.completedSessionIds = completedSessionIds
        self.cycleHistory = cycleHistory
        self.flowTuningOffsetPercent = flowTuningOffsetPercent
        self.isActive = isActive
    }

    /// Berechnet den adaptiven Status und gibt evidenzbasierte Empfehlungen gemaess Verzug
    public func evaluateSafeReturn(program: TrainingProgram) -> SafeReturnEvaluation {
        guard let lastDate = lastCompletedAt else {
            return SafeReturnEvaluation(
                action: .normalProgression,
                daysSinceLastSession: 0,
                recommendedWeek: 1,
                recommendedSessionIndex: 0,
                loadReductionPercent: 0,
                volumeAdjustmentNotes: "Programmstart. Grundlagenbelastung gemaess Plan.",
                clinicalRationale: "Keine Vorbelastung vorhanden. Einstieg mit geplanter Basislast.",
                statusTitle: "Initialer Start • Zyklus \(currentCycle)"
            )
        }

        let elapsedDays = max(0, Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0)

        // 1. 0 bis 3 Tage: Normaler Rhythmus
        if elapsedDays <= 3 {
            return SafeReturnEvaluation(
                action: .normalProgression,
                daysSinceLastSession: elapsedDays,
                recommendedWeek: currentWeek,
                recommendedSessionIndex: currentSessionIndex,
                loadReductionPercent: 0,
                volumeAdjustmentNotes: "Regulaere Satzanzahl und Arbeitsgewichte.",
                clinicalRationale: "Optimaler Superkompensations-Zeitkorridor. Keine Deconditioning-Effekte.",
                statusTitle: "Im Rhythmus (Volle Progression)"
            )
        }

        // 2. 4 bis 7 Tage: Leichte Verzoegerung
        if elapsedDays <= 7 {
            return SafeReturnEvaluation(
                action: .holdStep,
                daysSinceLastSession: elapsedDays,
                recommendedWeek: currentWeek,
                recommendedSessionIndex: currentSessionIndex,
                loadReductionPercent: 0,
                volumeAdjustmentNotes: "Arbeitsgewicht halten, letzter Arbeitssatz kann optional entfallen.",
                clinicalRationale: "Leichte Unterbrechung. Wiederakklimatisierung des Nervensystems ohne Laststeigerung.",
                statusTitle: "Leichte Verzoegerung (Stufe halten)"
            )
        }

        // 3. 8 bis 14 Tage (1-2 Wochen): Initiales Deconditioning
        if elapsedDays <= 14 {
            let regWeek = max(1, currentWeek - 1)
            return SafeReturnEvaluation(
                action: .minorRegression,
                daysSinceLastSession: elapsedDays,
                recommendedWeek: regWeek,
                recommendedSessionIndex: 0,
                loadReductionPercent: 10,
                volumeAdjustmentNotes: "Arbeitslast um ca. 10 % reduzieren. RIR 2-3 wahren.",
                clinicalRationale: "Beginnender Rueckgang der Laktattoleranz und Muskelproteinsynthese. 1 Woche Regression schuetzt vor starkem DOMS.",
                statusTitle: "1-2 Wochen Pause (-10% Last)"
            )
        }

        // 4. 15 bis 28 Tage (2-4 Wochen): Signifikanter Formverlust
        if elapsedDays <= 28 {
            let regWeek = max(1, currentWeek - 2)
            return SafeReturnEvaluation(
                action: .moderateRegression,
                daysSinceLastSession: elapsedDays,
                recommendedWeek: regWeek,
                recommendedSessionIndex: 0,
                loadReductionPercent: 20,
                volumeAdjustmentNotes: "Lasten um 20 % reduzieren. Maximal 2-3 Saetze pro Uebung.",
                clinicalRationale: "Rueckgang von Myofibrillen-Dichte und Sehnensteifigkeit. Phasenrueckstufung verhindert Sehnenansatzreizung.",
                statusTitle: "2-4 Wochen Pause (-20% Last)"
            )
        }

        // 5. 29 bis 90 Tage (1-3 Monate): Strukturelle Rueckbildung
        if elapsedDays <= 90 {
            return SafeReturnEvaluation(
                action: .phaseReset,
                daysSinceLastSession: elapsedDays,
                recommendedWeek: 1,
                recommendedSessionIndex: 0,
                loadReductionPercent: 30,
                volumeAdjustmentNotes: "Rueckkehr zu Phase 1 mit 30 % reduzierter Last.",
                clinicalRationale: "Signifikanter Kraft- und Kardioabbau. Bindegewebe und intraabdominaler Druck muessen behutsam re-adaptiert werden.",
                statusTitle: "1-3 Monate Pause (Phasen-Reset)"
            )
        }

        // 6. > 90 Tage (> 3 Monate): Vollstaendiger Neustart
        return SafeReturnEvaluation(
            action: .fullProgramReset,
            daysSinceLastSession: elapsedDays,
            recommendedWeek: 1,
            recommendedSessionIndex: 0,
            loadReductionPercent: 0,
            volumeAdjustmentNotes: "Vollstaendiger Neustart Woche 1 / Tag 1 mit Fokus auf RPE 6.",
            clinicalRationale: "Ueber 90 Tage Pause erfordern einen vollstaendigen physiologischen Neuaufbau zur Vermeidung von Verletzungen.",
            statusTitle: "Vollstaendiger Neustart erforderlich"
        )
    }

    /// Markiert eine Session als abgeschlossen und unterstuetzt automatische Zyklen-Progression
    public mutating func markSessionCompleted(sessionId: UUID, program: TrainingProgram) {
        if !completedSessionIds.contains(sessionId) {
            completedSessionIds.append(sessionId)
        }
        lastCompletedAt = Date()

        let all = program.allSessions
        if let idx = all.firstIndex(where: { $0.id == sessionId }) {
            if idx + 1 < all.count {
                let nextSession = all[idx + 1]
                if let loc = program.findSessionLocation(id: nextSession.id) {
                    currentWeek = program.phases[loc.phaseIndex].weeks[loc.weekIndex].weekNumber
                    currentSessionIndex = loc.sessionIndex
                }
            } else {
                // Zyklus vollendet!
                let cycleRecord = CycleCompletionRecord(
                    cycleIndex: currentCycle,
                    completedAt: Date(),
                    totalTonnageKg: 0.0,
                    sessionsCount: completedSessionIds.count,
                    notes: "Zyklus \(currentCycle) erfolgreich abgeschlossen."
                )
                cycleHistory.append(cycleRecord)

                if program.cycleType == .cyclicalRolling || program.cycleType == .continuousLifestyle {
                    // Automatischer Uebergang in den naechsten Zyklus
                    currentCycle += 1
                    currentWeek = 1
                    currentSessionIndex = 0
                    completedSessionIds = []
                } else {
                    currentSessionIndex = all.count
                }
            }
        }
    }

    /// Prozentualer Gesamtfortschritt im aktuellen Zyklus
    public func progressPercentage(program: TrainingProgram) -> Double {
        let total = program.totalSessionsCount
        guard total > 0 else { return 0.0 }
        let completed = completedSessionIds.count
        return min(1.0, Double(completed) / Double(total))
    }
}
