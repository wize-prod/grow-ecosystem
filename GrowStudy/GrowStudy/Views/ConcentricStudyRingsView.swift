import SwiftUI

public struct ConcentricStudyRingsView: View {
    @EnvironmentObject private var store: StudyStore
    public var onOpenRoadmap: (() -> Void)? = nil

    private let phase0Color = Color(red: 0.0, green: 0.82, blue: 0.92)  // Cyan / Blue (#00D1EB)
    private let bfdColor = Color(red: 0.20, green: 0.50, blue: 0.98)     // Cobalt Blue (#3380FA)

    public init(onOpenRoadmap: (() -> Void)? = nil) {
        self.onOpenRoadmap = onOpenRoadmap
    }

    public var body: some View {
        let allWinfSteps = store.steps(for: .wirtschaftsinformatik)
        let phase0Steps = allWinfSteps.filter { $0.phase.contains("Phase 0") }
        let bfdSteps = allWinfSteps.filter { $0.phase.contains("Phase 1") || $0.phase.contains("BFD") }

        let p0Done = phase0Steps.filter { $0.isCompleted }.count
        let p0Total = max(1, phase0Steps.count)
        let p0Ratio = Double(p0Done) / Double(p0Total)

        let bfdDone = bfdSteps.filter { $0.isCompleted }.count
        let bfdTotal = max(1, bfdSteps.count)
        let bfdRatio = Double(bfdDone) / Double(bfdTotal)

        Button(action: {
            HapticFeedback.light()
            onOpenRoadmap?()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text("STUDIEN-RINGE (PHASE 0 & BFD 2027)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.textMuted)
                        .tracking(1.0)
                    Spacer()
                    if onOpenRoadmap != nil {
                        HStack(spacing: 3) {
                            Text("Fahrplan")
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(phase0Color)
                    }
                }

                HStack(spacing: 16) {
                    // Concentric Rings (Outer: Phase 0 OMB+, Inner: BFD 2027)
                    ZStack {
                        // Outer Ring: Phase 0 OMB+ & Vorbereitung (80px)
                        Circle()
                            .stroke(phase0Color.opacity(0.18), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0.005, p0Ratio)))
                            .stroke(phase0Color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        // Inner Ring: BFD 2027 Lehrgänge (58px)
                        Circle()
                            .stroke(bfdColor.opacity(0.18), lineWidth: 6)
                            .frame(width: 58, height: 58)
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0.005, bfdRatio)))
                            .stroke(bfdColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 58, height: 58)
                            .rotationEffect(.degrees(-90))

                        // Center Percentage (Phase 0)
                        Text("\(Int(p0Ratio * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(StudyTheme.textPrimary)
                    }
                    .frame(width: 88, height: 88)

                    // Metrics Stack
                    VStack(alignment: .leading, spacing: 8) {
                        // Phase 0
                        HStack(spacing: 6) {
                            Circle().fill(phase0Color).frame(width: 6, height: 6)
                            Text("Phase 0 (OMB+ & IT):")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(StudyTheme.textPrimary)
                            Spacer()
                            Text("\(p0Done)/\(p0Total) (\(Int(p0Ratio * 100))%)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(phase0Color)
                        }

                        // BFD 2027
                        HStack(spacing: 6) {
                            Circle().fill(bfdColor).frame(width: 6, height: 6)
                            Text("BFD 2027 (7 Lehrgänge):")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(StudyTheme.textSecondary)
                            Spacer()
                            Text("\(bfdDone)/\(bfdTotal)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(bfdColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .wellnessCard(borderColor: StudyTheme.border, cornerRadius: 18)
        }
        .buttonStyle(AppleTactileButtonStyle())
    }
}
