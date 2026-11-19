import SwiftUI

public struct StudyLogPlanningSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StudyStore

    public let targetDate: Date
    @State private var selectedTrackTab: StudyTrack = .wirtschaftsinformatik
    @State private var searchQuery: String = ""
    @State private var schedulingStep: RoadmapStep? = nil
    @State private var schedulingSubmodule: (step: RoadmapStep, submodule: StudySubmodule)? = nil
    @State private var showingAddModuleSheet = false

    // Time schedule states for the selected task
    @State private var plannedStartTime: Date = Date()
    @State private var plannedEndTime: Date = Date().addingTimeInterval(3600)
    @State private var toastMessage: String? = nil

    public init(targetDate: Date = Date()) {
        self.targetDate = targetDate
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                StudyTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Active Track Label
                    HStack(spacing: 8) {
                        Image(systemName: "laptopcomputer")
                            .foregroundColor(StudyTheme.strongBlue)
                        Text("B.Sc. Wirtschaftsinformatik & BFD 2027")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(StudyTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Chronological Uncompleted Tasks List
                    let uncompletedSteps = store.steps(for: selectedTrackTab).filter { !$0.isCompleted }
                    let filteredSteps = filterSteps(uncompletedSteps)

                    if filteredSteps.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "checkmark.circle.badge.questionmark")
                                .font(.system(size: 38))
                                .foregroundColor(StudyTheme.sageGreen)
                            Text("Keine offenen Aufgaben gefunden")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(StudyTheme.textPrimary)
                            Text("Alle Module dieses Pfads sind abgeschlossen oder passen nicht zum Suchbegriff.")
                                .font(.system(size: 12))
                                .foregroundColor(StudyTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button {
                                showingAddModuleSheet = true
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Neues Modul oder Submodul anlegen")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(StudyTheme.strongBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(StudyTheme.surfaceElevated)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                // Prominent Action Button: Create New Module or Submodule
                                Button {
                                    showingAddModuleSheet = true
                                    HapticFeedback.light()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Neues Modul oder Submodul erstellen & einplanen")
                                            .font(.system(size: 13, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(StudyTheme.strongBlue)
                                    .padding(12)
                                    .background(StudyTheme.surfaceElevated)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(StudyTheme.strongBlue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.bottom, 4)

                                ForEach(filteredSteps) { step in
                                    planningStepCard(step: step)
                                }
                                Spacer(minLength: 110)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                }

                // Hovering Search Bar at Bottom of iPhone Screen
                hoveringBottomSearchBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Inline Scheduling Modal (Start & End Time Picker)
                if schedulingStep != nil || schedulingSubmodule != nil {
                    timeSchedulerModal
                }
            }
            .navigationTitle("Module & Aufgaben planen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Neu anlegen") {
                        showingAddModuleSheet = true
                        HapticFeedback.light()
                    }
                    .foregroundColor(StudyTheme.strongBlue)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(StudyTheme.strongBlue)
                        .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingAddModuleSheet) {
                AddCustomModuleSheet(targetDate: targetDate)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Track Selector Button
    private func trackSegmentButton(track: StudyTrack, title: String, icon: String) -> some View {
        Button(action: {
            HapticFeedback.light()
            selectedTrackTab = track
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(selectedTrackTab == track ? StudyTheme.bg : StudyTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTrackTab == track ? StudyTheme.strongBlue : StudyTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedTrackTab == track ? StudyTheme.strongBlue : StudyTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Planning Step Card
    private func planningStepCard(step: RoadmapStep) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                // Sequence / Module Number Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(StudyTheme.surfaceElevated)
                        .frame(width: 32, height: 32)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(StudyTheme.borderSubtle, lineWidth: 1))
                    Text("\(step.sequenceNumber)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.warmSand)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(StudyTheme.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(step.type.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(StudyTheme.surfaceElevated)
                            .foregroundColor(StudyTheme.textMuted)
                            .cornerRadius(4)

                        Text("~\(Int(step.estimatedHours))h")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(StudyTheme.textSecondary)

                        if let cert = step.certBadge {
                            Text(cert)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(StudyTheme.sageGreen)
                        }
                    }
                }

                Spacer()

                // Schedule '+' Button
                Button(action: {
                    HapticFeedback.medium()
                    openTimeScheduler(for: step)
                }) {
                    ZStack {
                        Circle()
                            .fill(StudyTheme.strongBlue)
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(StudyTheme.bg)
                    }
                }
                .buttonStyle(.plain)
            }

            // Submodules (if any exist)
            if !step.submodules.isEmpty {
                VStack(spacing: 6) {
                    ForEach(step.submodules) { sub in
                        if !sub.isCompleted {
                            HStack(spacing: 8) {
                                Image(systemName: sub.type.systemImage)
                                    .font(.system(size: 10))
                                    .foregroundColor(StudyTheme.textMuted)
                                Text(sub.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(StudyTheme.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text("~\(sub.durationMinutes)m")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(StudyTheme.textMuted)

                                Button(action: {
                                    HapticFeedback.light()
                                    openTimeScheduler(for: step, submodule: sub)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(StudyTheme.cyanAccent)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(StudyTheme.surface))
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(StudyTheme.surfaceElevated.opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(StudyTheme.borderSubtle, lineWidth: 1))
    }

    // MARK: - Hovering Bottom Search Bar
    private var hoveringBottomSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(StudyTheme.textMuted)

            TextField("Module & Aufgaben durchsuchen...", text: $searchQuery)
                .font(.system(size: 13))
                .foregroundColor(StudyTheme.textPrimary)
                .autocorrectionDisabled()

            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(StudyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Time Scheduler Modal
    private var timeSchedulerModal: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture {
                    schedulingStep = nil
                    schedulingSubmodule = nil
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("ZEITFENSTER TERMINIEREN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.warmSand)
                    Spacer()
                    Button(action: {
                        schedulingStep = nil
                        schedulingSubmodule = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }

                if let sub = schedulingSubmodule {
                    Text(sub.submodule.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(StudyTheme.textPrimary)
                } else if let st = schedulingStep {
                    Text(st.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(StudyTheme.textPrimary)
                }

                VStack(spacing: 8) {
                    DatePicker("Startzeit:", selection: $plannedStartTime, displayedComponents: [.hourAndMinute])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(StudyTheme.textPrimary)
                        .accentColor(StudyTheme.strongBlue)

                    DatePicker("Endzeit:", selection: $plannedEndTime, displayedComponents: [.hourAndMinute])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(StudyTheme.textPrimary)
                        .accentColor(StudyTheme.strongBlue)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(StudyTheme.surface))

                Button(action: commitScheduling) {
                    HStack {
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                        Text("In Google Kalender & Log sichern")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(StudyTheme.bg)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(StudyTheme.strongBlue))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(StudyTheme.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(StudyTheme.strongBlue.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 24)
        }
    }

    private func openTimeScheduler(for step: RoadmapStep, submodule: StudySubmodule? = nil) {
        if let sub = submodule {
            schedulingSubmodule = (step: step, submodule: sub)
            schedulingStep = nil
        } else {
            schedulingStep = step
            schedulingSubmodule = nil
        }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: targetDate)
        comps.hour = 17
        comps.minute = 0
        plannedStartTime = cal.date(from: comps) ?? targetDate
        comps.hour = 18
        comps.minute = 30
        plannedEndTime = cal.date(from: comps) ?? targetDate.addingTimeInterval(5400)
    }

    private func commitScheduling() {
        if let sub = schedulingSubmodule {
            store.planSubmodule(stepId: sub.step.id, submoduleId: sub.submodule.id, date: targetDate)
        } else if let st = schedulingStep {
            store.planStep(stepId: st.id, date: targetDate)
        }
        HapticFeedback.success()
        schedulingStep = nil
        schedulingSubmodule = nil
        dismiss()
    }

    private func filterSteps(_ steps: [RoadmapStep]) -> [RoadmapStep] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return steps.sorted { $0.sequenceNumber < $1.sequenceNumber }
        }
        let q = searchQuery.lowercased()
        return steps.filter {
            $0.title.lowercased().contains(q) ||
            $0.subtitle.lowercased().contains(q) ||
            $0.category.lowercased().contains(q) ||
            $0.submodules.contains { $0.title.lowercased().contains(q) }
        }.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }
}
