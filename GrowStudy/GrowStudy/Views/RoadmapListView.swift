import SwiftUI

public struct RoadmapListView: View {
    @EnvironmentObject private var store: StudyStore
    @State private var selectedStep: RoadmapStep?
    @State private var searchText: String = ""
    @State private var selectedTrackFilter: StudyTrack? = nil
    @State private var showFilterSheet: Bool = false
    @State private var showAddModuleSheet: Bool = false
    @State private var expandedPhases: Set<String> = []
    @State private var isRoadmapDropTargeted: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                StudyTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Studienringe atop tab
                        ConcentricStudyRingsView()

                        // Drop-Zone für neue Module per Drag & Drop
                        VStack(spacing: 6) {
                            HStack(spacing: 10) {
                                Image(systemName: isRoadmapDropTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
                                    .font(.system(size: 15))
                                    .foregroundColor(isRoadmapDropTargeted ? StudyTheme.bg : StudyTheme.strongBlue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isRoadmapDropTargeted ? "Datei ablegen..." : "PDFs & Skripte hierher ziehen")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(isRoadmapDropTargeted ? StudyTheme.bg : StudyTheme.textPrimary)

                                    Text("Erstellt automatisch ein neues Modul im Fahrplan")
                                        .font(.system(size: 10))
                                        .foregroundColor(isRoadmapDropTargeted ? StudyTheme.bg.opacity(0.8) : StudyTheme.textMuted)
                                }

                                Spacer()

                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 13))
                                    .foregroundColor(isRoadmapDropTargeted ? StudyTheme.bg : StudyTheme.warmSand)
                            }
                            .padding(11)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isRoadmapDropTargeted ? StudyTheme.strongBlue : StudyTheme.surface.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(isRoadmapDropTargeted ? StudyTheme.strongBlue : StudyTheme.border, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                            )
                        }
                        .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isRoadmapDropTargeted) { providers in
                            let currentTrack = selectedTrackFilter ?? store.activeTrack
                            store.importDroppedFiles(from: providers, targetTrack: currentTrack)
                            return true
                        }

                        // 2. Track Header & Overall Progress
                        let currentTrack = selectedTrackFilter ?? store.activeTrack
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label(selectedTrackFilter == nil ? "ALLE PFEILER" : currentTrack.shortTitle, 
                                      systemImage: selectedTrackFilter == nil ? "square.grid.2x2.fill" : currentTrack.systemImage)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(StudyTheme.strongBlue)

                                Spacer()

                                if let filter = selectedTrackFilter {
                                    let stats = store.subtaskStats(for: filter)
                                    Text("\(stats.completed) / \(stats.total) (\(Int(stats.ratio * 100))%)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.warmSand)
                                } else {
                                    let allSteps = store.steps
                                    let done = allSteps.filter { $0.isCompleted }.count
                                    Text("\(done) / \(allSteps.count) Module")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.warmSand)
                                }
                            }

                            Text(selectedTrackFilter == nil ? "Gesamt-Fahrplan" : currentTrack.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(StudyTheme.textPrimary)

                            Text(selectedTrackFilter == nil ? "Strukturierte Meilensteine: B.Sc. Wirtschaftsinformatik & BFD 2027" : currentTrack.deadlineNote)
                                .font(.system(size: 12))
                                .foregroundColor(StudyTheme.textSecondary)

                            // Overall Progress Bar
                            if let filter = selectedTrackFilter {
                                let stats = store.subtaskStats(for: filter)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(StudyTheme.surfaceElevated)
                                            .frame(height: 6)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(StudyTheme.sageGreen)
                                            .frame(width: geo.size.width * CGFloat(stats.ratio), height: 6)
                                    }
                                }
                                .frame(height: 6)
                                .padding(.top, 4)
                            }
                        }
                        .somaCard()

                        // 3. Visual Phase Blocks for Each Track
                        let displayedTracks = selectedTrackFilter != nil ? [selectedTrackFilter!] : StudyTrack.allCases

                        ForEach(displayedTracks) { track in
                            let trackSteps = filteredSteps(for: track)
                            if !trackSteps.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    if selectedTrackFilter == nil {
                                        HStack {
                                            Label(track.shortTitle.uppercased(), systemImage: track.systemImage)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(StudyTheme.warmSand)
                                            Spacer()
                                            let done = trackSteps.filter { $0.isCompleted }.count
                                            Text("\(done)/\(trackSteps.count)")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(StudyTheme.textMuted)
                                        }
                                        .padding(.horizontal, 4)
                                    }

                                    let phases = Array(Set(trackSteps.map { $0.phase })).sorted()
                                    ForEach(phases, id: \.self) { phase in
                                        let phaseSteps = trackSteps.filter { $0.phase == phase }
                                        let isExpanded = expandedPhases.contains(phase) || !searchText.isEmpty

                                        RoadmapPhaseBlock(
                                            phaseTitle: phase,
                                            track: track,
                                            steps: phaseSteps,
                                            isExpanded: isExpanded,
                                            onToggle: {
                                                HapticFeedback.selection()
                                                if expandedPhases.contains(phase) {
                                                    expandedPhases.remove(phase)
                                                } else {
                                                    expandedPhases.insert(phase)
                                                }
                                            },
                                            onSelectStep: { step in
                                                selectedStep = step
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 90)
                    }
                    .padding(16)
                }

                // Bottom Search & Action Dock
                VStack(spacing: 0) {
                    Divider().background(StudyTheme.border)

                    HStack(spacing: 10) {
                        // Search Field Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(StudyTheme.textMuted)

                            TextField("Module, Videos, Zertifikate suchen...", text: $searchText)
                                .font(.system(size: 13))
                                .foregroundColor(StudyTheme.textPrimary)
                                .autocorrectionDisabled()

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
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(StudyTheme.surfaceElevated)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(StudyTheme.border, lineWidth: 1)
                        )

                        // Circular Filter Button
                        Button {
                            HapticFeedback.selection()
                            showFilterSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedTrackFilter != nil ? StudyTheme.strongBlue : StudyTheme.surfaceElevated)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedTrackFilter != nil ? StudyTheme.strongBlue : StudyTheme.border, lineWidth: 1)
                                    )

                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedTrackFilter != nil ? StudyTheme.bg : StudyTheme.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)

                        // Circular Add Button
                        Button {
                            HapticFeedback.medium()
                            showAddModuleSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(StudyTheme.strongBlue)
                                    .frame(width: 40, height: 40)

                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(StudyTheme.bg)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
                    .background(
                        StudyTheme.bg
                            .opacity(0.95)
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle("Fahrplan")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedStep) { step in
                StepDetailSheet(step: step)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showFilterSheet) {
                TrackFilterSheet(selectedTrackFilter: $selectedTrackFilter)
            }
            .sheet(isPresented: $showAddModuleSheet) {
                AddCustomModuleSheet()
                    .environmentObject(store)
            }
        }
    }

    private func filteredSteps(for track: StudyTrack) -> [RoadmapStep] {
        let all = store.steps.filter { $0.track == track }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all
        }
        let q = searchText.lowercased()
        return all.filter { step in
            step.title.lowercased().contains(q) ||
            step.subtitle.lowercased().contains(q) ||
            step.phase.lowercased().contains(q) ||
            step.subtasks.contains(where: { $0.text.lowercased().contains(q) }) ||
            step.submodules.contains(where: { $0.title.lowercased().contains(q) })
        }
    }
}

private struct RoadmapPhaseBlock: View {
    let phaseTitle: String
    let track: StudyTrack
    let steps: [RoadmapStep]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelectStep: (RoadmapStep) -> Void
    @EnvironmentObject private var store: StudyStore
    @State private var isPhaseDropTargeted: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Visual Block Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(StudyTheme.surfaceElevated)
                            .frame(width: 36, height: 36)

                        Image(systemName: iconForTrack(track))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorForTrack(track))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(phaseTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(StudyTheme.textPrimary)
                            .lineLimit(1)

                        let doneCount = steps.filter { $0.isCompleted }.count
                        let totalHours = steps.reduce(0) { $0 + Int($1.estimatedHours) }
                        HStack(spacing: 6) {
                            Text("\(doneCount)/\(steps.count) erledigt")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(doneCount == steps.count && !steps.isEmpty ? StudyTheme.sageGreen : StudyTheme.warmSand)

                            Text("•")
                                .foregroundColor(StudyTheme.textMuted)

                            Text("\(totalHours)h")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(StudyTheme.textMuted)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .padding(14)
                .background(isPhaseDropTargeted ? StudyTheme.strongBlue.opacity(0.15) : StudyTheme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPhaseDropTargeted ? StudyTheme.strongBlue : StudyTheme.border, lineWidth: isPhaseDropTargeted ? 2 : 1)
                )
            }
            .buttonStyle(.plain)
            .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isPhaseDropTargeted) { providers in
                store.importDroppedFiles(from: providers, targetTrack: track, targetPhase: phaseTitle)
                return true
            }

            // Revealed Module List
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(steps) { step in
                        RoadmapStepCard(step: step) {
                            onSelectStep(step)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func iconForTrack(_ track: StudyTrack) -> String {
        switch track {
        case .wirtschaftsinformatik: return "laptopcomputer"
        case .bfd: return "rosette"
        case .gym: return "figure.run"
        case .nutrition: return "fork.knife"
        case .care: return "cross.case.fill"
        case .chores: return "house.fill"
        case .cyberSecurity: return "shield.lefthalf.filled"
        }
    }

    private func colorForTrack(_ track: StudyTrack) -> Color {
        switch track {
        case .wirtschaftsinformatik: return StudyTheme.strongBlue
        case .bfd: return StudyTheme.warmSand
        case .gym: return StudyTheme.cyanAccent
        case .nutrition: return StudyTheme.appleGreen
        case .care: return StudyTheme.sageGreen
        case .chores: return StudyTheme.mintAccent
        case .cyberSecurity: return StudyTheme.textMuted
        }
    }
}

private struct RoadmapStepCard: View {
    let step: RoadmapStep
    let onTap: () -> Void
    @EnvironmentObject private var store: StudyStore
    @State private var isCardDropTargeted: Bool = false

    var body: some View {
        let status = store.status(for: step)

        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Icon / Number
                ZStack {
                    Circle()
                        .fill(statusBgColor(for: status))
                        .frame(width: 30, height: 30)

                    if status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(StudyTheme.bg)
                    } else if status == .locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(StudyTheme.textMuted)
                    } else {
                        Text("\(step.sequenceNumber)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(statusTextColor(for: status))
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    if isCardDropTargeted {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 9))
                            Text("PDF als Submodul anfügen...")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(StudyTheme.strongBlue)
                    }

                    HStack {
                        Text(step.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(status == .locked ? StudyTheme.textMuted : StudyTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        if let cert = step.certBadge {
                            Text(cert)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(StudyTheme.sageGreen.opacity(0.15))
                                .foregroundColor(StudyTheme.sageGreen)
                                .cornerRadius(4)
                        }
                    }

                    HStack(spacing: 8) {
                        Label(step.type.rawValue, systemImage: step.type.systemImage)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(StudyTheme.textMuted)

                        if !step.submodules.isEmpty {
                            let doneSubs = step.submodules.filter { $0.isCompleted }.count
                            Text("• \(doneSubs)/\(step.submodules.count) Units")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(StudyTheme.warmSand)
                        } else if !step.subtasks.isEmpty {
                            let done = step.subtasks.filter { $0.isDone }.count
                            Text("• \(done)/\(step.subtasks.count) Subtasks")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(StudyTheme.warmSand)
                        }

                        Spacer()

                        Text("\(Int(step.estimatedHours))h")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                }
            }
            .padding(12)
            .background(isCardDropTargeted ? StudyTheme.strongBlue.opacity(0.2) : StudyTheme.surfaceElevated.opacity(0.6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCardDropTargeted ? StudyTheme.strongBlue : (status == .inProgress ? StudyTheme.strongBlue.opacity(0.4) : Color.white.opacity(0.04)), lineWidth: isCardDropTargeted ? 1.8 : 1)
            )
        }
        .buttonStyle(.plain)
        .onDrop(of: StudyStore.supportedDropTypes, isTargeted: $isCardDropTargeted) { providers in
            store.importDroppedFiles(from: providers, targetStepId: step.id)
            return true
        }
    }

    private func statusBgColor(for status: StepStatus) -> Color {
        switch status {
        case .completed: return StudyTheme.sageGreen
        case .inProgress: return StudyTheme.strongBlue.opacity(0.2)
        case .available: return StudyTheme.surfaceElevated
        case .locked: return StudyTheme.surfaceElevated.opacity(0.5)
        }
    }

    private func statusTextColor(for status: StepStatus) -> Color {
        switch status {
        case .completed: return StudyTheme.bg
        case .inProgress: return StudyTheme.strongBlue
        case .available: return StudyTheme.warmSand
        case .locked: return StudyTheme.textMuted
        }
    }
}
