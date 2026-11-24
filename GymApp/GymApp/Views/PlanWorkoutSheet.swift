import SwiftUI

public struct PlanWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    public let targetDate: Date

    @State private var selectedDate: Date
    @State private var isMarkedCompleted: Bool = false
    @State private var customTitle: String = ""
    @State private var customNotes: String = ""

    public init(targetDate: Date) {
        self.targetDate = targetDate
        _selectedDate = State(initialValue: targetDate)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: GrowGeometry.sectionSpacing) {
                        // 1. Datum & Status-Auswahl
                        dateAndStatusCard

                        // 2. Freie Einheit anlegen
                        customWorkoutCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, GrowGeometry.horizontalPadding)
                    .padding(.top, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
                .dismissKeyboardOnSwipeDown()
            }
            .navigationTitle("Einheit planen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                        .font(GrowTypography.body)
                        .foregroundColor(GymTheme.textSecondary)
                        .frame(minHeight: GrowGeometry.minTouchTarget)
                }
            }
        }
    }

    // MARK: - 1. Date & Status Card
    private var dateAndStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Datum & Status")
                        .font(GrowTypography.caption)
                        .foregroundColor(GymTheme.textSecondary)
                    Text(formatFullDate(selectedDate))
                        .font(GrowTypography.headline)
                        .foregroundColor(GymTheme.textPrimary)
                }
                Spacer()
                Image(systemName: isMarkedCompleted ? "checkmark.circle.fill" : "calendar")
                    .font(.title3)
                    .foregroundColor(isMarkedCompleted ? GymTheme.sageGreen : GymTheme.cyanAccent)
            }

            DatePicker(
                "Datum",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            Divider().background(GymTheme.borderSubtle)

            Picker("Status", selection: $isMarkedCompleted) {
                Text("Geplant").tag(false)
                Text("Absolviert").tag(true)
            }
            .pickerStyle(.segmented)
        }
        .padding(GrowGeometry.cardInnerPadding)
        .background(GymTheme.surface)
        .cornerRadius(GrowGeometry.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: GrowGeometry.cardCornerRadius, style: .continuous)
                .stroke(GymTheme.border, lineWidth: 0.75)
        )
    }

    // MARK: - 2. Custom Workout Card
    private var customWorkoutCard: some View {
        let isValid = !customTitle.trimmingCharacters(in: .whitespaces).isEmpty

        return VStack(alignment: .leading, spacing: 14) {
            GrowSectionHeader(
                title: "Einheit erstellen",
                subtitle: "Für detaillierte Trainingspläne nutze Gemini."
            )

            TextField("Titel (z. B. Oberkörper, Core, Lauf)", text: $customTitle)
                .font(GrowTypography.body)
                .foregroundColor(GymTheme.textPrimary)
                .padding(14)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(GrowGeometry.subCardCornerRadius)
                .overlay(RoundedRectangle(cornerRadius: GrowGeometry.subCardCornerRadius).stroke(GymTheme.border, lineWidth: 0.75))

            TextField("Notiz oder Fokus (optional)", text: $customNotes)
                .font(GrowTypography.subheadline)
                .foregroundColor(GymTheme.textPrimary)
                .padding(14)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(GrowGeometry.subCardCornerRadius)
                .overlay(RoundedRectangle(cornerRadius: GrowGeometry.subCardCornerRadius).stroke(GymTheme.border, lineWidth: 0.75))

            Button {
                let cleanTitle = customTitle.trimmingCharacters(in: .whitespaces)
                guard !cleanTitle.isEmpty else { return }
                store.addHistoricalOrPlannedWorkout(
                    title: cleanTitle,
                    date: selectedDate,
                    isCompleted: isMarkedCompleted,
                    notes: customNotes
                )
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isMarkedCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(isMarkedCompleted ? "Als absolviert speichern" : "Einheit planen")
                }
                .font(GrowTypography.headline)
                .frame(maxWidth: .infinity, minHeight: GrowGeometry.buttonHeight)
                .background(isValid ? GymTheme.sageGreen : GymTheme.surfaceElevated)
                .foregroundColor(isValid ? GymTheme.bg : GymTheme.textMuted)
                .cornerRadius(GrowGeometry.subCardCornerRadius)
            }
            .buttonStyle(GrowTactileButtonStyle())
            .disabled(!isValid)
        }
        .padding(GrowGeometry.cardInnerPadding)
        .background(GymTheme.surface)
        .cornerRadius(GrowGeometry.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: GrowGeometry.cardCornerRadius, style: .continuous)
                .stroke(GymTheme.border, lineWidth: 0.75)
        )
    }

    private func formatFullDate(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .full
        return formatter.string(from: d)
    }
}
