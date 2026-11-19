import SwiftUI

// MARK: - Circular Profile Button (GrowStudy / GrowTasks)
public struct StudyCircularProfileButton: View {
    @State private var showingProfile = false

    public init() {}

    public var body: some View {
        Button {
            HapticFeedback.light()
            showingProfile = true
        } label: {
            ZStack {
                Circle()
                    .fill(StudyTheme.surfaceElevated)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(StudyTheme.border, lineWidth: 1))
                Text("P")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
        .sheet(isPresented: $showingProfile) {
            StudyEcosystemProfileSheet()
        }
    }
}

// MARK: - Study Ecosystem Profile Sheet (Austerer & Streng Sachlicher Status)
public struct StudyEcosystemProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StudyStore

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                StudyTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Hero Header
                        heroHeaderSection

                        // 2. 4-Pfeiler Telemetrie-Matrix
                        ecosystemMatrixSection

                        // 3. Studien- & Vorbereitungsstatus
                        studyDrilldownSection

                        // 4. Sync Footer
                        syncFooterSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ecosystem Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(StudyTheme.strongBlue)
                }
            }
        }
    }

    private var heroHeaderSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(StudyTheme.surfaceElevated)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("P")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(StudyTheme.textPrimary)
                    )
                    .overlay(Circle().stroke(StudyTheme.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("parris")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)

                Text("B.Sc. Wirtschaftsinformatik & BFD 2027")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(StudyTheme.strongBlue)

                Text("System- & Aufgabenstatus")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(StudyTheme.textMuted)
            }

            Spacer()
        }
        .studyCard()
    }

    private var ecosystemMatrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ECOSYSTEM TELEMETRIE & STATUS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.textMuted)
                    .tracking(0.8)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                pillarTelemetryCard(
                    title: "Grow (Training)",
                    headline: store.workouts(for: Date()).first?.title ?? "Regeneration",
                    detail: store.workouts(for: Date()).first?.isCompleted == true ? "Einheit absolviert" : (store.workouts(for: Date()).isEmpty ? "Kein Split geplant" : "Geplant"),
                    icon: "figure.strengthtraining.traditional",
                    color: StudyTheme.strongBlue
                )
                pillarTelemetryCard(
                    title: "Grow (Ernährung)",
                    headline: "\(Int(GrowSuiteBridge.shared.loadMacros()?.protein ?? 0))g / 160g",
                    detail: "\(Int(GrowSuiteBridge.shared.loadMacros()?.calories ?? 0)) kcal • \(store.meals(for: Date()).count) Mahlzeiten",
                    icon: "leaf.fill",
                    color: StudyTheme.appleGreen
                )
                pillarTelemetryCard(
                    title: "GrowTasks (Akademik)",
                    headline: "\(store.steps.filter { $0.isCompleted }.count)/\(store.steps.count) Module",
                    detail: "\(store.totalStudyMinutesToday) Min. Fokus heute",
                    icon: "book.closed.fill",
                    color: StudyTheme.amber
                )
                pillarTelemetryCard(
                    title: "GrowFinance (Finanzen)",
                    headline: "1.274,70 € / Mo.",
                    detail: "Feste Tilgungsquote • 5 Gates",
                    icon: "shield.lefthalf.filled",
                    color: Color(red: 0.85, green: 0.65, blue: 0.30)
                )
            }
        }
        .studyCard()
    }

    private func pillarTelemetryCard(title: String, headline: String, detail: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(StudyTheme.textMuted)
            }

            Text(headline)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(StudyTheme.textPrimary)
                .lineLimit(1)

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(StudyTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(StudyTheme.surfaceElevated))
    }

    private var studyDrilldownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STUDIEN- & VORBEREITUNGSSTATUS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(StudyTheme.textMuted)
                .tracking(0.8)

            let completedSteps = store.steps.filter { $0.isCompleted }.count
            let totalSteps = store.steps.count
            let minutesToday = store.totalStudyMinutesToday

            VStack(spacing: 8) {
                HStack {
                    Text("Meilensteine & Module")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(StudyTheme.textPrimary)
                    Spacer()
                    Text("\(completedSteps) / \(totalSteps) abgeschlossen")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.amber)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(StudyTheme.surfaceElevated))

                HStack {
                    Text("Fokus-Zeit heute")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(StudyTheme.textPrimary)
                    Spacer()
                    Text("\(minutesToday) Minuten")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.appleGreen)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(StudyTheme.surfaceElevated))
            }
        }
        .studyCard()
    }

    private var syncFooterSection: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(StudyTheme.strongBlue)
                .frame(width: 5, height: 5)
            Text("Ecosystem IPC • Synchronisiert mit Grow & GrowFinance")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(StudyTheme.textMuted)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
