import SwiftUI

public struct OlympicCoachView: View {
    @Environment(\.dismiss) private var dismiss
    public var exercise: Exercise?
    public var onApplyToWorkout: ((Double, Int, Int) -> Void)? = nil

    @State private var unitKg: Bool = true
    @State private var enteredWeight: String = "100"
    @State private var enteredReps: String = "5"
    @State private var selectedFormula: OneRepMaxFormula = .brzycki

    // Questionnaire
    @State private var readiness = OlympicReadinessInput(
        mentalFocus: 4,
        somaticRecovery: 4,
        sleepQuality: 4,
        dailyStress: 4
    )
    @State private var selectedGoal: String = "Volume"

    @State private var copiedToClipboard: Bool = false

    public init(
        exercise: Exercise? = nil,
        onApplyToWorkout: ((Double, Int, Int) -> Void)? = nil
    ) {
        self.exercise = exercise
        self.onApplyToWorkout = onApplyToWorkout
    }

    private var currentWeightValue: Double {
        Double(enteredWeight.replacingOccurrences(of: ",", with: ".")) ?? 100.0
    }

    private var currentRepsValue: Int {
        Int(enteredReps) ?? 5
    }

    private var calculatedPrescription: DynamicCoachPrescription {
        let ex = exercise ?? Exercise(
            name: "Grunduebung",
            targetMuscle: .chest,
            equipment: .flatBenchBarbell,
            defaultSets: 3,
            defaultReps: 10
        )
        return OlympicCoachEngine.shared.prescribeWorkout(
            exercise: ex,
            sessionsHistory: GymStore.shared.sessions,
            readiness: readiness,
            formula: selectedFormula,
            preferredGoal: selectedGoal
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header / Context
                    if let ex = exercise {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ex.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(GymTheme.textPrimary)
                                Text("Olympic Coach Algorithmus & 1RM Lastprofil")
                                    .font(.caption)
                                    .foregroundColor(GymTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Card 1: Your Lift (Matches Screenshot 5 Left Card)
                    yourLiftCard

                    // Card 2: Estimated One-Rep Max & Zones (Matches Screenshot 5 Right Card)
                    estimated1RMCard

                    // Card 3: Olympic Coach Algorithmic Readiness Check-In
                    coachReadinessCard

                    // Action: Apply prescription to workout if in active session
                    if let onApply = onApplyToWorkout {
                        Button {
                            HapticFeedback.success()
                            let p = calculatedPrescription
                            onApply(p.prescribedWeightKg, p.prescribedReps, p.prescribedSets)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Vorgabe ins Workout uebernehmen (\(String(format: "%.1f", calculatedPrescription.prescribedWeightKg)) kg x \(calculatedPrescription.prescribedReps))")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(GymTheme.background.ignoresSafeArea())
            .navigationTitle("Olympic Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .foregroundColor(GymTheme.textSecondary)
                }
            }
            .onAppear {
                loadInitialExerciseHistory()
            }
        }
    }

    private func loadInitialExerciseHistory() {
        guard let ex = exercise else { return }
        // Look up last completed set for this exercise
        let pastSets = GymStore.shared.sessions.flatMap { $0.exercises }
            .filter { $0.exercise.name.lowercased() == ex.name.lowercased() || $0.exercise.id == ex.id }
            .flatMap { $0.sets }
            .filter { $0.isCompleted && $0.weightKg > 0 }

        if let last = pastSets.last {
            enteredWeight = String(format: "%.1f", last.weightKg).replacingOccurrences(of: ".0", with: "")
            enteredReps = "\(last.reps)"
        }
    }

    // MARK: - Card 1: Your Lift (Input Section)
    private var yourLiftCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your lift")
                .font(.headline)
                .foregroundColor(GymTheme.textPrimary)

            // Unit Toggle: KG / LBS
            HStack {
                Text("Einheiten")
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        unitKg = true
                        HapticFeedback.selection()
                    } label: {
                        Text("KG")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 60, height: 32)
                            .background(unitKg ? Color(red: 0.10, green: 0.35, blue: 0.85) : GymTheme.surface)
                            .foregroundColor(unitKg ? .white : GymTheme.textSecondary)
                    }

                    Button {
                        unitKg = false
                        HapticFeedback.selection()
                    } label: {
                        Text("LBS")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 60, height: 32)
                            .background(!unitKg ? Color(red: 0.10, green: 0.35, blue: 0.85) : GymTheme.surface)
                            .foregroundColor(!unitKg ? .white : GymTheme.textSecondary)
                    }
                }
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            // Weight input
            VStack(alignment: .leading, spacing: 6) {
                Text("Gehobenes Gewicht")
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                HStack {
                    TextField("100", text: $enteredWeight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(GymTheme.textPrimary)
                    Text(unitKg ? "kg" : "lbs")
                        .font(.subheadline)
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(12)
                .background(GymTheme.surface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
            }

            // Reps input
            VStack(alignment: .leading, spacing: 6) {
                Text("Durchgefuehrte Wiederholungen")
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                HStack {
                    TextField("5", text: $enteredReps)
                        .keyboardType(.numberPad)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(GymTheme.textPrimary)
                    Text("Wiederholungen")
                        .font(.subheadline)
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(12)
                .background(GymTheme.surface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
            }

            // Formula selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Formula")
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                Menu {
                    ForEach(OneRepMaxFormula.allCases) { formula in
                        Button {
                            selectedFormula = formula
                            HapticFeedback.selection()
                        } label: {
                            HStack {
                                Text(formula.rawValue)
                                if selectedFormula == formula {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedFormula.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(GymTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(GymTheme.textMuted)
                    }
                    .padding(12)
                    .background(GymTheme.surface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
                }
            }

            // Calculate Button
            Button {
                HapticFeedback.light()
            } label: {
                HStack {
                    Text("Calculate 1RM")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(red: 0.10, green: 0.35, blue: 0.85))
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // Disclaimer
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield")
                    .font(.caption)
                    .foregroundColor(GymTheme.textMuted)
                Text("Estimate only. Use a spotter for heavy attempts.")
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textMuted)
            }
        }
        .padding(16)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(GymTheme.border, lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - Card 2: Estimated One-Rep Max & Zones (Matches Screenshot 5)
    private var estimated1RMCard: some View {
        let p = calculatedPrescription

        return VStack(spacing: 16) {
            Text("ESTIMATED ONE-REP MAX")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.2)
                .foregroundColor(GymTheme.textSecondary)

            // Barbell Graphic with scale & pointer
            barbellGraphicView(oneRepMax: p.estimated1RM)

            // Giant 1RM display
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(p.estimated1RM))")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(GymTheme.textPrimary)
                    Text(unitKg ? "kg" : "lbs")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(GymTheme.textSecondary)
                }

                Text("estimated range \(Int(p.estimated1RMRangeMin))-\(Int(p.estimated1RMRangeMax)) kg")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GymTheme.textMuted)
            }

            Divider()
                .background(GymTheme.border)

            // TRAINING ZONES
            VStack(alignment: .leading, spacing: 14) {
                Text("TRAINING ZONES")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textPrimary)

                ForEach(p.zones) { zone in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(zone.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(zone.isPeak ? Color(red: 0.94, green: 0.22, blue: 0.18) : Color(red: 0.15, green: 0.40, blue: 0.85))
                                Text("\(Int(zone.percentageMin))-\(Int(zone.percentageMax))%")
                                    .font(.system(size: 12))
                                    .foregroundColor(GymTheme.textMuted)
                            }
                        }
                        .frame(width: 120, alignment: .leading)

                        // Zone track bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(GymTheme.surface)
                                    .frame(height: 6)

                                let width = geo.size.width
                                let startFraction = zone.percentageMin / 100.0
                                let endFraction = zone.percentageMax / 100.0
                                let barWidth = width * (endFraction - startFraction)
                                let xOffset = width * startFraction

                                Capsule()
                                    .fill(zone.isPeak ? Color(red: 0.94, green: 0.22, blue: 0.18) : Color(red: 0.15, green: 0.40, blue: 0.85))
                                    .frame(width: max(8, barWidth), height: 6)
                                    .offset(x: xOffset)
                            }
                        }
                        .frame(height: 6)

                        Spacer()

                        Text("\(Int(zone.loadMinKg))-\(Int(zone.loadMaxKg)) kg")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(zone.isPeak ? Color(red: 0.94, green: 0.22, blue: 0.18) : GymTheme.textPrimary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }

            // Percentage Milestone Markers
            milestonePercentageBar(oneRepMax: p.estimated1RM)

            // Copy load chart button
            Button {
                HapticFeedback.light()
                let chart = OlympicCoachEngine.shared.formattedLoadChartText(prescription: p)
                UIPasteboard.general.string = chart
                copiedToClipboard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    copiedToClipboard = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13))
                    Text(copiedToClipboard ? "Kopiert!" : "Copy load chart")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.85))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(GymTheme.surface)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.15, green: 0.40, blue: 0.85).opacity(0.3), lineWidth: 1))
            }
        }
        .padding(16)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(GymTheme.border, lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - Barbell Graphic Component
    private func barbellGraphicView(oneRepMax: Double) -> some View {
        VStack(spacing: 4) {
            // Scale ticks
            HStack {
                Text("80")
                Spacer()
                Text("90")
                Spacer()
                Text("100")
                Spacer()
                Text("110")
                Spacer()
                Text("120")
                Spacer()
                Text("130 kg")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(GymTheme.textMuted)
            .padding(.horizontal, 24)

            // Barbell shape
            ZStack {
                // Main bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.10, green: 0.35, blue: 0.85))
                    .frame(height: 6)
                    .padding(.horizontal, 20)

                // Left plates
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.10, green: 0.35, blue: 0.85)).frame(width: 5, height: 42)
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.10, green: 0.35, blue: 0.85)).frame(width: 5, height: 38)
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.10, green: 0.35, blue: 0.85)).frame(width: 5, height: 32)
                    Spacer()
                }

                // Right plates
                HStack(spacing: 2) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.10, green: 0.35, blue: 0.85)).frame(width: 5, height: 32)
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.10, green: 0.35, blue: 0.85)).frame(width: 5, height: 38)
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.10, green: 0.35, blue: 0.85)).frame(width: 5, height: 42)
                }

                // Red indicator needle pointing to current 1RM
                GeometryReader { geo in
                    let clamped = max(70.0, min(140.0, oneRepMax))
                    let fraction = (clamped - 70.0) / (140.0 - 70.0)
                    let xPos = 20.0 + (geo.size.width - 40.0) * fraction

                    VStack(spacing: 0) {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 8))
                            .rotationEffect(.degrees(180))
                            .foregroundColor(Color(red: 0.94, green: 0.22, blue: 0.18))
                        Rectangle()
                            .fill(Color.primary)
                            .frame(width: 1.5, height: 26)
                    }
                    .position(x: xPos, y: geo.size.height / 2)
                }
            }
            .frame(height: 50)
        }
    }

    // MARK: - Percentage Milestone Bar
    private func milestonePercentageBar(oneRepMax: Double) -> some View {
        let percentages: [Double] = [50, 60, 70, 80, 90, 100]

        return VStack(spacing: 8) {
            HStack {
                ForEach(percentages, id: \.self) { pct in
                    let isHundred = pct == 100
                    VStack(spacing: 4) {
                        Text("\(Int(pct))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isHundred ? Color(red: 0.94, green: 0.22, blue: 0.18) : Color(red: 0.15, green: 0.40, blue: 0.85))

                        Circle()
                            .fill(isHundred ? Color(red: 0.94, green: 0.22, blue: 0.18) : Color(red: 0.15, green: 0.40, blue: 0.85))
                            .frame(width: 6, height: 6)

                        Text("\(Int(oneRepMax * (pct / 100.0)))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isHundred ? Color(red: 0.94, green: 0.22, blue: 0.18) : GymTheme.textPrimary)
                    }
                    if pct != 100 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 10)
        .background(GymTheme.surface)
        .cornerRadius(10)
    }

    // MARK: - Card 3: Olympic Coach Readiness Check-In
    private var coachReadinessCard: some View {
        let status = readiness.statusDescription
        let p = calculatedPrescription

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OLYMPIC COACH READINESS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(GymTheme.textSecondary)
                    Text("Biometrische Tagesform & Autoregulation")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textMuted)
                }
                Spacer()
                Text(status.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.15))
                    .foregroundColor(status.color)
                    .cornerRadius(6)
            }

            // Sliders / Question Matrix
            VStack(spacing: 12) {
                readinessSlider(
                    title: "Mentale Schaefe / Fokus",
                    value: $readiness.mentalFocus,
                    lowLabel: "Zerstreut",
                    highLabel: "Tunnel"
                )
                readinessSlider(
                    title: "Physische Erholung (Somatic)",
                    value: $readiness.somaticRecovery,
                    lowLabel: "Muskelkater",
                    highLabel: "Primed"
                )
                readinessSlider(
                    title: "Schlaf & Zirkadian (CPAP/Nachtruhe)",
                    value: $readiness.sleepQuality,
                    lowLabel: "< 5h",
                    highLabel: "> 8h Optimal"
                )
                readinessSlider(
                    title: "Dienst- & Stresslevel",
                    value: $readiness.dailyStress,
                    lowLabel: "Extrem hoch",
                    highLabel: "Minimal / Ruhetag"
                )
            }

            // Training Goal Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Trainings-Schwerpunkt")
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                Picker("Ziel", selection: $selectedGoal) {
                    Text("Hypertrophie (Volume)").tag("Volume")
                    Text("Maximalkraft (Strength)").tag("Strength")
                }
                .pickerStyle(.segmented)
            }

            // Algorithmic Coach Recommendation Banner
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(GymTheme.primary)
                    Text("Algorithmus-Vorgabe")
                        .font(.subheadline.bold())
                        .foregroundColor(GymTheme.textPrimary)
                    Spacer()
                    Text(p.rirTarget)
                        .font(.caption.bold())
                        .foregroundColor(GymTheme.accent)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ziel-Last")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Text("\(String(format: "%.1f", p.prescribedWeightKg)) kg")
                            .font(.title3.bold())
                            .foregroundColor(GymTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wiederholungen")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Text("\(p.prescribedReps) Reps")
                            .font(.title3.bold())
                            .foregroundColor(GymTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saetze")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Text("\(p.prescribedSets) Saetze")
                            .font(.title3.bold())
                            .foregroundColor(GymTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pause")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Text("\(p.targetRestSeconds)s")
                            .font(.title3.bold())
                            .foregroundColor(GymTheme.textPrimary)
                    }
                }

                Text(p.coachRecommendation)
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                    .padding(8)
                    .background(GymTheme.surface)
                    .cornerRadius(6)

                Text(p.historicalBasisSummary)
                    .font(.system(size: 10))
                    .foregroundColor(GymTheme.textMuted)
            }
            .padding(12)
            .background(GymTheme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.primary.opacity(0.3), lineWidth: 1))
        }
        .padding(16)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(GymTheme.border, lineWidth: 1))
        .padding(.horizontal)
    }

    private func readinessSlider(
        title: String,
        value: Binding<Int>,
        lowLabel: String,
        highLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GymTheme.textPrimary)
                Spacer()
                Text("\(value.wrappedValue) / 5")
                    .font(.caption.bold())
                    .foregroundColor(GymTheme.textSecondary)
            }
            HStack(spacing: 8) {
                Text(lowLabel)
                    .font(.system(size: 10))
                    .foregroundColor(GymTheme.textMuted)
                    .frame(width: 60, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { Double(value.wrappedValue) },
                        set: { value.wrappedValue = Int($0) }
                    ),
                    in: 1...5,
                    step: 1
                )
                .tint(GymTheme.primary)

                Text(highLabel)
                    .font(.system(size: 10))
                    .foregroundColor(GymTheme.textMuted)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
}
