import SwiftUI

public struct FlowCheckInSheet: View {
    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss

    public let sessionId: UUID
    public let programId: UUID?
    public let onComplete: (Int, String) -> Void

    @State private var selectedFlowZone: FlowZone = .flow
    @State private var rpeScore: Double = 7.0
    @State private var selectedVisceralSafety: VisceralSafetyStatus = .asymptomatic
    @State private var mentalFocusScore: Int = 4
    @State private var userNotes: String = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FLOW-STATE & KONTROLLE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(GymTheme.sageGreen)
                            Text("Post-Workout Diagnose")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(GymTheme.textPrimary)
                            Text("Das 4 %-Challenge-Skill-System kalibriert deine naechste Einheit, um dich dauerhaft im Flow-Zustand zu halten.")
                                .font(.caption)
                                .foregroundColor(GymTheme.textSecondary)
                        }

                        // Completed Workout Overview Card (Sets, Reps, Weights per Exercise)
                        if let s = currentSession {
                            workoutPerformanceOverviewCard(session: s)
                        }

                        // 1. Flow Zone Selector (Boredom vs Flow vs Anxiety)
                        flowZoneSection

                        // 2. Viszerale & Rumpf-Sicherheit (BWK-Ulm Gate)
                        visceralSafetySection

                        // 3. RPE Belastungsskala (1-10)
                        rpeSection

                        // 4. Mentaler Fokus (1-5)
                        focusSection

                        // 5. Notizen
                        notesSection

                        // Action Button
                        Button {
                            submitAndFinish()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Einheit abschliessen & Flow kalibrieren")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.sageGreen)
                            .foregroundColor(GymTheme.bg)
                            .cornerRadius(10)
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Workout Reflexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Ueberspringen") {
                        onComplete(Int(rpeScore), userNotes)
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Flow Zone Selector
    private var flowZoneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1. Wie fordernd war das Workout?")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(GymTheme.textPrimary)

            ForEach(FlowZone.allCases) { zone in
                let isSelected = selectedFlowZone == zone
                Button {
                    selectedFlowZone = zone
                    HapticFeedback.selection()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(isSelected ? Color(hex: zone.badgeColorHex) : GymTheme.surfaceElevated)
                            .frame(width: 14, height: 14)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(zone.title)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(GymTheme.textPrimary)
                                Spacer()
                                if zone == .boredom {
                                    Text("+4% Last")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(hex: zone.badgeColorHex))
                                } else if zone == .anxiety {
                                    Text("-4% bis -8% Last")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(hex: zone.badgeColorHex))
                                } else {
                                    Text("Erhalt")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(hex: zone.badgeColorHex))
                                }
                            }

                            Text(zone.description)
                                .font(.caption2)
                                .foregroundColor(GymTheme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(12)
                    .background(isSelected ? Color(hex: zone.badgeColorHex).opacity(0.12) : GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color(hex: zone.badgeColorHex) : GymTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Viszerale Sicherheit
    private var visceralSafetySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.caption)
                    .foregroundColor(Color(hex: "00B4D8"))
                Text("2. Rumpf- & Viszeral-Status (BWK-Ulm Gate)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.textPrimary)
            }

            ForEach(VisceralSafetyStatus.allCases) { status in
                let isSelected = selectedVisceralSafety == status
                Button {
                    selectedVisceralSafety = status
                    HapticFeedback.selection()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? (status.isSafeForProgression ? GymTheme.sageGreen : Color(hex: "E74C3C")) : GymTheme.textSecondary)

                        Text(status.rawValue)
                            .font(.caption)
                            .foregroundColor(GymTheme.textPrimary)

                        Spacer()
                    }
                    .padding(10)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - RPE Section
    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("3. Subjektive Anstrengung (RPE)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.textPrimary)
                Spacer()
                Text("RPE \(Int(rpeScore)) / 10")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.sageGreen)
            }

            Slider(value: $rpeScore, in: 1...10, step: 1)
                .accentColor(GymTheme.sageGreen)
        }
    }

    // MARK: - Fokus Section
    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4. Mentale Schaerfe & Fokus")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(GymTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        mentalFocusScore = score
                        HapticFeedback.light()
                    } label: {
                        Text("\(score)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(mentalFocusScore == score ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                            .foregroundColor(mentalFocusScore == score ? GymTheme.bg : GymTheme.textPrimary)
                            .cornerRadius(6)
                    }
                }
            }
        }
    }

    // MARK: - Notizen
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("5. Beobachtungen (Optional)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(GymTheme.textPrimary)

            TextField("z.B. Schulter fuehlte sich extrem stabil an, Satzpausen waren zu lang...", text: $userNotes)
                .font(.caption)
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(6)
                .foregroundColor(GymTheme.textPrimary)
        }
    }

    private var currentSession: WorkoutSession? {
        if let active = store.activeSession, active.id == sessionId {
            return active
        }
        return store.sessions.first(where: { $0.id == sessionId })
    }

    // MARK: - Completed Workout Overview Card (Sets, Reps, Weights per Exercise)
    private func workoutPerformanceOverviewCard(session: WorkoutSession) -> some View {
        let totalCompletedSets = session.exercises.reduce(0) { sum, ex in
            sum + ex.sets.filter { $0.isCompleted }.count
        }
        let totalReps = session.exercises.reduce(0) { sum, ex in
            sum + ex.sets.filter { $0.isCompleted }.reduce(0) { $0 + $1.reps }
        }
        let totalTonnage = session.totalTonnageKg

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ABGESCHLOSSENE LEISTUNGSUEBERSICHT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(GymTheme.accentGold)

                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(GymTheme.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(totalTonnage)) kg")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)

                    Text("Gesamtlast")
                        .font(.system(size: 9))
                        .foregroundColor(GymTheme.textMuted)
                }
            }

            // High-Level KPI Row
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(session.exercises.count)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                    Text("Uebungen")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GymTheme.surface)
                .cornerRadius(6)

                HStack(spacing: 4) {
                    Text("\(totalCompletedSets)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.finishGreen)
                    Text("Saetze")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GymTheme.surface)
                .cornerRadius(6)

                HStack(spacing: 4) {
                    Text("\(totalReps)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.strongBlue)
                    Text("Wiederholungen")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GymTheme.surface)
                .cornerRadius(6)
            }

            Divider().background(GymTheme.borderSubtle)

            // Per Exercise Breakdown
            VStack(spacing: 12) {
                ForEach(session.exercises) { exRecord in
                    let completedSets = exRecord.sets.filter { $0.isCompleted }
                    let setsToShow = completedSets.isEmpty ? exRecord.sets : completedSets

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(exRecord.exercise.name)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(GymTheme.textPrimary)

                            Spacer()

                            Text("\(completedSets.count) / \(exRecord.sets.count) Saetze")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(completedSets.count == exRecord.sets.count ? GymTheme.finishGreen : GymTheme.textSecondary)
                        }

                        // Detailed Sets List (Weight and Reps)
                        VStack(spacing: 4) {
                            ForEach(Array(setsToShow.enumerated()), id: \.element.id) { index, s in
                                WorkoutSetOverviewRow(index: index, setRecord: s)
                            }
                        }
                    }
                    .padding(10)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.borderSubtle, lineWidth: 1))
                }
            }
        }
        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)
    }

    private func submitAndFinish() {
        let feedback = FlowPostSessionFeedback(
            sessionId: sessionId,
            programId: programId,
            date: Date(),
            flowZone: selectedFlowZone,
            rpeScore: rpeScore,
            visceralSafety: selectedVisceralSafety,
            mentalFocusScore: mentalFocusScore,
            userNotes: userNotes
        )

        store.submitFlowFeedback(feedback)
        onComplete(Int(rpeScore), userNotes)
        dismiss()
    }
}

// MARK: - Subview for Individual Set Summary Row
private struct WorkoutSetOverviewRow: View {
    let index: Int
    let setRecord: WorkoutSetRecord

    var body: some View {
        HStack {
            Text("Satz \(index + 1)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .frame(width: 50, alignment: .leading)

            if setRecord.isPR {
                Text("PR")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(GymTheme.accentGold.opacity(0.2))
                    .foregroundColor(GymTheme.accentGold)
                    .cornerRadius(3)
            }

            Spacer()

            Text(setRecord.weightKg > 0 ? "\(String(format: "%.1f", setRecord.weightKg)) kg" : "Koerpergewicht")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(GymTheme.textPrimary)

            Text("×")
                .font(.caption2)
                .foregroundColor(GymTheme.textMuted)

            Text("\(setRecord.reps) Wdh")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textPrimary)
                .frame(width: 55, alignment: .trailing)

            Image(systemName: setRecord.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundColor(setRecord.isCompleted ? GymTheme.finishGreen : GymTheme.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(GymTheme.surface)
        .cornerRadius(6)
    }
}
