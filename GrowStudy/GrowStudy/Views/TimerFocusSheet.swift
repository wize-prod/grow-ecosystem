import SwiftUI

// MARK: - Einfacher & minimalistischer Fokus-Timer (Simple Pomodoro Focus Timer)
public struct TimerFocusSheet: View {
    let step: RoadmapStep?
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    let isSheet: Bool

    // Ausgewaehlte Timer-Dauer in Minuten
    @State private var selectedMinutes: Int = 25
    @State private var showCompletionAlert: Bool = false
    @State private var completedSessionSummary: String = ""

    private let presetDurations = [15, 25, 45, 60]

    public init(step: RoadmapStep? = nil, isSheet: Bool = false) {
        self.step = step
        self.isSheet = isSheet
    }

    private var minutesRemaining: Int {
        store.focusTimerSecondsRemaining / 60
    }

    private var secondsRemaining: Int {
        store.focusTimerSecondsRemaining % 60
    }

    private var totalSeconds: Double {
        Double(selectedMinutes * 60)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = totalSeconds - Double(store.focusTimerSecondsRemaining)
        return min(1.0, max(0.0, elapsed / totalSeconds))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Fester, kollisionsfreier Header
            HStack {
                Text("Fokus-Timer")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)
                Spacer()
                if isSheet {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(StudyTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 12)
            .background(StudyTheme.bg)

            Divider()
                .background(StudyTheme.border)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 1. Aufgaben- / Modul-Header
                    taskHeaderSection

                    // 2. Zeit-Dauer Wahltasten (nur aenderbar wenn Timer pausiert/gestoppt ist)
                    if !store.isFocusTimerRunning {
                        durationPickerSection
                    }

                    // 3. Grosser, klarer kreisfoermiger Countdown
                    circularCountdownSection

                    // 3.5 Direkter Link zur aktiven (Teil-)Aufgabe
                    activeTaskDirectLink

                    // 4. Steuerungs-Tasten (Start / Pause / Abschliessen)
                    timerControlsSection
                        .padding(.top, 4)

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 520, idealHeight: 560)
#endif
        .background(StudyTheme.bg.ignoresSafeArea())
        .alert("Fokus-Session abgeschlossen", isPresented: $showCompletionAlert) {
            Button("Fertig", role: .cancel) {
                if isSheet {
                    dismiss()
                }
            }
        } message: {
            Text(completedSessionSummary)
        }
    }

    // MARK: - 1. Aufgaben- & Modul-Header
    private var taskHeaderSection: some View {
        VStack(spacing: 6) {
            if let sub = store.activeTimerSubmodule {
                Text(sub.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let parent = step ?? store.activeTimerStep {
                    Text(parent.title)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(StudyTheme.strongBlue)
                        .cornerRadius(6)
                }
            } else if let currentStep = step ?? store.activeTimerStep {
                Text(currentStep.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(currentStep.phase)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .foregroundColor(StudyTheme.appleGreen)
                    .cornerRadius(6)
            } else {
                Text("Ungestörte Fokus-Session")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)

                Text("Konzentriertes Arbeiten nach Pomodoro-Prinzip")
                    .font(.system(size: 12))
                    .foregroundColor(StudyTheme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    // MARK: - 1.5 Direkter Link zur aktiven (Teil-)Aufgabe
    private var activeTaskDirectLink: some View {
        Group {
            if let sub = store.activeTimerSubmodule {
                Button {
                    HapticFeedback.light()
                    if let urlStr = sub.url, let url = URL(string: urlStr) {
                        UIApplication.shared.open(url)
                    } else if let res = sub.allResources.first, let url = URL(string: res.url) {
                        UIApplication.shared.open(url)
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 14))
                            .foregroundColor(StudyTheme.cyanAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sub.title)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(StudyTheme.textPrimary)
                                .lineLimit(1)

                            Text(sub.url != nil ? "Direktlink öffnen (Web / Lab)" : "Zur Teilaufgabe im Board springen")
                                .font(.system(size: 10))
                                .foregroundColor(StudyTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(StudyTheme.surfaceElevated)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(StudyTheme.cyanAccent.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(AppleTactileButtonStyle())
                .frame(maxWidth: 420)
            } else if let s = step ?? store.activeTimerStep {
                Button {
                    HapticFeedback.light()
                    if let purl = s.primaryURL, let url = URL(string: purl) {
                        UIApplication.shared.open(url)
                    } else if let res = s.resources.first, let url = URL(string: res.url) {
                        UIApplication.shared.open(url)
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 14))
                            .foregroundColor(StudyTheme.cyanAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(StudyTheme.textPrimary)
                                .lineLimit(1)

                            Text((s.primaryURL != nil || !s.resources.isEmpty) ? "Verknüpfte Ressource öffnen" : "Zur Aufgabe im Board springen")
                                .font(.system(size: 10))
                                .foregroundColor(StudyTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(StudyTheme.surfaceElevated)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(StudyTheme.cyanAccent.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(AppleTactileButtonStyle())
                .frame(maxWidth: 420)
            }
        }
    }

    // MARK: - 2. Dauer-Auswahl (15, 25, 45, 60 Min)
    private var durationPickerSection: some View {
        HStack(spacing: 8) {
            ForEach(presetDurations, id: \.self) { mins in
                let isSelected = (selectedMinutes == mins)
                Button {
                    HapticFeedback.selection()
                    selectedMinutes = mins
                    store.focusTimerSecondsRemaining = mins * 60
                } label: {
                    Text("\(mins) Min")
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(isSelected ? StudyTheme.strongBlue : Color.white.opacity(0.06))
                        )
                        .foregroundColor(isSelected ? Color.white : StudyTheme.textSecondary)
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? StudyTheme.strongBlue : Color.white.opacity(0.10),
                                    lineWidth: 0.8
                                )
                        )
                }
                .buttonStyle(AppleTactileButtonStyle())
            }
        }
    }

    // MARK: - 3. Kreisfoermiger Countdown
    private var circularCountdownSection: some View {
        ZStack {
            // Hintergrund-Ring
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 12)
                .frame(width: 190, height: 190)

            // Fortschritts-Ring (Apple Technical Blue / Cyan Gradient)
            Circle()
                .trim(from: 0.0, to: CGFloat(store.isFocusTimerRunning ? (1.0 - progress) : 1.0))
                .stroke(
                    LinearGradient(
                        colors: [StudyTheme.appleBlue, StudyTheme.cyanAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 190, height: 190)
                .animation(.linear(duration: 1.0), value: store.focusTimerSecondsRemaining)

            // Digitale Ziffernanzeige in der Mitte (SF Pro Monospaced)
            VStack(spacing: 3) {
                Text(String(format: "%02d:%02d", minutesRemaining, secondsRemaining))
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.textPrimary)

                Text(store.isFocusTimerRunning ? "Fokussiert" : "Bereit")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(store.isFocusTimerRunning ? StudyTheme.cyanAccent : StudyTheme.textMuted)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 4. Steuerungs-Tasten
    private var timerControlsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if store.isFocusTimerRunning {
                    // Pause-Taste (Liquid Glass)
                    Button {
                        HapticFeedback.light()
                        store.stopFocusTimer()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Pausieren")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .liquidGlass(cornerRadius: 16)
                        .foregroundColor(StudyTheme.textPrimary)
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                } else {
                    // Start-Taste (Apple Prominent Action)
                    Button {
                        HapticFeedback.medium()
                        store.startFocusTimer(
                            for: step?.id ?? "general_focus",
                            minutes: selectedMinutes
                        )
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Starten")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(StudyTheme.strongBlue)
                        )
                        .foregroundColor(Color.white)
                        .shadow(color: StudyTheme.strongBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }

                // Vorzeitig als erfolgreich abschliessen (Liquid Glass)
                Button {
                    finishSession()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                        Text("Abschließen")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .liquidGlass(cornerRadius: 16)
                    .foregroundColor(StudyTheme.textPrimary)
                }
                .buttonStyle(AppleTactileButtonStyle())
            }

            // Zuruecksetzen falls pausiert
            if !store.isFocusTimerRunning && store.focusTimerSecondsRemaining < selectedMinutes * 60 {
                Button {
                    HapticFeedback.light()
                    store.focusTimerSecondsRemaining = selectedMinutes * 60
                } label: {
                    Text("Auf \(selectedMinutes) Minuten zurücksetzen")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(AppleTactileButtonStyle())
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Sitzung abschliessen
    private func finishSession() {
        HapticFeedback.success()

        if let s = step {
            store.completeStep(id: s.id)
        }
        store.stopFocusTimer()

        completedSessionSummary = "\(selectedMinutes) Minuten ungestört fokussiert abgeschlossen."
        showCompletionAlert = true
    }
}
