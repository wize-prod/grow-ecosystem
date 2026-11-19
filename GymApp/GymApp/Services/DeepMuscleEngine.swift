import Foundation

// MARK: - Tiefenmuskel-Analyse-Report
public struct DeepMuscleAnalysisReport: Identifiable {
    public var id = UUID()
    public var evaluatedAt: Date
    public var totalMusclesTracked: Int
    public var overallSymmetryScore: Double // 0.0 bis 100.0
    public var strongestMuscles: [MuscleEvaluationMetric]
    public var weakestMuscles: [MuscleEvaluationMetric]
    public var criticalDeficits: [MuscleEvaluationMetric]
    public var regionHealth: [MuscleRegion: Double] // Region -> Durchschnittsscore (0-100)
    public var recommendedProgramBlock: ProgramBlock
    public var recommendedArchetype: CalisthenicArchetype?
    public var coachRecommendationRationale: String
    public var clinicalPrehabPrescription: String
}

public final class DeepMuscleEngine {
    public static let shared = DeepMuscleEngine()

    private init() {}

    // MARK: - Hauptanalyse aller abgeschlossenen Einheiten
    public func evaluateAllMuscles(sessions: [WorkoutSession]) -> DeepMuscleAnalysisReport {
        let allEntities = DeepMuscleIndex.allMuscles
        let now = Date()

        // 1. Berechne kumulierte Stimuli pro Muskel-ID
        var muscleStimulusMap: [String: (totalEffectiveSets: Double, lastDate: Date?)] = [:]
        for m in allEntities {
            muscleStimulusMap[m.id] = (0.0, nil)
        }

        // Durchlaufe alle Trainingssitzungen
        for session in sessions {
            let sessionDate = session.startTime

            if session.exercises.isEmpty {
                // Externe Einheit (z. B. Apple Health / Strava Lauf)
                let text = (session.title + " " + session.somaticNotes).lowercased()
                if text.contains("lauf") || text.contains("run") || text.contains("jog") || text.contains("sprint") || text.contains("25km") {
                    let runningAttributions: [String: Double] = [
                        "soleus": 1.0,
                        "gastrocnemius": 0.9,
                        "tibialis_anterior": 0.85,
                        "tibialis_posterior": 0.8,
                        "gluteus_maximus": 0.75,
                        "gluteus_medius_minimus": 0.65,
                        "vastus_medialis": 0.65,
                        "biceps_femoris": 0.65,
                        "rectus_femoris": 0.6,
                        "transversus_abdominis": 0.5,
                        "iliopsoas": 0.55
                    ]
                    let durationMins = max(20.0, Double(session.durationMinutes))
                    let setsCount = min(20.0, max(4.0, durationMins / 5.0))
                    for (muscleId, weight) in runningAttributions {
                        let effectiveSets = setsCount * weight
                        let current = muscleStimulusMap[muscleId] ?? (0.0, nil)
                        let newSets = current.totalEffectiveSets + effectiveSets
                        let newDate = current.lastDate.map { max($0, sessionDate) } ?? sessionDate
                        muscleStimulusMap[muscleId] = (newSets, newDate)
                    }
                }
            } else {
                for item in session.exercises {
                    let setsCount = max(Double(item.completedSetsCount), Double(item.sets.filter { $0.isCompleted || $0.reps > 0 }.count))
                    guard setsCount > 0 else { continue }

                    // Attribuiere kinetische Last
                    let attributions = attributeExerciseStimulus(exerciseName: item.exercise.name, targetMuscle: item.exercise.targetMuscle)
                    for (muscleId, weight) in attributions {
                        let effectiveSets = setsCount * weight
                        let current = muscleStimulusMap[muscleId] ?? (0.0, nil)
                        let newSets = current.totalEffectiveSets + effectiveSets
                        let newDate: Date
                        if let existing = current.lastDate {
                            newDate = max(existing, sessionDate)
                        } else {
                            newDate = sessionDate
                        }
                        muscleStimulusMap[muscleId] = (newSets, newDate)
                    }
                }
            }
        }

        // 2. Erstelle detaillierte Muskel-Metriken mit Zeit-Zerfall
        var evaluations: [MuscleEvaluationMetric] = []
        for muscle in allEntities {
            let (sets, lastDate) = muscleStimulusMap[muscle.id] ?? (0.0, nil)
            let daysAgo: Int
            if let ld = lastDate {
                daysAgo = max(0, Calendar.current.dateComponents([.day], from: ld, to: now).day ?? 0)
            } else {
                daysAgo = 90 // Nie trainiert -> Maximaler Zerfall
            }

            // Exponentieller Zerfall (Halbwertszeit 21 Tage fuer Stabilisatoren, 30 Tage fuer Primaerbeweger)
            let halfLifeDays: Double = (muscle.tier == .deepStabilizer) ? 21.0 : 28.0
            let decayFactor = pow(0.5, Double(daysAgo) / halfLifeDays)

            // Berechne Staerkescore (0 bis 100)
            // 15 effektive Saetze bei vollem Reizfaktor entsprechen 100 Punkten
            let rawScore = min(100.0, (sets / 15.0) * 100.0)
            let currentScore = max(0.0, rawScore * decayFactor)

            let status: MuscleBalanceStatus
            if currentScore >= 70.0 {
                status = .peak
            } else if currentScore >= 40.0 {
                status = .adequate
            } else if currentScore >= 18.0 {
                status = .lagging
            } else {
                status = .criticalNeglect
            }

            evaluations.append(
                MuscleEvaluationMetric(
                    muscle: muscle,
                    effectiveVolumeScore30Days: sets,
                    daysSinceLastStimulus: daysAgo,
                    decayFactor: decayFactor,
                    currentStrengthScore: currentScore,
                    status: status
                )
            )
        }

        // 3. Sortierungen & Regionen-Aggregation
        let sorted = evaluations.sorted(by: { $0.currentStrengthScore > $1.currentStrengthScore })
        let strongest = Array(sorted.prefix(5))
        let weakest = Array(sorted.reversed().prefix(5))
        let critical = evaluations.filter { $0.status == .criticalNeglect || $0.status == .lagging }

        var regionScores: [MuscleRegion: [Double]] = [:]
        for ev in evaluations {
            regionScores[ev.muscle.region, default: []].append(ev.currentStrengthScore)
        }

        var regionHealthMap: [MuscleRegion: Double] = [:]
        for (reg, scores) in regionScores {
            let avg = scores.reduce(0.0, +) / Double(max(1, scores.count))
            regionHealthMap[reg] = avg
        }

        let overallSymmetry = evaluations.map(\.currentStrengthScore).reduce(0.0, +) / Double(max(1, evaluations.count))

        // 4. KI-Vorhersage & Empfehlung fuer das naechste Trainingsprogramm
        let (recBlock, recArchetype, rationale, prehab) = generateRecommendation(
            regionHealth: regionHealthMap,
            weakestMuscles: weakest,
            evaluations: evaluations
        )

        return DeepMuscleAnalysisReport(
            evaluatedAt: now,
            totalMusclesTracked: allEntities.count,
            overallSymmetryScore: overallSymmetry,
            strongestMuscles: strongest,
            weakestMuscles: weakest,
            criticalDeficits: critical,
            regionHealth: regionHealthMap,
            recommendedProgramBlock: recBlock,
            recommendedArchetype: recArchetype,
            coachRecommendationRationale: rationale,
            clinicalPrehabPrescription: prehab
        )
    }

    // MARK: - Kinetische Lasten-Attribution (Uebung -> Muskeln mit Gewichtung)
    private func attributeExerciseStimulus(exerciseName: String, targetMuscle: MuscleGroup? = nil) -> [String: Double] {
        let name = exerciseName.lowercased()

        // 1. Spezifische Rumpf- & Reha-Uebungen (McGill Big 3, Deadbug, Stabi)
        if name.contains("curl-up") || name.contains("curlup") || name.contains("mcgill") && !name.contains("side") {
            return [
                "rectus_abdominis": 1.0,
                "transversus_abdominis": 0.9,
                "obliquus_internus_externus": 0.75,
                "longus_colli": 0.55
            ]
        }
        if name.contains("deadbug") {
            return [
                "transversus_abdominis": 1.0,
                "rectus_abdominis": 0.85,
                "multifidi": 0.75,
                "iliopsoas": 0.75,
                "pelvic_floor_levator_ani": 0.65
            ]
        }
        if name.contains("side plank") || name.contains("seitstuetz") || name.contains("seitstütz") {
            return [
                "quadratus_lumborum": 1.0,
                "obliquus_internus_externus": 0.95,
                "gluteus_medius_minimus": 0.9,
                "transversus_abdominis": 0.8,
                "serratus_anterior": 0.75
            ]
        }
        if name.contains("kindeshaltung") || name.contains("child") || name.contains("dekompression") {
            return [
                "erector_spinae": 0.9,
                "multifidi": 0.85,
                "latissimus_dorsi": 0.6,
                "quadratus_lumborum": 0.7
            ]
        }

        // 2. Druckuebungen (Bankdruecken, Liegestuetze, Dips, Trizeps)
        if name.contains("bankdruecken") || name.contains("bench") || (name.contains("press") && name.contains("chest")) {
            return [
                "pectoralis_major": 1.0,
                "deltoideus_lateralis": 0.6,
                "serratus_anterior": 0.5,
                "infraspinatus_teres_minor": 0.35,
                "subscapularis": 0.4
            ]
        }
        if name.contains("liegestuetz") || name.contains("pushup") || name.contains("push-up") {
            return [
                "pectoralis_major": 0.85,
                "serratus_anterior": 0.9,
                "triceps_brachii": 0.75,
                "transversus_abdominis": 0.65,
                "multifidi": 0.45,
                "longus_colli": 0.4
            ]
        }
        if name.contains("dips") || name.contains("barren") {
            return [
                "pectoralis_major": 0.8,
                "serratus_anterior": 0.85,
                "triceps_brachii": 0.85,
                "rhomboidei": 0.5,
                "trapezius_ascendens": 0.4
            ]
        }
        if name.contains("trizeps") || name.contains("triceps") || name.contains("bettkante") {
            return [
                "triceps_brachii": 1.0,
                "serratus_anterior": 0.5,
                "pectoralis_major": 0.4
            ]
        }

        // 3. Zuguebungen (Klimmzuege, Rudern, Face Pulls)
        if name.contains("klimmzug") || name.contains("pull-up") || name.contains("chin-up") || name.contains("lat") {
            return [
                "latissimus_dorsi": 1.0,
                "rhomboidei": 0.8,
                "brachialis": 0.75,
                "biceps_brachii": 0.7,
                "forearm_flexors": 0.75,
                "trapezius_ascendens": 0.6,
                "splenius_capitis": 0.4,
                "transversus_abdominis": 0.4
            ]
        }
        if name.contains("rudern") || name.contains("row") {
            return [
                "rhomboidei": 1.0,
                "latissimus_dorsi": 0.85,
                "infraspinatus_teres_minor": 0.7,
                "trapezius_ascendens": 0.75,
                "multifidi": 0.5,
                "brachialis": 0.6
            ]
        }
        if name.contains("face pull") || name.contains("facepull") {
            return [
                "infraspinatus_teres_minor": 1.0,
                "rhomboidei": 0.85,
                "deltoideus_lateralis": 0.7,
                "trapezius_ascendens": 0.8,
                "splenius_capitis": 0.6,
                "suboccipitales": 0.5
            ]
        }

        // 4. Rumpf & Haltung (Plank, Bird-Dog, Glute Bridge, Pallof)
        if name.contains("plank") || name.contains("unterarmstuetz") {
            return [
                "transversus_abdominis": 1.0,
                "rectus_abdominis": 0.85,
                "multifidi": 0.85,
                "pelvic_floor_levator_ani": 0.7,
                "serratus_anterior": 0.6,
                "longus_colli": 0.5,
                "gluteus_maximus": 0.5
            ]
        }
        if name.contains("bird-dog") || name.contains("vierfuessler") {
            return [
                "multifidi": 1.0,
                "gluteus_maximus": 0.85,
                "transversus_abdominis": 0.8,
                "quadratus_lumborum": 0.7,
                "longus_colli": 0.5
            ]
        }
        if name.contains("glute bridge") || name.contains("beckenheben") {
            return [
                "gluteus_maximus": 1.0,
                "gluteus_medius_minimus": 0.75,
                "semitendinosus_semimembranosus": 0.7,
                "multifidi": 0.6,
                "pelvic_floor_levator_ani": 0.65
            ]
        }
        if name.contains("pallof") || name.contains("anti-rotation") {
            return [
                "transversus_abdominis": 1.0,
                "obliquus_internus_externus": 0.9,
                "multifidi": 0.8,
                "gluteus_medius_minimus": 0.6
            ]
        }

        // 5. Beine & Unterkoerper (Squats, Split Squats, RDL, Beinpresse)
        if name.contains("kniebeuge") || name.contains("squat") || name.contains("beinpresse") {
            return [
                "vastus_medialis": 1.0,
                "rectus_femoris": 0.85,
                "gluteus_maximus": 0.85,
                "gluteus_medius_minimus": 0.6,
                "multifidi": 0.55,
                "soleus": 0.5,
                "transversus_abdominis": 0.5
            ]
        }
        if name.contains("kreuzheben") || name.contains("rdl") || name.contains("deadlift") {
            return [
                "biceps_femoris": 1.0,
                "semitendinosus_semimembranosus": 0.95,
                "gluteus_maximus": 0.95,
                "erector_spinae": 0.85,
                "multifidi": 0.75,
                "forearm_flexors": 0.7,
                "latissimus_dorsi": 0.5
            ]
        }
        if name.contains("split squat") || name.contains("lunge") || name.contains("ausfallschritt") {
            return [
                "vastus_medialis": 0.9,
                "gluteus_medius_minimus": 0.95,
                "gluteus_maximus": 0.85,
                "piriformis_obturatorius": 0.75,
                "tibialis_anterior": 0.4
            ]
        }

        // 6. Ausdauer, Laufen & Sprints
        if name.contains("lauf") || name.contains("run") || name.contains("sprint") || name.contains("jog") {
            return [
                "soleus": 1.0,
                "gastrocnemius": 0.85,
                "tibialis_anterior": 0.8,
                "tibialis_posterior": 0.75,
                "gluteus_maximus": 0.7,
                "vastus_medialis": 0.6,
                "biceps_femoris": 0.65,
                "gluteus_medius_minimus": 0.6
            ]
        }

        // 7. Nacken & Schulterblatt spezifisch
        if name.contains("neck") || name.contains("nacken") || name.contains("shrug") {
            return [
                "splenius_capitis": 1.0,
                "longus_colli": 0.8,
                "suboccipitales": 0.8,
                "sternocleidomastoideus": 0.6
            ]
        }

        // 8. Intelligenter Fallback ueber TargetMuscle
        if let target = targetMuscle {
            switch target {
            case .functionalCore:
                return ["transversus_abdominis": 0.85, "rectus_abdominis": 0.85, "obliquus_internus_externus": 0.7, "multifidi": 0.6]
            case .lowerBack:
                return ["erector_spinae": 0.9, "multifidi": 0.85, "quadratus_lumborum": 0.75]
            case .back:
                return ["latissimus_dorsi": 0.9, "rhomboidei": 0.85, "trapezius_ascendens": 0.7]
            case .chest:
                return ["pectoralis_major": 0.9, "pectoralis_minor": 0.7, "serratus_anterior": 0.6]
            case .shoulders:
                return ["deltoideus_lateralis": 0.9, "supraspinatus": 0.6, "infraspinatus_teres_minor": 0.6]
            case .glutesPosterior:
                return ["gluteus_maximus": 0.9, "gluteus_medius_minimus": 0.8, "semitendinosus_semimembranosus": 0.7]
            case .legs:
                return ["vastus_medialis": 0.85, "rectus_femoris": 0.8, "soleus": 0.7, "gastrocnemius": 0.7]
            case .arms:
                return ["biceps_brachii": 0.85, "triceps_brachii": 0.85, "brachialis": 0.7]
            case .cardioConditioning:
                return ["soleus": 0.8, "gastrocnemius": 0.8, "tibialis_anterior": 0.7]
            case .mobilityFlexibility:
                return ["multifidi": 0.6, "erector_spinae": 0.6, "quadratus_lumborum": 0.6]
            }
        }

        // Letzter Fallback: Verteile moderaten Reiz auf Rumpf
        return [
            "transversus_abdominis": 0.4,
            "multifidi": 0.4
        ]
    }

    // MARK: - Intelligente Empfehlungs-Engine
    private func generateRecommendation(
        regionHealth: [MuscleRegion: Double],
        weakestMuscles: [MuscleEvaluationMetric],
        evaluations: [MuscleEvaluationMetric]
    ) -> (ProgramBlock, CalisthenicArchetype?, String, String) {
        // Finde Schwaechste Region
        let sortedRegions = regionHealth.sorted(by: { $0.value < $1.value })
        guard let lowestRegionTuple = sortedRegions.first else {
            return (.kraftHypertrophie, nil, "Ausgewogener Baseline-Zustand.", "Kein akuter Prehab-Bedarf.")
        }

        let lowestRegion = lowestRegionTuple.key
        let lowestScore = lowestRegionTuple.value

        // Pruefe auf BWK-kritische Defizite
        let bwkDeficits = evaluations.filter { $0.muscle.isBWKCoreCritical && ($0.status == .criticalNeglect || $0.status == .lagging) }
        if !bwkDeficits.isEmpty {
            let names = bwkDeficits.map(\.muscle.commonName).joined(separator: ", ")
            return (
                .mobilitaetReha,
                .prometheus,
                "Kritisches Defizit in den tiefen Rumpf- und Beckenstabilisatoren (\(names)). Hoechste Prioritaet gemaess BWK-Ulm Standard zur Vermeidung intraabdominaler Druckkrisen.",
                "Taeglich: 3x 45s Plank, 3x 12 Bird-Dog, Pallof Press und kontrollierte Zwerchfellatmung. Striktes Crunches-Verbot."
            )
        }

        // Regionale Zuordnungen
        switch lowestRegion {
        case .cranialJaw, .cervicalNeck, .shoulderScapula:
            return (
                .aesthetikSymmetrie,
                .apollo,
                "Defizit im Bereich Cranium/Kiefer (M. masseter, M. temporalis) oder Hals/Nacken (M. splenius capitis / tiefe Halsbeuger) und Scapula-Retraktoren (Score: \(Int(lowestScore))/100). Gefaehrdung von V-Taper, Haltung und Kopfaufrichtung.",
                "Erhöhung von Face Pulls (3x 15 Wdh), Scapular Retraktion an der Stange und isometrischen Nackenspannungen gegen Widerstand."
            )

        case .backLatUpper:
            return (
                .calisthenicsGoetter,
                .poseidon,
                "Ruecken- und Zugkraft-Defizit (Score: \(Int(lowestScore))/100). Der M. latissimus dorsi und die Rhomboideen benoetigen vertikale Zugreize.",
                "Fokus auf Klimmzuege im neutralen Griff, Scapula Pull-ups und horizontales Rudern."
            )

        case .spineMultifidi, .deepCorePelvis:
            return (
                .mobilitaetReha,
                .prometheus,
                "Tiefenstabilitaets-Rueckstand an der LWS und den segmentalen Multifidi (Score: \(Int(lowestScore))/100).",
                "Isometrische Stabilisation: Planks, Side Planks, Bird-Dog und Glute Bridges mit 2 Sekunden Peak-Kontraktion."
            )

        case .hipGluteRotator:
            return (
                .kraftHypertrophie,
                .hercules,
                "Hueft- und Gesaessmuskulatur (Gluteus medius/minimus & Piriformis) zeigen Rueckstand (Score: \(Int(lowestScore))/100). Risiko fuer Knievalgus.",
                "Bulgarian Split Squats, RDLs und einbeinige Glute Bridges zur symmetrischen Kraeftigung."
            )

        case .hamstringsPosterior:
            return (
                .kraftHypertrophie,
                nil,
                "Ungleichgewicht zwischen Kniestreckern (Quads) und Kniebeugern (Hamstrings). Verletzungsgefahr bei schnellen Antritten.",
                "Rumaenisches Kreuzheben (RDL), Beinbeuger an der Maschine und Nordic-Curl Progressionen."
            )

        case .lowerLegFoot:
            return (
                .ausdauerRunning,
                .hermes,
                "Unterschenkel- und Sprunggelenksstabilisatoren (M. soleus, M. tibialis anterior) unterbeansprucht (Score: \(Int(lowestScore))/100).",
                "Tibialis Raises an der Wand, Wadenheben stehend/sitzend und aerobe Zone-2 Dauerlaeufe."
            )

        case .chestThorax, .quadricepsThigh, .armsForearms:
            return (
                .kraftHypertrophie,
                .ares,
                "Allgemeine Hypertrophie-Akkumulation fuer den Ober- und Unterkoerper empfohlen (Score: \(Int(lowestScore))/100).",
                "Gefuehrte Grunduebungen mit RIR 2-3 zur Ausreizung der mechanischen Spannung."
            )
        }
    }
}
