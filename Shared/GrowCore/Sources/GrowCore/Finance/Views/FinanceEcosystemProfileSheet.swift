import SwiftUI

// MARK: - Circular Profile Button (GrowFinance)
public struct FinanceCircularProfileButton: View {
    @State private var showingProfile = false

    public init() {}

    public var body: some View {
        Button {
            HapticFeedback.light()
            showingProfile = true
        } label: {
            ZStack {
                Circle()
                    .fill(FinanceTheme.surfaceRaised)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(FinanceTheme.accent.opacity(0.8), lineWidth: 1.0)
                    )

                Text("P")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FinanceTheme.textPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            FinanceEcosystemProfileSheet()
        }
    }
}

// MARK: - Finance Ecosystem Profile Sheet
public struct FinanceEcosystemProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FinanceStore.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Hero Header
                        heroHeaderSection

                        // 2. 4-Pfeiler Telemetrie-Matrix
                        ecosystemMatrixSection

                        // 3. Finance Deep-Dive
                        financeDrilldownSection

                        // 4. Sync Footer
                        syncFooterSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ecosystem Profil")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FinanceTheme.accent)
                }
            }
        }
    }

    private var heroHeaderSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(FinanceTheme.surfaceRaised)
                .frame(width: 64, height: 64)
                .overlay(
                    Text("P")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(FinanceTheme.textPrimary)
                )
                .overlay(Circle().stroke(FinanceTheme.accent.opacity(0.8), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("parris")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FinanceTheme.textPrimary)

                Text("5-Gate Budget & Tilgungsarchitektur")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FinanceTheme.accent)

                Text("Feste Tilgung: 1.274,70 € / Monat")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(FinanceTheme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(FinanceTheme.surfaceRaised))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FinanceTheme.accent.opacity(0.2), lineWidth: 1))
    }

    private var ecosystemMatrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ECOSYSTEM TELEMETRIE & STATUS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textSecondary)
                    .tracking(0.8)
                Spacer()
                Text("Synchron")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(FinanceTheme.accent)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                pillarTelemetryCard(title: "Grow (Training)", status: "Training aktiv", icon: "figure.strengthtraining.traditional", color: Color(red: 0.25, green: 0.45, blue: 0.90))
                pillarTelemetryCard(title: "Grow (Ernährung)", status: "Ernährung synchron", icon: "leaf.fill", color: Color(red: 0.45, green: 0.70, blue: 0.45))
                pillarTelemetryCard(title: "GrowTasks (Akademik)", status: "Tasks gekoppelt", icon: "book.closed.fill", color: Color(red: 0.85, green: 0.65, blue: 0.30))
                pillarTelemetryCard(title: "GrowFinance (Finanzen)", status: "1.274,70 € Tilgung", icon: "shield.lefthalf.filled", color: FinanceTheme.accent)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(FinanceTheme.surfaceRaised))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FinanceTheme.accent.opacity(0.2), lineWidth: 1))
    }

    private func pillarTelemetryCard(title: String, status: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(FinanceTheme.textSecondary)
                .lineLimit(1)

            Text(status)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FinanceTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(FinanceTheme.surfaceRaised.opacity(0.8)))
    }

    private var financeDrilldownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FINANZIELLE TELEMETRIE & PUFFER")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textSecondary)
                .tracking(0.8)

            VStack(spacing: 8) {
                metricRow(
                    title: "Frei verfügbar (Safe-to-Spend)",
                    detail: String(format: "%.2f €", store.safeToSpend)
                )
                metricRow(
                    title: "Dispo-Schutz Puffer (> 100 €)",
                    detail: store.isDispoSafe ? "Aktiv (Sicher)" : "Kritisch"
                )
                metricRow(
                    title: "Lieferdienst-Freie Serie",
                    detail: "\(store.foodLeakFreeStreakDays) Tage"
                )
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(FinanceTheme.surfaceRaised))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FinanceTheme.accent.opacity(0.2), lineWidth: 1))
    }

    private func metricRow(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FinanceTheme.textPrimary)
            Spacer()
            Text(detail)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.accent)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(FinanceTheme.surfaceRaised.opacity(0.8)))
    }

    private var syncFooterSection: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(FinanceTheme.accent)
                .frame(width: 5, height: 5)
            Text("Ecosystem IPC • Synchronisiert mit Grow & GrowTasks")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(FinanceTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
