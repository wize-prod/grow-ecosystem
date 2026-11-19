import SwiftUI

// MARK: - Detailed Muscle Explanation Sheet (Interactive ⓘ Inspector)
public struct MuscleDetailExplanationSheet: View {
    public let muscle: DetailedAnatomicalMuscle
    public var onFilterByMuscle: ((MuscleGroup) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    @State private var selectedExerciseForDetail: Exercise? = nil

    public init(muscle: DetailedAnatomicalMuscle, onFilterByMuscle: ((MuscleGroup) -> Void)? = nil) {
        self.muscle = muscle
        self.onFilterByMuscle = onFilterByMuscle
    }

    private var matchingCatalogExercises: [Exercise] {
        let targetGroup = muscle.zone.matchingMuscleGroup
        return store.exercises.filter { ex in
            ex.targetMuscle == targetGroup || ex.secondaryMuscles.contains(targetGroup)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Card with Latin Nomenclature & Zone
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(muscle.region.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(GymTheme.accentOrange)

                            Spacer()

                            Text(muscle.zone.displayName.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(GymTheme.surfaceElevated)
                                .foregroundColor(GymTheme.textSecondary)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(GymTheme.borderSubtle, lineWidth: 1))
                        }

                        Text(muscle.commonName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)

                        Text(muscle.latinName)
                            .font(.system(size: 13, weight: .medium))
                            .italic()
                            .foregroundColor(GymTheme.accentGold)
                    }
                    .padding(16)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(GymTheme.borderSubtle, lineWidth: 1))

                    // 1. BIOMECHANICAL ACTION (Hauptfunktion)
                    anatomicalSection(
                        title: "BIOMECHANISCHE HAUPTFUNKTION & BEWEGUNG (ACTION)",
                        icon: "arrow.triangle.2.circlepath",
                        accentColor: GymTheme.cyanAccent
                    ) {
                        Text(muscle.primaryAction)
                            .font(.system(size: 13))
                            .foregroundColor(GymTheme.textPrimary)
                            .lineSpacing(3)
                    }

                    // 2. RECIPROCAL ANTAGONISTS (Gegenspieler)
                    anatomicalSection(
                        title: "REZIPROKE ANTAGONISTEN (GEGENSPIELER)",
                        icon: "arrow.left.arrow.right",
                        accentColor: GymTheme.accentRed
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(muscle.antagonist)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(GymTheme.accentRed)
                                .lineSpacing(3)

                            Text("Biomechanische Reziprozitaet: Eine reflektorische Hemmung des Antagonisten (Reziproke Inhibition) ermoeglicht eine maximale konzentrische Kontraktionsamplitude des Zielmuskels.")
                                .font(.system(size: 11))
                                .foregroundColor(GymTheme.textMuted)
                                .lineSpacing(2)
                        }
                    }

                    // 3. SYNERGISTS (Mitspieler)
                    anatomicalSection(
                        title: "SYNERGISTISCHE MUSKULATUR (MITSPIELER)",
                        icon: "person.2.fill",
                        accentColor: GymTheme.accentGreen
                    ) {
                        Text(muscle.synergists)
                            .font(.system(size: 13))
                            .foregroundColor(GymTheme.textSecondary)
                            .lineSpacing(3)
                    }

                    // 4. PERIPHERAL INNERVATION & NERVE ROOTS
                    anatomicalSection(
                        title: "PERIPHERE INNERVATION & NERVENWURZELN",
                        icon: "bolt.horizontal.fill",
                        accentColor: GymTheme.accentGold
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("Nerv:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(GymTheme.textMuted)
                                Text(muscle.innervation)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(GymTheme.accentGold)
                            }

                            HStack(spacing: 8) {
                                Text("Wurzeln:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(GymTheme.textMuted)
                                Text(muscle.nerveRoots)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(GymTheme.textPrimary)
                            }
                        }
                    }

                    // 5. ORIGIN & INSERTION (Ursprung & Ansatz)
                    anatomicalSection(
                        title: "URSPRUNG & ANSATZ (ORIGO & INSERTIO)",
                        icon: "scope",
                        accentColor: GymTheme.textSecondary
                    ) {
                        Text(muscle.originInsertion)
                            .font(.system(size: 13))
                            .foregroundColor(GymTheme.textSecondary)
                            .lineSpacing(3)
                    }

                    // 6. CLINICAL & TRAINING RELEVANCE (BWK / Haltung)
                    anatomicalSection(
                        title: "KLINISCHE & METHODISCHE TRAININGS-RELEVANZ",
                        icon: "cross.case.fill",
                        accentColor: GymTheme.accentOrange
                    ) {
                        Text(muscle.clinicalRelevance)
                            .font(.system(size: 13))
                            .foregroundColor(GymTheme.textPrimary)
                            .lineSpacing(3)
                    }

                    // 7. TARGET EXERCISES (Katalog & Empfehlungen)
                    anatomicalSection(
                        title: "ZIELGERICHTETE UEBUNGEN (\(matchingCatalogExercises.count) IM KATALOG)",
                        icon: "dumbbell.fill",
                        accentColor: GymTheme.strongBlue
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            if !matchingCatalogExercises.isEmpty {
                                ForEach(matchingCatalogExercises.prefix(6)) { ex in
                                    Button {
                                        selectedExerciseForDetail = ex
                                        HapticFeedback.light()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 6) {
                                                    Text(ex.name)
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(GymTheme.textPrimary)
                                                    if store.isFavorite(exerciseName: ex.name) {
                                                        Image(systemName: "star.fill")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(Color(white: 0.65))
                                                    }
                                                }
                                                Text("\(ex.targetMuscle.rawValue) • \(ex.equipment.rawValue)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(GymTheme.textSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundColor(GymTheme.textMuted)
                                        }
                                        .padding(10)
                                        .background(GymTheme.surface)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                ForEach(muscle.recommendedExercises, id: \.self) { ex in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(GymTheme.strongBlue)
                                            .frame(width: 5, height: 5)
                                        Text(ex)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(GymTheme.textPrimary)
                                    }
                                }
                            }

                            if let onFilter = onFilterByMuscle {
                                Button {
                                    onFilter(muscle.zone.matchingMuscleGroup)
                                    HapticFeedback.selection()
                                    dismiss()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                        Text("Im Katalog nach \(muscle.zone.displayName) filtern")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(GymTheme.strongBlue.opacity(0.18))
                                    .foregroundColor(GymTheme.strongBlue)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(GymTheme.strongBlue.opacity(0.35), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(16)
            }
            .background(GymTheme.bg)
            .safeAreaInset(edge: .bottom) {
                // Fixed Bottom Thumb-Zone Dismiss Button (iPhone 16 Pro Max Ergonomie)
                VStack(spacing: 0) {
                    Divider().background(GymTheme.borderSubtle)
                    Button(action: {
                        dismiss()
                        HapticFeedback.light()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                            Text("Schliessen")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(GymTheme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(GymTheme.accentOrange)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(GymTheme.surfaceElevated)
            }
            .navigationTitle("ANATOMISCHE ANALYSE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GymTheme.accentOrange)
                }
            }
            .sheet(item: $selectedExerciseForDetail) { ex in
                ExerciseDetailSheet(exercise: ex)
                    .environmentObject(store)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func anatomicalSection<Content: View>(
        title: String,
        icon: String,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(accentColor)
            }

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }
}
