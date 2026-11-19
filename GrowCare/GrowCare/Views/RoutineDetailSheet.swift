import SwiftUI

public struct RoutineDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = GrowCareStore.shared
    public let routine: CareRoutineItem
    public var onOpenProduct: ((CareProduct) -> Void)? = nil

    @State private var timerSecondsRemaining: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var isShowingRunner: Bool = false

    public init(routine: CareRoutineItem, onOpenProduct: ((CareProduct) -> Void)? = nil) {
        self.routine = routine
        self.onOpenProduct = onOpenProduct
    }

    private var isDone: Bool {
        store.isRoutineCompleted(routine, on: store.selectedDate)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(routine.zone.rawValue.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(CareTheme.careLilac.opacity(0.18))
                                .foregroundColor(CareTheme.careLilac)
                                .clipShape(Capsule())

                            Text(routine.category.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(CareTheme.surfaceElevated)
                                .foregroundColor(CareTheme.textSecondary)
                                .clipShape(Capsule())

                            Spacer()

                            Text("\(routine.estimatedMinutes) Min")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(CareTheme.textSecondary)

                            Text(routine.defaultFrequency.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(CareTheme.textSecondary)
                                .clipShape(Capsule())
                        }

                        Text(routine.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(CareTheme.textPrimary)

                        if !routine.clinicalRationale.isEmpty {
                            Text(routine.clinicalRationale)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(CareTheme.textSecondary)
                                .lineSpacing(3)
                                .padding(.top, 4)
                        }

                        // Tactical Runner Launch Button
                        Button(action: {
                            isShowingRunner = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Gefuehrte Ausfuehrung starten")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(CareTheme.careLilac)
                            .foregroundColor(CareTheme.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 6)
                    }
                    .careCard()

                    // Timer Card (if applicable, e.g. BHA 10 Min wait or 20s UV application)
                    if routine.id.contains("bha") || routine.id.contains("rasurfrei") {
                        bhaTimerCard
                    }

                    // Steps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SCHRITT-FUER-SCHRITT ANLEITUNG")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(CareTheme.textMuted)

                        ForEach(routine.steps) { step in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(CareTheme.surfaceElevated)
                                        .frame(width: 24, height: 24)
                                    Text("\(step.number)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(CareTheme.careLilac)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(CareTheme.textPrimary)

                                    Text(step.instruction)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(CareTheme.textSecondary)
                                        .lineSpacing(2)

                                    if !step.keyToolOrIngredient.isEmpty {
                                        Text("Fokus: \(step.keyToolOrIngredient)")
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(CareTheme.warmSand)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                            .padding(.vertical, 6)

                            if step.id != routine.steps.last?.id {
                                Divider()
                                    .background(CareTheme.border)
                            }
                        }
                    }
                    .careCard()

                    // Products Section
                    if !routine.products.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BENOTIGTE WIRKSTOFFE & EQUIPMENT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(CareTheme.textMuted)

                            ForEach(routine.products) { prod in
                                Button(action: {
                                    onOpenProduct?(prod)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(prod.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(CareTheme.textPrimary)
                                            Text("\(prod.brand) | \(prod.category)")
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundColor(CareTheme.textSecondary)
                                        }

                                        Spacer()

                                        Text(String(format: "%.2f EUR", prod.price))
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(CareTheme.textPrimary)

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(CareTheme.textMuted)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)

                                if prod.id != routine.products.last?.id {
                                    Divider()
                                        .background(CareTheme.border)
                                }
                            }
                        }
                        .careCard()
                    }

                    // Complete Action Button
                    Button(action: {
                        let haptic = UINotificationFeedbackGenerator()
                        haptic.notificationOccurred(.success)
                        store.toggleRoutineCompletion(routine, on: store.selectedDate)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .bold))
                            Text(isDone ? "Routine erledigt (Rueckgaengig machen)" : "Als erledigt verbuchen")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(isDone ? CareTheme.bg : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isDone ? CareTheme.careSage : CareTheme.careLilac)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(CareTactileButtonStyle())
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(CareTheme.bg.ignoresSafeArea())
            .navigationTitle("Pflegeroutine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(CareTheme.careLilac)
                }
            }
            .sheet(isPresented: $isShowingRunner) {
                RoutineRunnerSheet(routine: routine)
            }
        }
    }

    private var bhaTimerCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("BHA-EINWIRKZEIT (10 MIN)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CareTheme.warmSand)
                Spacer()
                if timerSecondsRemaining > 0 {
                    Text(String(format: "%02d:%02d", timerSecondsRemaining / 60, timerSecondsRemaining % 60))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(CareTheme.warmSand)
                }
            }

            Button(action: {
                toggleTimer(seconds: 600)
            }) {
                HStack {
                    Image(systemName: isTimerRunning ? "stop.fill" : "timer")
                    Text(isTimerRunning ? "Timer anhalten" : "10-Minuten Einwirk-Timer starten")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CareTheme.warmSand)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(CareTheme.warmSand.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .careCard(borderColor: CareTheme.warmSand.opacity(0.3))
    }

    private func toggleTimer(seconds: Int) {
        if isTimerRunning {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
            timerSecondsRemaining = 0
        } else {
            timerSecondsRemaining = seconds
            isTimerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
                if timerSecondsRemaining > 0 {
                    timerSecondsRemaining -= 1
                } else {
                    t.invalidate()
                    isTimerRunning = false
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.warning)
                }
            }
        }
    }
}

