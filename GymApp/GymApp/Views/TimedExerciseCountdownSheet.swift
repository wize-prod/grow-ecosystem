import SwiftUI
import Combine

public struct TimedSetContext: Identifiable {
    public var id: UUID { setId }
    public let exerciseId: UUID
    public let setId: UUID
    public let exerciseName: String
    public let setNumber: Int
    public let targetSeconds: Int

    public init(
        exerciseId: UUID,
        setId: UUID,
        exerciseName: String,
        setNumber: Int,
        targetSeconds: Int
    ) {
        self.exerciseId = exerciseId
        self.setId = setId
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.targetSeconds = targetSeconds
    }
}

public struct TimedExerciseCountdownSheet: View {
    public let context: TimedSetContext
    public let onComplete: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var remainingSeconds: Int
    @State private var totalSeconds: Int
    @State private var isRunning: Bool = true
    @State private var timerCancellable: AnyCancellable? = nil
    @State private var targetEndTime: Date? = nil
    private let notificationId = "grow_timed_exercise_notification"

    public init(context: TimedSetContext, onComplete: @escaping (Int) -> Void) {
        self.context = context
        self.onComplete = onComplete
        _remainingSeconds = State(initialValue: max(5, context.targetSeconds))
        _totalSeconds = State(initialValue: max(5, context.targetSeconds))
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = totalSeconds - remainingSeconds
        return min(1.0, max(0.0, Double(elapsed) / Double(totalSeconds)))
    }

    private var formattedRemaining: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header Info
                    VStack(spacing: 6) {
                        Text("ISOMETRISCHER ZEIT-TIMER")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundColor(GymTheme.cyanAccent)

                        Text(context.exerciseName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        Text("Satz \(context.setNumber) • Geplante Dauer: \(formatDuration(totalSeconds))")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                    .padding(.top, 16)

                    // Giant Circular Countdown Display
                    ZStack {
                        // Background Track
                        Circle()
                            .stroke(GymTheme.surfaceElevated, lineWidth: 16)
                            .frame(width: 250, height: 250)

                        // Progress Ring
                        Circle()
                            .trim(from: 0.0, to: CGFloat(progress))
                            .stroke(
                                remainingSeconds <= 5 ? GymTheme.accentGold : GymTheme.cyanAccent,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 250, height: 250)
                            .animation(.linear(duration: 1.0), value: progress)

                        // Center Countdown Digits
                        VStack(spacing: 4) {
                            Text(formattedRemaining)
                                .font(.system(size: 52, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textPrimary)

                            Text(isRunning ? "Verbleibend" : "Pausiert")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(isRunning ? GymTheme.sageGreen : GymTheme.textMuted)
                        }
                    }
                    .padding(.vertical, 10)

                    // Quick Adjustments (+15s / -15s / +30s)
                    HStack(spacing: 12) {
                        Button("-15s") {
                            adjustTime(by: -15)
                        }
                        .adjustButtonStyle()

                        Button("+15s") {
                            adjustTime(by: 15)
                        }
                        .adjustButtonStyle()

                        Button("+30s") {
                            adjustTime(by: 30)
                        }
                        .adjustButtonStyle()

                        Button("+60s") {
                            adjustTime(by: 60)
                        }
                        .adjustButtonStyle()
                    }

                    // Main Controls: Pause / Resume
                    HStack(spacing: 14) {
                        Button {
                            toggleRunning()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                Text(isRunning ? "Pause" : "Fortsetzen")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
                        }

                        Button {
                            completeSuccessfully()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Abschliessen")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(GymTheme.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(GymTheme.sageGreen)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Direct Full Credit Button if already held
                    Button {
                        completeSuccessfully(duration: totalSeconds)
                    } label: {
                        Text("Bereits vollstaendig gehalten (\(formatDuration(totalSeconds)))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GymTheme.textSecondary)
                            .underline()
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Zeit-Uebung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        stopTimer()
                        dismiss()
                    }
                    .foregroundColor(GymTheme.textMuted)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            recalculateRemaining()
        }
    }

    private func recalculateRemaining() {
        guard isRunning, let target = targetEndTime else { return }
        let rem = Int(ceil(target.timeIntervalSinceNow))
        if rem > 0 {
            remainingSeconds = rem
        } else {
            remainingSeconds = 0
            stopTimer()
            BoxingBellAudioService.shared.playBoxingBell()
            HapticFeedback.success()
            completeSuccessfully()
        }
    }

    private func startTimer() {
        isRunning = true
        targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        scheduleNotification(seconds: remainingSeconds)

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard isRunning, let target = targetEndTime else { return }
                let rem = Int(ceil(target.timeIntervalSinceNow))
                if rem > 0 {
                    remainingSeconds = rem
                    let elapsed = totalSeconds - rem
                    if elapsed > 0 && elapsed % 15 == 0 && rem > 5 {
                        BoxingBellAudioService.shared.playCountdownBeep()
                        HapticFeedback.medium()
                    }
                    if rem <= 5 && rem >= 1 {
                        BoxingBellAudioService.shared.playCountdownBeep()
                        HapticFeedback.light()
                    }
                } else {
                    remainingSeconds = 0
                    stopTimer()
                    BoxingBellAudioService.shared.playBoxingBell()
                    HapticFeedback.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        completeSuccessfully()
                    }
                }
            }
    }

    private func scheduleNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Zeit-Uebung geschafft!"
        content.body = "\(context.exerciseName) erfolgreich beendet (\(totalSeconds)s)."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        targetEndTime = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    private func toggleRunning() {
        if isRunning {
            stopTimer()
            isRunning = false
        } else {
            startTimer()
        }
        HapticFeedback.selection()
    }

    private func adjustTime(by delta: Int) {
        let newRem = max(5, remainingSeconds + delta)
        let newTotal = max(5, totalSeconds + delta)
        remainingSeconds = newRem
        totalSeconds = newTotal
        if isRunning {
            targetEndTime = Date().addingTimeInterval(TimeInterval(newRem))
            scheduleNotification(seconds: newRem)
        }
        HapticFeedback.light()
    }

    private func completeSuccessfully(duration: Int? = nil) {
        stopTimer()
        let finalDuration = duration ?? max(1, totalSeconds - remainingSeconds)
        onComplete(finalDuration)
        BoxingBellAudioService.shared.playBoxingBell()
        HapticFeedback.success()
        dismiss()
    }

    private func formatDuration(_ secs: Int) -> String {
        let m = secs / 60
        let s = secs % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s)) min" : "\(s)s"
    }
}

fileprivate extension View {
    func adjustButtonStyle() -> some View {
        self
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(GymTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(GymTheme.surfaceElevated)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }
}

