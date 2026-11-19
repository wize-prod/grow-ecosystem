import Foundation
import SwiftUI

// MARK: - Flow-Zonen (Csikszentmihalyi Challenge-Skill Matrix)
public enum FlowZone: String, CaseIterable, Codable, Identifiable {
    case boredom = "Unterforderung (Boredom)"
    case flow = "Optimaler Flow (Razor's Edge)"
    case anxiety = "Ueberforderung (Anxiety / Overwhelm)"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .boredom: return "Unterforderung"
        case .flow: return "Im Flow"
        case .anxiety: return "Ueberforderung"
        }
    }

    public var description: String {
        switch self {
        case .boredom:
            return "Faehigkeit war deutlich hoeher als die Anforderung. Mental unbeteiligt, zu leicht."
        case .flow:
            return "Perfekte Balance. Anforderung lag ca. 4 % ueber dem Koennen. Voller Fokus, im Tunnel."
        case .anxiety:
            return "Anforderung war zu hoch. Stress, Formverlust, Frustration oder uebermaessige Erschoepfung."
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .boredom: return "3498DB" // Kuehles Blau (niedrige Erregung)
        case .flow: return "2ECC71"    // Optimales Smaragdgruen
        case .anxiety: return "E74C3C" // Alarm-Rot
        }
    }
}

// MARK: - Viszerale & Post-OP Rumpf-Sicherheit (BWK Ulm Standard)
public enum VisceralSafetyStatus: String, CaseIterable, Codable, Identifiable {
    case asymptomatic = "Vollstaendig schmerzfrei & stabil"
    case mildTension = "Leichte Spannung im Becken/LWS"
    case warningPressure = "Erhoehter intraabdominaler Druck / Beschwerden"

    public var id: String { rawValue }

    public var isSafeForProgression: Bool {
        self == .asymptomatic
    }
}

// MARK: - Post-Session Diagnostic Feedback
public struct FlowPostSessionFeedback: Identifiable, Codable, Equatable {
    public var id: UUID
    public var sessionId: UUID
    public var programId: UUID?
    public var date: Date
    public var flowZone: FlowZone
    public var rpeScore: Double          // 1.0 bis 10.0
    public var visceralSafety: VisceralSafetyStatus
    public var mentalFocusScore: Int     // 1 bis 5 Sterne
    public var userNotes: String

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        programId: UUID? = nil,
        date: Date = Date(),
        flowZone: FlowZone = .flow,
        rpeScore: Double = 7.0,
        visceralSafety: VisceralSafetyStatus = .asymptomatic,
        mentalFocusScore: Int = 4,
        userNotes: String = ""
    ) {
        self.id = id
        self.sessionId = sessionId
        self.programId = programId
        self.date = date
        self.flowZone = flowZone
        self.rpeScore = rpeScore
        self.visceralSafety = visceralSafety
        self.mentalFocusScore = mentalFocusScore
        self.userNotes = userNotes
    }
}

// MARK: - Ergebnis der Flow-Kalibrierung (Tuning Result)
public struct FlowTuningResult: Codable, Equatable {
    public var loadAdjustmentPercent: Double
    public var restIntervalAdjustmentSeconds: Int
    public var targetRepsModifier: Int
    public var coachingDirective: String
    public var tacticalTip: String

    public init(
        loadAdjustmentPercent: Double,
        restIntervalAdjustmentSeconds: Int,
        targetRepsModifier: Int,
        coachingDirective: String,
        tacticalTip: String
    ) {
        self.loadAdjustmentPercent = loadAdjustmentPercent
        self.restIntervalAdjustmentSeconds = restIntervalAdjustmentSeconds
        self.targetRepsModifier = targetRepsModifier
        self.coachingDirective = coachingDirective
        self.tacticalTip = tacticalTip
    }
}

// MARK: - Flow-State Engine
public final class FlowStateEngine {
    public static let shared = FlowStateEngine()

    private init() {}

    /// Analysiert das Feedback und leitet mathematische Anpassungen fuer die Folge-Einheit ab
    public func evaluateSession(feedback: FlowPostSessionFeedback) -> FlowTuningResult {
        // 1. Viszeraler Sicherheits-Veto (BWK Ulm)
        if feedback.visceralSafety == .warningPressure {
            return FlowTuningResult(
                loadAdjustmentPercent: -15.0,
                restIntervalAdjustmentSeconds: 30,
                targetRepsModifier: -2,
                coachingDirective: "BWK-Ulm Sicherheitsbremse: Druckentlastung aktiviert. Lasten um 15 % gedrosselt.",
                tacticalTip: "Konzentriere dich auf strikte Bauchatmung und isometrische Rumpfstabilisation. Keine Pressatmung."
            )
        }

        // 2. Zone-Klassifikation
        switch feedback.flowZone {
        case .boredom:
            // Unterforderung -> +4 % Ueberlast-Regel (Csikszentmihalyi / Kotler)
            let loadAdd: Double
            let repMod: Int
            let restMod: Int

            if feedback.rpeScore <= 5.0 {
                // Sehr stark unterfordert
                loadAdd = 5.0
                repMod = 1
                restMod = -15
            } else {
                // Milde Unterforderung
                loadAdd = 4.0
                repMod = 0
                restMod = -10
            }

            return FlowTuningResult(
                loadAdjustmentPercent: loadAdd,
                restIntervalAdjustmentSeconds: restMod,
                targetRepsModifier: repMod,
                coachingDirective: "Boredom detektiert. Die 4 %-Ueberlast-Kante wird fuer die naechste Session angewandt.",
                tacticalTip: "Erhoehe die Arbeitslast um 4 % und verkuerze die Satzpausen um 10-15 Sekunden, um sofort in den Flow-Zustand zu kommen."
            )

        case .flow:
            // Perfekte Flow-Zone -> Regulaere Mikro-Progression
            return FlowTuningResult(
                loadAdjustmentPercent: 1.5,
                restIntervalAdjustmentSeconds: 0,
                targetRepsModifier: 0,
                coachingDirective: "Optimale Flow-Zone gehalten. Standard-Progression bleibt aktiv.",
                tacticalTip: "Behalte das Tempo, den Fokus und die Pausenintervalle exakt bei. Du bist optimal austariert."
            )

        case .anxiety:
            // Ueberforderung / Stress -> Drosselung um 4 % bis 8 %
            let loadDec: Double = feedback.rpeScore >= 9.5 ? -8.0 : -4.0
            return FlowTuningResult(
                loadAdjustmentPercent: loadDec,
                restIntervalAdjustmentSeconds: 20,
                targetRepsModifier: -1,
                coachingDirective: "Ueberlastung detektiert. Entlastungs-Drosselung um \(abs(Int(loadDec))) % eingeleitet.",
                tacticalTip: "Teile anstrengende Saetze mental in Micro-Steps auf. Verlaengere die Satzpause, um das Nervensystem zu regenerieren."
            )
        }
    }
}
