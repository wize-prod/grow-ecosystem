import SwiftUI

public struct ChoreDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = GrowCareStore.shared
    public let chore: ChoreRoutineItem

    public init(chore: ChoreRoutineItem) {
        self.chore = chore
    }

    private var isDone: Bool {
        store.isChoreCompleted(chore, on: store.selectedDate)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(chore.category.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(CareTheme.careSage.opacity(0.18))
                                .foregroundColor(CareTheme.careSage)
                                .clipShape(Capsule())

                            Spacer()

                            Text("\(chore.estimatedMinutes) Min")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.textSecondary)

                            Text(chore.defaultFrequency.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(CareTheme.textSecondary)
                                .clipShape(Capsule())
                        }

                        Text(chore.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(CareTheme.textPrimary)

                        if !chore.rationale.isEmpty {
                            Text(chore.rationale)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(CareTheme.textSecondary)
                                .lineSpacing(3)
                                .padding(.top, 4)
                        }
                    }
                    .careCard()

                    // Steps Checklist Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIENST- & REINIGUNGSABLAUF")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(CareTheme.textMuted)

                        ForEach(chore.steps) { step in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(CareTheme.surfaceElevated)
                                        .frame(width: 24, height: 24)
                                    Text("\(step.number)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(CareTheme.careSage)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(CareTheme.textPrimary)

                                    Text(step.instruction)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(CareTheme.textSecondary)
                                        .lineSpacing(2)

                                    if !step.equipmentOrTool.isEmpty {
                                        Text("Material / Werkzeug: \(step.equipmentOrTool)")
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(CareTheme.careBlue)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                            .padding(.vertical, 6)

                            if step.id != chore.steps.last?.id {
                                Divider()
                                    .background(CareTheme.border)
                            }
                        }
                    }
                    .careCard()

                    // Completion Button
                    Button(action: {
                        let haptic = UINotificationFeedbackGenerator()
                        haptic.notificationOccurred(.success)
                        store.toggleChoreCompletion(chore, on: store.selectedDate)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .bold))
                            Text(isDone ? "Aufgabe erledigt (Rueckgaengig machen)" : "Als erledigt verbuchen")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(isDone ? CareTheme.bg : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isDone ? CareTheme.careSage : CareTheme.careBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(CareTactileButtonStyle())
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(CareTheme.bg.ignoresSafeArea())
            .navigationTitle("Kasernendienst & Stube")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(CareTheme.careSage)
                }
            }
        }
    }
}

