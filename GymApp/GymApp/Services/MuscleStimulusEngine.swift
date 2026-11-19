import SwiftUI
import Foundation

public enum AnatomicalZone: String, CaseIterable, Identifiable, Codable {
    // Anterior (Vorderseite)
    case chest = "Brust"
    case frontDelts = "Vordere Schultern"
    case biceps = "Bizeps"
    case forearms = "Unterarme"
    case abdominals = "Bauchmuskeln"
    case obliques = "Seitliche Bauchmuskeln"
    case quads = "Quadrizeps"
    case calvesAnterior = "Waden"

    // Posterior (Rueckseite)
    case traps = "Trapez & Nacken"
    case rearDelts = "Hintere Schultern"
    case lats = "Latissimus & Oberer Ruecken"
    case triceps = "Trizeps"
    case lowerBack = "Unterer Ruecken"
    case glutes = "Gluteus"
    case hamstrings = "Ischios / Beinbeuger"
    case calvesPosterior = "Waden (Posterior)"

    public var id: String { rawValue }

    public var isAnterior: Bool {
        switch self {
        case .chest, .frontDelts, .biceps, .forearms, .abdominals, .obliques, .quads, .calvesAnterior:
            return true
        default:
            return false
        }
    }

    public var isPosterior: Bool {
        switch self {
        case .traps, .rearDelts, .lats, .triceps, .lowerBack, .glutes, .hamstrings, .calvesPosterior:
            return true
        default:
            return false
        }
    }

    public var displayName: String {
        switch self {
        case .calvesAnterior, .calvesPosterior:
            return "Waden"
        default:
            return rawValue
        }
    }

    public var matchingMuscleGroup: MuscleGroup {
        switch self {
        case .chest: return .chest
        case .frontDelts, .rearDelts: return .shoulders
        case .biceps, .triceps, .forearms: return .arms
        case .abdominals, .obliques: return .functionalCore
        case .lowerBack: return .lowerBack
        case .traps, .lats: return .back
        case .glutes, .hamstrings: return .glutesPosterior
        case .quads, .calvesAnterior, .calvesPosterior: return .legs
        }
    }

    public var antagonisticZones: Set<AnatomicalZone> {
        switch self {
        case .chest: return [.lats, .rearDelts]
        case .lats: return [.chest, .frontDelts]
        case .biceps: return [.triceps]
        case .triceps: return [.biceps, .forearms]
        case .frontDelts: return [.rearDelts, .lats]
        case .rearDelts: return [.frontDelts, .chest]
        case .quads: return [.hamstrings, .glutes]
        case .hamstrings: return [.quads]
        case .glutes: return [.quads]
        case .abdominals: return [.lowerBack]
        case .obliques: return [.lowerBack]
        case .lowerBack: return [.abdominals]
        case .traps: return [.lats]
        case .forearms: return [.biceps]
        case .calvesAnterior: return [.calvesPosterior]
        case .calvesPosterior: return [.calvesAnterior]
        }
    }

    public var synergisticZones: Set<AnatomicalZone> {
        switch self {
        case .chest: return [.frontDelts, .triceps]
        case .frontDelts: return [.chest, .triceps, .traps]
        case .rearDelts: return [.traps, .lats, .biceps]
        case .biceps: return [.forearms, .lats]
        case .triceps: return [.chest, .frontDelts]
        case .forearms: return [.biceps]
        case .abdominals: return [.obliques]
        case .obliques: return [.abdominals, .lowerBack]
        case .lowerBack: return [.glutes, .hamstrings]
        case .glutes: return [.hamstrings, .lowerBack]
        case .hamstrings: return [.glutes, .calvesPosterior]
        case .quads: return [.glutes, .calvesAnterior]
        case .traps: return [.rearDelts, .frontDelts]
        case .lats: return [.biceps, .rearDelts, .traps]
        case .calvesAnterior, .calvesPosterior: return [.hamstrings, .quads]
        }
    }

    public var stabilizerZones: Set<AnatomicalZone> {
        switch self {
        case .chest, .frontDelts, .triceps: return [.abdominals, .lowerBack]
        case .lats, .rearDelts, .traps: return [.lowerBack, .abdominals]
        case .biceps, .forearms: return [.frontDelts, .abdominals]
        case .quads, .hamstrings, .glutes: return [.abdominals, .lowerBack]
        case .abdominals, .obliques, .lowerBack: return [.glutes, .traps]
        case .calvesAnterior, .calvesPosterior: return [.abdominals]
        }
    }
}

public enum StimulusIntensityLevel: String, CaseIterable {
    case none = "Kein Reiz"
    case light = "Leichter Reiz"
    case medium = "Mittlerer Reiz"
    case high = "Hoher Reiz"
    case extreme = "Maximaler Reiz (Zielmuskel brennt)"

    public var color: Color {
        switch self {
        case .none:
            return Color(red: 0.16, green: 0.15, blue: 0.14) // Muted slate surface
        case .light:
            return Color(red: 0.96, green: 0.62, blue: 0.12) // Warm Amber Orange (#F59E0B)
        case .medium:
            return Color(red: 0.98, green: 0.45, blue: 0.08) // Vivid Electric Orange (#F97316)
        case .high:
            return Color(red: 0.94, green: 0.22, blue: 0.18) // Fiery Signal Red (#EF4444)
        case .extreme:
            return Color(red: 0.72, green: 0.10, blue: 0.10) // Deep Crimson Red (#B91C1C)
        }
    }

    public var hexString: String {
        switch self {
        case .none: return "#292624"
        case .light: return "#F59E0B"
        case .medium: return "#F97316"
        case .high: return "#EF4444"
        case .extreme: return "#B91C1C"
        }
    }
}

public struct MuscleContribution: Identifiable {
    public var id: String { exerciseName }
    public var exerciseName: String
    public var sets: Int
    public var isPrimary: Bool
}

public struct MuscleZoneStimulus: Identifiable {
    public var id: AnatomicalZone { zone }
    public var zone: AnatomicalZone
    public var effectiveScore: Double
    public var totalSets: Int
    public var intensity: StimulusIntensityLevel
    public var contributions: [MuscleContribution]

    public var color: Color {
        intensity.color
    }
}

public final class MuscleStimulusEngine {
    public static let shared = MuscleStimulusEngine()

    private init() {}

    // MARK: - Exercise to Anatomical Zones Resolver
    public func resolveZones(for exercise: Exercise) -> (primary: [AnatomicalZone], secondary: [AnatomicalZone]) {
        let nameLower = exercise.name.lowercased()
        var primary: [AnatomicalZone] = []
        var secondary: [AnatomicalZone] = []

        // Primary base mapping by targetMuscle enum
        switch exercise.targetMuscle {
        case .chest:
            primary.append(.chest)
            secondary.append(contentsOf: [.frontDelts, .triceps])
        case .shoulders:
            if nameLower.contains("rear") || nameLower.contains("hinter") || nameLower.contains("face pull") || nameLower.contains("rhomboideus") {
                primary.append(.rearDelts)
                secondary.append(contentsOf: [.traps, .lats])
            } else {
                primary.append(.frontDelts)
                secondary.append(contentsOf: [.traps, .triceps])
            }
        case .back:
            primary.append(.lats)
            secondary.append(contentsOf: [.traps, .rearDelts, .biceps])
        case .lowerBack:
            primary.append(.lowerBack)
            secondary.append(contentsOf: [.glutes, .hamstrings])
        case .functionalCore:
            if nameLower.contains("oblique") || nameLower.contains("seit") || nameLower.contains("rotary") || nameLower.contains("torso") {
                primary.append(.obliques)
                secondary.append(.abdominals)
            } else {
                primary.append(.abdominals)
                secondary.append(contentsOf: [.obliques, .lowerBack])
            }
        case .glutesPosterior:
            if nameLower.contains("rdl") || nameLower.contains("kreuzheben") || nameLower.contains("curl") || nameLower.contains("beug") {
                primary.append(contentsOf: [.hamstrings, .glutes])
                secondary.append(.lowerBack)
            } else {
                primary.append(.glutes)
                secondary.append(contentsOf: [.hamstrings, .lowerBack])
            }
        case .legs:
            if nameLower.contains("waden") || nameLower.contains("calf") {
                primary.append(contentsOf: [.calvesAnterior, .calvesPosterior])
            } else if nameLower.contains("addukt") || nameLower.contains("abdukt") {
                primary.append(.glutes)
            } else {
                primary.append(.quads)
                secondary.append(contentsOf: [.glutes, .calvesPosterior])
            }
        case .arms:
            if nameLower.contains("trizeps") || nameLower.contains("dip") || nameLower.contains("pushdown") || nameLower.contains("french") {
                primary.append(.triceps)
                secondary.append(.chest)
            } else {
                primary.append(.biceps)
                secondary.append(.forearms)
            }
        case .cardioConditioning:
            secondary.append(contentsOf: [.quads, .calvesAnterior, .calvesPosterior, .abdominals])
        case .mobilityFlexibility:
            primary.append(contentsOf: [.lowerBack, .hamstrings])
            secondary.append(contentsOf: [.glutes, .lats, .abdominals])
        }

        // Secondary muscles explicitly declared on the model
        for sec in exercise.secondaryMuscles {
            let secResolved = resolveBaseZones(for: sec)
            for z in secResolved where !primary.contains(z) && !secondary.contains(z) {
                secondary.append(z)
            }
        }

        // Name-based fine-tuning overrides
        if nameLower.contains("bankdruecken") || nameLower.contains("bench") || nameLower.contains("push-up") || nameLower.contains("liegestuetz") {
            if !primary.contains(.chest) { primary.append(.chest) }
            if !secondary.contains(.frontDelts) { secondary.append(.frontDelts) }
            if !secondary.contains(.triceps) { secondary.append(.triceps) }
        } else if nameLower.contains("klimmzug") || nameLower.contains("latzug") || nameLower.contains("pull-up") || nameLower.contains("pulldown") {
            if !primary.contains(.lats) { primary.append(.lats) }
            if !secondary.contains(.biceps) { secondary.append(.biceps) }
        } else if nameLower.contains("rudern") || nameLower.contains("row") {
            if !primary.contains(.lats) { primary.append(.lats) }
            if !secondary.contains(.rearDelts) { secondary.append(.rearDelts) }
            if !secondary.contains(.biceps) { secondary.append(.biceps) }
        } else if nameLower.contains("hyperextension") || nameLower.contains("rueckenstrecken") {
            if !primary.contains(.lowerBack) { primary.append(.lowerBack) }
            if !secondary.contains(.glutes) { secondary.append(.glutes) }
        } else if nameLower.contains("plank") || nameLower.contains("pallof") || nameLower.contains("bird-dog") {
            if !primary.contains(.abdominals) { primary.append(.abdominals) }
            if !secondary.contains(.obliques) { secondary.append(.obliques) }
            if !secondary.contains(.lowerBack) { secondary.append(.lowerBack) }
        } else if nameLower.contains("dehn") || nameLower.contains("stretch") || nameLower.contains("katze") || nameLower.contains("kindhaltung") {
            if !primary.contains(.lowerBack) { primary.append(.lowerBack) }
            if !secondary.contains(.lats) { secondary.append(.lats) }
        }

        return (primary, secondary)
    }

    // MARK: - 3-Tier Anatomical Zone Distribution (Primary, Secondary, Stabilizers)
    public func resolveThreeTierZones(for exercise: Exercise) -> (primary: [AnatomicalZone], secondary: [AnatomicalZone], stabilizers: [AnatomicalZone]) {
        let (primary, secondary) = resolveZones(for: exercise)
        var stabilizers: [AnatomicalZone] = []

        // 1. Check detailed stabilizers declared on model
        for rawName in exercise.stabilizersDetailed {
            if let zone = mapDetailedNameToZone(rawName) {
                if !primary.contains(zone) && !secondary.contains(zone) && !stabilizers.contains(zone) {
                    stabilizers.append(zone)
                }
            }
        }

        // 2. Postural stabilization patterns if none explicitly found
        if stabilizers.isEmpty {
            switch exercise.targetMuscle {
            case .chest:
                stabilizers.append(contentsOf: [.abdominals, .lats, .rearDelts])
            case .shoulders:
                stabilizers.append(contentsOf: [.abdominals, .lowerBack, .traps])
            case .back:
                stabilizers.append(contentsOf: [.abdominals, .lowerBack, .forearms])
            case .lowerBack:
                stabilizers.append(contentsOf: [.abdominals, .obliques, .glutes])
            case .functionalCore:
                stabilizers.append(contentsOf: [.glutes, .lowerBack, .frontDelts])
            case .glutesPosterior:
                stabilizers.append(contentsOf: [.abdominals, .lowerBack, .quads])
            case .legs:
                stabilizers.append(contentsOf: [.abdominals, .lowerBack, .glutes])
            case .arms:
                stabilizers.append(contentsOf: [.forearms, .frontDelts, .abdominals])
            case .cardioConditioning:
                stabilizers.append(contentsOf: [.abdominals, .lowerBack])
            case .mobilityFlexibility:
                stabilizers.append(contentsOf: [.abdominals, .traps])
            }
            stabilizers.removeAll { primary.contains($0) || secondary.contains($0) }
        }

        return (primary, secondary, stabilizers)
    }

    // MARK: - Antagonists & Functional Roles Resolution
    public func resolveAntagonists(for zones: [AnatomicalZone]) -> [AnatomicalZone] {
        var antagonists: Set<AnatomicalZone> = []
        for z in zones {
            switch z {
            case .chest:
                antagonists.formUnion([.lats, .rearDelts, .traps])
            case .frontDelts:
                antagonists.formUnion([.rearDelts, .lats])
            case .biceps:
                antagonists.formUnion([.triceps])
            case .triceps:
                antagonists.formUnion([.biceps])
            case .forearms:
                antagonists.formUnion([])
            case .abdominals, .obliques:
                antagonists.formUnion([.lowerBack])
            case .lowerBack:
                antagonists.formUnion([.abdominals, .obliques])
            case .quads:
                antagonists.formUnion([.hamstrings])
            case .hamstrings:
                antagonists.formUnion([.quads])
            case .glutes:
                antagonists.formUnion([.quads])
            case .calvesAnterior:
                antagonists.formUnion([.calvesPosterior])
            case .calvesPosterior:
                antagonists.formUnion([.calvesAnterior])
            case .traps:
                antagonists.formUnion([.chest, .frontDelts])
            case .rearDelts:
                antagonists.formUnion([.frontDelts, .chest])
            case .lats:
                antagonists.formUnion([.chest, .frontDelts])
            }
        }
        antagonists.subtract(zones)
        return Array(antagonists)
    }

    public func resolveWorkoutFunctionalRoles(for session: WorkoutSession) -> (
        agonists: [AnatomicalZone],
        synergists: [AnatomicalZone],
        antagonists: [AnatomicalZone],
        stabilizers: [AnatomicalZone]
    ) {
        var allPrimary = Set<AnatomicalZone>()
        var allSecondary = Set<AnatomicalZone>()
        var allStabilizers = Set<AnatomicalZone>()

        for exRecord in session.exercises {
            let (prim, sec, stab) = resolveThreeTierZones(for: exRecord.exercise)
            allPrimary.formUnion(prim)
            allSecondary.formUnion(sec)
            allStabilizers.formUnion(stab)
        }

        allSecondary.subtract(allPrimary)
        allStabilizers.subtract(allPrimary)
        allStabilizers.subtract(allSecondary)

        let allAntagonists = resolveAntagonists(for: Array(allPrimary))
            .filter { !allPrimary.contains($0) && !allSecondary.contains($0) }

        return (
            Array(allPrimary),
            Array(allSecondary),
            allAntagonists,
            Array(allStabilizers)
        )
    }

    private func mapDetailedNameToZone(_ name: String) -> AnatomicalZone? {
        let lower = name.lowercased()
        if lower.contains("brust") || lower.contains("pectoral") { return .chest }
        if (lower.contains("vorder") && lower.contains("schulter")) || lower.contains("anterior delt") { return .frontDelts }
        if (lower.contains("hinter") && lower.contains("schulter")) || lower.contains("rear delt") { return .rearDelts }
        if lower.contains("schulter") || lower.contains("deltoid") { return .frontDelts }
        if lower.contains("bizeps") || lower.contains("biceps") { return .biceps }
        if lower.contains("trizeps") || lower.contains("triceps") { return .triceps }
        if lower.contains("unterarm") || lower.contains("forearm") || lower.contains("brachiorad") { return .forearms }
        if lower.contains("bauch") || lower.contains("core") || lower.contains("rumpf") || lower.contains("abdomin") { return .abdominals }
        if lower.contains("oblique") || lower.contains("seitlich") { return .obliques }
        if lower.contains("lat") || lower.contains("oberer rücken") || lower.contains("rücken") { return .lats }
        if lower.contains("trapez") || lower.contains("nacken") { return .traps }
        if lower.contains("unterer rücken") || lower.contains("erector") || lower.contains("spinal") { return .lowerBack }
        if lower.contains("glute") || lower.contains("gesäß") { return .glutes }
        if lower.contains("quad") || lower.contains("schenkel") { return .quads }
        if lower.contains("ischio") || lower.contains("hamstring") || lower.contains("beinbeuger") { return .hamstrings }
        if lower.contains("wade") || lower.contains("calf") { return .calvesPosterior }
        return nil
    }

    private func resolveBaseZones(for group: MuscleGroup) -> [AnatomicalZone] {
        switch group {
        case .chest: return [.chest]
        case .shoulders: return [.frontDelts, .rearDelts]
        case .back: return [.lats, .traps]
        case .lowerBack: return [.lowerBack]
        case .functionalCore: return [.abdominals, .obliques]
        case .glutesPosterior: return [.glutes, .hamstrings]
        case .legs: return [.quads, .calvesAnterior, .calvesPosterior]
        case .arms: return [.biceps, .triceps, .forearms]
        case .cardioConditioning: return [.abdominals, .quads]
        case .mobilityFlexibility: return [.lowerBack, .hamstrings, .glutes, .lats]
        }
    }

    // MARK: - Stimulus Calculation
    public func calculateStimulus(from items: [WorkoutTemplateItem]) -> [AnatomicalZone: MuscleZoneStimulus] {
        var zoneScores: [AnatomicalZone: Double] = [:]
        var zoneSets: [AnatomicalZone: Int] = [:]
        var contributionsMap: [AnatomicalZone: [MuscleContribution]] = [:]

        for zone in AnatomicalZone.allCases {
            zoneScores[zone] = 0.0
            zoneSets[zone] = 0
            contributionsMap[zone] = []
        }

        for item in items {
            let sets = max(1, item.targetSets)
            let (primary, secondary) = resolveZones(for: item.exercise)

            for p in primary {
                zoneScores[p, default: 0.0] += Double(sets) * 1.0
                zoneSets[p, default: 0] += sets
                contributionsMap[p, default: []].append(
                    MuscleContribution(exerciseName: item.exercise.name, sets: sets, isPrimary: true)
                )
            }

            for s in secondary {
                zoneScores[s, default: 0.0] += Double(sets) * 0.5
                zoneSets[s, default: 0] += sets
                contributionsMap[s, default: []].append(
                    MuscleContribution(exerciseName: item.exercise.name, sets: sets, isPrimary: false)
                )
            }
        }

        var result: [AnatomicalZone: MuscleZoneStimulus] = [:]
        for zone in AnatomicalZone.allCases {
            let score = zoneScores[zone, default: 0.0]
            let sets = zoneSets[zone, default: 0]
            let intensity = level(for: score)
            result[zone] = MuscleZoneStimulus(
                zone: zone,
                effectiveScore: score,
                totalSets: sets,
                intensity: intensity,
                contributions: contributionsMap[zone, default: []]
            )
        }

        return result
    }

    public func calculateStimulus(for session: WorkoutSession) -> [AnatomicalZone: MuscleZoneStimulus] {
        var items: [WorkoutTemplateItem] = []
        for se in session.exercises {
            let completedSets = se.sets.filter { $0.isCompleted }.count
            let effectiveSets = completedSets > 0 ? completedSets : se.sets.count
            items.append(WorkoutTemplateItem(
                exercise: se.exercise,
                targetSets: max(1, effectiveSets)
            ))
        }
        return calculateStimulus(from: items)
    }

    /// Aggregates cumulative muscle volume and stimulus across multiple historical sessions over a specified time horizon.
    public func calculateCumulativeStimulus(for sessions: [WorkoutSession]) -> [AnatomicalZone: MuscleZoneStimulus] {
        var items: [WorkoutTemplateItem] = []
        for session in sessions {
            for se in session.exercises {
                let completedSets = se.sets.filter { $0.isCompleted }.count
                let effectiveSets = completedSets > 0 ? completedSets : se.sets.count
                if effectiveSets > 0 {
                    items.append(WorkoutTemplateItem(
                        exercise: se.exercise,
                        targetSets: effectiveSets
                    ))
                }
            }
        }
        return calculateStimulus(from: items)
    }

    public func calculateStimulus(for template: WorkoutTemplate) -> [AnatomicalZone: MuscleZoneStimulus] {
        return calculateStimulus(from: template.items)
    }

    // MARK: - Intensity Tier Mapping
    public func level(for score: Double) -> StimulusIntensityLevel {
        if score <= 0.05 {
            return .none
        } else if score < 3.5 {
            return .light // 1-3 sets
        } else if score < 6.5 {
            return .medium // 4-6 sets
        } else if score < 9.5 {
            return .high // 7-9 sets
        } else {
            return .extreme // 10+ sets ("Hurts")
        }
    }
}
