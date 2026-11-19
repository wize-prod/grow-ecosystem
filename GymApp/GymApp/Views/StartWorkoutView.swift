import SwiftUI

// MARK: - Filter Enums fuer Workouts
public enum WorkoutDurationFilter: String, CaseIterable, Identifiable {
    case under30 = "Unter 30 min"
    case from30to45 = "30 - 45 min"
    case from45to60 = "45 - 60 min"
    case over60 = "Ueber 60 min"
    
    public var id: String { rawValue }
    
    public func matches(minutes: Int) -> Bool {
        switch self {
        case .under30: return minutes < 30
        case .from30to45: return minutes >= 30 && minutes <= 45
        case .from45to60: return minutes > 45 && minutes <= 60
        case .over60: return minutes > 60
        }
    }
}

public enum WorkoutMuscleFocusFilter: String, CaseIterable, Identifiable {
    case upper = "Oberkoerper (Push/Pull)"
    case lower = "Unterkoerper (Beine/Gluteus)"
    case fullBody = "Ganzkoerper"
    case coreReha = "Rumpf & Reha (BWK Ulm)"
    
    public var id: String { rawValue }
    
    public func matches(template: WorkoutTemplate) -> Bool {
        let nameLower = template.name.lowercased()
        let catLower = template.category.lowercased()
        switch self {
        case .upper:
            return nameLower.contains("push") || nameLower.contains("pull") || nameLower.contains("oberkoerper") || nameLower.contains("brust") || nameLower.contains("ruecken") || nameLower.contains("schulter") || nameLower.contains("arm") || catLower.contains("oberkoerper")
        case .lower:
            return nameLower.contains("bein") || nameLower.contains("unterkoerper") || nameLower.contains("leg") || nameLower.contains("quad") || nameLower.contains("glute") || catLower.contains("unterkoerper")
        case .fullBody:
            return nameLower.contains("ganzkoerper") || nameLower.contains("full body") || (!nameLower.contains("push") && !nameLower.contains("pull") && !template.isBWKRehaFocused)
        case .coreReha:
            return template.isBWKRehaFocused || nameLower.contains("reha") || nameLower.contains("rumpf") || nameLower.contains("core") || nameLower.contains("plank")
        }
    }
}

public enum WorkoutWeightTypeFilter: String, CaseIterable, Identifiable {
    case withWeights = "Mit Gewichten (Hanteln/Maschinen)"
    case bodyweight = "Ohne Gewichte (Bodyweight)"
    
    public var id: String { rawValue }
    
    public func matches(template: WorkoutTemplate) -> Bool {
        let isBodyweight = template.items.allSatisfy { $0.targetWeightKg == 0 } || template.name.lowercased().contains("bodyweight") || template.name.lowercased().contains("calisthenics") || template.isBWKRehaFocused
        switch self {
        case .withWeights: return !isBodyweight
        case .bodyweight: return isBodyweight
        }
    }
}

public enum WorkoutLocationFilter: String, CaseIterable, Identifiable {
    case gym = "Gym (Fitnessstudio)"
    case room = "Stube / Zimmer (Zuhause)"
    
    public var id: String { rawValue }
    
    public func matches(template: WorkoutTemplate) -> Bool {
        let folderLower = template.folderName.lowercased()
        let nameLower = template.name.lowercased()
        let isRoom = folderLower.contains("stube") || folderLower.contains("einsatz") || nameLower.contains("stube") || template.isBWKRehaFocused
        switch self {
        case .gym: return !isRoom
        case .room: return isRoom
        }
    }
}

public struct StartWorkoutView: View {
    @EnvironmentObject private var store: GymStore
    @State private var showingActiveWorkout = false
    @State private var showingNewTemplateSheet = false
    @State private var templateToEdit: WorkoutTemplate?
    @State private var searchText = ""
    @State private var showingNewFolderDialog = false
    @State private var newFolderName = ""
    @State private var selectedFolderForNewTemplate: String = "Einsatz & Reise"
    @State private var selectedTemplateForMuscleMap: WorkoutTemplate?
    @State private var collapsedFolders: Set<String> = []
    
    // Bottom Filter States
    @State private var showingFilterSheet = false
    @State private var selectedDurationFilter: WorkoutDurationFilter? = nil
    @State private var selectedMuscleFocus: WorkoutMuscleFocusFilter? = nil
    @State private var selectedWeightType: WorkoutWeightTypeFilter? = nil
    @State private var selectedLocation: WorkoutLocationFilter? = nil

    private var hasActiveFilters: Bool {
        selectedDurationFilter != nil || selectedMuscleFocus != nil || selectedWeightType != nil || selectedLocation != nil
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Vorlagen (Templates & Folders) Section
                        schablonenSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
                .scrollDismissesKeyboard(.interactively)

                // Floating Bottom Control Bar (Search + Filter + Circular +)
                bottomControlBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingNewTemplateSheet) {
                EditWorkoutTemplateSheet(preselectedFolder: selectedFolderForNewTemplate)
                    .environmentObject(store)
            }
            .sheet(item: $templateToEdit) { template in
                EditWorkoutTemplateSheet(templateToEdit: template)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingFilterSheet) {
                WorkoutFilterSheet(
                    selectedDuration: $selectedDurationFilter,
                    selectedMuscleFocus: $selectedMuscleFocus,
                    selectedWeightType: $selectedWeightType,
                    selectedLocation: $selectedLocation
                )
            }
            .sheet(item: $selectedTemplateForMuscleMap) { template in
                NavigationStack {
                    ZStack {
                        GymTheme.bg.ignoresSafeArea()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(GymTheme.textPrimary)
                                    Text("\(template.category) • ca. \(template.estimatedMinutes) min")
                                        .font(.caption)
                                        .foregroundColor(GymTheme.textSecondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)

                                let stimulusMap = MuscleStimulusEngine.shared.calculateStimulus(for: template)
                                AnatomicalMuscleMapView(stimulusMap: stimulusMap)
                                    .padding(.horizontal)

                                Spacer(minLength: 30)
                            }
                        }
                    }
                    .navigationTitle("Muskel-Heatmap")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fertig") {
                                selectedTemplateForMuscleMap = nil
                            }
                            .foregroundColor(GymTheme.sageGreen)
                        }
                    }
                }
            }
            .alert("Neuen Ordner erstellen", isPresented: $showingNewFolderDialog) {
                TextField("Ordnername", text: $newFolderName)
                Button("Erstellen") {
                    store.addFolder(name: newFolderName)
                    newFolderName = ""
                }
                Button("Abbrechen", role: .cancel) {
                    newFolderName = ""
                }
            }
        }
    }

    // MARK: - Vorlagen Section
    private var schablonenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Vorlagen")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.textPrimary)

                Spacer()

                Button {
                    selectedFolderForNewTemplate = store.customFolders.first ?? "Einsatz & Reise"
                    showingNewTemplateSheet = true
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Vorlage")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GymTheme.surfaceElevated)
                    .foregroundColor(GymTheme.strongBlue)
                    .cornerRadius(6)
                }

                Button {
                    showingNewFolderDialog = true
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                        .padding(6)
                        .background(GymTheme.surfaceElevated)
                        .foregroundColor(GymTheme.strongBlue)
                        .cornerRadius(6)
                }
            }

            // Iterate over all folders in store
            ForEach(store.customFolders, id: \.self) { folderName in
                let matchingTemplates = store.templates.filter { t in
                    let matchesFolder = t.folderName.localizedCaseInsensitiveContains(folderName) ||
                                        folderName.localizedCaseInsensitiveContains(t.folderName)
                    
                    guard matchesFolder else { return false }
                    
                    // Search text filtering
                    if !searchText.isEmpty {
                        let matchesName = t.name.localizedCaseInsensitiveContains(searchText)
                        let matchesEx = t.items.contains(where: { $0.exercise.name.localizedCaseInsensitiveContains(searchText) })
                        guard matchesName || matchesEx else { return false }
                    }
                    
                    // Duration Filter
                    if let dur = selectedDurationFilter, !dur.matches(minutes: t.estimatedMinutes) {
                        return false
                    }
                    
                    // Muscle Focus Filter
                    if let mf = selectedMuscleFocus, !mf.matches(template: t) {
                        return false
                    }
                    
                    // Weights vs Bodyweight Filter
                    if let wt = selectedWeightType, !wt.matches(template: t) {
                        return false
                    }
                    
                    // Location Filter
                    if let loc = selectedLocation, !loc.matches(template: t) {
                        return false
                    }
                    
                    return true
                }

                folderBlock(folderName: folderName, templates: matchingTemplates)
            }
        }
    }

    private func folderBlock(folderName: String, templates: [WorkoutTemplate]) -> some View {
        let isCollapsed = collapsedFolders.contains(folderName)

        return VStack(alignment: .leading, spacing: 10) {
            // Header with toggle action
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if isCollapsed {
                            collapsedFolders.remove(folderName)
                        } else {
                            collapsedFolders.insert(folderName)
                        }
                    }
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .foregroundColor(GymTheme.strongBlue)
                            .font(.subheadline)
                        Text(folderName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(GymTheme.textPrimary)

                        Text("\(templates.count)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.sageGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(GymTheme.surfaceElevated))

                        Spacer()

                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.caption)
                            .foregroundColor(GymTheme.textMuted)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Menu {
                    Button("Neue Vorlage in diesem Ordner") {
                        selectedFolderForNewTemplate = folderName
                        showingNewTemplateSheet = true
                    }
                    Button(role: .destructive) {
                        store.deleteFolder(name: folderName)
                    } label: {
                        Text("Ordner loeschen")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(GymTheme.textSecondary)
                        .font(.caption)
                        .padding(6)
                }
            }

            // Expanded content
            if !isCollapsed {
                if templates.isEmpty {
                    VStack(spacing: 6) {
                        Text("Keine passenden Vorlagen")
                            .font(.caption)
                            .foregroundColor(GymTheme.textMuted)
                        if hasActiveFilters || !searchText.isEmpty {
                            Button("Filter zuruecksetzen") {
                                selectedDurationFilter = nil
                                selectedMuscleFocus = nil
                                selectedWeightType = nil
                                selectedLocation = nil
                                searchText = ""
                            }
                            .font(.caption2)
                            .foregroundColor(GymTheme.strongBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(GymTheme.surface)
                    .cornerRadius(10)
                } else {
                    ForEach(templates) { template in
                        let stimulusMap = MuscleStimulusEngine.shared.calculateStimulus(for: template)
                        let activeMuscles = stimulusMap.values.filter { $0.effectiveScore > 0.5 }.sorted { $0.effectiveScore > $1.effectiveScore }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(GymTheme.textPrimary)
                                    Text("\(template.category) • \(template.estimatedMinutes) min")
                                        .font(.caption)
                                        .foregroundColor(GymTheme.textSecondary)
                                }

                                Spacer()

                                if template.isBWKRehaFocused {
                                    Text("Reha Safe")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(GymTheme.sageGreen.opacity(0.2))
                                        .foregroundColor(GymTheme.sageGreen)
                                        .cornerRadius(4)
                                }
                            }

                            // Mini Muscle Heatmap Badges
                            if !activeMuscles.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(activeMuscles.prefix(3)) { stim in
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(stim.color)
                                                    .frame(width: 6, height: 6)
                                                Text(stim.zone.displayName)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(GymTheme.textPrimary)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GymTheme.surfaceElevated)
                                            .cornerRadius(6)
                                        }

                                        Button {
                                            selectedTemplateForMuscleMap = template
                                            HapticFeedback.light()
                                        } label: {
                                            HStack(spacing: 3) {
                                                Image(systemName: "figure.cross.training")
                                                Text("Heatmap")
                                            }
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(GymTheme.sageGreen)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GymTheme.surfaceElevated)
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }

                            HStack(spacing: 10) {
                                Button {
                                    store.startWorkout(from: template)
                                    showingActiveWorkout = true
                                    HapticFeedback.medium()
                                } label: {
                                    Text("Starten")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 7)
                                        .background(GymTheme.sageGreen)
                                        .foregroundColor(GymTheme.bg)
                                        .cornerRadius(8)
                                }

                                Button {
                                    templateToEdit = template
                                    HapticFeedback.light()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil")
                                        Text("Bearbeiten")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(GymTheme.surfaceElevated)
                                    .foregroundColor(GymTheme.sageGreen)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .somaCard()
                    }
                }
            }
        }
        .padding(12)
        .somaCard(borderColor: GymTheme.border, background: GymTheme.surface)
    }

    // MARK: - Floating Bottom Control Bar (Search + Filter + Circular + with Water above)
    private var bottomControlBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Search Input Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GymTheme.textMuted)
                    .font(.system(size: 14))

                TextField("Vorlagen & Uebungen suchen...", text: $searchText)
                    .foregroundColor(GymTheme.textPrimary)
                    .font(.system(size: 13))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(GymTheme.textMuted)
                            .font(.system(size: 13))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(GymTheme.surfaceElevated)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(GymTheme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Circular Filter Button (Time, Muscle Focus, Weights, Gym/Room)
            Button {
                showingFilterSheet = true
                HapticFeedback.light()
            } label: {
                ZStack {
                    Circle()
                        .fill(hasActiveFilters ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(GymTheme.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasActiveFilters ? GymTheme.bg : GymTheme.textPrimary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Circular Start / Add Workout (+) Button
            Button {
                store.startWorkout()
                showingActiveWorkout = true
                HapticFeedback.medium()
            } label: {
                ZStack {
                    Circle()
                        .fill(GymTheme.strongBlue)
                        .frame(width: 44, height: 44)
                        .shadow(color: GymTheme.strongBlue.opacity(0.4), radius: 6, x: 0, y: 3)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(GymTheme.bg)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Workout Filter Sheet
public struct WorkoutFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDuration: WorkoutDurationFilter?
    @Binding var selectedMuscleFocus: WorkoutMuscleFocusFilter?
    @Binding var selectedWeightType: WorkoutWeightTypeFilter?
    @Binding var selectedLocation: WorkoutLocationFilter?

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Dauer / Zeit (Time)
                        filterSection(title: "DAUER / TRAININGSZEIT") {
                            ForEach(WorkoutDurationFilter.allCases) { filter in
                                filterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedDuration == filter,
                                    action: {
                                        if selectedDuration == filter {
                                            selectedDuration = nil
                                        } else {
                                            selectedDuration = filter
                                        }
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }

                        // Section 2: Muskelfokus (Muscle Focus)
                        filterSection(title: "MUSKELFOKUS & ANATOMIE") {
                            ForEach(WorkoutMuscleFocusFilter.allCases) { filter in
                                filterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedMuscleFocus == filter,
                                    action: {
                                        if selectedMuscleFocus == filter {
                                            selectedMuscleFocus = nil
                                        } else {
                                            selectedMuscleFocus = filter
                                        }
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }

                        // Section 3: Gewichte vs Bodyweight
                        filterSection(title: "WIDERSTANDSFORM (GEWICHTE VS BODYWEIGHT)") {
                            ForEach(WorkoutWeightTypeFilter.allCases) { filter in
                                filterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedWeightType == filter,
                                    action: {
                                        if selectedWeightType == filter {
                                            selectedWeightType = nil
                                        } else {
                                            selectedWeightType = filter
                                        }
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }

                        // Section 4: Trainingsort (Gym vs Stube / Zimmer)
                        filterSection(title: "TRAININGSORT (GYM / STUBE)") {
                            ForEach(WorkoutLocationFilter.allCases) { filter in
                                filterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedLocation == filter,
                                    action: {
                                        if selectedLocation == filter {
                                            selectedLocation = nil
                                        } else {
                                            selectedLocation = filter
                                        }
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }

                        // Reset Button
                        Button {
                            selectedDuration = nil
                            selectedMuscleFocus = nil
                            selectedWeightType = nil
                            selectedLocation = nil
                            HapticFeedback.light()
                        } label: {
                            Text("Alle Filter zuruecksetzen")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(GymTheme.surfaceElevated)
                                .foregroundColor(GymTheme.terracotta)
                                .cornerRadius(8)
                        }
                        .padding(.top, 10)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Workout filtern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(GymTheme.strongBlue)
                }
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(GymTheme.textMuted)

            FlowLayout(spacing: 8) {
                content()
            }
        }
        .padding(12)
        .somaCard()
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                .foregroundColor(isSelected ? GymTheme.bg : GymTheme.textPrimary)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? GymTheme.strongBlue : GymTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
