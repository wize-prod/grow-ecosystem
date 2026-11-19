import SwiftUI
import UniformTypeIdentifiers

// MARK: - Google Tasks Architecture für Wirtschaftsinformatik
public struct CyberSecView: View {
    @EnvironmentObject private var store: StudyStore
    @State private var selectedStep: RoadmapStep?
    @State private var searchText: String = ""
    @State private var showAddModuleSheet: Bool = false
    @State private var viewMode: TasksViewMode = .columns
    @State private var activeSingleListPhase: String = ""
    @State private var activeExpandedTaskId: String? = nil
    @FocusState private var isSearchFocused: Bool

    public enum TasksViewMode: String, CaseIterable {
        case columns = "Spalten-Board"
        case singleList = "Listen-Ansicht"
    }

    public init() {}

    private var phases: [String] {
        store.phases(for: .wirtschaftsinformatik)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Obere Kontrollleiste: Suchleiste & Ansichts-Umschalter
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(StudyTheme.textMuted)

                        TextField("Aufgaben, Module & Inhalte durchsuchen...", text: $searchText)
                            .font(.system(size: 13))
                            .foregroundColor(StudyTheme.textPrimary)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(StudyTheme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )

                    Picker("Ansicht", selection: $viewMode) {
                        ForEach(TasksViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)

                // Hauptarbeitsbereich
                if viewMode == .columns {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(phases, id: \.self) { phase in
                                GoogleTasksColumnCard(
                                    phaseTitle: phase,
                                    searchText: searchText,
                                    activeExpandedTaskId: $activeExpandedTaskId,
                                    onSelectStep: { step in
                                        selectedStep = step
                                    }
                                )
                                .frame(width: 360)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .padding(.bottom, 24)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            activeExpandedTaskId = nil
                        }
                    })
                } else {
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(phases, id: \.self) { phase in
                                    let isSelected = (activeSingleListPhase.isEmpty ? phases.first == phase : activeSingleListPhase == phase)
                                    Button {
                                        activeSingleListPhase = phase
                                        HapticFeedback.selection()
                                    } label: {
                                        Text(phase)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? Color.white : StudyTheme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isSelected ? StudyTheme.strongBlue : StudyTheme.surfaceElevated)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }

                        let currentPhase = activeSingleListPhase.isEmpty ? (phases.first ?? "") : activeSingleListPhase
                        ScrollView {
                            GoogleTasksColumnCard(
                                phaseTitle: currentPhase,
                                searchText: searchText,
                                isSingleListFullWidth: true,
                                activeExpandedTaskId: $activeExpandedTaskId,
                                onSelectStep: { step in
                                    selectedStep = step
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                activeExpandedTaskId = nil
                            }
                        })
                    }
                }
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea())
            .navigationTitle("Aufgaben & Module (WInf)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+ Neue Liste") {
                        HapticFeedback.medium()
                        showAddModuleSheet = true
                    }
                    .foregroundColor(StudyTheme.strongBlue)
                }
            }
            .sheet(item: $selectedStep) { step in
                StepDetailSheet(step: step)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddModuleSheet) {
                AddCustomModuleSheet()
                    .environmentObject(store)
            }
            .onAppear {
                if activeSingleListPhase.isEmpty, let first = phases.first {
                    activeSingleListPhase = first
                }
            }
        }
    }
}

// MARK: - Google Tasks Column Card (Eine vollwertige Aufgabenliste im Google Tasks Design)
struct GoogleTasksColumnCard: View {
    let phaseTitle: String
    let searchText: String
    var isSingleListFullWidth: Bool = false
    @Binding var activeExpandedTaskId: String?
    let onSelectStep: (RoadmapStep) -> Void

    @EnvironmentObject private var store: StudyStore
    @State private var isColumnDropTargeted: Bool = false
    @State private var isAddingInlineTask: Bool = false
    @State private var inlineTaskTitle: String = ""
    @State private var isCompletedFoldExpanded: Bool = false
    @State private var showingRenameAlert: Bool = false
    @State private var editedListName: String = ""
    @FocusState private var isInlineFieldFocused: Bool

    private var stepsInPhase: [RoadmapStep] {
        let all = store.steps.filter { $0.phase == phaseTitle }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all
        }
        let q = searchText.lowercased()
        return all.filter {
            $0.title.lowercased().contains(q) ||
            $0.notes.lowercased().contains(q) ||
            $0.submodules.contains(where: { $0.title.lowercased().contains(q) || ($0.notes ?? "").lowercased().contains(q) })
        }
    }

    private var activeSteps: [RoadmapStep] {
        stepsInPhase.filter { !$0.isCompleted }
    }

    private var completedSteps: [RoadmapStep] {
        stepsInPhase.filter { $0.isCompleted }
    }

    private var totalCompletedSubmodulesCount: Int {
        stepsInPhase.reduce(0) { sum, s in
            sum + s.submodules.filter { $0.isCompleted }.count
        }
    }

    private var totalCompletedCount: Int {
        completedSteps.count + totalCompletedSubmodulesCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(StudyTheme.textMuted.opacity(0.6))
                    .padding(.top, 3)

                VStack(alignment: .leading, spacing: 3) {
                    if let f = store.folder(for: phaseTitle) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 8.5))
                            Text(f.name)
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(StudyTheme.strongBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(StudyTheme.strongBlue.opacity(0.12))
                        .cornerRadius(4)
                    }

                    HStack(spacing: 6) {
                        Text(phaseTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            editedListName = phaseTitle
                            showingRenameAlert = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundColor(StudyTheme.textMuted.opacity(0.8))
                                .padding(2)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editedListName = phaseTitle
                        showingRenameAlert = true
                    }

                    Text("\(activeSteps.count) offen • \(totalCompletedCount) erledigt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(StudyTheme.textMuted)
                }

                Spacer()

                Menu {
                    Button {
                        isAddingInlineTask = true
                        isInlineFieldFocused = true
                    } label: {
                        Label("Aufgabe oben hinzufügen", systemImage: "plus")
                    }

                    Button {
                        editedListName = phaseTitle
                        showingRenameAlert = true
                    } label: {
                        Label("Liste umbenennen", systemImage: "pencil")
                    }
                    Divider()
                    Menu("In Ordner verschieben") {
                        ForEach(store.folders) { f in
                            Button {
                                store.moveList(listName: phaseTitle, toFolderId: f.id)
                            } label: {
                                if store.lists(in: f.id).contains(phaseTitle) {
                                    Label(f.name, systemImage: "checkmark")
                                } else {
                                    Text(f.name)
                                }
                            }
                        }
                        if store.folder(for: phaseTitle) != nil {
                            Divider()
                            Button("Aus Ordner entfernen") {
                                store.moveList(listName: phaseTitle, toFolderId: nil)
                            }
                        }
                    }
                    if totalCompletedCount > 0 {
                        Divider()
                        Button("Erledigte Aufgaben bereinigen", role: .destructive) {
                            store.deleteCompletedTasks(inPhase: phaseTitle)
                        }
                    }
                    Divider()
                    Button("Liste löschen", role: .destructive) {
                        store.deleteList(name: phaseTitle)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(6)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .contentShape(Rectangle())
            .draggable(phaseTitle)

            // Schnell-Eingabe
            if isAddingInlineTask {
                HStack(spacing: 10) {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    TextField("Titel der Aufgabe eingeben...", text: $inlineTaskTitle)
                        .font(.system(size: 13.5))
                        .foregroundColor(Color.white)
                        .textFieldStyle(.plain)
                        .focused($isInlineFieldFocused)
                        .onSubmit {
                            commitInlineTask()
                        }

                    Button("Hinzufügen") {
                        commitInlineTask()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                    .disabled(inlineTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        isAddingInlineTask = false
                        inlineTaskTitle = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isAddingInlineTask = true
                        isInlineFieldFocused = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(StudyTheme.strongBlue)

                        Text("Aufgabe hinzufügen")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(StudyTheme.strongBlue)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.white.opacity(0.08))

            // Scrollbare Aufgabenliste
            ScrollView {
                VStack(spacing: 4) {
                    if activeSteps.isEmpty && completedSteps.isEmpty {
                        VStack(spacing: 6) {
                            Text("Keine Aufgaben vorhanden")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(StudyTheme.textMuted)
                            Text("Aufgabe oben anlegen oder aus anderer Liste hierher ziehen")
                                .font(.system(size: 11))
                                .foregroundColor(StudyTheme.textMuted.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .padding(.horizontal, 16)
                    } else if activeSteps.isEmpty && !completedSteps.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 28))
                                .foregroundColor(StudyTheme.sageGreen.opacity(0.8))
                                .padding(.top, 10)
                            Text("Alle Aufgaben erledigt")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.white)
                            Text("Hervorragende Arbeit!")
                                .font(.system(size: 12))
                                .foregroundColor(StudyTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(activeSteps) { step in
                            GoogleTaskItemRow(
                                step: step,
                                currentPhase: phaseTitle,
                                activeExpandedId: $activeExpandedTaskId,
                                onSelectStep: { onSelectStep(step) }
                            )
                        }
                    }

                    // Collapsible "Completed (N)" Fold
                    if totalCompletedCount > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isCompletedFoldExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isCompletedFoldExpanded ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(StudyTheme.textMuted)

                                    Text("Erledigt (\(totalCompletedCount))")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.textSecondary)

                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)

                            if isCompletedFoldExpanded {
                                VStack(spacing: 3) {
                                    ForEach(completedSteps) { step in
                                        GoogleTaskItemRow(
                                            step: step,
                                            currentPhase: phaseTitle,
                                            activeExpandedId: $activeExpandedTaskId,
                                            onSelectStep: { onSelectStep(step) }
                                        )
                                    }

                                    ForEach(activeSteps) { step in
                                        let doneSubs = step.submodules.filter { $0.isCompleted }
                                        ForEach(doneSubs) { sub in
                                            CompletedSubmoduleRow(
                                                submodule: sub,
                                                parentStepId: step.id
                                            )
                                        }
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.top, 14)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isColumnDropTargeted ? StudyTheme.strongBlue : Color.white.opacity(0.06), lineWidth: isColumnDropTargeted ? 2 : 1)
        )
        .onDrop(of: [.plainText, .text, .pdf, .item, .data], isTargeted: $isColumnDropTargeted) { providers in
            handleDropOnColumn(providers: providers)
            return true
        }
        .alert("Liste umbenennen", isPresented: $showingRenameAlert) {
            TextField("Neuer Listenname", text: $editedListName)
            Button("Abbrechen", role: .cancel) {}
            Button("Speichern") {
                let clean = editedListName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty && clean != phaseTitle {
                    store.renameList(oldName: phaseTitle, newName: clean)
                }
            }
        } message: {
            Text("Gib einen neuen Namen für diese Aufgabenliste ein. Alle zugehörigen Aufgaben und Ordnerzuweisungen werden automatisch aktualisiert.")
        }
    }

    private func commitInlineTask() {
        let trimmed = inlineTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextSeq = (stepsInPhase.map { $0.sequenceNumber }.max() ?? 0) + 1
        let newStep = RoadmapStep(
            id: "step-\(UUID().uuidString.prefix(8))",
            track: .wirtschaftsinformatik,
            phase: phaseTitle,
            sequenceNumber: nextSeq,
            title: trimmed,
            subtitle: "",
            type: .webModule,
            estimatedHours: 1.0,
            category: "Aufgabe",
            difficulty: "Normal",
            submodules: [],
            isCompleted: false
        )
        store.steps.append(newStep)
        store.saveAllSteps()
        inlineTaskTitle = ""
        isInlineFieldFocused = true
        HapticFeedback.success()
    }

    private func handleDropOnColumn(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSString.self) {
                _ = provider.loadObject(ofClass: NSString.self) { item, _ in
                    guard let payload = item as? String else { return }
                    Task { @MainActor in processDragPayload(payload) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                    if let str = data as? String {
                        Task { @MainActor in self.processDragPayload(str) }
                    } else if let data = data as? Data, let str = String(data: data, encoding: .utf8) {
                        Task { @MainActor in self.processDragPayload(str) }
                    }
                }
            } else {
                store.importDroppedFiles(from: [provider], targetPhase: phaseTitle)
            }
        }
    }

    private func processDragPayload(_ payload: String) {
        if payload.hasPrefix("step:") {
            let stepId = String(payload.dropFirst(5))
            store.moveStep(stepId: stepId, toPhase: phaseTitle)
            store.updateStepDetails(stepId: stepId, clearPlannedDate: true)
        } else if payload.hasPrefix("submodule:") {
            let parts = payload.components(separatedBy: ":")
            if parts.count == 3 {
                let fromStepId = parts[1]
                let subId = parts[2]
                store.moveSubmoduleToPhase(submoduleId: subId, fromStepId: fromStepId, toPhase: phaseTitle)
                store.updateSubmoduleDetails(parentStepId: fromStepId, submoduleId: subId, clearPlannedDate: true)
            }
        }
    }
}

// MARK: - Google Task Item Row (Inline aufklappbar mit Beschreibung, Datum & Anhängen)
struct GoogleTaskItemRow: View {
    let step: RoadmapStep
    let currentPhase: String
    @Binding var activeExpandedId: String?
    let onSelectStep: () -> Void

    @EnvironmentObject private var store: StudyStore
    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var isAddingSubtaskInline: Bool = false
    @State private var inlineSubtaskTitle: String = ""
    @State private var isHovered: Bool = false
    @State private var isRowDropTargeted: Bool = false
    @State private var showingDatePickerPopover: Bool = false
    @State private var showingRecurrenceSheet: Bool = false
    @State private var showingLabelsSheet: Bool = false
    @State private var showingAddLinkField: Bool = false
    @State private var newLinkURL: String = ""
    @State private var newLinkTitle: String = ""
    @State private var showingFilePicker: Bool = false
    @FocusState private var isSubtaskFieldFocused: Bool

    private var liveStep: RoadmapStep {
        store.steps.first(where: { $0.id == step.id }) ?? step
    }

    private var isExpanded: Bool {
        activeExpandedId == liveStep.id
    }

    private var isPlannedToday: Bool {
        guard let d = liveStep.plannedDate else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var isPlannedTomorrow: Bool {
        guard let d = liveStep.plannedDate else { return false }
        return Calendar.current.isDateInTomorrow(d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            taskHeaderRow

            if isExpanded {
                taskExpandedSection
            }

            // Eingerückte Unteraufgaben (nur aktive, nicht erledigte Unteraufgaben)
            let activeSubmodules = liveStep.submodules.filter { !$0.isCompleted }
            if !activeSubmodules.isEmpty {
                VStack(spacing: 2) {
                    ForEach(activeSubmodules) { sub in
                        GoogleSubtaskItemRow(
                            submodule: sub,
                            parentStepId: liveStep.id,
                            currentPhase: currentPhase,
                            activeExpandedId: $activeExpandedId,
                            onSelectParent: onSelectStep
                        )
                    }
                }
                .padding(.leading, 26)
            }

            // Inline "+ Unteraufgabe hinzufügen"
            if isAddingSubtaskInline {
                HStack(spacing: 8) {
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                        .frame(width: 15, height: 15)

                    TextField("Unteraufgabe eingeben...", text: $inlineSubtaskTitle)
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.white)
                        .textFieldStyle(.plain)
                        .focused($isSubtaskFieldFocused)
                        .onSubmit { commitInlineSubtask() }

                    Button("Hinzufügen") { commitInlineSubtask() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(StudyTheme.strongBlue)
                        .disabled(inlineSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        isAddingSubtaskInline = false
                        inlineSubtaskTitle = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.03))
                .cornerRadius(6)
                .padding(.leading, 26)
                .padding(.top, 2)
            }
        }
        .background(isExpanded ? Color.white.opacity(0.05) : Color.white.opacity(isHovered ? 0.04 : (isRowDropTargeted ? 0.08 : 0)))
        .cornerRadius(isExpanded ? 10 : 8)
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? 10 : 8)
                .stroke(isExpanded ? StudyTheme.strongBlue.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .onHover { h in isHovered = h }
        .onDrag {
            NSItemProvider(object: "step:\(liveStep.id)" as NSString)
        }
        .onDrop(of: [.plainText, .text, .item, .pdf], isTargeted: $isRowDropTargeted) { providers in
            handleDropOnRow(providers: providers)
            return true
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .data, .item, .text],
            allowsMultipleSelection: false
        ) { result in
            handlePickedFile(result: result)
        }
        .onKeyPress(.tab, phases: .down) { press in
            if !press.modifiers.contains(.shift) {
                store.indentStep(stepId: liveStep.id)
                return .handled
            }
            return .ignored
        }
        .sheet(isPresented: $showingRecurrenceSheet) {
            CustomRecurrencePickerSheet(initialRule: liveStep.recurrenceRule) { rule in
                if let r = rule {
                    store.updateStepDetails(stepId: liveStep.id, recurrenceRule: r)
                } else {
                    store.updateStepDetails(stepId: liveStep.id, clearRecurrenceRule: true)
                }
            }
        }
        .sheet(isPresented: $showingLabelsSheet) {
            TaskLabelsManagementSheet()
                .environmentObject(store)
        }
        .contextMenu {
            if liveStep.plannedDate != nil {
                Button(role: .destructive) {
                    store.updateStepDetails(stepId: liveStep.id, clearPlannedDate: true)
                } label: {
                    Label("Termin entfernen", systemImage: "calendar.badge.minus")
                }
            }

            Button {
                store.indentStep(stepId: liveStep.id)
            } label: {
                Label("Einrücken (zu Teilaufgabe)", systemImage: "arrow.right.to.line")
            }

            Divider()

            Button(role: .destructive) {
                store.deleteStep(id: liveStep.id)
            } label: {
                Label("Aufgabe löschen", systemImage: "trash")
            }
        }
        .onAppear {
            editedTitle = liveStep.title
            editedNotes = liveStep.notes
        }
        .onChange(of: activeExpandedId) { oldVal, newVal in
            if oldVal == liveStep.id && newVal != liveStep.id {
                saveAllEdits()
            } else if oldVal != liveStep.id && newVal == liveStep.id {
                editedTitle = liveStep.title
                editedNotes = liveStep.notes
            }
        }
    }

    // MARK: - Task Subviews
    @ViewBuilder
    private var taskHeaderRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.grid.2x1.fill")
                .font(.system(size: 9))
                .foregroundColor(isHovered ? StudyTheme.textMuted : Color.clear)
                .frame(width: 8)
                .padding(.top, 4)

            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    store.toggleStep(id: liveStep.id)
                }
            } label: {
                if liveStep.isCompleted {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.22, green: 0.68, blue: 0.38))
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.38), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                if isExpanded {
                    TextField("Aufgabentitel", text: $editedTitle, axis: .vertical)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(Color.white)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 1)
                        .onChange(of: editedTitle) { _, _ in
                            saveTitle()
                        }
                        .onSubmit { saveTitle() }
                } else {
                    Text(liveStep.title)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(liveStep.isCompleted ? Color.white.opacity(0.38) : Color.white.opacity(0.92))
                        .strikethrough(liveStep.isCompleted, color: Color.white.opacity(0.38))
                        .lineLimit(2)
                        .contentShape(Rectangle())
                        .onTapGesture { expandTask() }
                }

                if !isExpanded && !liveStep.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let firstLine = liveStep.notes.components(separatedBy: .newlines).first ?? ""
                    HStack(spacing: 4) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 9.5))
                            .foregroundColor(StudyTheme.textMuted)
                        Text(LocalizedStringKey(firstLine))
                            .font(.system(size: 11.5))
                            .foregroundColor(StudyTheme.textMuted)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expandTask() }
                }

                if !isExpanded {
                    collapsedBadgesView
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isExpanded {
                    expandTask()
                }
            }

            Spacer()

            if isExpanded {
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        saveAllEdits()
                        activeExpandedId = nil
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }

            Menu {
                Button(isExpanded ? "Details einklappen" : "Details aufklappen") {
                    expandTask()
                }
                Divider()
                Button("Einrücken (Tab)") {
                    store.indentStep(stepId: liveStep.id)
                }
                Divider()
                Button("Unteraufgabe hinzufügen") {
                    withAnimation {
                        isAddingSubtaskInline = true
                        isSubtaskFieldFocused = true
                    }
                }
                Menu("In andere Liste verschieben...") {
                    ForEach(store.phases(for: .wirtschaftsinformatik), id: \.self) { p in
                        if p != currentPhase {
                            Button(p) { store.moveStep(stepId: liveStep.id, toPhase: p) }
                        }
                    }
                }
                Divider()
                Button("Löschen", role: .destructive) {
                    store.deleteStep(id: liveStep.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundColor(StudyTheme.textMuted.opacity(0.8))
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var collapsedBadgesView: some View {
        HStack(spacing: 6) {
            if let pd = liveStep.plannedDate {
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(formattedChipDate(pd))
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .background(StudyTheme.strongBlue.opacity(0.18))
                .foregroundColor(StudyTheme.strongBlue)
                .cornerRadius(4)
            }

            if let rule = liveStep.recurrenceRule {
                HStack(spacing: 3) {
                    Image(systemName: "repeat")
                        .font(.system(size: 8.5))
                    Text(rule.summaryText)
                        .font(.system(size: 9, weight: .medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .background(StudyTheme.cyanAccent.opacity(0.18))
                .foregroundColor(StudyTheme.cyanAccent)
                .cornerRadius(4)
            }

            if let lbl = store.label(for: liveStep.labelId) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: lbl.colorHex))
                        .frame(width: 6, height: 6)
                    Text(lbl.name)
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .background(Color(hex: lbl.colorHex).opacity(0.2))
                .foregroundColor(Color(hex: lbl.colorHex))
                .cornerRadius(4)
            }
        }
        .padding(.top, 1)
    }

    @ViewBuilder
    private var taskExpandedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Notizen & Markdown Editor
            MarkdownNotesEditorView(
                text: $editedNotes,
                placeholder: "Details / Notizen hinzufügen (Markdown unterstützt)..."
            ) {
                store.updateStepDetails(stepId: liveStep.id, notes: editedNotes)
            }
            .padding(.horizontal, 4)

            taskDateChipsRow
            taskAttachmentsSection
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var taskDateChipsRow: some View {
        HStack(spacing: 6) {
            // 1. Termin Icon-Button
            Button {
                showingDatePickerPopover = true
            } label: {
                Image(systemName: liveStep.plannedDate != nil ? "calendar.badge.clock" : "clock")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 26)
                    .background(liveStep.plannedDate != nil ? StudyTheme.strongBlue.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(liveStep.plannedDate != nil ? StudyTheme.strongBlue : StudyTheme.textMuted)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(liveStep.plannedDate != nil ? StudyTheme.strongBlue : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(liveStep.plannedDate != nil ? formattedChipDate(liveStep.plannedDate!) : "Termin / Fälligkeit festlegen")
            .popover(isPresented: $showingDatePickerPopover) {
                VStack(spacing: 8) {
                    DatePicker("Fälligkeit", selection: Binding(
                        get: { liveStep.plannedDate ?? Date() },
                        set: { store.updateStepDetails(stepId: liveStep.id, plannedDate: $0) }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    HStack {
                        Button("Termin löschen", role: .destructive) {
                            store.updateStepDetails(stepId: liveStep.id, clearPlannedDate: true)
                            showingDatePickerPopover = false
                        }
                        Spacer()
                        Button("Fertig") { showingDatePickerPopover = false }
                    }
                }
                .padding(12)
                .frame(width: 280)
            }

            if let date = liveStep.plannedDate {
                HStack(spacing: 4) {
                    Text(formattedChipDate(date))
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(StudyTheme.strongBlue)

                    Button {
                        HapticFeedback.light()
                        store.updateStepDetails(stepId: liveStep.id, clearPlannedDate: true)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Termin entfernen")
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(StudyTheme.strongBlue.opacity(0.18))
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(StudyTheme.strongBlue.opacity(0.4), lineWidth: 1))
            }

            // 2. Wiederholen Icon-Button
            Button {
                showingRecurrenceSheet = true
            } label: {
                Image(systemName: liveStep.recurrenceRule != nil ? "repeat.circle.fill" : "repeat")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 26)
                    .background(liveStep.recurrenceRule != nil ? StudyTheme.strongBlue.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(liveStep.recurrenceRule != nil ? StudyTheme.strongBlue : StudyTheme.textMuted)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(liveStep.recurrenceRule != nil ? StudyTheme.strongBlue : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(liveStep.recurrenceRule?.summaryText ?? "Wiederholung konfigurieren")

            // 3. Label Icon-Button (Menu)
            Menu {
                if liveStep.labelId != nil {
                    Button(role: .destructive) {
                        store.updateStepDetails(stepId: liveStep.id, clearLabel: true)
                    } label: {
                        Label("Kein Label", systemImage: "xmark")
                    }
                    Divider()
                }

                ForEach(store.labels) { lbl in
                    Button {
                        store.updateStepDetails(stepId: liveStep.id, labelId: lbl.id)
                    } label: {
                        HStack {
                            Text(lbl.name)
                            if liveStep.labelId == lbl.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    showingLabelsSheet = true
                } label: {
                    Label("Labels verwalten...", systemImage: "tag")
                }
            } label: {
                ZStack {
                    if let lbl = store.label(for: liveStep.labelId) {
                        Circle()
                            .fill(Color(hex: lbl.colorHex))
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "tag")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                }
                .frame(width: 28, height: 26)
                .background(liveStep.labelId != nil ? (Color(hex: store.label(for: liveStep.labelId)?.colorHex ?? "#039BE5").opacity(0.22)) : Color.white.opacity(0.06))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(liveStep.labelId != nil ? (Color(hex: store.label(for: liveStep.labelId)?.colorHex ?? "#039BE5").opacity(0.6)) : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(store.label(for: liveStep.labelId)?.name ?? "Label zuweisen")

            // 4. Link Icon-Button (Menu - Alle Links & Dateien dahinter gebündelt)
            Menu {
                if !liveStep.resources.isEmpty {
                    Section("Angehängte Ressourcen") {
                        ForEach(liveStep.resources) { res in
                            Button {
                                if let u = URL(string: res.url) { UIApplication.shared.open(u) }
                            } label: {
                                Label(res.title, systemImage: res.url.hasPrefix("file://") ? "doc.fill" : "link")
                            }
                        }
                    }

                    Section("Verwalten") {
                        Menu("Ressource löschen...") {
                            ForEach(liveStep.resources) { res in
                                Button(role: .destructive) {
                                    store.deleteResource(from: liveStep.id, resourceId: res.id)
                                } label: {
                                    Text(res.title)
                                }
                            }
                        }
                    }

                    Divider()
                }

                Button {
                    showingAddLinkField = true
                } label: {
                    Label("Web-Link hinzufügen", systemImage: "link.badge.plus")
                }

                Button {
                    showingFilePicker = true
                } label: {
                    Label("Datei / PDF hinzufügen", systemImage: "doc.badge.plus")
                }
            } label: {
                let hasLinks = !liveStep.resources.isEmpty
                ZStack {
                    Image(systemName: "link")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(hasLinks ? StudyTheme.strongBlue : StudyTheme.textMuted)
                }
                .frame(width: 28, height: 26)
                .background(hasLinks ? StudyTheme.strongBlue.opacity(0.25) : Color.white.opacity(0.06))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(hasLinks ? StudyTheme.strongBlue : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(liveStep.resources.isEmpty ? "Link oder Datei hinzufügen" : "\(liveStep.resources.count) Ressource(n) vorhanden")

            // 5. Pomodoro Timer Icon-Button (Startet Pomodoro-Timer für diese Aufgabe)
            let isTimerActiveForThisTask = (store.activeTimerStepId == liveStep.id && store.isFocusTimerRunning)
            Button {
                HapticFeedback.medium()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    if isTimerActiveForThisTask {
                        store.stopFocusTimer()
                    } else {
                        store.startFocusTimer(for: liveStep.id, minutes: 25)
                    }
                }
            } label: {
                Image(systemName: isTimerActiveForThisTask ? "stopwatch.fill" : "stopwatch")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isTimerActiveForThisTask ? StudyTheme.cyanAccent : StudyTheme.textMuted)
                    .frame(width: 28, height: 26)
                    .background(isTimerActiveForThisTask ? StudyTheme.cyanAccent.opacity(0.25) : Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isTimerActiveForThisTask ? StudyTheme.cyanAccent : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(isTimerActiveForThisTask ? "Pomodoro-Timer anhalten" : "25m Pomodoro-Timer für diese Aufgabe starten")
        }
    }

    @ViewBuilder
    private var taskAttachmentsSection: some View {
        if showingAddLinkField {
            HStack(spacing: 6) {
                TextField("Titel", text: $newLinkTitle)
                    .font(.system(size: 11.5))
                    .textFieldStyle(.plain)
                    .frame(width: 90)

                TextField("URL...", text: $newLinkURL)
                    .font(.system(size: 11.5))
                    .textFieldStyle(.plain)
                    .onSubmit { commitNewLink() }

                Button("Speichern") { commitNewLink() }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                    .disabled(newLinkURL.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    showingAddLinkField = false
                    newLinkURL = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)
        }
    }

    private func expandTask() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            if isExpanded {
                saveAllEdits()
                activeExpandedId = nil
            } else {
                editedTitle = liveStep.title
                editedNotes = liveStep.notes
                activeExpandedId = liveStep.id
            }
        }
    }

    private func saveTitle() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateStepDetails(stepId: liveStep.id, title: trimmed)
        }
    }

    private func saveAllEdits() {
        saveTitle()
        store.updateStepDetails(stepId: liveStep.id, notes: editedNotes)
    }

    private func commitNewLink() {
        var cleanURL = newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty else { return }
        if !cleanURL.contains("://") && !cleanURL.hasPrefix("file://") {
            cleanURL = "https://" + cleanURL
        }
        let title = newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (URL(string: cleanURL)?.host ?? "Link") : newLinkTitle
        store.addResource(to: liveStep.id, title: title, url: cleanURL, type: "Web")
        newLinkURL = ""
        newLinkTitle = ""
        showingAddLinkField = false
    }

    private func handlePickedFile(result: Result<[URL], Error>) {
        if case .success(let urls) = result, let sourceURL = urls.first {
            let canAccess = sourceURL.startAccessingSecurityScopedResource()
            defer { if canAccess { sourceURL.stopAccessingSecurityScopedResource() } }
            if let saved = store.saveAttachmentFile(from: sourceURL) {
                let fileName = sourceURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                store.addResource(to: liveStep.id, title: fileName, url: saved.absoluteString, type: "PDF")
            }
        }
    }

    private func commitInlineSubtask() {
        let trimmed = inlineSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = store.addSubmodule(
            to: liveStep.id,
            title: trimmed,
            type: .webModule,
            url: nil,
            durationMinutes: 25
        )
        inlineSubtaskTitle = ""
        isSubtaskFieldFocused = true
        HapticFeedback.success()
    }

    private func handleDropOnRow(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSString.self) {
                _ = provider.loadObject(ofClass: NSString.self) { item, _ in
                    guard let payload = item as? String else { return }
                    Task { @MainActor in
                        if payload.hasPrefix("submodule:") {
                            let parts = payload.components(separatedBy: ":")
                            if parts.count == 3 {
                                store.moveSubmodule(submoduleId: parts[2], fromStepId: parts[1], toStepId: liveStep.id)
                                store.updateSubmoduleDetails(parentStepId: liveStep.id, submoduleId: parts[2], clearPlannedDate: true)
                            }
                        } else if payload.hasPrefix("step:") {
                            let dragStepId = String(payload.dropFirst(5))
                            store.reorderStep(stepId: dragStepId, beforeStepId: liveStep.id)
                            store.updateStepDetails(stepId: dragStepId, clearPlannedDate: true)
                        }
                    }
                }
            } else {
                store.importDroppedFiles(from: [provider], targetStepId: liveStep.id, isResourceOnly: true)
            }
        }
    }

    private func formattedChipDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Heute" }
        if Calendar.current.isDateInTomorrow(date) { return "Morgen" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d. MMM"
        return f.string(from: date)
    }
}

// MARK: - Google Subtask Item Row (Inline aufklappbar mit Ausrücken per Shift+Tab)
struct GoogleSubtaskItemRow: View {
    let submodule: StudySubmodule
    let parentStepId: String
    let currentPhase: String
    @Binding var activeExpandedId: String?
    let onSelectParent: () -> Void

    @EnvironmentObject private var store: StudyStore
    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var isHovered: Bool = false
    @State private var showingDatePickerPopover: Bool = false
    @State private var showingRecurrenceSheet: Bool = false
    @State private var showingLabelsSheet: Bool = false
    @State private var showingAddLinkField: Bool = false
    @State private var newLinkURL: String = ""
    @State private var newLinkTitle: String = ""
    @State private var showingFilePicker: Bool = false

    private var liveSubmodule: StudySubmodule {
        if let parent = store.steps.first(where: { $0.id == parentStepId }),
           let sm = parent.submodules.first(where: { $0.id == submodule.id }) {
            return sm
        }
        return submodule
    }

    private var isExpanded: Bool {
        activeExpandedId == submodule.id
    }

    private var isPlannedToday: Bool {
        guard let d = liveSubmodule.plannedDate else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var isPlannedTomorrow: Bool {
        guard let d = liveSubmodule.plannedDate else { return false }
        return Calendar.current.isDateInTomorrow(d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            subtaskHeaderRow

            if isExpanded {
                subtaskExpandedSection
            }
        }
        .background(isExpanded ? Color.white.opacity(0.05) : Color.white.opacity(isHovered ? 0.03 : 0))
        .cornerRadius(isExpanded ? 8 : 6)
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? 8 : 6)
                .stroke(isExpanded ? StudyTheme.strongBlue.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .onHover { h in isHovered = h }
        .onDrag {
            NSItemProvider(object: "submodule:\(parentStepId):\(liveSubmodule.id)" as NSString)
        }
        .onDrop(of: [.pdf, .data, .item], isTargeted: .constant(false)) { providers in
            store.importDroppedFiles(from: providers, targetStepId: parentStepId, targetSubmoduleId: liveSubmodule.id, isResourceOnly: true)
            return true
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .data, .item, .text],
            allowsMultipleSelection: false
        ) { result in
            handlePickedFile(result: result)
        }
        .onKeyPress(.tab, phases: .down) { press in
            if press.modifiers.contains(.shift) {
                store.unindentSubmodule(submoduleId: liveSubmodule.id, parentStepId: parentStepId)
                return .handled
            }
            return .ignored
        }
        .sheet(isPresented: $showingRecurrenceSheet) {
            CustomRecurrencePickerSheet(initialRule: liveSubmodule.recurrenceRule) { rule in
                if let r = rule {
                    store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, recurrenceRule: r)
                } else {
                    store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, clearRecurrenceRule: true)
                }
            }
        }
        .sheet(isPresented: $showingLabelsSheet) {
            TaskLabelsManagementSheet()
                .environmentObject(store)
        }
        .contextMenu {
            if liveSubmodule.plannedDate != nil {
                Button(role: .destructive) {
                    store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, clearPlannedDate: true)
                } label: {
                    Label("Termin entfernen", systemImage: "calendar.badge.minus")
                }
            }

            Button {
                store.unindentSubmodule(submoduleId: liveSubmodule.id, parentStepId: parentStepId)
            } label: {
                Label("Ausrücken (zu Hauptaufgabe)", systemImage: "arrow.left.to.line")
            }

            Divider()

            Button(role: .destructive) {
                store.deleteSubmodule(from: parentStepId, submoduleId: liveSubmodule.id)
            } label: {
                Label("Teilaufgabe löschen", systemImage: "trash")
            }
        }
        .onAppear {
            editedTitle = liveSubmodule.title
            editedNotes = liveSubmodule.notes ?? ""
        }
        .onChange(of: activeExpandedId) { oldVal, newVal in
            if oldVal == submodule.id && newVal != submodule.id {
                saveAllEdits()
            } else if oldVal != submodule.id && newVal == submodule.id {
                editedTitle = liveSubmodule.title
                editedNotes = liveSubmodule.notes ?? ""
            }
        }
    }

    @ViewBuilder
    private var subtaskHeaderRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.grid.2x1.fill")
                .font(.system(size: 8))
                .foregroundColor(isHovered ? StudyTheme.textMuted : Color.clear)
                .frame(width: 8)

            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    store.toggleSubmodule(stepId: parentStepId, submoduleId: liveSubmodule.id)
                }
            } label: {
                if liveSubmodule.isCompleted {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.22, green: 0.68, blue: 0.38))
                            .frame(width: 15, height: 15)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                        .frame(width: 15, height: 15)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                if isExpanded {
                    TextField("Unteraufgabe", text: $editedTitle, axis: .vertical)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Color.white)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 1)
                        .onChange(of: editedTitle) { _, _ in
                            saveTitle()
                        }
                        .onSubmit { saveTitle() }
                } else {
                    Text(liveSubmodule.title)
                        .font(.system(size: 12.5))
                        .foregroundColor(liveSubmodule.isCompleted ? Color.white.opacity(0.35) : Color.white.opacity(0.9))
                        .strikethrough(liveSubmodule.isCompleted, color: Color.white.opacity(0.35))
                        .lineLimit(1)
                        .contentShape(Rectangle())
                        .onTapGesture { expandSubtask() }
                }

                if !isExpanded, let notes = liveSubmodule.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let firstLine = notes.components(separatedBy: .newlines).first ?? ""
                    HStack(spacing: 4) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 8.5))
                            .foregroundColor(StudyTheme.textMuted)
                        Text(LocalizedStringKey(firstLine))
                            .font(.system(size: 11))
                            .foregroundColor(StudyTheme.textMuted)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expandSubtask() }
                }

                if !isExpanded {
                    HStack(spacing: 5) {
                        if let pd = liveSubmodule.plannedDate {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.system(size: 8))
                                Text(formattedChipDate(pd))
                                    .font(.system(size: 9, design: .monospaced))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(StudyTheme.strongBlue.opacity(0.18))
                            .foregroundColor(StudyTheme.strongBlue)
                            .cornerRadius(3)
                        }

                        if let rule = liveSubmodule.recurrenceRule {
                            HStack(spacing: 2) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 7.5))
                                Text(rule.summaryText)
                                    .font(.system(size: 8.5))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(StudyTheme.cyanAccent.opacity(0.18))
                            .foregroundColor(StudyTheme.cyanAccent)
                            .cornerRadius(3)
                        }

                        if let lbl = store.label(for: liveSubmodule.labelId) {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color(hex: lbl.colorHex))
                                    .frame(width: 5, height: 5)
                                Text(lbl.name)
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color(hex: lbl.colorHex).opacity(0.2))
                            .foregroundColor(Color(hex: lbl.colorHex))
                            .cornerRadius(3)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isExpanded {
                    expandSubtask()
                }
            }

            Spacer()

            if isExpanded {
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        saveAllEdits()
                        activeExpandedId = nil
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }

            Menu {
                Button(isExpanded ? "Details einklappen" : "Details aufklappen") {
                    expandSubtask()
                }
                Divider()
                Button("Ausrücken (Shift+Tab)") {
                    store.unindentSubmodule(submoduleId: liveSubmodule.id, parentStepId: parentStepId)
                }
                Menu("In andere Liste verschieben...") {
                    ForEach(store.phases(for: .wirtschaftsinformatik), id: \.self) { p in
                        if p != currentPhase {
                            Button(p) { store.moveSubmoduleToPhase(submoduleId: liveSubmodule.id, fromStepId: parentStepId, toPhase: p) }
                        }
                    }
                }
                Divider()
                Button("Löschen", role: .destructive) {
                    store.deleteSubmodule(from: parentStepId, submoduleId: liveSubmodule.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(StudyTheme.textMuted.opacity(0.6))
                    .padding(2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private var subtaskExpandedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Notizen & Markdown Editor
            MarkdownNotesEditorView(
                text: $editedNotes,
                placeholder: "Details hinzufügen (Markdown unterstützt)..."
            ) {
                store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, notes: editedNotes)
            }
            .padding(.horizontal, 2)

            subtaskDateChipsRow
            subtaskAttachmentsSection
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var subtaskDateChipsRow: some View {
        HStack(spacing: 5) {
            // 1. Termin Icon-Button
            Button {
                showingDatePickerPopover = true
            } label: {
                Image(systemName: liveSubmodule.plannedDate != nil ? "calendar.badge.clock" : "clock")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 26, height: 24)
                    .background(liveSubmodule.plannedDate != nil ? StudyTheme.strongBlue.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(liveSubmodule.plannedDate != nil ? StudyTheme.strongBlue : StudyTheme.textMuted)
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(liveSubmodule.plannedDate != nil ? StudyTheme.strongBlue : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(liveSubmodule.plannedDate != nil ? formattedChipDate(liveSubmodule.plannedDate!) : "Termin / Fälligkeit festlegen")
            .popover(isPresented: $showingDatePickerPopover) {
                VStack(spacing: 8) {
                    DatePicker("Termin", selection: Binding(
                        get: { liveSubmodule.plannedDate ?? Date() },
                        set: { store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, plannedDate: $0) }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    HStack {
                        Button("Termin löschen", role: .destructive) {
                            store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, clearPlannedDate: true)
                            showingDatePickerPopover = false
                        }
                        Spacer()
                        Button("Fertig") { showingDatePickerPopover = false }
                    }
                }
                .padding(10)
                .frame(width: 270)
            }

            if let date = liveSubmodule.plannedDate {
                HStack(spacing: 3) {
                    Text(formattedChipDate(date))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(StudyTheme.strongBlue)

                    Button {
                        HapticFeedback.light()
                        store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, clearPlannedDate: true)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Termin entfernen")
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(StudyTheme.strongBlue.opacity(0.18))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(StudyTheme.strongBlue.opacity(0.4), lineWidth: 1))
            }

            // 2. Wiederholen Icon-Button
            Button {
                showingRecurrenceSheet = true
            } label: {
                Image(systemName: liveSubmodule.recurrenceRule != nil ? "repeat.circle.fill" : "repeat")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 26, height: 24)
                    .background(liveSubmodule.recurrenceRule != nil ? StudyTheme.strongBlue.opacity(0.25) : Color.white.opacity(0.06))
                    .foregroundColor(liveSubmodule.recurrenceRule != nil ? StudyTheme.strongBlue : StudyTheme.textMuted)
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(liveSubmodule.recurrenceRule != nil ? StudyTheme.strongBlue : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(liveSubmodule.recurrenceRule?.summaryText ?? "Wiederholung konfigurieren")

            // 3. Label Icon-Button (Menu)
            Menu {
                if liveSubmodule.labelId != nil {
                    Button(role: .destructive) {
                        store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, clearLabel: true)
                    } label: {
                        Label("Kein Label", systemImage: "xmark")
                    }
                    Divider()
                }

                ForEach(store.labels) { lbl in
                    Button {
                        store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, labelId: lbl.id)
                    } label: {
                        HStack {
                            Text(lbl.name)
                            if liveSubmodule.labelId == lbl.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    showingLabelsSheet = true
                } label: {
                    Label("Labels verwalten...", systemImage: "tag")
                }
            } label: {
                ZStack {
                    if let lbl = store.label(for: liveSubmodule.labelId) {
                        Circle()
                            .fill(Color(hex: lbl.colorHex))
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "tag")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                }
                .frame(width: 26, height: 24)
                .background(liveSubmodule.labelId != nil ? (Color(hex: store.label(for: liveSubmodule.labelId)?.colorHex ?? "#039BE5").opacity(0.22)) : Color.white.opacity(0.06))
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(liveSubmodule.labelId != nil ? (Color(hex: store.label(for: liveSubmodule.labelId)?.colorHex ?? "#039BE5").opacity(0.6)) : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(store.label(for: liveSubmodule.labelId)?.name ?? "Label zuweisen")

            // 4. Link Icon-Button (Menu - Alle Links & Dateien dahinter gebündelt)
            Menu {
                if !liveSubmodule.allResources.isEmpty {
                    Section("Angehängte Ressourcen") {
                        ForEach(liveSubmodule.allResources) { res in
                            Button {
                                if let u = URL(string: res.url) { UIApplication.shared.open(u) }
                            } label: {
                                Label(res.title, systemImage: res.url.hasPrefix("file://") ? "doc.fill" : "link")
                            }
                        }
                    }

                    Section("Verwalten") {
                        Menu("Ressource löschen...") {
                            ForEach(liveSubmodule.allResources) { res in
                                Button(role: .destructive) {
                                    store.deleteResourceFromSubmodule(stepId: parentStepId, submoduleId: liveSubmodule.id, resourceId: res.id)
                                } label: {
                                    Text(res.title)
                                }
                            }
                        }
                    }

                    Divider()
                }

                Button {
                    showingAddLinkField = true
                } label: {
                    Label("Web-Link hinzufügen", systemImage: "link.badge.plus")
                }

                Button {
                    showingFilePicker = true
                } label: {
                    Label("Datei / PDF hinzufügen", systemImage: "doc.badge.plus")
                }
            } label: {
                let hasLinks = !liveSubmodule.allResources.isEmpty
                ZStack {
                    Image(systemName: "link")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(hasLinks ? StudyTheme.strongBlue : StudyTheme.textMuted)
                }
                .frame(width: 26, height: 24)
                .background(hasLinks ? StudyTheme.strongBlue.opacity(0.25) : Color.white.opacity(0.06))
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(hasLinks ? StudyTheme.strongBlue : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(liveSubmodule.allResources.isEmpty ? "Link oder Datei hinzufügen" : "\(liveSubmodule.allResources.count) Ressource(n) vorhanden")

            // 5. Pomodoro Timer Icon-Button (Startet Pomodoro-Timer für diese Teilaufgabe)
            let isTimerActiveForThisSub = (store.activeTimerStepId == liveSubmodule.id && store.isFocusTimerRunning)
            Button {
                HapticFeedback.medium()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    if isTimerActiveForThisSub {
                        store.stopFocusTimer()
                    } else {
                        store.startFocusTimer(for: liveSubmodule.id, minutes: 25)
                    }
                }
            } label: {
                Image(systemName: isTimerActiveForThisSub ? "stopwatch.fill" : "stopwatch")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isTimerActiveForThisSub ? StudyTheme.cyanAccent : StudyTheme.textMuted)
                    .frame(width: 26, height: 24)
                    .background(isTimerActiveForThisSub ? StudyTheme.cyanAccent.opacity(0.25) : Color.white.opacity(0.06))
                    .cornerRadius(7)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(isTimerActiveForThisSub ? StudyTheme.cyanAccent : Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(isTimerActiveForThisSub ? "Pomodoro-Timer anhalten" : "25m Pomodoro-Timer für diese Teilaufgabe starten")
        }
    }

    @ViewBuilder
    private var subtaskAttachmentsSection: some View {
        if showingAddLinkField {
            HStack(spacing: 5) {
                TextField("Titel", text: $newLinkTitle)
                    .font(.system(size: 11))
                    .textFieldStyle(.plain)
                    .frame(width: 80)
                TextField("URL...", text: $newLinkURL)
                    .font(.system(size: 11))
                    .textFieldStyle(.plain)
                    .onSubmit { commitNewLink() }
                Button("Speichern") { commitNewLink() }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                    .disabled(newLinkURL.trimmingCharacters(in: .whitespaces).isEmpty)
                Button {
                    showingAddLinkField = false
                    newLinkURL = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(Color.white.opacity(0.05))
            .cornerRadius(5)
        }
    }

    private func expandSubtask() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            if isExpanded {
                saveAllEdits()
                activeExpandedId = nil
            } else {
                editedTitle = liveSubmodule.title
                editedNotes = liveSubmodule.notes ?? ""
                activeExpandedId = submodule.id
            }
        }
    }

    private func saveTitle() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, title: trimmed)
        }
    }

    private func saveAllEdits() {
        saveTitle()
        store.updateSubmoduleDetails(parentStepId: parentStepId, submoduleId: liveSubmodule.id, notes: editedNotes)
    }

    private func commitNewLink() {
        var cleanURL = newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty else { return }
        if !cleanURL.contains("://") && !cleanURL.hasPrefix("file://") {
            cleanURL = "https://" + cleanURL
        }
        let title = newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (URL(string: cleanURL)?.host ?? "Link") : newLinkTitle
        store.addResourceToSubmodule(stepId: parentStepId, submoduleId: liveSubmodule.id, title: title, url: cleanURL, type: "Web")
        newLinkURL = ""
        newLinkTitle = ""
        showingAddLinkField = false
    }

    private func handlePickedFile(result: Result<[URL], Error>) {
        if case .success(let urls) = result, let sourceURL = urls.first {
            let canAccess = sourceURL.startAccessingSecurityScopedResource()
            defer { if canAccess { sourceURL.stopAccessingSecurityScopedResource() } }
            if let saved = store.saveAttachmentFile(from: sourceURL) {
                let fileName = sourceURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                store.addResourceToSubmodule(stepId: parentStepId, submoduleId: liveSubmodule.id, title: fileName, url: saved.absoluteString, type: "PDF")
            }
        }
    }

    private func formattedChipDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Heute" }
        if Calendar.current.isDateInTomorrow(date) { return "Morgen" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d. MMM"
        return f.string(from: date)
    }
}

// MARK: - Completed Submodule Row (In der "Erledigt"-Sektion)
struct CompletedSubmoduleRow: View {
    let submodule: StudySubmodule
    let parentStepId: String
    @EnvironmentObject private var store: StudyStore

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    store.toggleSubmodule(stepId: parentStepId, submoduleId: submodule.id)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.22, green: 0.68, blue: 0.38))
                        .frame(width: 14, height: 14)
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            Text(submodule.title)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.35))
                .strikethrough(true, color: Color.white.opacity(0.35))
                .lineLimit(1)

            Spacer()

            Button("Wiederherstellen") {
                withAnimation {
                    store.toggleSubmodule(stepId: parentStepId, submoduleId: submodule.id)
                }
            }
            .font(.system(size: 10))
            .foregroundColor(StudyTheme.strongBlue)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
    }
}
