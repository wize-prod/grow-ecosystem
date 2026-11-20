import SwiftUI

public enum ExerciseSortOption: String, CaseIterable, Identifiable {
    case nameAscending = "Name (A - Z)"
    case nameDescending = "Name (Z - A)"
    case mostLogged = "Meist absolviert"
    case muscleGroup = "Muskelgruppe"
    case equipment = "Geraetetyp"
    case customFirst = "Eigene Uebungen zuerst"

    public var id: String { rawValue }
}

struct ExerciseSection: Identifiable {
    var id: String { title }
    let title: String
    let exercises: [Exercise]
}

public struct ExercisesView: View {
    @EnvironmentObject private var store: GymStore
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var selectedEquipment: EquipmentType? = nil
    @State private var selectedExercise: Exercise? = nil
    @State private var showingNewExerciseSheet = false
    @State private var showingFilterSheet = false
    @State private var showingMuscleMapSheet = false
    @State private var showingActiveWorkout = false
    @State private var activeScrubbedLetter: String? = nil
    @State private var isScrubbingAlphabet: Bool = false

    @State private var selectedSortOption: ExerciseSortOption = .nameAscending
    @State private var exerciseToRename: Exercise? = nil
    @State private var newExerciseNameText = ""
    @State private var showingRenameAlert = false
    @State private var isFavoritesExpanded: Bool = true

    let alphabet = ["#"] + "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GymTheme.bg.ignoresSafeArea()

                // Main Exercise List
                ZStack(alignment: .trailing) {
                    ScrollViewReader { proxy in
                        ZStack(alignment: .trailing) {
                            List {
                                if displaySections.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("Keine Uebungen gefunden")
                                            .font(.subheadline)
                                            .foregroundColor(GymTheme.textMuted)
                                        if selectedMuscle != nil || selectedEquipment != nil || !searchText.isEmpty {
                                            Button("Filter zuruecksetzen") {
                                                selectedMuscle = nil
                                                selectedEquipment = nil
                                                searchText = ""
                                            }
                                            .font(.caption)
                                            .foregroundColor(GymTheme.strongBlue)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .listRowBackground(GymTheme.bg)
                                } else {
                                    ForEach(displaySections) { section in
                                        let isFavSection = section.title == "Favoriten" || section.title == "Top-Treffer & Favoriten"
                                        Section {
                                            if !isFavSection || isFavoritesExpanded {
                                                ForEach(section.exercises) { exercise in
                                                    Button {
                                                        selectedExercise = exercise
                                                        HapticFeedback.light()
                                                    } label: {
                                                        exerciseItemRow(exercise: exercise)
                                                    }
                                                    .listRowBackground(GymTheme.bg)
                                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 32))
                                                    .listRowSeparator(.hidden)
                                                }
                                            }
                                        } header: {
                                            if isFavSection {
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        isFavoritesExpanded.toggle()
                                                    }
                                                    HapticFeedback.light()
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        Text(section.title)
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(GymTheme.textMuted)
                                                        Text("(\(section.exercises.count))")
                                                            .font(.caption2)
                                                            .foregroundColor(GymTheme.textSecondary)
                                                        Spacer()
                                                        Image(systemName: isFavoritesExpanded ? "chevron.up" : "chevron.down")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(GymTheme.textSecondary)
                                                    }
                                                    .contentShape(Rectangle())
                                                }
                                                .buttonStyle(.plain)
                                                .id(section.title)
                                            } else {
                                                Text(section.title)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(GymTheme.textMuted)
                                                    .padding(.leading, 4)
                                                    .id(section.title)
                                            }
                                        }
                                    }
                                }

                                // Bottom space so list content isn't covered by bottom floating bar
                                Spacer()
                                    .frame(height: 80)
                                    .listRowBackground(GymTheme.bg)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .scrollDismissesKeyboard(.interactively)

                            // Interactive A-Z Quick Scroll Index Strip (only in alphabetical mode without active search)
                            if selectedSortOption == .nameAscending && searchText.isEmpty {
                                alphabetIndexStrip(proxy: proxy)
                            }

                            // Active Letter Floating HUD
                            if let letter = activeScrubbedLetter, isScrubbingAlphabet {
                                Text(letter)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.textPrimary)
                                    .frame(width: 54, height: 54)
                                    .background(GymTheme.surfaceElevated.opacity(0.96))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(GymTheme.strongBlue, lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .padding(.trailing, 36)
                                    .padding(.bottom, 36)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: searchText) { newValue in
                store.recordExerciseSearch(query: newValue)
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle("Katalog")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Uebung suchen...")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // 1. Skelettale Muskelkarte
                    Button {
                        HapticFeedback.light()
                        showingMuscleMapSheet = true
                    } label: {
                        Image(systemName: "figure.stand")
                            .foregroundColor(GymTheme.cyanAccent)
                    }
                    .accessibilityLabel("Muskelkarte")

                    // 2. Filter Button
                    Button {
                        HapticFeedback.light()
                        showingFilterSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundColor((selectedMuscle != nil || selectedEquipment != nil) ? GymTheme.strongBlue : GymTheme.textSecondary)
                            if selectedMuscle != nil || selectedEquipment != nil {
                                Circle()
                                    .fill(GymTheme.terracotta)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .accessibilityLabel("Filter")

                    // 3. Sort Menu
                    Menu {
                        Picker("Sortierung", selection: $selectedSortOption) {
                            ForEach(ExerciseSortOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(selectedSortOption != .nameAscending ? GymTheme.strongBlue : GymTheme.textSecondary)
                    }
                    .accessibilityLabel("Sortierung")

                    // 4. Solitaere getoente Primäraktion (+)
                    Button {
                        HapticFeedback.mechanicalClick()
                        showingNewExerciseSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(GymTheme.bg)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(GymTheme.strongBlue))
                    }
                    .accessibilityLabel("Neue Uebung erstellen")
                }
            }
            .sheet(item: $selectedExercise, onDismiss: {
                if store.activeSession != nil {
                    showingActiveWorkout = true
                }
            }) { exercise in
                ExerciseDetailSheet(exercise: exercise)
            }
            .sheet(isPresented: $showingActiveWorkout) {
                if store.activeSession != nil {
                    ActiveWorkoutView()
                        .environmentObject(store)
                }
            }
            .onChange(of: store.activeSession) { _, newSession in
                if newSession == nil {
                    showingActiveWorkout = false
                }
            }
            .sheet(isPresented: $showingNewExerciseSheet) {
                NewCustomExerciseSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingFilterSheet) {
                ExerciseFilterSheet(
                    selectedMuscle: $selectedMuscle,
                    selectedEquipment: $selectedEquipment
                )
            }
            .alert("Uebung umbenennen", isPresented: $showingRenameAlert) {
                TextField("Neuer Name", text: $newExerciseNameText)
                Button("Speichern") {
                    if let ex = exerciseToRename {
                        store.renameExercise(id: ex.id, newName: newExerciseNameText)
                        exerciseToRename = nil
                    }
                }
                Button("Abbrechen", role: .cancel) {
                    exerciseToRename = nil
                }
            }
            .sheet(isPresented: $showingMuscleMapSheet) {
                NavigationStack {
                    ScrollView {
                        AnatomicalMuscleMapView(
                            title: "Tiefen-Muskel-Katalog (32 Einheiten)",
                            isInteractive: true,
                            onSelectZone: { zone in
                                selectedMuscle = zone.matchingMuscleGroup
                            }
                        )
                        .padding(16)
                    }
                    .background(GymTheme.bg.ignoresSafeArea())
                    .navigationTitle("Skelettale Muskelkarte")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fertig") { showingMuscleMapSheet = false }
                                .foregroundColor(GymTheme.strongBlue)
                        }
                    }
                }
                .presentationDragIndicator(.visible)
            }
        }
    }



    // MARK: - Exercise Item Row
    private func exerciseItemRow(exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            // Icon thumbnail circle
            ZStack {
                Circle()
                    .fill(GymTheme.surfaceElevated)
                    .frame(width: 40, height: 40)

                Text(String(exercise.name.prefix(1)))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(exercise.isBWKContraindicated ? GymTheme.terracotta : (exercise.isCustom ? Color(red: 0.35, green: 0.75, blue: 1.0) : GymTheme.textSecondary))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(highlightedExerciseName(exercise.name))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(exercise.isBWKContraindicated ? GymTheme.terracotta : GymTheme.textPrimary)

                HStack(spacing: 6) {
                    Text("\(exercise.targetMuscle.rawValue) • \(exercise.equipment.rawValue)")
                        .font(.system(size: 11))
                        .foregroundColor(GymTheme.textSecondary)

                    if exercise.isCustom {
                        Text("EIGENE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.18))
                            .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                            .cornerRadius(3)
                    }
                }
            }

            Spacer()

            if exercise.isBWKContraindicated {
                Text("BWK SPERRE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(GymTheme.terracotta.opacity(0.18))
                    .foregroundColor(GymTheme.terracotta)
                    .cornerRadius(4)
            } else if selectedSortOption == .mostLogged {
                let count = exerciseLogCount(exercise)
                if count > 0 {
                    Text("\(count)×")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.sageGreen)
                }
            }

            // Subtle Grey Star for Favorites & Frequently Performed Exercises
            let isFav = store.isFavorite(exerciseName: exercise.name)
            Button {
                store.toggleFavorite(exerciseName: exercise.name)
            } label: {
                Image(systemName: isFav ? "star.fill" : "star")
                    .font(.system(size: 15))
                    .foregroundColor(isFav ? Color(white: 0.65) : GymTheme.textMuted.opacity(0.35))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .wellnessCard(borderColor: exercise.isBWKContraindicated ? GymTheme.terracotta.opacity(0.4) : (exercise.isCustom ? Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.4) : GymTheme.border), cornerRadius: 14)
        .contextMenu {
            Button {
                store.startSingleExerciseWorkout(exercise: exercise)
                showingActiveWorkout = true
                HapticFeedback.medium()
            } label: {
                Label("Einzeluebung starten", systemImage: "play.circle.fill")
            }

            Button {
                selectedExercise = exercise
                HapticFeedback.light()
            } label: {
                Label("Details & Anleitung", systemImage: "info.circle")
            }

            if exercise.isCustom {
                Button {
                    exerciseToRename = exercise
                    newExerciseNameText = exercise.name
                    showingRenameAlert = true
                    HapticFeedback.light()
                } label: {
                    Label("Uebung umbenennen", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    store.archiveExercise(id: exercise.id)
                } label: {
                    Label("Uebung archivieren", systemImage: "trash")
                }
            }
        }
    }

    private func exerciseLogCount(_ ex: Exercise) -> Int {
        store.sessions.reduce(0) { total, s in
            total + (s.exercises.contains(where: { $0.exercise.name.caseInsensitiveCompare(ex.name) == .orderedSame || $0.exercise.id == ex.id }) ? 1 : 0)
        }
    }

    private var displaySections: [ExerciseSection] {
        // When searching, leverage the multi-token, synonym-aware search engine and surface top hits
        if !searchText.isEmpty {
            let baseFiltered = store.exercises.filter { ex in
                if let target = selectedMuscle, ex.targetMuscle != target {
                    return false
                }
                if let eq = selectedEquipment, ex.equipment != eq {
                    return false
                }
                return true
            }
            let rankedMatches = ExerciseSearchEngine.shared.search(query: searchText, in: baseFiltered, store: store)
            let topFavorites = rankedMatches.filter { store.isFavorite(exerciseName: $0.name) || store.exercisePopularityScore($0) >= 30 }
            let others = rankedMatches.filter { !topFavorites.contains($0) }
            var sections: [ExerciseSection] = []
            if !topFavorites.isEmpty {
                sections.append(ExerciseSection(title: "Top-Treffer & Favoriten", exercises: topFavorites))
            }
            if !others.isEmpty {
                sections.append(ExerciseSection(title: topFavorites.isEmpty ? "Suchergebnisse" : "Weitere Treffer", exercises: others))
            }
            return sections
        }

        let filtered = store.exercises.filter { ex in
            if let target = selectedMuscle, ex.targetMuscle != target {
                return false
            }
            if let eq = selectedEquipment, ex.equipment != eq {
                return false
            }
            return true
        }

        switch selectedSortOption {
        case .nameAscending:
            let favorites = filtered.filter { store.isFavorite(exerciseName: $0.name) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            let sorted = filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            var dict: [String: [Exercise]] = [:]
            for ex in sorted {
                let firstChar = String(ex.name.prefix(1)).uppercased()
                let initial = firstChar.rangeOfCharacter(from: .letters) != nil ? firstChar : "#"
                dict[initial, default: []].append(ex)
            }
            var sections: [ExerciseSection] = []
            if !favorites.isEmpty {
                sections.append(ExerciseSection(title: "Favoriten", exercises: favorites))
            }
            let sortedKeys = dict.keys.sorted { k1, k2 in
                if k1 == "#" { return true }
                if k2 == "#" { return false }
                return k1 < k2
            }
            sections.append(contentsOf: sortedKeys.map { ExerciseSection(title: $0, exercises: dict[$0] ?? []) })
            return sections

        case .nameDescending:
            let sorted = filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
            return [ExerciseSection(title: "Z - A", exercises: sorted)]

        case .mostLogged:
            let sorted = filtered.sorted { exerciseLogCount($0) > exerciseLogCount($1) }
            return [ExerciseSection(title: "Meist absolviert", exercises: sorted)]

        case .muscleGroup:
            var dict: [MuscleGroup: [Exercise]] = [:]
            for ex in filtered {
                dict[ex.targetMuscle, default: []].append(ex)
            }
            return MuscleGroup.allCases.compactMap { mg in
                if let list = dict[mg], !list.isEmpty {
                    return ExerciseSection(title: mg.rawValue, exercises: list.sorted { $0.name < $1.name })
                }
                return nil
            }

        case .equipment:
            var dict: [EquipmentType: [Exercise]] = [:]
            for ex in filtered {
                dict[ex.equipment, default: []].append(ex)
            }
            return EquipmentType.allCases.compactMap { eq in
                if let list = dict[eq], !list.isEmpty {
                    return ExerciseSection(title: eq.rawValue, exercises: list.sorted { $0.name < $1.name })
                }
                return nil
            }

        case .customFirst:
            let custom = filtered.filter { $0.isCustom }.sorted { $0.name < $1.name }
            let standard = filtered.filter { !$0.isCustom }.sorted { $0.name < $1.name }
            var sections: [ExerciseSection] = []
            if !custom.isEmpty {
                sections.append(ExerciseSection(title: "Eigene Uebungen", exercises: custom))
            }
            if !standard.isEmpty {
                sections.append(ExerciseSection(title: "Standard Katalog", exercises: standard))
            }
            return sections
        }
    }

    // MARK: - Visual Search Highlighting & Fuzzy Match
    private struct FuzzyMatchResult {
        let isMatch: Bool
        let score: Int
        let matchedRanges: [Range<String.Index>]
    }

    private func fuzzyMatch(query: String, in text: String) -> FuzzyMatchResult {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            return FuzzyMatchResult(isMatch: true, score: 0, matchedRanges: [])
        }
        let dummy = Exercise(name: text, targetMuscle: .chest, equipment: .bodyweight)
        let eval = ExerciseSearchEngine.shared.evaluate(query: clean, exercise: dummy, store: store)
        return FuzzyMatchResult(isMatch: eval.isMatch, score: eval.score, matchedRanges: eval.matchedRanges)
    }

    private func highlightedExerciseName(_ name: String) -> AttributedString {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else {
            return AttributedString(name)
        }
        var attr = AttributedString(name)
        let dummy = Exercise(name: name, targetMuscle: .chest, equipment: .bodyweight)
        let match = ExerciseSearchEngine.shared.evaluate(query: cleanQuery, exercise: dummy, store: store)
        for r in match.matchedRanges {
            if let lower = AttributedString.Index(r.lowerBound, within: attr),
               let upper = AttributedString.Index(r.upperBound, within: attr) {
                attr[lower..<upper].foregroundColor = Color(red: 0.35, green: 0.75, blue: 1.0)
                attr[lower..<upper].font = .system(size: 14, weight: .bold)
            }
        }
        return attr
    }

    // MARK: - Interactive Compact Alphabet Index Scrubbing Strip (Lower Half Thumb Reachability)
    private func alphabetIndexStrip(proxy: ScrollViewProxy) -> some View {
        let compactLetterHeight: CGFloat = 11.0
        let verticalPadding: CGFloat = 4.0

        return VStack(spacing: 0) {
            ForEach(alphabet, id: \.self) { char in
                let isCurrent = activeScrubbedLetter == char
                Text(char)
                    .font(.system(size: isCurrent ? 10.0 : 8.0, weight: isCurrent ? .black : .bold))
                    .foregroundColor(isCurrent ? GymTheme.accentGold : GymTheme.strongBlue)
                    .frame(width: 16, height: compactLetterHeight)
                    .background(
                        isCurrent
                            ? Circle().fill(GymTheme.accentGold.opacity(0.3)).frame(width: 13, height: 13)
                            : nil
                    )
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, 2)
        .background(
            Capsule()
                .fill(GymTheme.surfaceElevated.opacity(0.88))
                .overlay(Capsule().stroke(GymTheme.borderSubtle, lineWidth: 0.8))
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isScrubbingAlphabet = true
                    let locationY = value.location.y - verticalPadding
                    let index = Int(locationY / compactLetterHeight)
                    if index >= 0 && index < alphabet.count {
                        let letter = alphabet[index]
                        if letter != activeScrubbedLetter {
                            activeScrubbedLetter = letter
                            HapticFeedback.selection()
                            scrollToLetter(letter, proxy: proxy)
                        }
                    }
                }
                .onEnded { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isScrubbingAlphabet = false
                            activeScrubbedLetter = nil
                        }
                    }
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 4)
        .padding(.bottom, 96)
    }

    private func scrollToLetter(_ letter: String, proxy: ScrollViewProxy) {
        if letter == "#" {
            if let first = displaySections.first(where: { $0.title == "#" || $0.title == "Favoriten" }) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(first.title, anchor: .top)
                }
            }
            return
        }
        if displaySections.contains(where: { $0.title == letter }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                proxy.scrollTo(letter, anchor: .top)
            }
        } else if let nextSection = displaySections.first(where: { $0.title > letter && $0.title != "#" && $0.title != "Favoriten" }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                proxy.scrollTo(nextSection.title, anchor: .top)
            }
        } else if let last = displaySections.last {
            withAnimation(.easeInOut(duration: 0.15)) {
                proxy.scrollTo(last.title, anchor: .top)
            }
        }
    }
}

// Exercise Filter Sheet
struct ExerciseFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMuscle: MuscleGroup?
    @Binding var selectedEquipment: EquipmentType?

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Muscle Groups
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MUSKELGRUPPE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(1.0)
                                .foregroundColor(GymTheme.textMuted)

                            FlowLayout(spacing: 8) {
                                filterChip(title: "Alle", isSelected: selectedMuscle == nil) {
                                    selectedMuscle = nil
                                }
                                ForEach(MuscleGroup.allCases) { muscle in
                                    filterChip(title: muscle.rawValue, isSelected: selectedMuscle == muscle) {
                                        selectedMuscle = muscle
                                    }
                                }
                            }
                        }
                        .somaCard()

                        // Equipment / Machines
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GERAETE & MASCHINEN")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(1.0)
                                .foregroundColor(GymTheme.textMuted)

                            FlowLayout(spacing: 8) {
                                filterChip(title: "Alle Geraete", isSelected: selectedEquipment == nil) {
                                    selectedEquipment = nil
                                }
                                ForEach(EquipmentType.allCases) { eq in
                                    filterChip(title: eq.rawValue, isSelected: selectedEquipment == eq) {
                                        selectedEquipment = eq
                                    }
                                }
                            }
                        }
                        .somaCard()

                        // Reset Button
                        if selectedMuscle != nil || selectedEquipment != nil {
                            Button {
                                selectedMuscle = nil
                                selectedEquipment = nil
                                HapticFeedback.soft()
                            } label: {
                                Text("Filter zuruecksetzen")
                                    .font(.subheadline)
                                    .foregroundColor(GymTheme.terracotta)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(GymTheme.strongBlue)
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticFeedback.light()
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                .foregroundColor(isSelected ? GymTheme.bg : GymTheme.textPrimary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? GymTheme.strongBlue : GymTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Catalog Picker Sheet
public struct ExerciseCatalogPickerSheet: View {
    public let title: String
    public let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    @State private var searchText: String = ""

    public init(title: String, onSelect: @escaping (String) -> Void) {
        self.title = title
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(GymTheme.textMuted)
                        TextField("Uebung im Katalog suchen...", text: $searchText)
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    .padding(10)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    List {
                        ForEach(filtered) { ex in
                            Button {
                                onSelect(ex.name)
                                HapticFeedback.light()
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(GymTheme.textPrimary)
                                        Text("\(ex.targetMuscle.rawValue) • \(ex.equipment.rawValue)")
                                            .font(.caption2)
                                            .foregroundColor(GymTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(GymTheme.strongBlue)
                                }
                            }
                            .listRowBackground(GymTheme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }

    private var filtered: [Exercise] {
        ExerciseSearchEngine.shared.search(query: searchText, in: store.exercises, store: store)
    }
}

// MARK: - New Custom Exercise Sheet
struct NewCustomExerciseSheet: View {
    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss

    // 1. Basisdaten & Muskeln
    @State private var name: String = ""
    @State private var targetMuscle: MuscleGroup = .chest
    @State private var secondaryMuscles: Set<MuscleGroup> = []
    @State private var equipment: EquipmentType = .dumbBells
    @State private var isBWKRehaSafe: Bool = true
    @State private var isContraindicated: Bool = false

    // 2. YouTube Video Tutorial
    @State private var youtubeVideoUrl: String = ""

    // 3. Anleitung & Ausfuehrung
    @State private var setup: String = ""
    @State private var execution: String = ""
    @State private var cuesText: String = ""
    @State private var commonMistakesText: String = ""
    @State private var executionNotes: String = ""

    // 4. Uebungsparameter
    @State private var isTimeBasedTracking: Bool = false
    @State private var defaultDurationSeconds: Int = 60
    @State private var defaultSets: Int = 3
    @State private var defaultReps: Int = 10
    @State private var defaultRestSeconds: Int = 90
    @State private var difficulty: String = "Mittelstufe"
    @State private var categoryType: String = "Pull"
    @State private var mechanics: String = "Grunduebung (Compound)"
    @State private var movementPattern: String = "Horizontal Pull"
    @State private var force: String = "Pull"

    // 5. Variationen & Progressionen
    @State private var easierOptions: [String] = []
    @State private var harderOptions: [String] = []
    @State private var newEasierText: String = ""
    @State private var newHarderText: String = ""
    @State private var showingEasierPicker: Bool = false
    @State private var showingHarderPicker: Bool = false

    private let difficulties = ["Anfaenger", "Mittelstufe", "Fortgeschritten", "Elite"]
    private let categories = ["Push", "Pull", "Legs", "Core", "Cardio", "Mobility"]
    private let mechanicsOptions = ["Grunduebung (Compound)", "Isolationsuebung (Isolation)", "Isometrisch"]
    private let movementPatterns = ["Horizontal Push", "Vertical Push", "Horizontal Pull", "Vertical Pull", "Squat", "Hinge", "Lunge", "Rotation", "Carry"]
    private let forces = ["Push", "Pull", "Static", "Hold"]

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Basisdaten & Name
                        basicDataSection

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

                        // Save Button
                        Button {
                            saveExercise()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Uebung im Katalog anlegen")
                            }
                            .font(.headline)
                            .foregroundColor(GymTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.strongBlue)
                            .cornerRadius(12)
                            .shadow(color: GymTheme.strongBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle("Neue Uebung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") { saveExercise() }
                        .font(.headline)
                        .foregroundColor(GymTheme.strongBlue)
                }
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

    private var basicDataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UEBUNGSNAME")
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1.0)
                .foregroundColor(GymTheme.textSecondary)

            TextField("z.B. Langhantel Bankdruecken", text: $name)
                .font(.headline)
                .foregroundColor(GymTheme.textPrimary)
                .padding(12)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
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

                Picker("Zielmuskel", selection: $targetMuscle) {
                    ForEach(MuscleGroup.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .tint(GymTheme.strongBlue)
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

                Picker("Geraet", selection: $equipment) {
                    ForEach(EquipmentType.allCases) { eq in
                        Text(eq.rawValue).tag(eq)
                    }
                }
                .pickerStyle(.menu)
                .tint(GymTheme.strongBlue)
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

            // Erfassungsmodus: Wiederholungen vs Zeit / Dauer (z. B. Plank)
            VStack(alignment: .leading, spacing: 6) {
                Text("ABSOLVIERUNGS- & ERFASSUNGSMODUS")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(GymTheme.textMuted)

                HStack(spacing: 8) {
                    Button {
                        isTimeBasedTracking = false
                        mechanics = "Grunduebung (Compound)"
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "repeat")
                            Text("Saetze & Wdh")
                        }
                        .font(.system(size: 11, weight: !isTimeBasedTracking ? .bold : .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!isTimeBasedTracking ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                        .foregroundColor(!isTimeBasedTracking ? GymTheme.bg : GymTheme.textSecondary)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(!isTimeBasedTracking ? GymTheme.strongBlue : GymTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        isTimeBasedTracking = true
                        mechanics = "Isometrisch"
                        force = "Static"
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stopwatch")
                            Text("Zeit / Dauer (Plank)")
                        }
                        .font(.system(size: 11, weight: isTimeBasedTracking ? .bold : .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isTimeBasedTracking ? GymTheme.cyanAccent : GymTheme.surfaceElevated)
                        .foregroundColor(isTimeBasedTracking ? GymTheme.bg : GymTheme.textSecondary)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isTimeBasedTracking ? GymTheme.cyanAccent : GymTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
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

                if isTimeBasedTracking {
                    VStack(spacing: 4) {
                        Text("DAUER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GymTheme.cyanAccent)
                        Stepper("", value: $defaultDurationSeconds, in: 5...600, step: 15)
                            .labelsHidden()
                        Text(formatDuration(defaultDurationSeconds))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.cyanAccent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(10)
                    .contextMenu {
                        Button("15 Sekunden") { defaultDurationSeconds = 15 }
                        Button("30 Sekunden") { defaultDurationSeconds = 30 }
                        Button("45 Sekunden") { defaultDurationSeconds = 45 }
                        Button("60 Sekunden (1 Min)") { defaultDurationSeconds = 60 }
                        Button("90 Sekunden (1.5 Min)") { defaultDurationSeconds = 90 }
                        Button("120 Sekunden (2 Min)") { defaultDurationSeconds = 120 }
                        Button("300 Sekunden (5 Min - Plank)") { defaultDurationSeconds = 300 }
                    }
                } else {
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
                }

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

    private func formatDuration(_ sec: Int) -> String {
        let mins = sec / 60
        let s = sec % 60
        if mins > 0 {
            return String(format: "%d:%02d min", mins, s)
        } else {
            return "\(s) s"
        }
    }

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty ? "Neue Uebung" : trimmedName

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

        let newEx = Exercise(
            name: resolvedName,
            targetMuscle: targetMuscle,
            secondaryMuscles: Array(secondaryMuscles),
            equipment: equipment,
            isBWKRehaSafe: isBWKRehaSafe,
            isContraindicated: isContraindicated,
            executionNotes: executionNotes,
            defaultSets: defaultSets,
            defaultReps: isTimeBasedTracking ? defaultDurationSeconds : defaultReps,
            defaultRestSeconds: defaultRestSeconds,
            difficulty: difficulty,
            categoryType: categoryType,
            mechanics: isTimeBasedTracking ? "Isometrisch" : mechanics,
            movementPattern: movementPattern,
            force: isTimeBasedTracking ? "Static" : force,
            primaryMusclesDetailed: [targetMuscle.rawValue],
            secondaryMusclesDetailed: secondaryMuscles.map { $0.rawValue },
            stabilizersDetailed: [],
            setup: setup,
            execution: execution,
            commonMistakes: mistakesList,
            cues: cuesList,
            easierOptions: finalEasier,
            harderOptions: finalHarder,
            programmingGuidance: "",
            youtubeVideoId: youtubeVideoUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : youtubeVideoUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            isCustom: true,
            isExplicitlyTimeBased: isTimeBasedTracking
        )

        store.addExercise(newEx)
        HapticFeedback.success()
        dismiss()
    }
}
