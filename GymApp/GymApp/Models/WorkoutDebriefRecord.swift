import Foundation
import SwiftUI

// MARK: - 1. Primaere Ausfall- und Abbruchgruende (User-Input Optionen)
public enum DropoutFailureReason: String, CaseIterable, Identifiable, Codable {
    case pacingOverreach = "Pacing-Fehler: Zu hohes Anfangstempo / Ueberzogene Startlast"
    case lacticBurnout = "Akuter Laktat-Burnout / Lokales Muskelbrennen vor dem Ziel"
    case cardiovascularWall = "Kardiovaskulaere Wand / Puls am Anschlag / Akute Atemnot"
    case glycogenDepletion = "Akuter Energiemangel / Hypoglykaemie / ZNS-Fatigue (Leerer Tank)"
    case orthopedicVisceralPain = "Muskulaerer Krampf / Schmerz / Viszerale Warnung (BWK-Ulm)"
    case sleepDeficitFatigue = "Zirkadiane Erschoepfung / Akuter Schlafmangel / CPAP-Defizit"
    case administrativeDuty = "Dienstliche / Externe Unterbrechung (Spiess, Alarm, Dienstbetrieb)"
    case mentalFocusLoss = "Mentale Blockade / Kognitive Reibung / Fehlender Handlungsfluss"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .pacingOverreach: return "Pacing-Fehler"
        case .lacticBurnout: return "Laktat-Burnout"
        case .cardiovascularWall: return "Kardiovaskulaere Wand"
        case .glycogenDepletion: return "Energiemangel / Glykogen"
        case .orthopedicVisceralPain: return "Schmerz / Viszeral (BWK)"
        case .sleepDeficitFatigue: return "Schlafdefizit / ZNS"
        case .administrativeDuty: return "Dienstliche Unterbrechung"
        case .mentalFocusLoss: return "Mentale Reibung"
        }
    }

    public var description: String {
        switch self {
        case .pacingOverreach:
            return "Das Tempo oder Startgewicht wurde unbewusst zu hoch gewaehlt (z.B. nach einer Trainingspause)."
        case .lacticBurnout:
            return "Extremes Brennen und Azidose in der Zielmuskulatur verhinderten das Erreichen der geplanten Wiederholungen/Distanz."
        case .cardiovascularWall:
            return "Herzfrequenz stieg fruehzeitig in den Maximalbereich; anaerobe Schwelle weit vor Zielerreichung ueberschritten."
        case .glycogenDepletion:
            return "Zittern, Schwindel oder ploetzlicher Leistungsabfall durch unzureichende Kohlenhydratverfuegbarkeit."
        case .orthopedicVisceralPain:
            return "Stechender Schmerz, Krampf oder unangenehmer Druckanstieg im Rumpf-/Beckenbereich (postoperativer Schutzreflex)."
        case .sleepDeficitFatigue:
            return "Schwere Glieder und traeges Nervensystem durch Schlafmangel oder CPAP-Incompliance."
        case .administrativeDuty:
            return "Befehl, Dienstverlaengerung, Antreten oder dringende administrative Pflichten erzwangen den Abbruch."
        case .mentalFocusLoss:
            return "Fehlende Fokussierung oder hohe paralimbische Aversion blockierten die Fortsetzung."
        }
    }
}

// MARK: - 2. Ergebnisstruktur der deterministischen Hardcoded-Szenarien
public struct HardcodedCoachScenarioResult: Identifiable, Codable, Equatable, Hashable {
    public var id: String { scenarioId }
    public var scenarioId: String
    public var scenarioNumber: Int
    public var scenarioTitle: String
    public var scenarioBadge: String
    public var diagnoseText: String
    public var physiologicalRationale: String
    public var immediatePrescription: String
    public var nextWorkoutConstraint: String
    public var paceOrLoadCap: String
    public var actionSteps: [String]

    public init(
        scenarioId: String,
        scenarioNumber: Int,
        scenarioTitle: String,
        scenarioBadge: String,
        diagnoseText: String,
        physiologicalRationale: String,
        immediatePrescription: String,
        nextWorkoutConstraint: String,
        paceOrLoadCap: String,
        actionSteps: [String]
    ) {
        self.scenarioId = scenarioId
        self.scenarioNumber = scenarioNumber
        self.scenarioTitle = scenarioTitle
        self.scenarioBadge = scenarioBadge
        self.diagnoseText = diagnoseText
        self.physiologicalRationale = physiologicalRationale
        self.immediatePrescription = immediatePrescription
        self.nextWorkoutConstraint = nextWorkoutConstraint
        self.paceOrLoadCap = paceOrLoadCap
        self.actionSteps = actionSteps
    }
}

// MARK: - 3. Vollstaendiger Debriefing-Datensatz
public struct WorkoutDebriefRecord: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var primaryReason: DropoutFailureReason
    public var perceivedExertionRPE: Int             // 1 bis 10
    public var pacingDisciplineRating: Int           // 1 (extrem ueberpaced) bis 5 (perfekt dosiert)
    public var sleepRecoveryRating: Int             // 1 (desolat) bis 5 (optimal)
    public var nutritionHydrationRating: Int         // 1 (nuechtern/leer) bis 5 (voll geladen)
    public var plannedMetric: String                // z.B. "5,0 km" oder "15 Saetze"
    public var achievedMetric: String               // z.B. "2,5 km" oder "6 Saetze"
    public var plannedVsAchievedRatio: Double        // 0.0 bis 1.0 (z.B. 0.50)
    public var daysSinceLastWorkout: Int            // Tage der Trainingspause
    public var notes: String
    public var coachResult: HardcodedCoachScenarioResult

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        primaryReason: DropoutFailureReason,
        perceivedExertionRPE: Int,
        pacingDisciplineRating: Int,
        sleepRecoveryRating: Int,
        nutritionHydrationRating: Int,
        plannedMetric: String,
        achievedMetric: String,
        plannedVsAchievedRatio: Double,
        daysSinceLastWorkout: Int,
        notes: String,
        coachResult: HardcodedCoachScenarioResult
    ) {
        self.id = id
        self.timestamp = timestamp
        self.primaryReason = primaryReason
        self.perceivedExertionRPE = perceivedExertionRPE
        self.pacingDisciplineRating = pacingDisciplineRating
        self.sleepRecoveryRating = sleepRecoveryRating
        self.nutritionHydrationRating = nutritionHydrationRating
        self.plannedMetric = plannedMetric
        self.achievedMetric = achievedMetric
        self.plannedVsAchievedRatio = plannedVsAchievedRatio
        self.daysSinceLastWorkout = daysSinceLastWorkout
        self.notes = notes
        self.coachResult = coachResult
    }
}

// MARK: - 4. Deterministische Hardcoded Entscheidungs-Matrix (OlympicCoachHardcodedRuleEngine)
public struct OlympicCoachHardcodedRuleEngine {

    /// Deterministische Auswertung gemaess vordefinierten, sportwissenschaftlich und militaerisch fundierten Regelsaetzen
    public static func evaluate(
        reason: DropoutFailureReason,
        rpe: Int,
        pacingRating: Int,
        sleepRating: Int,
        nutritionRating: Int,
        plannedVsAchievedRatio: Double,
        daysSinceLastWorkout: Int,
        plannedMetric: String,
        achievedMetric: String
    ) -> HardcodedCoachScenarioResult {

        // SZENARIO 1: Akuter Detraining-Rebound-Schock (Das 5km-Streak -> Pause -> 2.5km Fail Muster)
        // Kriterien: Mehrtägige Pause (>= 5 Tage), Abbruch bei <= 70% der Leistung, Grund Pacing/Laktat/Kardiovaskulaer oder Pacing <= 2
        let isPacingOrCardioIssue = (reason == .pacingOverreach || reason == .lacticBurnout || reason == .cardiovascularWall || pacingRating <= 2)
        if daysSinceLastWorkout >= 5 && plannedVsAchievedRatio <= 0.70 && isPacingOrCardioIssue {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_1_DETRAINING_REBOUND_SHOCK",
                scenarioNumber: 1,
                scenarioTitle: "Szenario 1: Detraining-Rebound-Schock (Pacing-Fehler nach Pause)",
                scenarioBadge: "DETRAINING-SCHOCK",
                diagnoseText: "Nach \(daysSinceLastWorkout) Tagen Trainingspause kam es zum vorzeitigen Leistungseinbruch bei \(Int(plannedVsAchievedRatio * 100)) % der geplanten Einheit (\(achievedMetric) statt \(plannedMetric)) bei RPE \(rpe). Das neuromuskulaere Tempo-Gedaechtnis forderte die vor der Pause gewohnte All-Out-Pace, waehrend die physiologischen Puffer noch im Ruhezustand verharrten.",
                physiologicalRationale: "Akuter Abfall des kardialen Schlagvolumens (~8 %) und voruebergehender Verlust der enzymatischen Laktatpufferkapazitaet (Laktatdehydrogenase). Die Laktatakkumulation erfolgte exponentiell frueher als im trainierten Streak-Zustand.",
                immediatePrescription: "Sofortige Beendigung fuer heute. Kein Ersatzausgleich oder Bestrafungslauf.",
                nextWorkoutConstraint: "Pace-Cap: Fuer die naechsten 5 Tage striktes Zone-2 Limit (+45 bis +60 s/km ueber Wettkampfpace). Erst nach 2 vollendeten Einheiten in Zone 2 erfolgt die Freigabe fuer Schwellenlaeufe.",
                paceOrLoadCap: "Zone 2 Deckelung: Max. 6:15 - 6:45 min/km bzw. -20 % Last",
                actionSteps: [
                    "Kein zweiter Versuch am selben Tag zur Schonung des vegetativen Nervensystems.",
                    "Naechste Laufeinheit: 3,0 km Brueckenlauf mit 4x 60s Gehintervallen.",
                    "Erhoehung der Hydration mit 500 ml Wasser und einer Prise Meersalz."
                ]
            )
        }

        // SZENARIO 2: Akuter metabolischer Glykogen-Mangel / Hypoglykaemie
        // Kriterien: Grund Glykogen ODER (Ernaehrung <= 2 und RPE >= 8)
        if reason == .glycogenDepletion || (nutritionRating <= 2 && rpe >= 8) {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_2_GLYCOGEN_DEPLETION",
                scenarioNumber: 2,
                scenarioTitle: "Szenario 2: Akuter Glykogen-Mangel / Hypoglykaemie",
                scenarioBadge: "METABOLISCHES DEFIZIT",
                diagnoseText: "Vorzeitiger Abbruch durch akutes Absinken der Blutglukose und entleerte Glykogenspeicher. Das ZNS hat die neuromuskulaere Rekrutierung zum Schutz vor Zellunterzuckerung gedrosselt.",
                physiologicalRationale: "Ohne ausreichende Kohlenhydratverfuegbarkeit bricht die glykolytische ATP-Resynthese bei hohen Intensitaeten zusammen. Der Fettstoffwechsel kann den Energiebedarf bei Anaerob-Belastung nicht schnell genug decken.",
                immediatePrescription: "Sofortige Zufuhr von 30 g schnellen Kohlenhydraten (Dextrose, Banane, Fruchtmus) + 400 ml Wasser mit Elektrolyten.",
                nextWorkoutConstraint: "Pre-Workout-Pflicht: 40-50 g komplexe Kohlenhydrate zwingend 60-90 Minuten vor Trainingsbeginn. Keine Nuechterntrainings bei Einheiten ueber 30 Minuten Dauer.",
                paceOrLoadCap: "Intensitaets-Limit: RIR >= 2; Pace-Limit Zone 2/3",
                actionSteps: [
                    "30g schnelle Kohlenhydrate jetzt zufuehren.",
                    "Kohlenhydrat-Timing im Tagesplan anpassen (Carb-Kopplung morgens).",
                    "3-Stunden-Fastenfenster am Vorabend strikt einhalten, dafuer Mittagsmahlzeit mit komplexen Carbs staerken."
                ]
            )
        }

        // SZENARIO 3: Viszerale & Abdominale Schutzabschaltung (BWK-Ulm Standard)
        // Kriterien: Grund Orthopaedisch/Viszeral
        if reason == .orthopedicVisceralPain {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_3_VISCERAL_PROTECTION_BWK",
                scenarioNumber: 3,
                scenarioTitle: "Szenario 3: Viszerale & Myofasziale Schutzabschaltung (BWK Ulm)",
                scenarioBadge: "VISZERALER SCHUTZ",
                diagnoseText: "Der Koerper hat ein akutes Schutzsignal im Rumpf-, Becken- oder viszeralen Bereich ausgeloest. Gemaess postoperativer Doktrin (BWK Ulm) ist die sofortige Lastabschaltung absolut verbindlich.",
                physiologicalRationale: "Vermeidung erhoehter intraabdominaler Druckspitzen. Schutz des Anorektaltraktes und der Beckenbodenmuskulatur vor Scherkraeften und venoeser Stauung.",
                immediatePrescription: "48 Stunden Ausschluss saemtlicher axialer Druckuebungen (keine schweren Kniebeugen, kein schweres Kreuzheben). Striktes Verbot von Pressatmung (Valsalva).",
                nextWorkoutConstraint: "Uebergang zu funktioneller Dekompression: Planks, Bird-Dog, Glute Bridges und diaphragmale Zwerchfellatmung. Striktes Crunches- und Sit-ups-Verbot.",
                paceOrLoadCap: "Isometrische Reha: Koerpergewicht only / 0 kg Zusatzlast",
                actionSteps: [
                    "15 Minuten Ruhelage in Stufenbettlagerung (90 Grad Huefte/Knie) zur Psoas-Entlastung.",
                    "Taegliche Ballaststoffzufuhr auf 25-35g pruefen (Bristol-Stuhlform Typ 4).",
                    "Bei persistierenden Symptomen Vorstellung beim Sanitaetsversorgungszentrum (SanVersZ)."
                ]
            )
        }

        // SZENARIO 4: Mechanisches Muskelversagen / Zu schwere Arbeitslast (Overload)
        // Kriterien: Laktat/Pacing ODER RPE >= 9 bei Kraft
        if (reason == .lacticBurnout || pacingRating <= 2) && rpe >= 9 {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_4_MECHANICAL_OVERLOAD",
                scenarioNumber: 4,
                scenarioTitle: "Szenario 4: Lokales Muskelversagen (RIR 0 Ueberschreitung)",
                scenarioBadge: "LOKALER OVERLOAD",
                diagnoseText: "Lokales Muskelversagen vor Erreichen des Zielvolumens bei maximaler Erschoepfung (RPE \(rpe)). Die gewaehlte Last oder Wiederholungszahl lag oberhalb der aktuellen Tagesform.",
                physiologicalRationale: "Erschoepfung der motorischen Einheiten mit hoher Reizschwelle (Typ-IIx Fasern) und intramuskulaere Azidose durch H+-Ionen-Akkumulation bei verkuerzten Satzpausen.",
                immediatePrescription: "Ausreichende Satzpause gewaehren. Keine weiteren Maximalwiederholungen bis zum Muskelversagen in dieser Trainingseinheit.",
                nextWorkoutConstraint: "Deload der Arbeitsgewichte um 7,5 % bis 10 % fuer die naechste Einheit. Verlaengerung der Satzpausen von 90 auf verbindliche 150 Sekunden.",
                paceOrLoadCap: "Reduktion der Last um -10 %; strikte Einhaltung von RIR 2-3",
                actionSteps: [
                    "Arbeitsgewicht fuer die naechste Einheit um eine Stufe reduzieren.",
                    "Satzpause via GymStore-Timer auf 2:30 min fixieren.",
                    "Fokus auf 3 Sekunden kontrollierte exzentrische Phase legen."
                ]
            )
        }

        // SZENARIO 5: Zirkadianes Schlafdefizit & ZNS-Fatigue (Schlafapnoe / CPAP)
        // Kriterien: Grund Schlafdefizit ODER (Schlaf <= 2 und RPE >= 8)
        if reason == .sleepDeficitFatigue || (sleepRating <= 2 && rpe >= 8) {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_5_SLEEP_DEFICIT_ZNS",
                scenarioNumber: 5,
                scenarioTitle: "Szenario 5: Zirkadiane ZNS-Fatigue (Schlafmangel / CPAP-Defizit)",
                scenarioBadge: "SCHLAF-FATIGUE",
                diagnoseText: "Zentralnervoese Erschoepfung durch unzureichende zirkadiane Erholung (Schlaf-Rating: \(sleepRating)/5). Erhoehte Reizbarkeit und stark herabgesetzte neuromuskulaere Reaktionsgeschwindigkeit.",
                physiologicalRationale: "Mangelhafte REM- und Tiefschlafphasen fuehren zu unvollstaendiger Clearance von zerebralem Adenosin und erhoehtem Ruhe-Cortisolspiegel. Das Verletzungsrisiko fuer passive Strukturen ist um das 2- bis 3-fache erhoeht.",
                immediatePrescription: "Training gilt fuer heute als beendet. Kein schlechtes Gewissen; das vegetative Nervensystem benoetigt zirkadiane Synchronisation.",
                nextWorkoutConstraint: "Nachtruhe heute strikt auf 21:30 Uhr vorziehen. CPAP-Nutzung sicherstellen. Keine schweren Hebeuebungen vor 07:00 Uhr.",
                paceOrLoadCap: "Volumen-Kappung: Max. 60 % des ueblichen Gesamtvolumens",
                actionSteps: [
                    "Heute Abend Nahrungskarenz ab 19:30 Uhr (3-Stunden-Fenster vor Bettruhe).",
                    "CPAP-Maskenanpassung vor dem Einschlafen kontrollieren.",
                    "Morgen frueh: 20 min MVPA (Morgenroutine) zur Orexin-Stimulation vor digitalen Systemen."
                ]
            )
        }

        // SZENARIO 6: Dienstliche / Administrative Unterbrechung (Militaerische Lage)
        // Kriterien: Grund Dienstlich / Extern
        if reason == .administrativeDuty {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_6_ADMINISTRATIVE_MILITARY_DUTY",
                scenarioNumber: 6,
                scenarioTitle: "Szenario 6: Dienstlicher Lageabbruch (Bundeswehr Dienstbetrieb)",
                scenarioBadge: "DIENST-UNTERBRECHUNG",
                diagnoseText: "Die Einheit wurde durch aeussere militaerische Pflichten (Dienstanordnung, Antreten, Stubeninspektion, Zeitnot) unterbrochen. Es liegt kein physiologisches Versagen vor.",
                physiologicalRationale: "Dienstliche Prioritaeten bilden den unverrueckbaren Existenzanker gemaess Global Operating System. Teilleistungen werden vollwertig verarbeitet.",
                immediatePrescription: "Kein Nachholzwang am Abend. Die erbrachte Teilleistung (\(achievedMetric)) wird vollstaendig in den Muskel-Index und das Banister-Modell eingespeist.",
                nextWorkoutConstraint: "Naechste planmaessige Einheit wird ohne Strafpunkte und ohne zusaetzliche Lastverschiebungen fortgesetzt.",
                paceOrLoadCap: "Regulaere Vorgaben ohne Einschraenkung",
                actionSteps: [
                    "Dienstliche Pflicht ohne kognitive Reibung wahrnehmen.",
                    "Erbrachte Teilsaetze bleiben im System gespeichert.",
                    "Naechster regulärer Block wird am Folgetag absolviert."
                ]
            )
        }

        // SZENARIO 7: Mentale Blockade & Kognitive Reibung
        // Kriterien: Grund Mentale Reibung
        if reason == .mentalFocusLoss {
            return HardcodedCoachScenarioResult(
                scenarioId: "SCENARIO_7_MENTAL_FRICTION_ACT",
                scenarioNumber: 7,
                scenarioTitle: "Szenario 7: Kognitive Reibung / Dopaminerge Blockade",
                scenarioBadge: "MENTALE REIBUNG",
                diagnoseText: "Hohe subjektive Aversion oder paralimbische Signale (Dread, Unlust) blockierten die Fortsetzung der Einheit.",
                physiologicalRationale: "Akzeptanz- und Commitment-Therapie (ACT): Emotionale Unlust ist ein transientes neurologisches Signal. Die motorische Handlung kann dennoch reibungsarm initiiert werden.",
                immediatePrescription: "Defusion anwenden: Den mentalen Widerstand neutral wahrnehmen. Keine uebermaessige Selbstkritik.",
                nextWorkoutConstraint: "Adaptive Reduktion fuer die naechste Einheit: Start mit einem simplen 5-Minuten-Setup (z.B. nur 5 min Ruderergometer oder 1 Satz Aufwaermen).",
                paceOrLoadCap: "Mikro-Aktions-Start: 1 reibungsfreies Initial-Set",
                actionSteps: [
                    "WENN Trainingszeit erreicht -> DANN starte ich nur die ersten 3 Minuten Warm-up.",
                    "Kein Meta-Planen im Liegen.",
                    "Schulter- und Nackendehnung durchfuehren."
                ]
            )
        }

        // SZENARIO 8: Konservative Erholungsanpassung (Allgemeines Stopp-Signal)
        // Fallback fuer alle uebrigen Konstellationen
        return HardcodedCoachScenarioResult(
            scenarioId: "SCENARIO_8_CONSERVATIVE_RECOVERY",
            scenarioNumber: 8,
            scenarioTitle: "Szenario 8: Konservative Erholungsanpassung",
            scenarioBadge: "ERHOLUNGSSIGNAL",
            diagnoseText: "Unspezifischer Leistungseinbruch oder freiwilliger Abbruch bei RPE \(rpe). Der Koerper signalisierte eine vorzeitige Belastungsgrenze.",
            physiologicalRationale: "Selbstregulierender Schutzmechanismus vor Ueberlastung.",
            immediatePrescription: "24 Stunden vegetative Erholung, ausreichende Fluessigkeitszufuhr und Schlaf.",
            nextWorkoutConstraint: "Naechste Einheit mit moderatem Einstieg (-15 % Last oder Zone 2) beginnen.",
            paceOrLoadCap: "-15 % Last / RPE max. 7",
            actionSteps: [
                "Teilleistung wird gespeichert.",
                "Spaziergang an frischer Luft zur Durchblutung.",
                "Magnesium-Malat am Morgen und Magnesium-Bisglycinat am Abend zur neuromuskulaeren Entspannung."
            ]
        )
    }
}

// MARK: - Autonomer 22:00 Uhr Tagesabschluss-Report (Data Contract)
public struct DailyEveningEvaluation: Codable, Identifiable, Equatable, Sendable {
    public var id: String { date }
    public let date: String
    public let userId: String
    public let timestamp: String
    public let nutrition: NutritionEval
    public let training: TrainingEval
    public let evaluationSummary: String

    public struct NutritionEval: Codable, Equatable, Sendable {
        public let caloriesActual: Int
        public let caloriesTarget: Int
        public let calorieDelta: Int
        public let proteinActualG: Int
        public let proteinTargetG: Int
        public let adherenceScorePct: Int

        enum CodingKeys: String, CodingKey {
            case caloriesActual = "calories_actual"
            case caloriesTarget = "calories_target"
            case calorieDelta = "calorie_delta"
            case proteinActualG = "protein_actual_g"
            case proteinTargetG = "protein_target_g"
            case adherenceScorePct = "adherence_score_pct"
        }
    }

    public struct TrainingEval: Codable, Equatable, Sendable {
        public let workoutPlanned: String
        public let exercisesCount: Int
        public let status: String

        enum CodingKeys: String, CodingKey {
            case workoutPlanned = "workout_planned"
            case exercisesCount = "exercises_count"
            case status
        }
    }

    enum CodingKeys: String, CodingKey {
        case date
        case userId = "user_id"
        case timestamp
        case nutrition
        case training
        case evaluationSummary = "evaluation_summary"
    }
}
