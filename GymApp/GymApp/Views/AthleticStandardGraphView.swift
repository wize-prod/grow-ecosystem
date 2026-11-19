import SwiftUI

public struct AthleticStandardGraphView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var selectedLevelTab: GoalHierarchyLevel = .pillar
    @State private var selectedDiscipline: DisciplineCategory = .kraft
    @State private var selectedEquipmentFilter: EquipmentFilter = .all

    enum DisciplineCategory: String, CaseIterable, Identifiable {
        case kraft = "Krafttraining"
        case calisthenics = "Calisthenics"
        case cardio = "Cardio & Ausdauer"
        case stretching = "Stretching & Mobilitaet"
        case reha = "BWK-Ulm Core-Reha"

        var id: String { rawValue }

        var accentColor: Color {
            switch self {
            case .kraft: return GymTheme.accentRed
            case .calisthenics: return GymTheme.cyanAccent
            case .cardio: return Color(hex: "F39C12")
            case .stretching: return GymTheme.sageGreen
            case .reha: return Color(hex: "00B4D8")
            }
        }
    }

    enum EquipmentFilter: String, CaseIterable, Identifiable {
        case all = "Alle"
        case withEquipment = "Mit Geraeten"
        case noEquipment = "Ohne Geraete (Zimmer)"

        var id: String { rawValue }
    }

    // Sample / Live Metrics against Human Baseline
    private var benchmarkMetrics: [AthleticStandardMetric] {
        [
            AthleticStandardMetric(id: "5km_pace", title: "5 km Lauf-Pace", pillar: .ausdauerRunning, humanBaselineValue: 30.0, userCurrentValue: 24.5, unit: "min", isHigherBetter: false),
            AthleticStandardMetric(id: "bench_press", title: "Bankdruecken 1RM", pillar: .kraftHypertrophie, humanBaselineValue: 75.0, userCurrentValue: 92.5, unit: "kg", isHigherBetter: true),
            AthleticStandardMetric(id: "squat", title: "Kniebeuge 1RM", pillar: .kraftHypertrophie, humanBaselineValue: 90.0, userCurrentValue: 120.0, unit: "kg", isHigherBetter: true),
            AthleticStandardMetric(id: "pullups", title: "Klimmzuege (Dead Hang)", pillar: .calisthenicsGoetter, humanBaselineValue: 8.0, userCurrentValue: 14.0, unit: "Wdh", isHigherBetter: true),
            AthleticStandardMetric(id: "plank", title: "Statischer Plank (BWK)", pillar: .mobilitaetReha, humanBaselineValue: 60.0, userCurrentValue: 90.0, unit: "s", isHigherBetter: true),
            AthleticStandardMetric(id: "bft_sprint", title: "BFT Sprinttest 11x10m", pillar: .bundeswehrMilFit, humanBaselineValue: 45.0, userCurrentValue: 39.5, unit: "s", isHigherBetter: false),
            AthleticStandardMetric(id: "bft_1000m", title: "BFT 1000m Lauf", pillar: .bundeswehrMilFit, humanBaselineValue: 4.0, userCurrentValue: 3.4, unit: "min", isHigherBetter: false),
            AthleticStandardMetric(id: "v_taper", title: "V-Taper Schulter/Taille", pillar: .aesthetikSymmetrie, humanBaselineValue: 1.25, userCurrentValue: 1.42, unit: "Ratio", isHigherBetter: true)
        ]
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - 1. Stufen-Hierarchie Hero
                        tiersHeroCard

                        // MARK: - 2. Graph mit vertikaler Referenzlinie (Human Standard)
                        athleticStandardGraphCard

                        // MARK: - 3. 3-Ebenen-Zielsystem
                        goalsHierarchySection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Leistungs-Standard & Ziele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .foregroundColor(GymTheme.textPrimary)
                }
            }
        }
    }

    // MARK: - 1. Tiers Hero Card
    private var tiersHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DAS 5-STUFEN-LEISTUNGSMODELL")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.strongBlue)

                Spacer()

                Text("Sportwissenschaftlicher Standard")
                    .font(.system(size: 10))
                    .foregroundColor(GymTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(AthleticStandardTier.allCases) { tier in
                    HStack(spacing: 8) {
                        Text("\(tier.tierNumber)")
                            .font(.system(size: 10))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color(hex: tier.tierColorHex))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(tier.shortTitle)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(GymTheme.textPrimary)

                                if tier == .basicFunctional {
                                    Text("REFERENZ 1.0x")
                                        .font(.system(size: 8))
                                        .fontWeight(.heavy)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color(hex: "3498DB").opacity(0.2))
                                        .foregroundColor(Color(hex: "3498DB"))
                                        .cornerRadius(3)
                                }
                            }

                            Text(tier.description)
                                .font(.system(size: 9))
                                .foregroundColor(GymTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(String(format: "%.2fx", tier.relativeMultiplier))
                            .font(.system(size: 10))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: tier.tierColorHex))
                    }
                    .padding(8)
                    .background(GymTheme.surface)
                    .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }

    // MARK: - 2. Graph mit vertikaler Referenzlinie
    private var athleticStandardGraphCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEISTUNGS-SPEKTRUM GEGEN NORMALSTANDARD")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(GymTheme.textPrimary)

                    Text("Die vertikale Linie markiert den normalen menschlichen Durchschnitt (1.0x).")
                        .font(.system(size: 10))
                        .foregroundColor(GymTheme.textSecondary)
                }

                Spacer()
            }

            // Graph Header Legend
            HStack {
                Text("Metrik")
                    .font(.system(size: 9))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(width: 90, alignment: .leading)

                Spacer()

                HStack(spacing: 12) {
                    Text("Sub (0.5x)")
                    Text("Normal (1.0x)")
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "3498DB"))
                    Text("Amateur (1.75x)")
                    Text("Profi (2.75x)")
                }
                .font(.system(size: 8))
                .foregroundColor(GymTheme.textSecondary)
            }

            // Metrik-Balken mit vertikaler Referenzlinie
            VStack(spacing: 12) {
                ForEach(benchmarkMetrics) { metric in
                    metricGraphRow(metric: metric)
                }
            }
        }
        .padding(16)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }

    private func metricGraphRow(metric: AthleticStandardMetric) -> some View {
        let mult = metric.performanceMultiplier
        let delta = metric.deltaPercentageToHumanStandard
        let isAbove = delta >= 0

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(GymTheme.textPrimary)
                    .frame(width: 110, alignment: .leading)
                    .lineLimit(1)

                Spacer()

                Text("\(metric.userCurrentValue, specifier: "%.1f") \(metric.unit)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)

                Text(isAbove ? "+\(delta)%" : "\(delta)%")
                    .font(.system(size: 9))
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color(hex: metric.currentTier.tierColorHex).opacity(0.15))
                    .foregroundColor(Color(hex: metric.currentTier.tierColorHex))
                    .cornerRadius(3)
            }

            // Balken mit vertikaler 1.0x Referenzlinie
            GeometryReader { geo in
                let totalWidth = geo.size.width
                // 1.0x Standard liegt bei 35 % der Gesamtbreite
                let baselineX = totalWidth * 0.35
                // Max Skala = 3.0x (entspricht 100% Breite)
                let normalizedUserWidth = min(totalWidth, max(8, totalWidth * (CGFloat(mult) / 3.0)))

                ZStack(alignment: .leading) {
                    // Hintergrund
                    RoundedRectangle(cornerRadius: 3)
                        .fill(GymTheme.surface)
                        .frame(height: 8)

                    // Nutzer-Fortschrittsbalken
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: metric.currentTier.tierColorHex))
                        .frame(width: normalizedUserWidth, height: 8)

                    // VERTIKALE REFERENZLINIE: Normaler menschlicher Standard (1.0x)
                    Rectangle()
                        .fill(Color(hex: "3498DB"))
                        .frame(width: 2, height: 14)
                        .offset(x: baselineX - 1, y: -3)
                }
            }
            .frame(height: 12)
        }
    }

    // MARK: - 3. 3-Ebenen-Zielsystem
    private var goalsHierarchySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PFLICHT-ZIELSYSTEM (MINDESTENS 3 ZIELE PRO EBENE)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(GymTheme.textPrimary)

            // Tab Picker
            HStack(spacing: 8) {
                goalLevelTabButton(title: "Disziplin-Saeulen", level: .pillar)
                goalLevelTabButton(title: "Adaptive Zyklen", level: .program)
                goalLevelTabButton(title: "Session-Ziele", level: .session)
            }

            // Content per Tab
            switch selectedLevelTab {
            case .pillar:
                pillarGoalsList
            case .program:
                adaptiveCycleGoalsList
            case .session:
                sessionGoalsList
            }
        }
        .padding(16)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }

    private func goalLevelTabButton(title: String, level: GoalHierarchyLevel) -> some View {
        let isSelected = selectedLevelTab == level
        return Button {
            selectedLevelTab = level
            HapticFeedback.light()
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isSelected ? GymTheme.strongBlue : GymTheme.surface)
                .foregroundColor(isSelected ? .white : GymTheme.textSecondary)
                .cornerRadius(6)
        }
    }

    private var pillarGoalsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Disziplin-Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(DisciplineCategory.allCases) { disc in
                        let isSel = selectedDiscipline == disc
                        Button {
                            selectedDiscipline = disc
                            HapticFeedback.selection()
                        } label: {
                            Text(disc.rawValue)
                                .font(.caption2)
                                .fontWeight(isSel ? .bold : .medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSel ? disc.accentColor : GymTheme.surface)
                                .foregroundColor(isSel ? GymTheme.bg : GymTheme.textPrimary)
                                .cornerRadius(6)
                        }
                    }
                }
            }

            // Equipment Filter Pill Bar
            HStack(spacing: 6) {
                ForEach(EquipmentFilter.allCases) { eq in
                    let isSel = selectedEquipmentFilter == eq
                    Button {
                        selectedEquipmentFilter = eq
                        HapticFeedback.light()
                    } label: {
                        Text(eq.rawValue)
                            .font(.system(size: 9.5, weight: isSel ? .bold : .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isSel ? GymTheme.surfaceElevated : GymTheme.surface)
                            .foregroundColor(isSel ? GymTheme.cyanAccent : GymTheme.textSecondary)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(isSel ? GymTheme.cyanAccent.opacity(0.4) : Color.clear, lineWidth: 0.8))
                    }
                }
            }

            let goals = disciplineGoals(for: selectedDiscipline, filter: selectedEquipmentFilter)
            ForEach(goals) { goal in
                goalRow(goal: goal)
            }
        }
    }

    private func disciplineGoals(for disc: DisciplineCategory, filter: EquipmentFilter) -> [GoalItem] {
        switch disc {
        case .kraft:
            var list: [GoalItem] = []
            if filter != .noEquipment {
                list.append(GoalItem(level: .pillar, title: "Bankdruecken 1RM (1.2x Koerpergewicht)", targetMetricDescription: "Langhantel-Verbundkraft mit sauberer Rumpfspannung", targetValue: 95.0, currentValue: 92.5, unit: "kg", tierRequired: .advancedAmateur))
                list.append(GoalItem(level: .pillar, title: "Kniebeuge 1RM (1.5x Koerpergewicht)", targetMetricDescription: "Tiefe Kniebeuge mit kontrollierter intraabdomineller Atmung", targetValue: 120.0, currentValue: 120.0, unit: "kg", tierRequired: .advancedAmateur))
            }
            if filter != .withEquipment {
                list.append(GoalItem(level: .pillar, title: "Einarmige Liegestuetze (10 Wdh / Arm)", targetMetricDescription: "Unilaterale Maximalkraft & Rumpfantirotation ohne Gewichte", targetValue: 10.0, currentValue: 10.0, unit: "Wdh/Arm", tierRequired: .advancedAmateur))
            }
            return list

        case .calisthenics:
            return [
                GoalItem(level: .pillar, title: "Einarmige Liegestuetze (10 Wdh / Arm)", targetMetricDescription: "Strikte Rumpf- und Beckenstabilitaet ohne Ausweichen", targetValue: 10.0, currentValue: 10.0, unit: "Wdh/Arm", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "Klimmzuege Dead Hang (15 Wdh)", targetMetricDescription: "Volle Amplitude, Daumen ueber der Stange, 0 Schwung", targetValue: 15.0, currentValue: 14.0, unit: "Wdh", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "Barren- / Ring-Dips (20 Wdh)", targetMetricDescription: "Saubere 90-Grad-Beugung mit Skapuladepression", targetValue: 20.0, currentValue: 15.0, unit: "Wdh", tierRequired: .basicFunctional)
            ]

        case .cardio:
            return [
                GoalItem(level: .pillar, title: "5 km Lauf-Pace (< 24:00 min)", targetMetricDescription: "Aerobe Kapazitaet gemaess Daniels VDOT-Skala", targetValue: 24.0, currentValue: 24.5, unit: "min", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "BFT 1000m Dienst-Sprint (< 3:30 min)", targetMetricDescription: "MilFit Maximalleistung ZDv 3/10", targetValue: 3.5, currentValue: 3.4, unit: "min", tierRequired: .advancedAmateur),
                GoalItem(level: .pillar, title: "20 min Morgen-MVPA (Wochenschnitt 100%)", targetMetricDescription: "Zirkadiane Orexin/Adenosin-Aktivierung nach dem Aufstehen", targetValue: 100.0, currentValue: 90.0, unit: "%", tierRequired: .basicFunctional)
            ]

        case .stretching:
            return [
                GoalItem(level: .pillar, title: "Hueftbeuger- & Psoas-Release", targetMetricDescription: "Tagesdehnung nach Dienstschluss zur LWS-Entlastung", targetValue: 100.0, currentValue: 85.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "Thorakale Extension & Skapula-Mobilitaet", targetMetricDescription: "Aufrichtung BWS fuer optimale Schulterblatt-Freiheit", targetValue: 100.0, currentValue: 80.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .pillar, title: "Dekompressions-Routine (Dead Hang & Child's Pose)", targetMetricDescription: "Reduktion intravertebralen Drucks nach schweren Einheiten", targetValue: 100.0, currentValue: 90.0, unit: "%", tierRequired: .basicFunctional)
            ]

        case .reha:
            return [
                GoalItem(level: .pillar, title: "Statischer Plank (5 Minuten Dauer)", targetMetricDescription: "Maximale isometrische Rumpfkontrolle ohne Beckenabsenkung", targetValue: 300.0, currentValue: 300.0, unit: "s", tierRequired: .professionalElite, clinicalSafetyNotes: "BWK-Standard: Ausatmung bei Anspannung"),
                GoalItem(level: .pillar, title: "Crunches-/Sit-ups-Verbot (100% Einhaltung)", targetMetricDescription: "Strikter Verzicht auf Beugung gegen Widerstand", targetValue: 100.0, currentValue: 100.0, unit: "%", tierRequired: .basicFunctional, clinicalSafetyNotes: "BWK Ulm Reha: Null Crunches"),
                GoalItem(level: .pillar, title: "Beckenboden- & Transversus-Stabilitaet", targetMetricDescription: "Funktionelle Rumpfstabilisation (Bird-Dog, Pallof Press, Glute Bridge)", targetValue: 100.0, currentValue: 95.0, unit: "%", tierRequired: .basicFunctional, clinicalSafetyNotes: "Schutz des OP-Areals")
            ]
        }
    }

    private var adaptiveCycleGoalsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adaptive Antigravity-Planung (Closed-Loop)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(GymTheme.cyanAccent)

            let cycleGoals = [
                GoalItem(level: .program, title: "Closed-Loop Einheiten-Generierung", targetMetricDescription: "Tages-Workouts taeglich adaptiv in Antigravity basierend auf Vortages-Daten abrufen", targetValue: 100.0, currentValue: 95.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .program, title: "2-Makro-Fokusblock Konsistenz", targetMetricDescription: "Strikte Begrenzung auf maximal 2 Makro-Ziele pro Tag gegen kognitive Zersplitterung", targetValue: 100.0, currentValue: 90.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .program, title: "Progressive Overload ohne Gewebeschaeden", targetMetricDescription: "Kontinuierlicher Last-, Zeit- oder Wdh-Zuwachs bei RIR 1-3", targetValue: 100.0, currentValue: 85.0, unit: "%", tierRequired: .advancedAmateur),
                GoalItem(level: .program, title: "Regenerative Resensibilisierung (Deload)", targetMetricDescription: "Gezielte ZNS- und Sehnen-Superkompensation nach 4–6 Belastungswochen", targetValue: 100.0, currentValue: 100.0, unit: "%", tierRequired: .basicFunctional)
            ]
            ForEach(cycleGoals) { goal in
                goalRow(goal: goal)
            }
        }
    }

    private var sessionGoalsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            let sessionGoals = [
                GoalItem(level: .session, title: "Volumen- & Lasten-Integritaet", targetMetricDescription: "Alle geplanten Saetze sauber absolvieren", targetValue: 100.0, currentValue: 100.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .session, title: "RPE- & Flow-Disziplin (RIR 1-3)", targetMetricDescription: "Strikte Vermeidung von vorzeitigem Muskelversagen vor dem Peak", targetValue: 100.0, currentValue: 95.0, unit: "%", tierRequired: .basicFunctional),
                GoalItem(level: .session, title: "Somatischer Schutz & Intraabdominelle Kontrolle (BWK-Ulm)", targetMetricDescription: "Intraabdominelle Druckkontrolle ohne Pressatmung (Ausatmung bei Kontraktion)", targetValue: 100.0, currentValue: 100.0, unit: "%", tierRequired: .basicFunctional, clinicalSafetyNotes: "BWK-Standard: Ausatmung bei Belastung"),
                GoalItem(level: .session, title: "Isometrische Rumpf- & Tiefenstabilitaet", targetMetricDescription: "Saubere Planks und Holds ohne Durchhaengen der LWS", targetValue: 100.0, currentValue: 100.0, unit: "%", tierRequired: .basicFunctional)
            ]
            ForEach(sessionGoals) { goal in
                goalRow(goal: goal)
            }
        }
    }

    private func goalRow(goal: GoalItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.textPrimary)

                Spacer()

                Text(goal.tierRequired.shortTitle)
                    .font(.system(size: 8))
                    .fontWeight(.bold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(hex: goal.tierRequired.tierColorHex).opacity(0.15))
                    .foregroundColor(Color(hex: goal.tierRequired.tierColorHex))
                    .cornerRadius(4)
            }

            Text(goal.targetMetricDescription)
                .font(.system(size: 10))
                .foregroundColor(GymTheme.textSecondary)

            if !goal.clinicalSafetyNotes.isEmpty {
                Text("BWK-Ulm: \(goal.clinicalSafetyNotes)")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "00B4D8"))
            }

            HStack {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(GymTheme.surfaceElevated)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: goal.tierRequired.tierColorHex))
                            .frame(width: g.size.width * CGFloat(goal.progressRatio))
                    }
                }
                .frame(height: 4)

                Text("\(Int(goal.targetValue)) \(goal.unit)")
                    .font(.system(size: 9))
                    .foregroundColor(GymTheme.textSecondary)
            }
        }
        .padding(10)
        .background(GymTheme.surface)
        .cornerRadius(8)
    }
}
