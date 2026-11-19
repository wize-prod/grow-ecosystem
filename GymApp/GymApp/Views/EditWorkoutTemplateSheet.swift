import SwiftUI

// MARK: - Template Creation & Customization Sheet with Live Muscle Heatmap
public struct EditWorkoutTemplateSheet: View {
    var templateToEdit: WorkoutTemplate?
    var preselectedFolder: String = "Fixed Schedule"

    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String = "Krafttraining"
    @State private var folderName: String = ""
    @State private var summary: String = ""
    @State private var estimatedMinutes: Int = 45
    @State private var targetTimeSlot: String = "17:00 - 18:30"
    @State private var items: [WorkoutTemplateItem] = []
    @State private var showingExercisePicker = false
    @State private var showingDeleteAlert = false

    public init(templateToEdit: WorkoutTemplate? = nil, preselectedFolder: String = "Fixed Schedule") {
        self.templateToEdit = templateToEdit
        self.preselectedFolder = preselectedFolder
        _name = State(initialValue: templateToEdit?.name ?? "")
        _category = State(initialValue: templateToEdit?.category ?? "Krafttraining")
        _folderName = State(initialValue: templateToEdit?.folderName ?? preselectedFolder)
        _summary = State(initialValue: templateToEdit?.summary ?? "")
        _estimatedMinutes = State(initialValue: templateToEdit?.estimatedMinutes ?? 45)
        _targetTimeSlot = State(initialValue: templateToEdit?.targetTimeSlot ?? "17:00 - 18:30")
        _items = State(initialValue: templateToEdit?.items ?? [])
    }

    private var isEditing: Bool {
        templateToEdit != nil
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Stammdaten Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workout-Basisdaten")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(GymTheme.textSecondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Name des Trainingsplans")
                                    .font(.caption2)
                                    .foregroundColor(GymTheme.textMuted)
                                TextField("z. B. Push & Reha Core", text: $name)
                                    .font(.subheadline)
                                    .padding(10)
                                    .background(GymTheme.surfaceElevated)
                                    .cornerRadius(8)
                                    .foregroundColor(GymTheme.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Trainings-Kategorie & Disziplin")
                                    .font(.caption2)
                                    .foregroundColor(GymTheme.textMuted)

                                HStack(spacing: 6) {
                                    ForEach(["Krafttraining", "Calisthenics", "Cardio", "Stretching"], id: \.self) { cat in
                                        Button {
                                            category = cat
                                            HapticFeedback.selection()
                                        } label: {
                                            Text(cat)
                                                .font(.system(size: 10, weight: category == cat ? .bold : .medium))
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 8)
                                                .background(category == cat ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                                                .foregroundColor(category == cat ? GymTheme.bg : GymTheme.textSecondary)
                                                .cornerRadius(6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(category == cat ? GymTheme.strongBlue : GymTheme.border, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kategorie-Bezeichnung")
                                        .font(.caption2)
                                        .foregroundColor(GymTheme.textMuted)
                                    TextField("Kraft / Calisthenics", text: $category)
                                        .font(.subheadline)
                                        .padding(10)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(8)
                                        .foregroundColor(GymTheme.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ordner")
                                        .font(.caption2)
                                        .foregroundColor(GymTheme.textMuted)
                                    TextField("Ordnername", text: $folderName)
                                        .font(.subheadline)
                                        .padding(10)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(8)
                                        .foregroundColor(GymTheme.textPrimary)
                                }
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dauer (Minuten)")
                                        .font(.caption2)
                                        .foregroundColor(GymTheme.textMuted)
                                    Stepper("\(estimatedMinutes) min", value: $estimatedMinutes, in: 10...180, step: 5)
                                        .font(.subheadline)
                                        .padding(8)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(8)
                                        .foregroundColor(GymTheme.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Zeitslot")
                                        .font(.caption2)
                                        .foregroundColor(GymTheme.textMuted)
                                    TextField("17:00 - 18:30", text: $targetTimeSlot)
                                        .font(.subheadline)
                                        .padding(10)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(8)
                                        .foregroundColor(GymTheme.textPrimary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Beschreibung & Fokus")
                                    .font(.caption2)
                                    .foregroundColor(GymTheme.textMuted)
                                TextField("Fokus, Progression oder Reha-Hinweise", text: $summary)
                                    .font(.subheadline)
                                    .padding(10)
                                    .background(GymTheme.surfaceElevated)
                                    .cornerRadius(8)
                                    .foregroundColor(GymTheme.textPrimary)
                            }
                        }
                        .somaCard()

                        // Uebungen Section (Individuell konfigurierbar)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Uebungen im Plan (\(items.count))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(GymTheme.textPrimary)
                                    Text("Saetze, Wiederholungen, Last und Pausen individuell anpassen")
                                        .font(.caption2)
                                        .foregroundColor(GymTheme.textMuted)
                                }
                                Spacer()
                                Button {
                                    showingExercisePicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Uebung")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(GymTheme.sageGreen)
                                    .foregroundColor(GymTheme.bg)
                                    .cornerRadius(8)
                                }
                            }

                            if items.isEmpty {
                                Text("Noch keine Uebungen im Trainingsplan. Klicke auf '+ Uebung' um eine Uebung hinzuzufuegen.")
                                    .font(.caption)
                                    .foregroundColor(GymTheme.textMuted)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    exerciseItemCard(index: index, item: item)
                                }
                            }
                        }
                        .somaCard()

                        // Live Interactive Target Muscle Heatmap
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Zielmuskel-Heatmap (Live)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(GymTheme.textPrimary)
                                Spacer()
                                Text("Dynamisch berechnet")
                                    .font(.caption2)
                                    .foregroundColor(GymTheme.textMuted)
                            }

                            let liveStimulus = MuscleStimulusEngine.shared.calculateStimulus(from: items)
                            AnatomicalMuscleMapView(stimulusMap: liveStimulus)
                        }
                        .somaCard()

                        // Methodical Training Principles & Balance Card
                        let totalSets = items.reduce(0) { $0 + $1.targetSets }
                        let isPureBodyweight = items.allSatisfy { $0.targetWeightKg == 0 && ($0.exercise.equipment == .bodyweight || $0.exercise.equipment == .roomFurniture || $0.exercise.equipment == .matArea || $0.exercise.equipment == .stretchingMat) }
                        let hasContraindicated = items.contains { $0.exercise.isContraindicated || !$0.exercise.isBWKRehaSafe }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .font(.caption)
                                    .foregroundColor(GymTheme.accentGold)
                                Text("TRAININGSPRINZIPIEN & BELASTUNGS-BALANCE")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(0.8)
                                    .foregroundColor(GymTheme.accentGold)
                                Spacer()
                                Text("\(totalSets) Saetze Gesamt")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(totalSets >= 10 && totalSets <= 25 ? GymTheme.sageGreen : GymTheme.warmSand)
                            }

                            HStack(spacing: 8) {
                                // Equipment Metric
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("EQUIPMENT-STATUS")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(GymTheme.textMuted)
                                    Text(isPureBodyweight ? "Ohne Equipment" : "Mit Equipment")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(GymTheme.textPrimary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(6)

                                // Reha Safety Metric
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("BWK REHA-STATUS")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(GymTheme.textMuted)
                                    Text(hasContraindicated ? "Veto: Druckspitzen" : "Reha-Konform")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(hasContraindicated ? GymTheme.terracotta : GymTheme.sageGreen)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(6)
                            }

                            // Movement Patterns Breakdown
                            let pushCount = items.filter { $0.exercise.targetMuscle == .chest || $0.exercise.targetMuscle == .shoulders }.reduce(0) { $0 + $1.targetSets }
                            let pullCount = items.filter { $0.exercise.targetMuscle == .back }.reduce(0) { $0 + $1.targetSets }
                            let legCount = items.filter { $0.exercise.targetMuscle == .legs || $0.exercise.targetMuscle == .glutesPosterior }.reduce(0) { $0 + $1.targetSets }
                            let coreCount = items.filter { $0.exercise.targetMuscle == .functionalCore || $0.exercise.targetMuscle == .lowerBack }.reduce(0) { $0 + $1.targetSets }

                            HStack(spacing: 6) {
                                balancePill(label: "Push", sets: pushCount, color: GymTheme.strongBlue)
                                balancePill(label: "Pull", sets: pullCount, color: GymTheme.cyanAccent)
                                balancePill(label: "Beine", sets: legCount, color: GymTheme.accentGold)
                                balancePill(label: "Rumpf", sets: coreCount, color: GymTheme.sageGreen)
                            }
                        }
                        .somaCard()

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                saveTemplate()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(isEditing ? "Aenderungen speichern" : "Trainingsplan anlegen")
                                }
                                .font(.headline)
                                .foregroundColor(GymTheme.bg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(GymTheme.sageGreen)
                                .cornerRadius(12)
                            }

                            if isEditing {
                                HStack(spacing: 12) {
                                    Button {
                                        if let orig = templateToEdit {
                                            store.duplicateTemplate(orig)
                                            dismiss()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                            Text("Duplizieren")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(GymTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(10)
                                    }

                                    Button {
                                        showingDeleteAlert = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "trash")
                                            Text("Loeschen")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(GymTheme.cancelRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle(isEditing ? "Plan anpassen" : "Neues Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") { saveTemplate() }
                        .fontWeight(.semibold)
                        .foregroundColor(GymTheme.sageGreen)
                }
            }
            .alert("Plan unwiderruflich loeschen?", isPresented: $showingDeleteAlert) {
                Button("Loeschen", role: .destructive) {
                    if let tpl = templateToEdit {
                        store.deleteTemplate(id: tpl.id)
                        dismiss()
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieser Trainingsplan wird aus deiner Sammlung entfernt.")
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet { ex in
                    let isTime = ex.isTimeBased
                    let newItem = WorkoutTemplateItem(
                        exercise: ex,
                        targetSets: ex.defaultSets,
                        targetReps: ex.defaultReps,
                        targetSeconds: isTime ? 60 : nil,
                        isTimeBased: isTime,
                        targetWeightKg: 0.0,
                        restSeconds: ex.defaultRestSeconds
                    )
                    items.append(newItem)
                }
            }
        }
    }

    private func balancePill(label: String, sets: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
            Text("\(sets) S.")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Exercise Item Editor Card
    private func exerciseItemCard(index: Int, item: WorkoutTemplateItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(index + 1).")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.sageGreen)
                    .frame(width: 20, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(GymTheme.textPrimary)

                    HStack(spacing: 6) {
                        Text(item.exercise.targetMuscle.rawValue)
                            .font(.caption2)
                            .foregroundColor(GymTheme.textSecondary)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Text(item.exercise.equipment.rawValue)
                            .font(.caption2)
                            .foregroundColor(GymTheme.textSecondary)

                        if item.exercise.isBWKRehaSafe {
                            Text("BWK-Safe")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(GymTheme.sageGreen.opacity(0.2))
                                .foregroundColor(GymTheme.sageGreen)
                                .cornerRadius(3)
                        }
                    }
                }

                Spacer()

                // Reorder and delete actions
                HStack(spacing: 8) {
                    if index > 0 {
                        Button {
                            items.swapAt(index, index - 1)
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.caption)
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(6)
                                .background(GymTheme.surface)
                                .cornerRadius(6)
                        }
                    }

                    if index < items.count - 1 {
                        Button {
                            items.swapAt(index, index + 1)
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: "arrow.down")
                                .font(.caption)
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(6)
                                .background(GymTheme.surface)
                                .cornerRadius(6)
                        }
                    }

                    Button {
                        items.remove(at: index)
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(GymTheme.cancelRed)
                            .padding(6)
                            .background(GymTheme.surface)
                            .cornerRadius(6)
                    }
                }
            }

            Divider()
                .background(GymTheme.surface)

            // Mode Toggle: Wiederholungen vs Zeit / Dauer (z. B. Planks)
            HStack {
                Text("Ziel-Modus:")
                    .font(.caption2)
                    .foregroundColor(GymTheme.textMuted)

                Spacer()

                Button {
                    items[index].isTimeBased = false
                    HapticFeedback.light()
                } label: {
                    Text("Wiederholungen")
                        .font(.system(size: 10, weight: !items[index].isTimeBased ? .bold : .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(!items[index].isTimeBased ? GymTheme.strongBlue : GymTheme.surface)
                        .foregroundColor(!items[index].isTimeBased ? GymTheme.bg : GymTheme.textSecondary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button {
                    items[index].isTimeBased = true
                    if items[index].targetSeconds == nil || items[index].targetSeconds == 0 {
                        items[index].targetSeconds = 60
                    }
                    HapticFeedback.light()
                } label: {
                    Text("Zeit / Dauer (Plank)")
                        .font(.system(size: 10, weight: items[index].isTimeBased ? .bold : .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(items[index].isTimeBased ? GymTheme.strongBlue : GymTheme.surface)
                        .foregroundColor(items[index].isTimeBased ? GymTheme.bg : GymTheme.textSecondary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // Granular Steppers Grid
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Saetze
                    HStack {
                        Text("Saetze:")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Spacer()
                        Stepper("\(items[index].targetSets)", value: $items[index].targetSets, in: 1...20)
                            .labelsHidden()
                        Text("\(items[index].targetSets)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(GymTheme.textPrimary)
                            .frame(minWidth: 20, alignment: .trailing)
                    }
                    .padding(8)
                    .background(GymTheme.surface)
                    .cornerRadius(8)

                    // Wiederholungen oder Zeit / Dauer
                    if items[index].isTimeBased {
                        let totalSec = items[index].targetSeconds ?? 60
                        HStack {
                            Text("Dauer:")
                                .font(.caption2)
                                .foregroundColor(GymTheme.textMuted)
                            Spacer()
                            Stepper(
                                "\(totalSec)s",
                                value: Binding(
                                    get: { items[index].targetSeconds ?? 60 },
                                    set: { items[index].targetSeconds = $0 }
                                ),
                                in: 5...3600,
                                step: 15
                            )
                            .labelsHidden()
                            Text(formatDuration(totalSec))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.sageGreen)
                                .frame(minWidth: 48, alignment: .trailing)
                        }
                        .padding(8)
                        .background(GymTheme.surface)
                        .cornerRadius(8)
                        .contextMenu {
                            Button("30 Sekunden") { items[index].targetSeconds = 30 }
                            Button("45 Sekunden") { items[index].targetSeconds = 45 }
                            Button("60 Sekunden (1 min)") { items[index].targetSeconds = 60 }
                            Button("90 Sekunden (1:30 min)") { items[index].targetSeconds = 90 }
                            Button("2:00 Minuten") { items[index].targetSeconds = 120 }
                            Button("3:00 Minuten") { items[index].targetSeconds = 180 }
                            Button("5:00 Minuten") { items[index].targetSeconds = 300 }
                        }
                    } else {
                        HStack {
                            Text("Wdh:")
                                .font(.caption2)
                                .foregroundColor(GymTheme.textMuted)
                            Spacer()
                            Stepper("\(items[index].targetReps)", value: $items[index].targetReps, in: 1...200)
                                .labelsHidden()
                            Text("\(items[index].targetReps)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(GymTheme.textPrimary)
                                .frame(minWidth: 24, alignment: .trailing)
                        }
                        .padding(8)
                        .background(GymTheme.surface)
                        .cornerRadius(8)
                    }
                }

                HStack(spacing: 12) {
                    // Last / Zusatzgewicht (kg)
                    HStack {
                        Text("Last:")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Spacer()
                        Stepper("\(String(format: "%.1f", items[index].targetWeightKg))", value: $items[index].targetWeightKg, in: 0...400, step: 2.5)
                            .labelsHidden()
                        Text("\(String(format: "%.1f", items[index].targetWeightKg)) kg")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(GymTheme.textPrimary)
                            .frame(minWidth: 50, alignment: .trailing)
                    }
                    .padding(8)
                    .background(GymTheme.surface)
                    .cornerRadius(8)

                    // Satzpause (Sekunden)
                    HStack {
                        Text("Pause:")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                        Spacer()
                        Stepper("\(items[index].restSeconds)s", value: $items[index].restSeconds, in: 0...600, step: 15)
                            .labelsHidden()
                        Text("\(items[index].restSeconds)s")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(GymTheme.textPrimary)
                            .frame(minWidth: 32, alignment: .trailing)
                    }
                    .padding(8)
                    .background(GymTheme.surface)
                    .cornerRadius(8)
                }
            }
        }
        .padding(10)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(10)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d min", mins, secs)
        } else {
            return "\(secs)s"
        }
    }

    private func saveTemplate() {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Mein Trainingsplan" : name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalFolder = folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? preselectedFolder : folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let allRehaSafe = items.allSatisfy { $0.exercise.isBWKRehaSafe }

        if var existing = templateToEdit {
            existing.name = finalName
            existing.folderName = finalFolder
            existing.category = category
            existing.summary = summary
            existing.items = items
            existing.estimatedMinutes = estimatedMinutes
            existing.targetTimeSlot = targetTimeSlot
            existing.isBWKRehaFocused = allRehaSafe
            store.updateTemplate(existing)
        } else {
            let newTemplate = WorkoutTemplate(
                name: finalName,
                folderName: finalFolder,
                category: category,
                summary: summary,
                items: items,
                estimatedMinutes: estimatedMinutes,
                targetTimeSlot: targetTimeSlot,
                isBWKRehaFocused: allRehaSafe
            )
            store.addTemplate(newTemplate)
        }
        HapticFeedback.success()
        dismiss()
    }
}

// Backwards compatibility alias
public typealias CreateTemplateSheet = EditWorkoutTemplateSheet

// MARK: - Exercise Picker Sheet
public struct ExercisePickerSheet: View {
    var onSelectExercise: ((Exercise) -> Void)? = nil
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup? = nil

    public init(selectedExercises: Binding<[Exercise]> = .constant([]), onSelectExercise: ((Exercise) -> Void)? = nil) {
        self._selectedExercises = selectedExercises
        self.onSelectExercise = onSelectExercise
    }

    var filteredExercises: [Exercise] {
        let base = store.exercises.filter { ex in
            selectedMuscle == nil || ex.targetMuscle == selectedMuscle
        }
        return ExerciseSearchEngine.shared.search(query: searchText, in: base, store: store)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(GymTheme.textMuted)
                        TextField("Uebung suchen...", text: $searchText)
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    .padding(10)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .padding(.horizontal)

                    // Muscle Group Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(title: "Alle", isSelected: selectedMuscle == nil) {
                                selectedMuscle = nil
                            }
                            ForEach(MuscleGroup.allCases) { mg in
                                filterChip(title: mg.rawValue, isSelected: selectedMuscle == nil ? false : selectedMuscle == mg) {
                                    selectedMuscle = mg
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Exercise List
                    List {
                        ForEach(filteredExercises) { ex in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                        .font(.subheadline)
                                        .foregroundColor(GymTheme.textPrimary)
                                    HStack(spacing: 4) {
                                        Text("\(ex.targetMuscle.rawValue) • \(ex.equipment.rawValue)")
                                            .font(.caption2)
                                            .foregroundColor(GymTheme.textSecondary)

                                        if ex.isBWKRehaSafe {
                                            Text("BWK-Safe")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(GymTheme.sageGreen.opacity(0.2))
                                                .foregroundColor(GymTheme.sageGreen)
                                                .cornerRadius(3)
                                        }
                                    }
                                }
                                Spacer()

                                let isFav = store.isFavorite(exerciseName: ex.name)
                                Button {
                                    store.toggleFavorite(exerciseName: ex.name)
                                } label: {
                                    Image(systemName: isFav ? "star.fill" : "star")
                                        .font(.system(size: 14))
                                        .foregroundColor(isFav ? Color(white: 0.65) : GymTheme.textMuted.opacity(0.35))
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)

                                if let _ = onSelectExercise {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(GymTheme.sageGreen)
                                } else {
                                    if selectedExercises.contains(ex) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(GymTheme.sageGreen)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(GymTheme.textMuted)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let onSelect = onSelectExercise {
                                    onSelect(ex)
                                    HapticFeedback.light()
                                    dismiss()
                                } else {
                                    if let idx = selectedExercises.firstIndex(of: ex) {
                                        selectedExercises.remove(at: idx)
                                    } else {
                                        selectedExercises.append(ex)
                                    }
                                    HapticFeedback.light()
                                }
                            }
                            .listRowBackground(GymTheme.surface)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle("Uebungen auswaehlen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(GymTheme.sageGreen)
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? GymTheme.sageGreen : GymTheme.surfaceElevated)
                .foregroundColor(isSelected ? GymTheme.bg : GymTheme.textPrimary)
                .cornerRadius(12)
        }
    }
}
