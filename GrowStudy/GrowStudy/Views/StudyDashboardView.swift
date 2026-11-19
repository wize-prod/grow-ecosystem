import SwiftUI

public struct StudyDashboardView: View {
    @EnvironmentObject private var store: StudyStore
    @State private var showingBFDSheet = false
    @State private var showingTimerSheet = false
    @State private var activeDetailStep: RoadmapStep? = nil

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                StudyTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Profile & Day Header
                        headerSection

                        // 3. Track Selector Segment (4 Pillars from Vault)
                        trackSelectorSection

                        // 4. "Up Next" Active Action Hero Card
                        if let nextStep = store.nextAvailableStep(for: store.activeTrack) {
                            upNextHeroCard(step: nextStep)
                        } else {
                            allCompletedHeroCard
                        }

                        // 5. BFD 2027 Lehrgänge Quick Access
                        bfdLauncherCard

                        // 6. Sequential Step-Gated Roadmap
                        RoadmapListView()

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }

                // Floating Action Cluster (Profile)
                VStack(spacing: 12) {
                    StudyCircularProfileButton()
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("GrowStudy")
                        .font(.headline)
                        .foregroundColor(StudyTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.rotateQuote()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(StudyTheme.strongBlue)
                    }
                }
            }
            .sheet(item: $activeDetailStep) { step in
                StepDetailSheet(step: step)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingBFDSheet) {
                BFDCoursesView()
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(StudyTheme.surfaceElevated)
                .frame(width: 48, height: 48)
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

                Text(formattedDate())
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
    }

    // MARK: - Track Selector
    private var trackSelectorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StudyTrack.allCases) { track in
                        let isSelected = store.activeTrack == track
                        Button {
                            store.activeTrack = track
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: track.systemImage)
                                    .font(.system(size: 11))
                                Text(track.shortTitle)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? StudyTheme.strongBlue : StudyTheme.surface)
                            .foregroundColor(isSelected ? StudyTheme.bg : StudyTheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? StudyTheme.strongBlue : StudyTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text(store.activeTrack.deadlineNote)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(store.activeTrack == .wirtschaftsinformatik ? StudyTheme.strongBlue : StudyTheme.warmSand)
                .padding(.leading, 4)
                .padding(.top, 2)
        }
    }

    // MARK: - Up Next Hero Card
    private func upNextHeroCard(step: RoadmapStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AKTUELLE PRIORITÄT • SCHRITT \(step.sequenceNumber)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.strongBlue)

                Spacer()

                Text("\(step.estimatedMinutes) min")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.warmSand)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)

                if !step.subtitle.isEmpty {
                    Text(step.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(StudyTheme.textSecondary)
                }
            }

            HStack(spacing: 10) {
                if let urlString = step.primaryURL, let url = URL(string: urlString) {
                    Button {
                        HapticFeedback.medium()
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("Öffnen")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(StudyTheme.strongBlue)
                        .foregroundColor(StudyTheme.bg)
                        .cornerRadius(8)
                    }
                }

                Button {
                    activeDetailStep = step
                    HapticFeedback.light()
                } label: {
                    Text("Details")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(StudyTheme.surfaceElevated)
                        .foregroundColor(StudyTheme.textPrimary)
                        .cornerRadius(8)
                }

                Button {
                    store.completeStep(id: step.id)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(StudyTheme.sageGreen)
                        .foregroundColor(StudyTheme.bg)
                        .cornerRadius(8)
                }
            }
        }
        .somaCard(borderColor: StudyTheme.strongBlue.opacity(0.4))
    }

    private var allCompletedHeroCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(StudyTheme.sageGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("Alle Meilensteine abgeschlossen")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StudyTheme.textPrimary)
                Text("Dieser Qualifikationspfad ist vollständig gemeistert.")
                    .font(.system(size: 11))
                    .foregroundColor(StudyTheme.textSecondary)
            }
        }
        .somaCard(borderColor: StudyTheme.sageGreen.opacity(0.4))
    }

    // MARK: - BFD Launcher
    private var bfdLauncherCard: some View {
        Button {
            showingBFDSheet = true
            HapticFeedback.light()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(StudyTheme.surfaceElevated)
                        .frame(width: 38, height: 38)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 15))
                        .foregroundColor(StudyTheme.strongBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BFD-Lehrgänge 2027")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(StudyTheme.textPrimary)
                    Text("7 Bildungsmaßnahmen • 29 Freistellungstage • PSM I, SAP, ITIL")
                        .font(.system(size: 11))
                        .foregroundColor(StudyTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(StudyTheme.textMuted)
            }
            .somaCard()
        }
        .buttonStyle(.plain)
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: Date())
    }
}
