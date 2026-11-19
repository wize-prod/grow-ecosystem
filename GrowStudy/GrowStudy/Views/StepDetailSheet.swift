import SwiftUI
import QuickLook
import UniformTypeIdentifiers

public struct StepDetailSheet: View {
    let step: RoadmapStep
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    // Sheets & Dialogs
    @State private var showingTimerSheet = false
    @State private var quickLookURL: URL? = nil
    @State private var showingEditStepSheet = false
    @State private var submoduleToEdit: StudySubmodule? = nil

    // Submodule Creation Form State
    @State private var showingAddSubmodule = false
    @State private var newSubTitle: String = ""
    @State private var newSubType: SubmoduleType = .webLink
    @State private var newSubURL: String = ""
    @State private var newSubDuration: String = "25"
    @State private var newSubIsFile: Bool = false
    @State private var showingSubmoduleFilePicker = false
    @State private var importedSubmoduleFileName: String? = nil
    @State private var importedSubmoduleFileURL: URL? = nil

    // Resource Creation Form State
    @State private var showingAddResource = false
    @State private var newResTitle: String = ""
    @State private var newResType: String = "Web"
    @State private var newResURL: String = ""
    @State private var newResIsFile: Bool = false
    @State private var showingResourceFilePicker = false
    @State private var importedResourceFileName: String? = nil
    @State private var importedResourceFileURL: URL? = nil

    // Drag & Drop State
    @State private var isSubmodulesDropTargeted: Bool = false
    @State private var targetedSubmoduleId: String? = nil
    @State private var isResourcesDropTargeted: Bool = false

    private var liveStep: RoadmapStep {
        store.steps.first(where: { $0.id == step.id }) ?? step
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StudyTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header Info Card
                        headerCard

                        // Action Buttons: Deep-Link Launcher & Focus Timer
                        actionButtons

                        // TAGES-PLANUNG & GOOGLE KALENDER SYNC
                        planningCard

                        // SUBMODULE & KURSE SECTION
                        submodulesSection

                        // TEILAUFGABEN (CHECKPOINTS)
                        if !liveStep.subtasks.isEmpty {
                            subtasksSection
                        }

                        // QUELLEN, LINKS & DATEIEN SECTION
                        resourcesSection

                        // Completion Toggle Button
                        completionButton

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Moduldetails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Bearbeiten") {
                        showingEditStepSheet = true
                        HapticFeedback.light()
                    }
                    .foregroundColor(StudyTheme.strongBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                }
            }
            .sheet(isPresented: $showingTimerSheet) {
                TimerFocusSheet(step: liveStep, isSheet: true)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingEditStepSheet) {
                EditStepSheet(step: liveStep)
                    .environmentObject(store)
            }
            .sheet(item: $submoduleToEdit) { submod in
                EditSubmoduleSheet(stepId: liveStep.id, submodule: submod)
                    .environmentObject(store)
            }
            .quickLookPreview($quickLookURL)
            .fileImporter(
                isPresented: $showingSubmoduleFilePicker,
                allowedContentTypes: [.pdf, .data, .item, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result, isSubmodule: true)
            }
            .fileImporter(
                isPresented: $showingResourceFilePicker,
                allowedContentTypes: [.pdf, .data, .item, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result, isSubmodule: false)
            }
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 480, idealWidth: 850, maxWidth: .infinity, minHeight: 450, idealHeight: 750, maxHeight: .infinity)
#endif
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(liveStep.type.rawValue, systemImage: liveStep.type.systemImage)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.strongBlue)

                Spacer()

                Text("\(Int(liveStep.estimatedHours))h (\(liveStep.estimatedMinutes) min Block)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.warmSand)
            }

            if !liveStep.phase.isEmpty {
                Text(liveStep.phase.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.textMuted)
            }

            Text(liveStep.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(StudyTheme.textPrimary)

            if !liveStep.subtitle.isEmpty {
                Text(liveStep.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(StudyTheme.textSecondary)
            }

            // Badges row
            HStack(spacing: 8) {
                if let cert = liveStep.certBadge {
                    Text(cert)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(StudyTheme.sageGreen.opacity(0.2))
                        .foregroundColor(StudyTheme.sageGreen)
                        .cornerRadius(6)
                }

                if !liveStep.difficulty.isEmpty {
                    Text(liveStep.difficulty)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(StudyTheme.surfaceElevated)
                        .foregroundColor(StudyTheme.textMuted)
                        .cornerRadius(6)
                }

                if !liveStep.category.isEmpty {
                    Text(liveStep.category)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(StudyTheme.surfaceElevated)
                        .foregroundColor(StudyTheme.strongBlue)
                        .cornerRadius(6)
                }
            }
            .padding(.top, 4)
        }
        .somaCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if let urlString = liveStep.primaryURL, !urlString.isEmpty {
                Button {
                    HapticFeedback.medium()
                    openItem(urlString: urlString)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: urlString.hasPrefix("file://") ? "doc.text.fill" : "arrow.up.right.square.fill")
                        Text(urlString.hasPrefix("file://") ? "Angehängtes Dokument / PDF öffnen" : "Primäre Ressource / Portal öffnen")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(StudyTheme.strongBlue)
                    .foregroundColor(StudyTheme.bg)
                    .cornerRadius(10)
                }
            }

            Button {
                showingTimerSheet = true
                HapticFeedback.light()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text("25-Minuten Fokusblock starten")
                }
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(StudyTheme.surfaceElevated)
                .foregroundColor(StudyTheme.warmSand)
                .cornerRadius(10)
            }
        }
    }

    private var planningCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("TAGESPLANUNG (GOOGLE KALENDER)", systemImage: "calendar.badge.clock")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.accent)

                Spacer()

                if liveStep.plannedDate != nil {
                    Text("Geplant")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.sageGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(StudyTheme.sageGreen.opacity(0.15))
                        .cornerRadius(4)
                }
            }

            if let pDate = liveStep.plannedDate {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Geplantes Datum:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(StudyTheme.textMuted)
                        Text(formattedPlanningDate(pDate))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(StudyTheme.textPrimary)
                    }
                    Spacer()
                    Button {
                        store.planStep(stepId: liveStep.id, date: nil)
                    } label: {
                        Text("Planung löschen")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(StudyTheme.terracotta)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(StudyTheme.terracotta.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Button {
                        store.planStep(stepId: liveStep.id, date: Date())
                    } label: {
                        Text("Heute")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(StudyTheme.surfaceElevated)
                            .foregroundColor(StudyTheme.textPrimary)
                            .cornerRadius(6)
                    }

                    Button {
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        store.planStep(stepId: liveStep.id, date: tomorrow)
                    } label: {
                        Text("Morgen")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(StudyTheme.surfaceElevated)
                            .foregroundColor(StudyTheme.textPrimary)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .somaCard()
    }

    // MARK: - Submodules & Kurse Section
    private var submodulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SUBMODULE & KURSE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.warmSand)

                Spacer()

                let doneSubmods = liveStep.submodules.filter { $0.isCompleted }.count
                Text("\(doneSubmods)/\(liveStep.submodules.count) abgeschlossen")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.sageGreen)
            }

            // Drop-Zone für neues Submodul
            HStack(spacing: 8) {
                Image(systemName: isSubmodulesDropTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSubmodulesDropTargeted ? StudyTheme.bg : StudyTheme.strongBlue)

                Text(isSubmodulesDropTargeted ? "PDF hier ablegen für neues Submodul..." : "PDF / Dokument hier ablegen (Neues Submodul)")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(isSubmodulesDropTargeted ? StudyTheme.bg : StudyTheme.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSubmodulesDropTargeted ? StudyTheme.strongBlue : StudyTheme.surfaceElevated.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isSubmodulesDropTargeted ? StudyTheme.strongBlue : StudyTheme.border, style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
            )
            .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isSubmodulesDropTargeted) { providers in
                store.importDroppedFiles(from: providers, targetStepId: liveStep.id)
                return true
            }

            if liveStep.submodules.isEmpty {
                Text("Noch keine Submodule oder Kurse hinterlegt.")
                    .font(.system(size: 12))
                    .foregroundColor(StudyTheme.textMuted)
                    .padding(.vertical, 4)
            } else {
                ForEach(liveStep.submodules) { submod in
                    let isRowTargeted = targetedSubmoduleId == submod.id
                    VStack(alignment: .leading, spacing: 8) {
                        if isRowTargeted {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 10))
                                Text("Datei als Anhang an dieses Submodul anfügen...")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(StudyTheme.strongBlue)
                            .padding(.bottom, 2)
                        }
                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                store.toggleSubmodule(stepId: liveStep.id, submoduleId: submod.id)
                            } label: {
                                Image(systemName: submod.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(submod.isCompleted ? StudyTheme.sageGreen : StudyTheme.textMuted)
                                    .padding(.top, 2)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label(submod.type.rawValue, systemImage: submod.type.systemImage)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.strongBlue)

                                    Spacer()

                                    Text("\(submod.durationMinutes) min")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.textSecondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(StudyTheme.surfaceElevated)
                                        .cornerRadius(4)
                                }

                                Text(submod.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(submod.isCompleted ? StudyTheme.textMuted : StudyTheme.textPrimary)
                                    .strikethrough(submod.isCompleted)

                                // Quick Plan Bar
                                HStack(spacing: 8) {
                                    if let pDate = submod.plannedDate {
                                        Text("Geplant: \(formattedShortDate(pDate))")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(StudyTheme.accent)

                                        Button {
                                            store.planSubmodule(stepId: liveStep.id, submoduleId: submod.id, date: nil)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(StudyTheme.terracotta)
                                        }
                                    } else {
                                        Button {
                                            store.planSubmodule(stepId: liveStep.id, submoduleId: submod.id, date: Date())
                                        } label: {
                                            Text("+ Heute planen")
                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                .foregroundColor(StudyTheme.accent)
                                        }
                                    }
                                }
                                .padding(.top, 2)
                            }

                            Spacer()

                            // Launcher Button (Web oder PDF)
                            if let urlStr = submod.url, !urlStr.isEmpty {
                                Button {
                                    HapticFeedback.light()
                                    openItem(urlString: urlStr)
                                } label: {
                                    Image(systemName: urlStr.hasPrefix("file://") ? "doc.text.fill" : "arrow.up.right.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(StudyTheme.strongBlue)
                                }
                                .buttonStyle(.plain)
                            }

                            // Edit Submodule Button
                            Button {
                                submoduleToEdit = submod
                                HapticFeedback.light()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13))
                                    .foregroundColor(StudyTheme.warmSand)
                                    .padding(4)
                                    .background(StudyTheme.surfaceElevated)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }

                        // Nur echte zusätzliche Anhänge unter dem Submodul anzeigen (verhindert Doppelung der primären URL)
                        let secondaryItems: [StepResource] = (submod.attachedResources ?? []).filter { $0.url != submod.url }
                        if !secondaryItems.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(secondaryItems) { att in
                                    HStack(spacing: 6) {
                                        Image(systemName: resourceIcon(for: att.type))
                                            .font(.system(size: 10))
                                            .foregroundColor(StudyTheme.strongBlue)
                                        Text(att.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(StudyTheme.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: att.url.hasPrefix("file://") ? "doc.viewfinder" : "arrow.up.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(StudyTheme.strongBlue)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(StudyTheme.surfaceElevated.opacity(0.8))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        openItem(urlString: att.url)
                                    }
                                }
                            }
                            .padding(.leading, 26)
                            .padding(.top, 2)
                        }
                    }
                    .padding(10)
                    .background(isRowTargeted ? StudyTheme.strongBlue.opacity(0.2) : StudyTheme.surfaceElevated.opacity(0.6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRowTargeted ? StudyTheme.strongBlue : Color.clear, lineWidth: 1.5)
                    )
                    .onDrop(of: StudyStore.supportedDropTypes, isTargeted: Binding(
                        get: { targetedSubmoduleId == submod.id },
                        set: { targeted in
                            if targeted {
                                targetedSubmoduleId = submod.id
                            } else if targetedSubmoduleId == submod.id {
                                targetedSubmoduleId = nil
                            }
                        }
                    )) { providers in
                        store.importDroppedFiles(from: providers, targetStepId: liveStep.id, targetSubmoduleId: submod.id)
                        return true
                    }
                }
            }

            // Formular zum Hinzufügen neuer Submodule
            if showingAddSubmodule {
                Divider().background(StudyTheme.border)
                addSubmoduleForm
            } else {
                Button {
                    withAnimation { showingAddSubmodule = true }
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Submodul, Link oder PDF hinzufügen")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(StudyTheme.strongBlue)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(StudyTheme.strongBlue.opacity(0.08))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .somaCard()
    }

    private var addSubmoduleForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEUES SUBMODUL / ANHANG")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(StudyTheme.strongBlue)

            TextField("Titel (z. B. Übungsblatt 01, Skript Kapitel 2)", text: $newSubTitle)
                .font(.system(size: 13))
                .padding(8)
                .background(StudyTheme.surfaceElevated)
                .cornerRadius(6)

            Picker("Typ", selection: $newSubType) {
                Text("Web-Link").tag(SubmoduleType.webLink)
                Text("PDF / Dokument").tag(SubmoduleType.pdfDocument)
                Text("Fachbuch / Skript").tag(SubmoduleType.readingChapter)
                Text("Web-Modul").tag(SubmoduleType.webModule)
                Text("Praxis-Lab / CLI").tag(SubmoduleType.handsOnLab)
                Text("Video").tag(SubmoduleType.youtubeVideo)
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(StudyTheme.surfaceElevated)
            .cornerRadius(6)

            Picker("Quelle", selection: $newSubIsFile) {
                Text("Web-URL").tag(false)
                Text("Datei / PDF").tag(true)
            }
            .pickerStyle(.segmented)

            if newSubIsFile {
                HStack {
                    Button {
                        showingSubmoduleFilePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.badge.plus")
                            Text(importedSubmoduleFileName ?? "PDF / Datei auswählen...")
                                .lineLimit(1)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(StudyTheme.surfaceElevated)
                        .foregroundColor(StudyTheme.textPrimary)
                        .cornerRadius(6)
                    }

                    if importedSubmoduleFileURL != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(StudyTheme.successGreen)
                    }
                    Spacer()
                }
            } else {
                TextField("URL (https://...)", text: $newSubURL)
                    .font(.system(size: 12))
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(8)
                    .background(StudyTheme.surfaceElevated)
                    .cornerRadius(6)
            }

            HStack {
                Text("Dauer (Minuten):")
                    .font(.system(size: 12))
                    .foregroundColor(StudyTheme.textSecondary)
                TextField("25", text: $newSubDuration)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(StudyTheme.surfaceElevated)
                    .cornerRadius(6)
                Spacer()
            }

            HStack {
                Button("Abbrechen") {
                    withAnimation {
                        showingAddSubmodule = false
                        resetSubmoduleForm()
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(StudyTheme.textMuted)

                Spacer()

                Button("Speichern") {
                    saveSubmoduleAction()
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(newSubTitle.isEmpty ? StudyTheme.border : StudyTheme.strongBlue)
                .foregroundColor(StudyTheme.bg)
                .cornerRadius(6)
                .disabled(newSubTitle.isEmpty)
            }
        }
        .padding(10)
        .background(StudyTheme.surfaceElevated.opacity(0.4))
        .cornerRadius(8)
    }

    private func saveSubmoduleAction() {
        guard !newSubTitle.isEmpty else { return }
        let duration = Int(newSubDuration) ?? 25
        let targetURL: String?
        if newSubIsFile {
            targetURL = importedSubmoduleFileURL?.absoluteString
        } else {
            targetURL = newSubURL.isEmpty ? nil : newSubURL
        }

        store.addSubmodule(
            to: liveStep.id,
            title: newSubTitle,
            type: newSubIsFile ? .pdfDocument : newSubType,
            url: targetURL,
            durationMinutes: duration
        )

        withAnimation {
            showingAddSubmodule = false
            resetSubmoduleForm()
        }
    }

    private func resetSubmoduleForm() {
        newSubTitle = ""
        newSubURL = ""
        newSubDuration = "25"
        newSubIsFile = false
        importedSubmoduleFileName = nil
        importedSubmoduleFileURL = nil
    }

    // MARK: - Subtasks Section
    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TEILAUFGABEN (CHECKPOINTS)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.textMuted)

                Spacer()

                let doneCount = liveStep.subtasks.filter { $0.isDone }.count
                Text("\(doneCount) / \(liveStep.subtasks.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(doneCount == liveStep.subtasks.count ? StudyTheme.sageGreen : StudyTheme.warmSand)
            }

            ForEach(liveStep.subtasks) { subtask in
                Button {
                    store.toggleSubtask(stepId: liveStep.id, subtaskId: subtask.id)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: subtask.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(subtask.isDone ? StudyTheme.sageGreen : StudyTheme.textMuted)
                            .padding(.top, 2)

                        Text(subtask.text)
                            .font(.system(size: 13))
                            .foregroundColor(subtask.isDone ? StudyTheme.textMuted : StudyTheme.textPrimary)
                            .strikethrough(subtask.isDone, color: StudyTheme.textMuted)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .somaCard()
    }

    // MARK: - Resources & Attachments Section
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("QUELLEN, LINKS & DATEIEN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.textMuted)

                Spacer()

                Text("\(liveStep.resources.count) Anhänge")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(StudyTheme.textSecondary)
            }

            // Drop-Zone für Ressourcen / Dokumente
            HStack(spacing: 8) {
                Image(systemName: isResourcesDropTargeted ? "arrow.down.doc.fill" : "paperclip.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isResourcesDropTargeted ? StudyTheme.bg : StudyTheme.warmSand)

                Text(isResourcesDropTargeted ? "Dokument hier als Ressource ablegen..." : "PDF / Datei hier als Ressource ablegen")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(isResourcesDropTargeted ? StudyTheme.bg : StudyTheme.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isResourcesDropTargeted ? StudyTheme.strongBlue : StudyTheme.surfaceElevated.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isResourcesDropTargeted ? StudyTheme.strongBlue : StudyTheme.border, style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
            )
            .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isResourcesDropTargeted) { providers in
                store.importDroppedFiles(from: providers, targetStepId: liveStep.id, isResourceOnly: true)
                return true
            }

            if liveStep.resources.isEmpty {
                Text("Keine Anhänge oder Dokumente vorhanden.")
                    .font(.system(size: 12))
                    .foregroundColor(StudyTheme.textMuted)
                    .padding(.vertical, 4)
            } else {
                ForEach(liveStep.resources) { res in
                    HStack(spacing: 10) {
                        Image(systemName: resourceIcon(for: res.type))
                            .font(.system(size: 14))
                            .foregroundColor(StudyTheme.strongBlue)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(res.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(StudyTheme.textPrimary)
                                .multilineTextAlignment(.leading)

                            Text(res.type.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(StudyTheme.warmSand)
                        }

                        Spacer()

                        Button {
                            HapticFeedback.light()
                            openItem(urlString: res.url)
                        } label: {
                            Image(systemName: res.url.hasPrefix("file://") ? "doc.viewfinder" : "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(StudyTheme.strongBlue)
                                .padding(6)
                                .background(StudyTheme.surfaceElevated)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.deleteResource(from: liveStep.id, resourceId: res.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(StudyTheme.terracotta.opacity(0.8))
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(StudyTheme.surfaceElevated.opacity(0.6))
                    .cornerRadius(8)
                }
            }

            // Formular zum Hinzufügen von Ressourcen / Links / PDFs
            if showingAddResource {
                Divider().background(StudyTheme.border)
                addResourceForm
            } else {
                Button {
                    withAnimation { showingAddResource = true }
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperclip.badge.plus")
                        Text("Link oder PDF-Dokument anhängen")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(StudyTheme.strongBlue)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(StudyTheme.strongBlue.opacity(0.08))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .somaCard()
    }

    private var addResourceForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEUE RESSOURCE / DATEI")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(StudyTheme.strongBlue)

            TextField("Titel (z. B. Vorlesungsskript, Altklausur)", text: $newResTitle)
                .font(.system(size: 13))
                .padding(8)
                .background(StudyTheme.surfaceElevated)
                .cornerRadius(6)

            Picker("Typ", selection: $newResType) {
                Text("Web-Portal").tag("Portal")
                Text("PDF / Skript").tag("PDF")
                Text("Fachbuch").tag("Buch")
                Text("Video").tag("Video")
                Text("Lab / Code").tag("Lab")
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(StudyTheme.surfaceElevated)
            .cornerRadius(6)

            Picker("Art", selection: $newResIsFile) {
                Text("Web-Link").tag(false)
                Text("Datei / PDF").tag(true)
            }
            .pickerStyle(.segmented)

            if newResIsFile {
                HStack {
                    Button {
                        showingResourceFilePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.badge.plus")
                            Text(importedResourceFileName ?? "PDF / Datei auswählen...")
                                .lineLimit(1)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(StudyTheme.surfaceElevated)
                        .foregroundColor(StudyTheme.textPrimary)
                        .cornerRadius(6)
                    }

                    if importedResourceFileURL != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(StudyTheme.successGreen)
                    }
                    Spacer()
                }
            } else {
                TextField("URL (https://...)", text: $newResURL)
                    .font(.system(size: 12))
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(8)
                    .background(StudyTheme.surfaceElevated)
                    .cornerRadius(6)
            }

            HStack {
                Button("Abbrechen") {
                    withAnimation {
                        showingAddResource = false
                        resetResourceForm()
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(StudyTheme.textMuted)

                Spacer()

                Button("Speichern") {
                    saveResourceAction()
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(newResTitle.isEmpty ? StudyTheme.border : StudyTheme.strongBlue)
                .foregroundColor(StudyTheme.bg)
                .cornerRadius(6)
                .disabled(newResTitle.isEmpty)
            }
        }
        .padding(10)
        .background(StudyTheme.surfaceElevated.opacity(0.4))
        .cornerRadius(8)
    }

    private func saveResourceAction() {
        guard !newResTitle.isEmpty else { return }
        let targetURL: String
        if newResIsFile {
            guard let url = importedResourceFileURL else { return }
            targetURL = url.absoluteString
        } else {
            guard !newResURL.isEmpty else { return }
            targetURL = newResURL
        }

        store.addResource(
            to: liveStep.id,
            title: newResTitle,
            url: targetURL,
            type: newResIsFile ? "PDF" : newResType
        )

        withAnimation {
            showingAddResource = false
            resetResourceForm()
        }
    }

    private func resetResourceForm() {
        newResTitle = ""
        newResURL = ""
        newResType = "Web"
        newResIsFile = false
        importedResourceFileName = nil
        importedResourceFileURL = nil
    }

    private var completionButton: some View {
        Button {
            store.toggleStep(id: liveStep.id)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: liveStep.isCompleted ? "arrow.counterclockwise" : "checkmark.circle.fill")
                Text(liveStep.isCompleted ? "Als unvollständig markieren" : "Modul als abgeschlossen abhaken")
            }
            .font(.system(size: 14, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(liveStep.isCompleted ? StudyTheme.surfaceElevated : StudyTheme.sageGreen)
            .foregroundColor(liveStep.isCompleted ? StudyTheme.terracotta : StudyTheme.bg)
            .cornerRadius(10)
        }
    }

    // MARK: - Helpers

    private func openItem(urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty else { return }
        if urlString.hasPrefix("file://") {
            if let url = URL(string: urlString) {
                self.quickLookURL = url
            }
        } else if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func handleFileSelection(result: Result<[URL], Error>, isSubmodule: Bool) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else { return }
            let canAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if canAccess { sourceURL.stopAccessingSecurityScopedResource() }
            }

            if let savedURL = store.saveAttachmentFile(from: sourceURL) {
                if isSubmodule {
                    self.importedSubmoduleFileName = sourceURL.lastPathComponent
                    self.importedSubmoduleFileURL = savedURL
                    if self.newSubTitle.isEmpty {
                        self.newSubTitle = sourceURL.deletingPathExtension().lastPathComponent
                    }
                } else {
                    self.importedResourceFileName = sourceURL.lastPathComponent
                    self.importedResourceFileURL = savedURL
                    if self.newResTitle.isEmpty {
                        self.newResTitle = sourceURL.deletingPathExtension().lastPathComponent
                    }
                }
                HapticFeedback.light()
            }
        case .failure:
            break
        }
    }

    private func resourceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "video": return "play.rectangle.fill"
        case "pdf", "skript", "doc", "document": return "doc.richtext.fill"
        case "book", "buch": return "book.closed.fill"
        case "lab", "terminal": return "terminal.fill"
        case "portal", "web": return "globe"
        default: return "link"
        }
    }

    private func formattedPlanningDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formattedShortDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Heute" }
        if cal.isDateInTomorrow(date) { return "Morgen" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE, d. MMM"
        return formatter.string(from: date)
    }
}

// MARK: - EditStepSheet (Kurs / Modul bearbeiten)
public struct EditStepSheet: View {
    let step: RoadmapStep
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var subtitle: String
    @State private var phase: String
    @State private var category: String
    @State private var difficulty: String
    @State private var certBadge: String
    @State private var hoursText: String
    @State private var primaryURLText: String
    @State private var isFile: Bool = false
    @State private var showingFilePicker = false
    @State private var importedFileName: String? = nil
    @State private var importedFileURL: URL? = nil
    @State private var notes: String

    public init(step: RoadmapStep) {
        self.step = step
        _title = State(initialValue: step.title)
        _subtitle = State(initialValue: step.subtitle)
        _phase = State(initialValue: step.phase)
        _category = State(initialValue: step.category)
        _difficulty = State(initialValue: step.difficulty)
        _certBadge = State(initialValue: step.certBadge ?? "")
        _hoursText = State(initialValue: String(format: "%.1f", step.estimatedHours))
        _primaryURLText = State(initialValue: step.primaryURL ?? "")
        _notes = State(initialValue: step.notes)
        _isFile = State(initialValue: (step.primaryURL ?? "").hasPrefix("file://"))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Allgemeine Modul-Informationen") {
                    TextField("Titel", text: $title)
                    TextField("Untertitel / Beschreibung", text: $subtitle)
                    TextField("Phase (z. B. Phase 0, Semester 1)", text: $phase)
                    TextField("Kategorie", text: $category)
                    TextField("Schwierigkeitsgrad", text: $difficulty)
                    TextField("Zertifikat / Badge", text: $certBadge)
                    TextField("Geschätzte Stunden", text: $hoursText)
                        .keyboardType(.decimalPad)
                }

                Section("Primärer Link / Angehängtes Dokument") {
                    Picker("Art", selection: $isFile) {
                        Text("Web-URL").tag(false)
                        Text("Datei / PDF").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if isFile {
                        HStack {
                            Button {
                                showingFilePicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.badge.plus")
                                    Text(importedFileName ?? (primaryURLText.hasPrefix("file://") ? (URL(string: primaryURLText)?.lastPathComponent ?? "Datei vorhanden") : "PDF / Datei auswählen..."))
                                        .lineLimit(1)
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(StudyTheme.strongBlue)
                            }
                            Spacer()
                        }
                    } else {
                        TextField("https://...", text: $primaryURLText)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Notizen") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Modul / Kurs bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(StudyTheme.textMuted)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                    .disabled(title.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .data, .item, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let sourceURL = urls.first else { return }
                    let canAccess = sourceURL.startAccessingSecurityScopedResource()
                    defer { if canAccess { sourceURL.stopAccessingSecurityScopedResource() } }

                    if let saved = store.saveAttachmentFile(from: sourceURL) {
                        importedFileName = sourceURL.lastPathComponent
                        importedFileURL = saved
                        primaryURLText = saved.absoluteString
                        HapticFeedback.light()
                    }
                case .failure:
                    break
                }
            }
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 450, idealWidth: 750, maxWidth: .infinity, minHeight: 400, idealHeight: 700, maxHeight: .infinity)
#endif
    }

    private func saveChanges() {
        var updated = step
        updated.title = title
        updated.subtitle = subtitle
        updated.phase = phase
        updated.category = category
        updated.difficulty = difficulty
        updated.certBadge = certBadge.isEmpty ? nil : certBadge
        if let h = Double(hoursText.replacingOccurrences(of: ",", with: ".")) {
            updated.estimatedHours = h
            updated.estimatedMinutes = Int(h * 60)
        }
        updated.primaryURL = primaryURLText.isEmpty ? nil : primaryURLText
        updated.notes = notes

        store.updateStep(updated)
        dismiss()
    }
}

// MARK: - EditSubmoduleSheet (Submodul bearbeiten & Quelle verwalten)
public struct EditSubmoduleSheet: View {
    let stepId: String
    let submodule: StudySubmodule
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var type: SubmoduleType
    @State private var durationMinutes: String
    @State private var primaryURLText: String
    @State private var secondaryResources: [StepResource]
    @State private var isEditingSource: Bool = false
    @State private var quickLookURL: URL? = nil
    @State private var isDropTargeted: Bool = false
    @State private var showingFilePicker = false

    public init(stepId: String, submodule: StudySubmodule) {
        self.stepId = stepId
        self.submodule = submodule
        _title = State(initialValue: submodule.title)
        _type = State(initialValue: submodule.type)
        _durationMinutes = State(initialValue: "\(submodule.durationMinutes)")
        let mainURL = submodule.url ?? ""
        _primaryURLText = State(initialValue: mainURL)
        // Nur sekundäre Ressourcen behalten (keine Doppelung der primären URL)
        let secondaries = (submodule.attachedResources ?? []).filter { $0.url != mainURL && !$0.id.hasPrefix("primary-") }
        _secondaryResources = State(initialValue: secondaries)
        _isEditingSource = State(initialValue: mainURL.isEmpty)
    }

    private var currentSubmodule: StudySubmodule {
        if let step = store.steps.first(where: { $0.id == stepId }),
           let sm = step.submodules.first(where: { $0.id == submodule.id }) {
            return sm
        }
        return submodule
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Allgemein") {
                    TextField("Titel der Lerneinheit", text: $title)
                        .font(.system(size: 13, weight: .medium))

                    Picker("Typ", selection: $type) {
                        Text("Web-Link").tag(SubmoduleType.webLink)
                        Text("PDF / Dokument").tag(SubmoduleType.pdfDocument)
                        Text("Fachbuch / Skript").tag(SubmoduleType.readingChapter)
                        Text("Web-Modul").tag(SubmoduleType.webModule)
                        Text("Praxis-Lab / CLI").tag(SubmoduleType.handsOnLab)
                        Text("Video").tag(SubmoduleType.youtubeVideo)
                    }

                    HStack {
                        Text("Dauer (Minuten)")
                            .foregroundColor(StudyTheme.textSecondary)
                        Spacer()
                        TextField("25", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Lernressource / Quelle") {
                    if !primaryURLText.isEmpty && !isEditingSource {
                        // Verknüpfte primäre Quelle als einzelne, elegante Karte
                        HStack(spacing: 12) {
                            Image(systemName: sourceIcon(for: primaryURLText, type: type))
                                .font(.system(size: 18))
                                .foregroundColor(StudyTheme.strongBlue)
                                .frame(width: 32, height: 32)
                                .background(StudyTheme.strongBlue.opacity(0.12))
                                .cornerRadius(6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(sourceDisplayName(for: primaryURLText))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(StudyTheme.textPrimary)
                                    .lineLimit(1)

                                Text(primaryURLText)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(StudyTheme.textMuted)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                openResource(urlString: primaryURLText)
                            } label: {
                                Image(systemName: primaryURLText.hasPrefix("file://") ? "doc.viewfinder" : "arrow.up.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(StudyTheme.strongBlue)
                                    .padding(6)
                                    .background(StudyTheme.surfaceElevated)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Öffnen")

                            Button {
                                isEditingSource = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.warmSand)
                                    .padding(6)
                                    .background(StudyTheme.surfaceElevated)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Link anpassen")

                            Button {
                                withAnimation {
                                    primaryURLText = ""
                                    isEditingSource = true
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.terracotta.opacity(0.85))
                                    .padding(6)
                                    .background(StudyTheme.surfaceElevated)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Verknüpfung entfernen")
                        }
                        .padding(.vertical, 3)
                    } else {
                        // Direkte Eingabe- und Drop-Zeile
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.system(size: 14))
                                    .foregroundColor(StudyTheme.strongBlue)

                                TextField("Web-URL eingeben oder Datei hier ablegen", text: $primaryURLText)
                                    .font(.system(size: 13))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)

                                if !primaryURLText.isEmpty {
                                    Button {
                                        primaryURLText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(StudyTheme.textMuted)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    showingFilePicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "folder")
                                        Text("Datei...")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(StudyTheme.strongBlue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(StudyTheme.surfaceElevated)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                if !primaryURLText.isEmpty {
                                    Button {
                                        isEditingSource = false
                                    } label: {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(StudyTheme.sageGreen)
                                            .padding(6)
                                            .background(StudyTheme.sageGreen.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            HStack(spacing: 6) {
                                Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
                                    .font(.system(size: 11))
                                Text(isDropTargeted ? "PDF jetzt ablegen..." : "PDF / Datei per Drag & Drop hier ablegen")
                                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                Spacer()
                            }
                            .foregroundColor(isDropTargeted ? StudyTheme.strongBlue : StudyTheme.textMuted)
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 4)
                        .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isDropTargeted) { providers in
                            handleDroppedFile(providers: providers)
                            return true
                        }
                    }
                }

                if !secondaryResources.isEmpty {
                    Section("Zusätzliche Materialien (\(secondaryResources.count))") {
                        ForEach(secondaryResources) { res in
                            HStack(spacing: 10) {
                                Image(systemName: res.url.hasPrefix("file://") ? "doc.richtext.fill" : "link")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.textSecondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(res.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(StudyTheme.textPrimary)
                                        .lineLimit(1)

                                    Text(res.url.hasPrefix("file://") ? (URL(string: res.url)?.lastPathComponent ?? "Datei") : res.url)
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .foregroundColor(StudyTheme.textMuted)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button {
                                    openResource(urlString: res.url)
                                } label: {
                                    Image(systemName: res.url.hasPrefix("file://") ? "doc.viewfinder" : "arrow.up.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(StudyTheme.strongBlue)
                                        .padding(4)
                                        .background(StudyTheme.surfaceElevated)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    withAnimation {
                                        secondaryResources.removeAll(where: { $0.id == res.id })
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(StudyTheme.terracotta.opacity(0.8))
                                        .padding(4)
                                        .background(StudyTheme.surfaceElevated)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        store.deleteSubmodule(from: stepId, submoduleId: submodule.id)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Submodul löschen")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Submodul bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(StudyTheme.textMuted)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveSubmoduleChanges()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .quickLookPreview($quickLookURL)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .data, .item, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let sourceURL = urls.first else { return }
                    let canAccess = sourceURL.startAccessingSecurityScopedResource()
                    defer { if canAccess { sourceURL.stopAccessingSecurityScopedResource() } }

                    if let saved = store.saveAttachmentFile(from: sourceURL) {
                        let fileName = sourceURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                        primaryURLText = saved.absoluteString
                        type = .pdfDocument
                        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            title = fileName
                        }
                        isEditingSource = false
                        HapticFeedback.light()
                    }
                case .failure:
                    break
                }
            }
            .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isDropTargeted) { providers in
                handleDroppedFile(providers: providers)
                return true
            }
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 460, idealWidth: 640, maxWidth: 720, minHeight: 380, idealHeight: 480, maxHeight: 600)
#endif
    }

    private func sourceDisplayName(for urlStr: String) -> String {
        if urlStr.hasPrefix("file://") {
            let name = URL(string: urlStr)?.lastPathComponent.replacingOccurrences(of: "_", with: " ") ?? "Lokales Dokument"
            return name
        } else if let u = URL(string: urlStr), let host = u.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return "Web-Ressource"
    }

    private func sourceIcon(for urlStr: String, type: SubmoduleType) -> String {
        if urlStr.hasPrefix("file://") {
            return "doc.text.fill"
        }
        return type.systemImage
    }

    private func saveSubmoduleChanges() {
        var cleanURL = primaryURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.isEmpty && !cleanURL.contains("://") && !cleanURL.hasPrefix("file://") {
            cleanURL = "https://" + cleanURL
        }

        var updated = currentSubmodule
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.type = type
        updated.durationMinutes = Int(durationMinutes) ?? 25
        updated.url = cleanURL.isEmpty ? nil : cleanURL

        // Nur sekundäre Ressourcen speichern (ohne Duplikate der Haupt-URL)
        let filteredSecondaries = secondaryResources.filter { $0.url != updated.url }
        updated.attachedResources = filteredSecondaries.isEmpty ? nil : filteredSecondaries

        store.updateSubmodule(stepId: stepId, updatedSubmodule: updated)
        dismiss()
    }

    private func handleDroppedFile(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, let saved = store.saveAttachmentFile(from: url) {
                        let fileName = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                        Task { @MainActor in
                            self.primaryURLText = saved.absoluteString
                            self.type = .pdfDocument
                            if self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.title = fileName
                            }
                            self.isEditingSource = false
                            HapticFeedback.success()
                        }
                        return
                    }
                    self.fallbackLoadDrop(provider: provider)
                }
            } else {
                fallbackLoadDrop(provider: provider)
            }
        }
    }

    private func fallbackLoadDrop(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { tempURL, error in
                if let tempURL = tempURL, let saved = store.saveAttachmentFile(from: tempURL) {
                    let fileName = tempURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                    Task { @MainActor in
                        self.primaryURLText = saved.absoluteString
                        self.type = .pdfDocument
                        if self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.title = fileName
                        }
                        self.isEditingSource = false
                        HapticFeedback.success()
                    }
                }
            }
        }
    }

    private func openResource(urlString: String) {
        if urlString.hasPrefix("file://") {
            if let url = URL(string: urlString) {
                quickLookURL = url
            }
        } else if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}