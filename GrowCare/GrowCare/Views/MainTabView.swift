import SwiftUI

public enum GrowCareTab: Int, CaseIterable, Identifiable {
    case heute = 0
    case inventar = 1
    case standards = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .heute: return "Heute"
        case .inventar: return "Inventar"
        case .standards: return "Standards"
        }
    }

    public var icon: String {
        switch self {
        case .heute: return "sparkles"
        case .inventar: return "archivebox"
        case .standards: return "book.closed"
        }
    }
}

public struct MainTabView: View {
    @ObservedObject var store = GrowCareStore.shared
    @State private var selectedTab: GrowCareTab = .heute

    // Inspection Sheets
    @State private var inspectingRoutine: CareRoutineItem? = nil
    @State private var inspectingChore: ChoreRoutineItem? = nil
    @State private var inspectingProduct: CareProduct? = nil
    @State private var runningRoutine: CareRoutineItem? = nil

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                heuteView
                    .tabItem {
                        Image(systemName: GrowCareTab.heute.icon)
                        Text(GrowCareTab.heute.title)
                    }
                    .tag(GrowCareTab.heute)

                CareInventoryView()
                    .tabItem {
                        Image(systemName: GrowCareTab.inventar.icon)
                        Text(GrowCareTab.inventar.title)
                    }
                    .tag(GrowCareTab.inventar)

                StandardsGuideView()
                    .tabItem {
                        Image(systemName: GrowCareTab.standards.icon)
                        Text(GrowCareTab.standards.title)
                    }
                    .tag(GrowCareTab.standards)
            }
            .environment(\.horizontalSizeClass, .compact)
            .accentColor(CareTheme.careLilac)
        }
        .background(CareTheme.bg.ignoresSafeArea())
        .sheet(item: $inspectingRoutine) { r in
            RoutineDetailSheet(routine: r, onOpenProduct: { inspectingProduct = $0 })
        }
        .sheet(item: $inspectingChore) { c in
            ChoreDetailSheet(chore: c)
        }
        .sheet(item: $inspectingProduct) { p in
            CareProductDetailSheet(product: p)
        }
        .sheet(item: $runningRoutine) { r in
            RoutineRunnerSheet(routine: r)
        }
    }

    // MARK: - Heute Tab
    private var heuteView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Interactive 14-day Calendar Strip
                CareCalendarStripView(selectedDate: $store.selectedDate)
                    .padding(.top, 6)

                // Today's Scheduled Routines & Chores
                let scheduledRoutines = store.scheduledRoutines(for: store.selectedDate, zone: .all)
                let scheduledChores = store.scheduledChores(for: store.selectedDate, zone: .all)

                let completedRoutines = scheduledRoutines.filter { store.isRoutineCompleted($0, on: store.selectedDate) }.count
                let completedChores = scheduledChores.filter { store.isChoreCompleted($0, on: store.selectedDate) }.count
                let totalTasks = scheduledRoutines.count + scheduledChores.count
                let totalDone = completedRoutines + completedChores

                // Summary Header Card
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LEITSTAND PFLEGE & KASERNE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(CareTheme.careLilac)

                        Text("Tagespensum fuer \(formattedSelectedDate)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(CareTheme.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(totalDone)/\(totalTasks) ERLEDIGT")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(totalDone == totalTasks && totalTasks > 0 ? CareTheme.careSage.opacity(0.18) : Color.white.opacity(0.06))
                            )
                            .foregroundColor(totalDone == totalTasks && totalTasks > 0 ? CareTheme.careSage : CareTheme.textSecondary)
                    }
                }
                .careCard()

                // Routines Section
                if !scheduledRoutines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EVIDENZBASIERTE PFLEGEROUTINEN")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(CareTheme.textMuted)

                        VStack(spacing: 8) {
                            ForEach(scheduledRoutines) { routine in
                                routineCard(routine)
                            }
                        }
                    }
                }

                // Chores Section
                if !scheduledChores.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("KASERNENDIENST & STUBENREINIGUNG")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(CareTheme.textMuted)

                        VStack(spacing: 8) {
                            ForEach(scheduledChores) { chore in
                                choreCard(chore)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(CareTheme.bg.ignoresSafeArea())
    }

    // MARK: - Card Builders
    @ViewBuilder
    private func routineCard(_ routine: CareRoutineItem) -> some View {
        let isDone = store.isRoutineCompleted(routine, on: store.selectedDate)

        HStack(spacing: 12) {
            // Completion Toggle Checkbox
            Button(action: {
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(isDone ? .warning : .success)
                store.toggleRoutineCompletion(routine, on: store.selectedDate)
            }) {
                ZStack {
                    Circle()
                        .fill(isDone ? CareTheme.careSage : CareTheme.surfaceElevated)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(isDone ? CareTheme.careSage : CareTheme.border, lineWidth: 1))

                    Image(systemName: isDone ? "checkmark" : "circle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isDone ? CareTheme.bg : CareTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            // Content (Tap to open detail sheet)
            Button(action: {
                inspectingRoutine = routine
            }) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(routine.shortTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isDone ? CareTheme.textSecondary : CareTheme.textPrimary)
                            .strikethrough(isDone, color: CareTheme.textMuted)

                        Spacer()

                        Text(String(format: "%02d:%02d", routine.defaultHour, routine.defaultMinute))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(CareTheme.careLilac)
                    }

                    HStack(spacing: 6) {
                        Text(routine.zone.shortLabel)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(CareTheme.surfaceElevated)
                            .foregroundColor(CareTheme.careLilac)
                            .clipShape(Capsule())

                        Text(routine.category)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CareTheme.textMuted)

                        Text("\(routine.estimatedMinutes) Min")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(CareTheme.textSecondary)

                        if !routine.products.isEmpty {
                            Text("\(routine.products.count) Prod.")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(CareTheme.textMuted)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Direct Step Runner Launch Button
            Button(action: {
                runningRoutine = routine
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(CareTheme.careLilac)
                    .padding(4)
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(CareTheme.textMuted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDone ? CareTheme.surface.opacity(0.6) : CareTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isDone ? CareTheme.careSage.opacity(0.3) : CareTheme.border, lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func choreCard(_ chore: ChoreRoutineItem) -> some View {
        let isDone = store.isChoreCompleted(chore, on: store.selectedDate)

        HStack(spacing: 12) {
            // Completion Toggle Checkbox
            Button(action: {
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(isDone ? .warning : .success)
                store.toggleChoreCompletion(chore, on: store.selectedDate)
            }) {
                ZStack {
                    Circle()
                        .fill(isDone ? CareTheme.careSage : CareTheme.surfaceElevated)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(isDone ? CareTheme.careSage : CareTheme.border, lineWidth: 1))

                    Image(systemName: isDone ? "checkmark" : "circle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isDone ? CareTheme.bg : CareTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            // Content (Tap to open detail sheet)
            Button(action: {
                inspectingChore = chore
            }) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(chore.shortTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isDone ? CareTheme.textSecondary : CareTheme.textPrimary)
                            .strikethrough(isDone, color: CareTheme.textMuted)

                        Spacer()

                        Text(String(format: "%02d:%02d", chore.reminderHour, chore.reminderMinute))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(CareTheme.careBlue)
                    }

                    HStack(spacing: 8) {
                        Text(chore.category)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CareTheme.textMuted)

                        Text("\(chore.estimatedMinutes) Min")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(CareTheme.textSecondary)

                        Text("\(chore.steps.count) Schritte")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CareTheme.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(CareTheme.textMuted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDone ? CareTheme.surface.opacity(0.6) : CareTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isDone ? CareTheme.careSage.opacity(0.3) : CareTheme.border, lineWidth: 0.8)
        )
    }

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: store.selectedDate)
    }
}
