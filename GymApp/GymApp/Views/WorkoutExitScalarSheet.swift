import SwiftUI

// MARK: - Workout Exit Scalar Sheet (Verbesserung 2)
// Vollstaendige Eliminierung von Text-Debriefings und Frageboegen.
// 1-Tap diskreter 4-Segment-Schalter zur deterministischen Modell-Kalibrierung.
public struct WorkoutExitScalarSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1-TAP EXIT-SKALAR")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.0)
                                .foregroundColor(GymTheme.strongBlue)

                            Text("Abschluss-Status waehlen")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(GymTheme.textPrimary)

                            Text("Ein einziger Fingertipp beendet die Einheit und kalibriert die physiologischen Modelle deterministisch im Hintergrund.")
                                .font(.system(size: 11))
                                .foregroundColor(GymTheme.textSecondary)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))

                        // 4 Diskrete Segmente
                        // [0] Planmaessig beendet (Standard / Gruen)
                        exitScalarButton(
                            code: 0,
                            codeLabel: "[0]",
                            title: "Planmaessig beendet",
                            badge: "VOLLSTAENDIG",
                            description: "Regulaerer Abschluss. Volle Volumen-Akkumulation, MPS-Refill & Reiz-Validierung.",
                            color: GymTheme.sageGreen
                        )

                        // [1] Dienstlicher Abbruch / Zeitnot (Neutral / Gelb)
                        exitScalarButton(
                            code: 1,
                            codeLabel: "[1]",
                            title: "Dienstlicher Abbruch / Zeitnot",
                            badge: "ZEITNOT",
                            description: "Dienstunterbrechung. Absolvierte Saetze verbucht, keine Daempfung, normale Re-Akkumulation.",
                            color: GymTheme.warmAmber
                        )

                        // [2] Systemische Erschoepfung (Orange)
                        exitScalarButton(
                            code: 2,
                            codeLabel: "[2]",
                            title: "Systemische Erschoepfung",
                            badge: "ZNS-DELOAD",
                            description: "Akute Erschoepfung. Erhoeht Banister-ATL (+25 TRIMP), loest ZNS-Deload-Empfehlung aus.",
                            color: GymTheme.terracotta
                        )

                        // [3] Lokaler Schmerz / Gelenk (Rot)
                        exitScalarButton(
                            code: 3,
                            codeLabel: "[3]",
                            title: "Lokaler Schmerz / Gelenk",
                            badge: "72H SCHUTZ",
                            description: "Schmerz-Signal. Loest sofortige 72h-Daempfung auf 50% fuer die betroffene Muskelkette aus.",
                            color: Color(hex: "E74C3C")
                        )

                        Spacer(minLength: 20)

                        // Zero-Touch Verwerfen
                        Button {
                            store.cancelWorkout()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Komplett verwerfen (Zero-Touch Fehleingabe)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(GymTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Workout beenden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Zurueck") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }

    private func exitScalarButton(
        code: Int,
        codeLabel: String,
        title: String,
        badge: String,
        description: String,
        color: Color
    ) -> some View {
        Button {
            HapticFeedback.success()
            Task {
                await store.finishWorkoutWithScalar(exitCode: code)
                dismiss()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Text(codeLabel)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                        Spacer()
                        Text(badge)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(color.opacity(0.12)))
                    }

                    Text(description)
                        .font(.system(size: 10.5))
                        .foregroundColor(GymTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(GymTheme.surfaceElevated)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
