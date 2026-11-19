import SwiftUI
import UniformTypeIdentifiers

public struct AddCustomModuleSheet: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    public let targetDate: Date?

    public enum CreationKind: String, CaseIterable {
        case submodule = "Submodul / Aufgabe"
        case standaloneModule = "Eigenständiges Modul"
    }

    @State private var creationKind: CreationKind = .submodule
    @State private var selectedTrack: StudyTrack = .wirtschaftsinformatik
    @State private var isFormDropTargeted: Bool = false

    // Submodul-Zustand (zu bestehendem Modul hinzufügen)
    @State private var selectedParentModuleId: String = ""
    @State private var subTitle: String = ""
    @State private var subType: SubmoduleType = .webModule
    @State private var subURL: String = ""
    @State private var subDurationMinutes: String = "45"
    @State private var planSubForDate: Bool = true

    // Eigenständiges Modul-Zustand
    @State private var selectedPhase: String = "Phase 0: OMB+ Mathematik & Vorbereitung"
    @State private var isCustomPhase: Bool = false
    @State private var customPhaseName: String = ""
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var type: StepType = .examSimulation
    @State private var hours: String = "1.5"
    @State private var webURL: String = ""
    @State private var planModuleForDate: Bool = true

    public init(targetDate: Date? = nil) {
        self.targetDate = targetDate
    }

    private var availableParentSteps: [RoadmapStep] {
        store.steps(for: selectedTrack)
    }

    private var dateLabel: String {
        guard let d = targetDate else { return "Heute" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "E, dd.MM.yyyy"
        return formatter.string(from: d)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Was möchtest du erstellen?") {
                    Picker("Art des Eintrags", selection: $creationKind) {
                        ForEach(CreationKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Drop-Zone für schnelles Vorbelegen
                    HStack(spacing: 8) {
                        Image(systemName: isFormDropTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
                            .font(.system(size: 13))
                            .foregroundColor(isFormDropTargeted ? StudyTheme.bg : StudyTheme.strongBlue)
                        Text(isFormDropTargeted ? "PDF ablegen..." : "PDF / Datei hier ablegen zum Vorbelegen")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(isFormDropTargeted ? StudyTheme.bg : StudyTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isFormDropTargeted ? StudyTheme.strongBlue : StudyTheme.surfaceElevated.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isFormDropTargeted ? StudyTheme.strongBlue : StudyTheme.border, style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                    )
                    .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isFormDropTargeted) { providers in
                        for provider in providers {
                            if provider.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
                                provider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { tempURL, error in
                                    if let tempURL = tempURL, let saved = store.saveAttachmentFile(from: tempURL) {
                                        let name = tempURL.deletingPathExtension().lastPathComponent
                                        Task { @MainActor in
                                            applyDroppedFile(savedURL: saved, fileName: name)
                                        }
                                    }
                                }
                            }
                        }
                        return true
                    }
                }

                if creationKind == .submodule {
                    submoduleSection
                } else {
                    standaloneModuleSection
                }
            }
            .navigationTitle(creationKind == .submodule ? "Neues Submodul anlegen" : "Neues Modul anlegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(StudyTheme.textMuted)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(targetDate != nil ? "Erstellen & Planen" : "Erstellen") {
                        commitCreation()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                    .disabled(isCreateDisabled)
                }
            }
            .scrollDismissesKeyboard(.interactively)
#if targetEnvironment(macCatalyst)
            .frame(minWidth: 460, idealWidth: 620, maxWidth: 680, minHeight: 420, idealHeight: 560, maxHeight: 660)
#endif
            .onAppear {
                initDefaultParent()
            }
        }
    }

    private var isCreateDisabled: Bool {
        if creationKind == .submodule {
            return subTitle.trimmingCharacters(in: .whitespaces).isEmpty || selectedParentModuleId.isEmpty
        } else {
            return title.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func initDefaultParent() {
        if selectedParentModuleId.isEmpty {
            if let omb = availableParentSteps.first(where: { $0.id == "winf-omb-1a" || $0.phase.contains("Phase 0") }) {
                selectedParentModuleId = omb.id
            } else if let first = availableParentSteps.first {
                selectedParentModuleId = first.id
            }
        }
    }

    // MARK: - Submodul Erstellungs-Formular
    private var submoduleSection: some View {
        Group {
            Section("1. Übergeordnetes Modul (Sektion)") {
                Picker("Ziel-Modul", selection: $selectedParentModuleId) {
                    ForEach(availableParentSteps) { step in
                        Text("\(step.phase) • \(step.title)")
                            .tag(step.id)
                    }
                }
            }

            Section("2. Submodul-Details") {
                TextField("Titel (z. B. MINTFIT Mathe Eingangstest Teil 1)", text: $subTitle)

                Picker("Typ", selection: $subType) {
                    Text("Web-Modul").tag(SubmoduleType.webModule)
                    Text("Prüfungs-Drill / Quiz").tag(SubmoduleType.examDrill)
                    Text("PDF / Dokument").tag(SubmoduleType.pdfDocument)
                    Text("Fachbuch / Skript").tag(SubmoduleType.readingChapter)
                    Text("Praxis-Lab / CLI").tag(SubmoduleType.handsOnLab)
                    Text("Video").tag(SubmoduleType.youtubeVideo)
                }

                TextField("Web-Link (https://...)", text: $subURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                HStack {
                    Text("Dauer (Minuten)")
                    Spacer()
                    TextField("45", text: $subDurationMinutes)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                if targetDate != nil {
                    Toggle("Direkt für \(dateLabel) einplanen", isOn: $planSubForDate)
                }
            }
        }
    }

    // MARK: - Eigenständiges Modul Erstellungs-Formular
    private var standaloneModuleSection: some View {
        Group {
            Section("1. Sektion & Qualifikationspfad") {
                Picker("Qualifikationspfad", selection: $selectedTrack) {
                    ForEach(StudyTrack.allCases) { track in
                        Text(track.shortTitle).tag(track)
                    }
                }

                let phases = store.existingPhases(for: selectedTrack)
                Picker("Sektion / Phase", selection: $selectedPhase) {
                    ForEach(phases, id: \.self) { p in
                        Text(p).tag(p)
                    }
                    Text("+ Neue Sektion / Phase anlegen...").tag("CUSTOM_PHASE")
                }
                .onChange(of: selectedPhase) { newPhase in
                    isCustomPhase = (newPhase == "CUSTOM_PHASE")
                }

                if isCustomPhase {
                    TextField("Name der neuen Sektion", text: $customPhaseName)
                }
            }

            Section("2. Modul-Details") {
                TextField("Titel (z. B. MINTFIT Mathematik Diagnosetest)", text: $title)
                TextField("Untertitel / Beschreibung", text: $subtitle)

                Picker("Modultyp", selection: $type) {
                    ForEach(StepType.allCases, id: \.self) { t in
                        Label(t.rawValue, systemImage: t.systemImage).tag(t)
                    }
                }

                HStack {
                    Text("Geschätzte Dauer (Stunden)")
                    Spacer()
                    TextField("1.5", text: $hours)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                TextField("Primäre URL / Link (https://...)", text: $webURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if targetDate != nil {
                    Toggle("Direkt für \(dateLabel) einplanen", isOn: $planModuleForDate)
                }
            }
        }
    }

    private func commitCreation() {
        if creationKind == .submodule {
            guard !selectedParentModuleId.isEmpty, !subTitle.isEmpty else { return }
            let duration = Int(subDurationMinutes) ?? 45
            let urlToSave = subURL.trimmingCharacters(in: .whitespaces).isEmpty ? nil : subURL.trimmingCharacters(in: .whitespaces)

            store.addSubmodule(
                to: selectedParentModuleId,
                title: subTitle,
                type: subType,
                url: urlToSave,
                durationMinutes: duration,
                planForDate: planSubForDate ? targetDate : nil
            )
        } else {
            guard !title.isEmpty else { return }
            let finalPhase = isCustomPhase ? (customPhaseName.isEmpty ? "Benutzerdefinierte Module" : customPhaseName) : selectedPhase
            let h = Double(hours.replacingOccurrences(of: ",", with: ".")) ?? 1.0
            let urlToSave = webURL.trimmingCharacters(in: .whitespaces).isEmpty ? nil : webURL.trimmingCharacters(in: .whitespaces)

            store.addCustomModule(
                track: selectedTrack,
                phase: finalPhase,
                title: title,
                subtitle: subtitle,
                type: type,
                hours: h,
                youtubeURL: urlToSave,
                planForDate: planModuleForDate ? targetDate : nil
            )
        }
        dismiss()
    }

    private func applyDroppedFile(savedURL: URL, fileName: String) {
        let clean = fileName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = clean.isEmpty ? "PDF-Dokument" : clean

        if creationKind == .submodule {
            subTitle = displayTitle
            subType = .pdfDocument
            subURL = savedURL.absoluteString
        } else {
            title = displayTitle
            type = .reading
            webURL = savedURL.absoluteString
        }
        HapticFeedback.success()
    }
}
