import SwiftUI

public struct EditExerciseSheet: View {
    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss

    @State private var exercise: Exercise
    @State private var exerciseName: String
    @State private var selectedMuscle: MuscleGroup
    @State private var secondaryMuscles: Set<MuscleGroup>
    @State private var selectedEquipment: EquipmentType
    @State private var defaultSets: Int
    @State private var defaultReps: Int
    @State private var defaultRestSeconds: Int
    @State private var executionNotes: String
    @State private var isBWKRehaSafe: Bool

    // Video
    @State private var youtubeVideoUrl: String

    // Anleitung & Ausfuehrung
    @State private var setup: String
    @State private var execution: String
    @State private var cuesText: String
    @State private var commonMistakesText: String

    // Uebungsparameter
    @State private var difficulty: String
    @State private var categoryType: String
    @State private var mechanics: String
    @State private var movementPattern: String
    @State private var force: String

    // Variationen & Progressionen
    @State private var easierOptions: [String]
    @State private var harderOptions: [String]
    @State private var newEasierText: String = ""
    @State private var newHarderText: String = ""
    @State private var showingEasierPicker: Bool = false
    @State private var showingHarderPicker: Bool = false

    @State private var showingTransferSheet = false
    @State private var showingArchiveConfirm = false
    @State private var targetTransferExercise: Exercise? = nil

    private let difficulties = ["Anfaenger", "Mittelstufe", "Fortgeschritten", "Elite"]
    private let categories = ["Push", "Pull", "Legs", "Core", "Cardio", "Mobility"]
    private let mechanicsOptions = ["Grunduebung (Compound)", "Isolationsuebung (Isolation)", "Isometrisch"]
    private let movementPatterns = ["Horizontal Push", "Vertical Push", "Horizontal Pull", "Vertical Pull", "Squat", "Hinge", "Lunge", "Rotation", "Carry"]
    private let forces = ["Push", "Pull", "Static", "Hold"]

    public init(exercise: Exercise) {
        _exercise = State(initialValue: exercise)
        _exerciseName = State(initialValue: exercise.name)
        _selectedMuscle = State(initialValue: exercise.targetMuscle)
        _secondaryMuscles = State(initialValue: Set(exercise.secondaryMuscles))
        _selectedEquipment = State(initialValue: exercise.equipment)
        _defaultSets = State(initialValue: exercise.defaultSets)
        _defaultReps = State(initialValue: exercise.defaultReps)
        _defaultRestSeconds = State(initialValue: exercise.defaultRestSeconds)
        _executionNotes = State(initialValue: exercise.executionNotes)
        _isBWKRehaSafe = State(initialValue: exercise.isBWKRehaSafe)

        _youtubeVideoUrl = State(initialValue: exercise.youtubeVideoId ?? "")
        _setup = State(initialValue: exercise.setup)
        _execution = State(initialValue: exercise.execution)
        _cuesText = State(initialValue: exercise.cues.joined(separator: "\n"))
        _commonMistakesText = State(initialValue: exercise.commonMistakes.joined(separator: "\n"))

        _difficulty = State(initialValue: exercise.difficulty.isEmpty ? "Mittelstufe" : exercise.difficulty)
        _categoryType = State(initialValue: exercise.categoryType.isEmpty ? "Pull" : exercise.categoryType)
        _mechanics = State(initialValue: exercise.mechanics.isEmpty ? "Grunduebung (Compound)" : exercise.mechanics)
        _movementPattern = State(initialValue: exercise.movementPattern.isEmpty ? "Horizontal Pull" : exercise.movementPattern)
        _force = State(initialValue: exercise.force.isEmpty ? "Pull" : exercise.force)

        _easierOptions = State(initialValue: exercise.easierOptions)
        _harderOptions = State(initialValue: exercise.harderOptions)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Name
                        basicNameSection

                        // Section 2: Zielmuskel & Sekundaermuskeln
                        muscleTargetSection

                        // Section 3: Geraet & BWK Reha
                        equipmentAndRehaSection

                        // Section 4: Anleitung & Ausfuehrung
                        instructionsSection

                        // Section 6: Uebungsparameter
                        parametersSection

                        // Section 7: Variationen & Progressionen
                        progressionsSection

                        // Section 8: Daten uebertragen
                        dataTransferSection

                        // Section 9: Archivieren
                        archiveSection

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle("Uebung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .font(.headline)
                    .foregroundColor(GymTheme.sageGreen)
                }
            }
            .confirmationDialog(
                "Moechtest du diese Uebung wirklich archivieren?",
                isPresented: $showingArchiveConfirm,
                titleVisibility: .visible
            ) {
                Button("Uebung archivieren", role: .destructive) {
                    store.archiveExercise(id: exercise.id)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .sheet(isPresented: $showingTransferSheet) {
                transferExercisePicker
            }
            .sheet(isPresented: $showingEasierPicker) {
                ExerciseCatalogPickerSheet(title: "Leichtere Option waehlen") { selected in
                    if !easierOptions.contains(selected) {
                        easierOptions.append(selected)
                    }
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showingHarderPicker) {
                ExerciseCatalogPickerSheet(title: "Schwerere Option waehlen") { selected in
                    if !harderOptions.contains(selected) {
                        harderOptions.append(selected)
                    }
                }
                .environmentObject(store)
            }
        }
    }

    private var basicNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAME")
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1.0)
                .foregroundColor(GymTheme.textSecondary)

            TextField("Uebungsname eingeben", text: $exerciseName)
                .font(.headline)
                .foregroundColor(GymTheme.textPrimary)
                .padding(12)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(GymTheme.border, lineWidth: 1)
                )
        }
        .somaCard()
    }

    private var muscleTargetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PRIMAERER ZIELMUSKEL")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textSecondary)

                Picker("Zielmuskel", selection: $selectedMuscle) {
                    ForEach(MuscleGroup.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .tint(GymTheme.warmSand)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("SEKUNDAERE MUSKELN (SYNERGISTEN)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                    ForEach(MuscleGroup.allCases) { m in
                        let isSelected = secondaryMuscles.contains(m)
                        Button {
                            if isSelected {
                                secondaryMuscles.remove(m)
                            } else {
                                secondaryMuscles.insert(m)
                            }
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11))
                                Text(m.rawValue)
                                    .font(.caption2)
                                    .fontWeight(isSelected ? .bold : .medium)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isSelected ? GymTheme.strongBlue.opacity(0.2) : GymTheme.surfaceElevated)
                            .foregroundColor(isSelected ? GymTheme.strongBlue : GymTheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? GymTheme.strongBlue : GymTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .somaCard()
    }

    private var equipmentAndRehaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("GERAET / AUSRUESTUNG")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textSecondary)

                Picker("Geraet", selection: $selectedEquipment) {
                    ForEach(EquipmentType.allCases) { eq in
                        Text(eq.rawValue).tag(eq)
                    }
                }
                .pickerStyle(.menu)
                .tint(GymTheme.warmSand)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
            }

            Divider().background(GymTheme.border)

            Toggle(isOn: $isBWKRehaSafe) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BWK Ulm Reha Safe")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(GymTheme.textPrimary)
                    Text("Kein schaedlicher intraabdominaler Druck, bauchwand- & beckenbodenschonend.")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
            .tint(GymTheme.sageGreen)
        }
        .somaCard()
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(GymTheme.sageGreen)
                Text("ANLEITUNG & AUSFUEHRUNG")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Setup & Ausgangsposition")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)
                TextEditor(text: $setup)
                    .frame(minHeight: 60)
                    .padding(6)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Bewegungsablauf (1 Schritt pro Zeile)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)
                TextEditor(text: $execution)
                    .frame(minHeight: 80)
                    .padding(6)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Mentale Cues & Fokuspunkte (1 Cue pro Zeile)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)
                TextEditor(text: $cuesText)
                    .frame(minHeight: 60)
                    .padding(6)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Typische Fehler (1 Fehler pro Zeile)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)
                TextEditor(text: $commonMistakesText)
                    .frame(minHeight: 60)
                    .padding(6)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Allgemeine Ausfuehrungsnotizen")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)
                TextField("z.B. Griffweite, Bankwinkel...", text: $executionNotes)
                    .font(.subheadline)
                    .padding(10)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }
        }
        .somaCard()
    }

    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(GymTheme.primary)
                Text("UEBUNGSPARAMETER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textSecondary)
            }

            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("SAETZE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Stepper("\(defaultSets)", value: $defaultSets, in: 1...15)
                        .labelsHidden()
                    Text("\(defaultSets)")
                        .font(.headline)
                        .foregroundColor(GymTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)

                VStack(spacing: 4) {
                    Text("REPS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Stepper("\(defaultReps)", value: $defaultReps, in: 1...60)
                        .labelsHidden()
                    Text("\(defaultReps)")
                        .font(.headline)
                        .foregroundColor(GymTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)

                VStack(spacing: 4) {
                    Text("PAUSE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Stepper("", value: $defaultRestSeconds, in: 15...300, step: 15)
                        .labelsHidden()
                    Text("\(defaultRestSeconds) s")
                        .font(.headline)
                        .foregroundColor(GymTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCHWIERIGKEIT")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Picker("Schwierigkeit", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GymTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("KATEGORIE")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Picker("Kategorie", selection: $categoryType) {
                        ForEach(categories, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GymTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MECHANIK")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Picker("Mechanik", selection: $mechanics) {
                        ForEach(mechanicsOptions, id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GymTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("KRAFTTYP")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)
                    Picker("Krafttyp", selection: $force) {
                        ForEach(forces, id: \.self) { f in
                            Text(f).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GymTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("BEWEGUNGSMUSTER")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(GymTheme.textMuted)
                Picker("Bewegungsmuster", selection: $movementPattern) {
                    ForEach(movementPatterns, id: \.self) { mp in
                        Text(mp).tag(mp)
                    }
                }
                .pickerStyle(.menu)
                .tint(GymTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(8)
            }
        }
        .somaCard()
    }

    private var progressionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                Text("VARIATIONEN & PROGRESSIONEN")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textSecondary)
            }

            // Easier options
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Leichtere Optionen (Regressions)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                    Spacer()
                    Button {
                        showingEasierPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "books.vertical")
                            Text("Aus Katalog")
                        }
                        .font(.caption2.bold())
                        .foregroundColor(GymTheme.strongBlue)
                    }
                }

                if !easierOptions.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(easierOptions, id: \.self) { opt in
                            HStack {
                                Text(opt)
                                    .font(.subheadline)
                                    .foregroundColor(GymTheme.textPrimary)
                                Spacer()
                                Button {
                                    easierOptions.removeAll(where: { $0 == opt })
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(GymTheme.textMuted)
                                }
                            }
                            .padding(8)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(8)
                        }
                    }
                }

                HStack {
                    TextField("Freitext-Option hinzufuegen", text: $newEasierText)
                        .font(.caption)
                        .padding(8)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(8)
                    Button {
                        let trimmed = newEasierText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !easierOptions.contains(trimmed) {
                            easierOptions.append(trimmed)
                            newEasierText = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(GymTheme.strongBlue)
                    }
                }
            }

            Divider().background(GymTheme.border)

            // Harder options
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Schwerere Optionen (Progressions)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.05))
                    Spacer()
                    Button {
                        showingHarderPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "books.vertical")
                            Text("Aus Katalog")
                        }
                        .font(.caption2.bold())
                        .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.05))
                    }
                }

                if !harderOptions.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(harderOptions, id: \.self) { opt in
                            HStack {
                                Text(opt)
                                    .font(.subheadline)
                                    .foregroundColor(GymTheme.textPrimary)
                                Spacer()
                                Button {
                                    harderOptions.removeAll(where: { $0 == opt })
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(GymTheme.textMuted)
                                }
                            }
                            .padding(8)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(8)
                        }
                    }
                }

                HStack {
                    TextField("Freitext-Option hinzufuegen", text: $newHarderText)
                        .font(.caption)
                        .padding(8)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(8)
                    Button {
                        let trimmed = newHarderText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !harderOptions.contains(trimmed) {
                            harderOptions.append(trimmed)
                            newHarderText = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.05))
                    }
                }
            }
        }
        .somaCard()
    }

    private var dataTransferSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DATEN UEBERTRAGEN")
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1.0)
                .foregroundColor(GymTheme.textSecondary)

            Button {
                showingTransferSheet = true
                HapticFeedback.light()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.swap")
                    Text("In andere Uebung uebertragen")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(GymTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(GymTheme.border, lineWidth: 1)
                )
            }
        }
        .somaCard()
    }

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showingArchiveConfirm = true
                HapticFeedback.medium()
            } label: {
                Text("Uebung archivieren")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.terracotta)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(GymTheme.terracotta.opacity(0.12))
                    .cornerRadius(8)
            }
        }
        .somaCard(borderColor: GymTheme.terracotta.opacity(0.3))
    }

    private func saveChanges() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && trimmedName != exercise.name {
            store.renameExercise(id: exercise.id, newName: trimmedName)
        }

        let cuesList = cuesText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let mistakesList = commonMistakesText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        var finalEasier = easierOptions
        let trimmedNewEasier = newEasierText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNewEasier.isEmpty && !finalEasier.contains(trimmedNewEasier) {
            finalEasier.append(trimmedNewEasier)
        }

        var finalHarder = harderOptions
        let trimmedNewHarder = newHarderText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNewHarder.isEmpty && !finalHarder.contains(trimmedNewHarder) {
            finalHarder.append(trimmedNewHarder)
        }

        var updated = exercise
        updated.name = trimmedName.isEmpty ? exercise.name : trimmedName
        updated.targetMuscle = selectedMuscle
        updated.secondaryMuscles = Array(secondaryMuscles)
        updated.equipment = selectedEquipment
        updated.defaultSets = defaultSets
        updated.defaultReps = defaultReps
        updated.defaultRestSeconds = defaultRestSeconds
        updated.executionNotes = executionNotes
        updated.isBWKRehaSafe = isBWKRehaSafe

        let videoTrim = youtubeVideoUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.youtubeVideoId = videoTrim.isEmpty ? nil : videoTrim

        updated.setup = setup
        updated.execution = execution
        updated.cues = cuesList
        updated.commonMistakes = mistakesList

        updated.difficulty = difficulty
        updated.categoryType = categoryType
        updated.mechanics = mechanics
        updated.movementPattern = movementPattern
        updated.force = force

        updated.easierOptions = finalEasier
        updated.harderOptions = finalHarder

        updated.primaryMusclesDetailed = [selectedMuscle.rawValue]
        updated.secondaryMusclesDetailed = secondaryMuscles.map { $0.rawValue }

        store.updateExercise(updated)
        dismiss()
    }

    private var transferExercisePicker: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                List {
                    ForEach(store.exercises.filter { $0.id != exercise.id }) { targetEx in
                        Button {
                            store.transferExerciseData(from: exercise.id, to: targetEx.id)
                            showingTransferSheet = false
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(targetEx.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(GymTheme.textPrimary)
                                Text("\(targetEx.targetMuscle.rawValue) | \(targetEx.equipment.rawValue)")
                                    .font(.caption2)
                                    .foregroundColor(GymTheme.textSecondary)
                            }
                        }
                        .listRowBackground(GymTheme.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ziel-Uebung waehlen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { showingTransferSheet = false }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }
}
