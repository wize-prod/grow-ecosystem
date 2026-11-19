import SwiftUI
import Combine

public struct RoutineRunnerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = GrowCareStore.shared
    public let routine: CareRoutineItem

    @State private var currentStepIndex: Int = 0
    @State private var secondsRemaining: Int = 60
    @State private var totalStepSeconds: Int = 60
    @State private var isRunning: Bool = false
    @State private var timerSubscription: AnyCancellable? = nil

    public init(routine: CareRoutineItem) {
        self.routine = routine
    }

    private var steps: [CareRoutineStep] {
        routine.steps
    }

    private var currentStep: CareRoutineStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Progress Bar
                progressHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Routine Meta Card
                        routineMetaCard

                        // Main Active Step Card
                        if let step = currentStep {
                            stepExecutionCard(step)
                        }

                        // Countdown Timer Control
                        timerControlCard
                    }
                    .padding(16)
                }

                // Bottom Action Footer
                footerBar
                    .padding(16)
                    .background(CareTheme.surface)
            }
            .background(CareTheme.bg.ignoresSafeArea())
            .navigationTitle("Routine Execution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") {
                        stopTimer()
                        dismiss()
                    }
                    .foregroundColor(CareTheme.textSecondary)
                }
            }
            .onAppear {
                setupStepTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("SCHRITT \(currentStepIndex + 1) VON \(max(1, steps.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CareTheme.careLilac)

                Spacer()

                Text("\(Int(progressFraction * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CareTheme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CareTheme.surfaceElevated)
                        .frame(height: 6)

                    Capsule()
                        .fill(CareTheme.careLilac)
                        .frame(width: geo.size.width * progressFraction, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: progressFraction)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressFraction: CGFloat {
        guard !steps.isEmpty else { return 1.0 }
        return CGFloat(currentStepIndex + 1) / CGFloat(steps.count)
    }

    // MARK: - Routine Meta Card
    private var routineMetaCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.zone.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CareTheme.careLilac)

                Text(routine.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(CareTheme.textPrimary)
            }

            Spacer()

            Text("\(routine.estimatedMinutes) Min")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CareTheme.surfaceElevated)
                .foregroundColor(CareTheme.textSecondary)
                .clipShape(Capsule())
        }
        .careCard()
    }

    // MARK: - Active Step Card
    @ViewBuilder
    private func stepExecutionCard(_ step: CareRoutineStep) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(CareTheme.careLilac)
                        .frame(width: 30, height: 30)
                    Text("\(step.number)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(CareTheme.bg)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(CareTheme.textPrimary)

                    if !step.keyToolOrIngredient.isEmpty {
                        Text("Werkzeug / Praeparat: \(step.keyToolOrIngredient)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(CareTheme.careSage)
                    }
                }
            }

            Divider().background(CareTheme.border)

            Text(step.instruction)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(CareTheme.textSecondary)
                .lineSpacing(4)
        }
        .careCard()
    }

    // MARK: - Timer Control Card
    private var timerControlCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("SCHRITT-TIMER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.0)
                    .foregroundColor(CareTheme.textMuted)

                Spacer()

                Text(timeString(from: secondsRemaining))
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(secondsRemaining == 0 ? CareTheme.careSage : CareTheme.textPrimary)
            }

            HStack(spacing: 12) {
                Button(action: {
                    toggleTimer()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 13))
                        Text(isRunning ? "Pause" : (secondsRemaining == 0 ? "Neustart" : "Start"))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isRunning ? CareTheme.warmSand : CareTheme.careLilac)
                    .foregroundColor(CareTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {
                    addSeconds(30)
                }) {
                    Text("+30s")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(CareTheme.surfaceElevated)
                        .foregroundColor(CareTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {
                    resetTimer()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(CareTheme.surfaceElevated)
                        .foregroundColor(CareTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .careCard()
    }

    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack(spacing: 12) {
            if currentStepIndex > 0 {
                Button(action: {
                    goToPreviousStep()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurueck")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(CareTheme.surfaceElevated)
                    .foregroundColor(CareTheme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Spacer()

            if isLastStep {
                Button(action: {
                    completeRoutine()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Routine Abschliessen")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CareTheme.careSage)
                    .foregroundColor(CareTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Button(action: {
                    goToNextStep()
                }) {
                    HStack(spacing: 6) {
                        Text("Naechster Schritt")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CareTheme.careLilac)
                    .foregroundColor(CareTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Timer Logic
    private func setupStepTimer() {
        guard let step = currentStep else { return }
        let text = (step.title + " " + step.instruction).lowercased()

        let detectedSeconds: Int = {
            if text.contains("15 min") || text.contains("15 minuten") { return 15 * 60 }
            if text.contains("10 min") || text.contains("10 minuten") { return 10 * 60 }
            if text.contains("5 min") || text.contains("5 minuten") { return 5 * 60 }
            if text.contains("3 min") || text.contains("3 minuten") { return 3 * 60 }
            if text.contains("2 min") || text.contains("2 minuten") { return 2 * 60 }
            if text.contains("1 min") || text.contains("1 minute") { return 60 }
            if text.contains("30 sek") || text.contains("30 sekunden") { return 30 }
            if text.contains("20 sek") || text.contains("20 sekunden") { return 20 }
            return 60
        }()

        totalStepSeconds = detectedSeconds
        secondsRemaining = detectedSeconds
        isRunning = false
        stopTimer()
    }

    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            if secondsRemaining == 0 {
                secondsRemaining = totalStepSeconds
            }
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                } else {
                    self.stopTimer()
                    let notifHaptic = UINotificationFeedbackGenerator()
                    notifHaptic.notificationOccurred(.success)
                }
            }
    }

    private func stopTimer() {
        isRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func resetTimer() {
        stopTimer()
        secondsRemaining = totalStepSeconds
    }

    private func addSeconds(_ secs: Int) {
        secondsRemaining += secs
    }

    private func goToNextStep() {
        stopTimer()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            setupStepTimer()
        }
    }

    private func goToPreviousStep() {
        stopTimer()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            setupStepTimer()
        }
    }

    private func completeRoutine() {
        stopTimer()
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        store.toggleRoutineCompletion(routine, on: store.selectedDate)
        dismiss()
    }

    private func timeString(from totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

