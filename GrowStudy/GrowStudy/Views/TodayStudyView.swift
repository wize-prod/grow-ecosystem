import SwiftUI

public struct TodayStudyView: View {
    @EnvironmentObject private var store: StudyStore
    public let onNavigateToRoadmap: () -> Void

    @State private var showingSettings = false
    @State private var showingTimerSheet = false

    public init(
        onNavigateToRoadmap: @escaping () -> Void = {}
    ) {
        self.onNavigateToRoadmap = onNavigateToRoadmap
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                StudyTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. User Profile & Header Section
                        profileHeaderSection

                        // 2. Asymmetric Overturn Lever & 6-Month Lead-Time Card
                        asymmetricOverturnCard

                        // 3. Active Focus Timer Banner (if running)
                        if store.isFocusTimerRunning {
                            activeTimerBanner
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }

                // Floating Action Button for Focus Timer
                floatingActionButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(StudyTheme.strongBlue)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("GrowStudy")
                        .font(.headline)
                        .foregroundColor(StudyTheme.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.rotateQuote()
                        HapticFeedback.selection()
                    } label: {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(StudyTheme.strongBlue)
                    }
                }
            }
            .sheet(isPresented: $showingTimerSheet) {
                if let nextStep = store.nextAvailableStep(for: store.activeTrack) {
                    TimerFocusSheet(step: nextStep, isSheet: true)
                        .environmentObject(store)
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    ZStack {
                        StudyTheme.bg.ignoresSafeArea()
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("STUDIEN-PROFIL & SYSTEM-STATUS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(StudyTheme.textMuted)

                                Text("Benutzer: parris")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(StudyTheme.textPrimary)

                                Text("Hochschule Hannover: Fakultät IV (Wirtschaft & Informatik)")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.textSecondary)

                                Text("Ziel: B.Sc. Wirtschaftsinformatik (Start SS 2028)")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.textSecondary)

                                Text("Bundeswehr: SaZ 4 (DZE 31.12.2027)")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.textSecondary)
                            }
                            .somaCard()

                            Spacer()
                        }
                        .padding(16)
                    }
                    .navigationTitle("Einstellungen")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Fertig") { showingSettings = false }
                                .foregroundColor(StudyTheme.strongBlue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile & Header Section
    private var profileHeaderSection: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(StudyTheme.surfaceElevated)
                .frame(width: 50, height: 50)
                .overlay(
                    Text("P")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(StudyTheme.textSecondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("parris")
                    .font(.headline)
                    .foregroundColor(StudyTheme.textPrimary)

                Text(currentDateString())
                    .font(.caption)
                    .foregroundColor(StudyTheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(StudyTheme.amber)
                    Text("\(store.totalStudyMinutesToday) min")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.textPrimary)
                }
                Text("Lernzeit heute")
                    .font(.system(size: 9))
                    .foregroundColor(StudyTheme.textMuted)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Active Focus Timer Banner
    private var activeTimerBanner: some View {
        Button {
            showingTimerSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fokusblock aktiv")
                        .font(.headline)
                        .foregroundColor(StudyTheme.textPrimary)
                    let min = store.focusTimerSecondsRemaining / 60
                    let sec = store.focusTimerSecondsRemaining % 60
                    Text(String(format: "%02d:%02d verbleibend", min, sec))
                        .font(.caption)
                        .foregroundColor(StudyTheme.terracotta)
                }

                Spacer()

                Image(systemName: "timer")
                    .foregroundColor(StudyTheme.sageGreen)
            }
            .somaCard(borderColor: StudyTheme.terracotta.opacity(0.6), background: StudyTheme.surfaceElevated)
        }
    }

    // MARK: - Floating Action Button Stack
    private var floatingActionButton: some View {
        Button {
            if store.nextAvailableStep(for: store.activeTrack) != nil {
                showingTimerSheet = true
                HapticFeedback.medium()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(StudyTheme.strongBlue)
                    .frame(width: 54, height: 54)
                    .shadow(color: StudyTheme.strongBlue.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "timer")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(StudyTheme.bg)
            }
        }
    }

    // MARK: - Asymmetric Overturn Lever Card (6-Monate-Vorsprung Doktrin)
    private var asymmetricOverturnCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.shield.fill")
                        .foregroundColor(StudyTheme.strongBlue)
                        .font(.system(size: 11))
                    Text("ASYMMETRISCHER HEBEL • 6-MONATE-VORSPRUNG")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.strongBlue)
                }
                Spacer()
                Text("INVERSION")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(StudyTheme.accent.opacity(0.12))
                    .foregroundColor(StudyTheme.accent)
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Aktiver Primärhebel: OMB+ Elementare Algebra")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)
                Text("Pre-Mortem Ziel: Vollständige Beherrschung 2 Monate vor BFD-Mathe (22.02.2027) und 15 Monate vor der HsH-Klausur Wirtschaftsmathematik.")
                    .font(.system(size: 11))
                    .foregroundColor(StudyTheme.textSecondary)
                    .lineSpacing(1.5)
            }

            Divider()
                .background(StudyTheme.border)

            // 4-Stufen Loop
            VStack(alignment: .leading, spacing: 5) {
                loopRow(step: "1. CHALLENGE", detail: "OMB+ Kap. ⅠA (Brüche, Terme, Potenzen) mit ≥ 80% abschließen")
                loopRow(step: "2. PRE-MORTEM", detail: "Versagensvektor gekillt: Keine passive Berieselung, 100% interaktive Aufgaben")
                loopRow(step: "3. VIA NEGATIVA", detail: "Pruning: Führerschein & Homelab stillgelegt. Null kognitive Zersplitterung")
                loopRow(step: "4. ALL-IN", detail: "100% Bandbreite auf die interaktiven Berechnungsmodule im Portal")
            }

            // Direct Link Button
            if let url = URL(string: "https://www.ombplus.de/ombplus/public/index.html") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("OMB+ Portal öffnen (Interaktives Rechnen)")
                            .font(.system(size: 11, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(StudyTheme.strongBlue)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(StudyTheme.strongBlue.opacity(0.08))
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(StudyTheme.surface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(StudyTheme.border, lineWidth: 1))
    }

    private func loopRow(step: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(step)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(StudyTheme.accent)
                .frame(width: 85, alignment: .leading)
            Text(detail)
                .font(.system(size: 10.5))
                .foregroundColor(StudyTheme.textSecondary)
        }
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: Date())
    }
}
