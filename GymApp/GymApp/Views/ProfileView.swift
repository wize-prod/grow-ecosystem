import SwiftUI

// MARK: - Unified Ecosystem Profile & Settings Sheet (Grow Architecture Parity)
public struct EcosystemProfileAndSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    @ObservedObject private var userAccount = UserAccountService.shared
    @StateObject private var growceryService = GrowcerySyncService.shared
    @StateObject private var healthService = HealthKitService.shared
    @StateObject private var googleService = GoogleHealthSyncService.shared

    @State private var showingAccountLogin = false
    @State private var showingMeasurements = false
    @State private var showingResetConfirmationAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. Hero Identity & Athlete Level Card
                        heroHeaderSection

                        // 2. Konto & Google Kalender 2-Way Sync
                        accountSettingsSection

                        // 3. 4-Pfeiler Ecosystem Status (0 - 999)
                        ecosystemMatrixSection

                        // 4. Ecosystem Integrationen & Synchronisation (Einstellungen)
                        integrationsSection

                        // 5. Trainings-Dashboard & Performance-Metriken (Profil)
                        trainingPerformanceSection

                        // 6. System-Verwaltung & Daten-Hygiene (Einstellungen)
                        systemManagementSection

                        // 7. App Metadata Footer
                        appMetadataFooter

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Profil & Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GymTheme.strongBlue)
                }
            }
            .sheet(isPresented: $showingAccountLogin) {
                GymAccountLoginSheet()
            }
            .sheet(isPresented: $showingMeasurements) {
                NavigationStack {
                    MeasurementsView()
                }
                .environmentObject(store)
            }
            .alert("Fortschritt auf 0 zuruecksetzen?", isPresented: $showingResetConfirmationAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Ja, alles auf 0 setzen", role: .destructive) {
                    store.resetAllProgressToZero()
                    HapticFeedback.success()
                    dismiss()
                }
            } message: {
                Text("Dies loescht alle absolvierten Einheiten, Koerper-Messungen und setzt saemtliche Leistungs-Standards zurueck.")
            }
        }
    }

    // MARK: - 1. Hero Header
    private var heroHeaderSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(GymTheme.surfaceElevated)
                .frame(width: 64, height: 64)
                .overlay(
                    Text(userAccount.currentAccount.initial)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                )
                .overlay(Circle().stroke(GymTheme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(userAccount.currentAccount.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)

                Text("Ecosystem Athlet")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(GymTheme.strongBlue)

                Text(userAccount.currentAccount.googleAccountEmail.isEmpty ? "Lokales Profil • Bundeswehr-Standard" : "\(userAccount.currentAccount.googleAccountEmail) • Bundeswehr-Standard")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .somaCard()
    }

    // MARK: - 2. Account & Google Calendar Section
    private var accountSettingsSection: some View {
        Button {
            HapticFeedback.light()
            showingAccountLogin = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(GymTheme.surfaceElevated)
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 18))
                        .foregroundColor(GymTheme.strongBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Konto & Google Kalender")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)

                        Text(userAccount.currentAccount.googleAccountEmail.isEmpty ? "ISOLIERT" : "VERBUNDEN")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(userAccount.currentAccount.googleAccountEmail.isEmpty ? GymTheme.warmSand : GymTheme.sageGreen)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(3)
                    }

                    if userAccount.currentAccount.googleAccountEmail.isEmpty {
                        Text("Kein Google Kalender verknuepft • Antippen zum Einrichten")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(GymTheme.textSecondary)
                    } else {
                        Text(userAccount.currentAccount.googleAccountEmail)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(GymTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(GymTheme.textMuted)
            }
            .somaCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. 4-Pfeiler Ecosystem Matrix
    private var ecosystemMatrixSection: some View {
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ECOSYSTEM TELEMETRIE & STATUS")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
                    .tracking(0.8)
                Spacer()
                Text("Ecosystem Verbunden")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.sageGreen)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                pillarItem(name: "Grow (Training)", status: "Training aktiv", color: GymTheme.strongBlue)
                pillarItem(name: "Grow (Ernährung)", status: "Ernährung synchron", color: GymTheme.sageGreen)
                pillarItem(name: "GrowTasks (Akademik)", status: "Tasks gekoppelt", color: GymTheme.warmSand)
                pillarItem(name: "GrowFinance (Finanzen)", status: "Budget geschützt", color: GymTheme.warmAmber)
            }
        }
        .somaCard()
    }

    private func pillarItem(name: String, status: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(GymTheme.textPrimary)
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(status)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(GymTheme.textSecondary)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(GymTheme.surfaceElevated.opacity(0.6)))
    }

    // MARK: - 4. Integrations & Synchronisation (Einstellungen)
    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SYNCHRONISATION & BRIDGES")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .tracking(0.8)

            // Growcery Sync-Bridge Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.sageGreen)
                        Text("Growcery Sync-Bridge")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    Spacer()
                    Circle()
                        .fill(GymTheme.sageGreen)
                        .frame(width: 7, height: 7)
                    Text("Aktiv")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.sageGreen)
                }

                Text("Autonome Makro-, Regenerations- und Belastungsberechnung.")
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textSecondary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protein-Ziel")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                        Text("160 g / Tag")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.sageGreen)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Energie-Budget")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                        Text("1.850 - 2.000 kcal")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textPrimary)
                    }

                    Spacer()

                    Button {
                        HapticFeedback.medium()
                        growceryService.openGrowcery(context: "settings")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("Oeffnen")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GymTheme.surfaceElevated)
                        .foregroundColor(GymTheme.strongBlue)
                        .cornerRadius(6)
                    }
                }
                .padding(.top, 2)
            }
            .somaCard()

            // Apple Health & Google Fit 2-Way Sync Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.terracotta)
                        Text("Apple Health & Google Fit")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    Spacer()
                    Circle()
                        .fill(healthService.isAuthorized ? GymTheme.sageGreen : GymTheme.terracotta)
                        .frame(width: 7, height: 7)
                    Text(healthService.isAuthorized ? "2-Wege Aktiv" : "Nicht autorisiert")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(healthService.isAuthorized ? GymTheme.sageGreen : GymTheme.terracotta)
                }

                Text("Workouts werden in Apple Health gebucht; Ruhepuls und Schritte werden in Grow eingelesen.")
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textSecondary)

                VStack(spacing: 6) {
                    metricRow(title: "Ruhepuls", value: healthService.restingHeartRate > 0 ? "\(healthService.restingHeartRate) bpm" : "Keine Messung", isAccent: healthService.restingHeartRate > 0)
                    metricRow(title: "Aktivkalorien heute", value: "\(Int(healthService.activeEnergyBurnedToday)) kcal", isAccent: false)
                    metricRow(title: "Schritte heute", value: "\(healthService.todaySteps)", isAccent: false)
                    metricRow(title: "Externe Einheiten", value: "\(healthService.syncedWorkouts.count) synchronisiert", isAccent: false)
                }
                .padding(10)
                .background(GymTheme.surface)
                .cornerRadius(8)

                HStack(spacing: 10) {
                    Button {
                        HapticFeedback.medium()
                        if healthService.isAuthorized {
                            healthService.fetchAllHealthData()
                        } else {
                            healthService.checkAndRequestAuthorization()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .bold))
                            Text(healthService.isAuthorized ? "Jetzt synchronisieren" : "Freigabe anfordern")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(GymTheme.surfaceElevated)
                        .foregroundColor(GymTheme.strongBlue)
                        .cornerRadius(7)
                    }

                    if googleService.isGoogleFitAppInstalled {
                        Button {
                            HapticFeedback.light()
                            googleService.openGoogleFitApp()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Google Fit")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(GymTheme.surfaceElevated)
                            .foregroundColor(GymTheme.sageGreen)
                            .cornerRadius(7)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .somaCard()
        }
    }

    private func metricRow(title: String, value: String, isAccent: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(GymTheme.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isAccent ? GymTheme.strongBlue : GymTheme.textPrimary)
        }
    }

    // MARK: - 5. Training Performance & Dashboard (Profil)
    private var trainingPerformanceSection: some View {
        let calendar = Calendar.current
        let today = Date()
        let weekSessions = store.allSessionsWithExternal.filter { s in
            let days = calendar.dateComponents([.day], from: s.startTime, to: today).day ?? 0
            return days <= 7
        }
        let totalTonnage = weekSessions.reduce(0.0) { $0 + $1.totalTonnageKg }

        return VStack(alignment: .leading, spacing: 12) {
            Text("TRAININGS-LEISTUNG & PROFIL-STATISTIKEN")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .tracking(0.8)

            // Weekly Summary Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Workouts Diese Woche")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(GymTheme.textPrimary)
                    Spacer()
                    Text("\(weekSessions.count) / 4")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(weekSessions.count >= 4 ? GymTheme.sageGreen : GymTheme.strongBlue)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wochentonnage")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                        Text("\(Int(totalTonnage)) kg")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.strongBlue)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gesamte Workouts")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                        Text("\(store.allSessionsWithExternal.count)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textPrimary)
                    }
                }
            }
            .somaCard()

            // Measurements Quick Link Card
            Button {
                HapticFeedback.light()
                showingMeasurements = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 38, height: 38)
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 15))
                            .foregroundColor(GymTheme.warmSand)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Koerpermasse & Messungen")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)
                        Text("Gewicht, Bauchumfang & viszerale Reha-Werte")
                            .font(.system(size: 10.5))
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(GymTheme.textMuted)
                }
                .somaCard()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 6. System Management & Reset (Einstellungen)
    private var systemManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DATEN-HYGIENE & SYSTEM-VERWALTUNG")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 10) {
                Text("Fortschritt & Standards auf 0 zuruecksetzen")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GymTheme.textPrimary)

                Text("Loescht alle absolvierten Einheiten, Koerper-Messungen und setzt Leistungs-Standards zurueck.")
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textSecondary)

                Button(role: .destructive) {
                    HapticFeedback.medium()
                    showingResetConfirmationAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .bold))
                        Text("Kompletten Fortschritt auf 0 setzen")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(GymTheme.terracotta.opacity(0.18))
                    .foregroundColor(GymTheme.terracotta)
                    .cornerRadius(7)
                }
            }
            .somaCard()
        }
    }

    // MARK: - 7. App Metadata Footer
    private var appMetadataFooter: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Grow iOS v1.0.0")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(GymTheme.textSecondary)
            Text("Bundle ID: com.nkembi.somagym • Grow Ecosystem 2026")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - Aliases for Backward Compatibility Across the Workspace
public struct UserProfileDetailSheet: View {
    public init() {}
    public var body: some View {
        EcosystemProfileAndSettingsSheet()
    }
}

public struct ProfileSettingsSheet: View {
    public init() {}
    public var body: some View {
        EcosystemProfileAndSettingsSheet()
    }
}

public struct ProfileView: View {
    public init() {}
    public var body: some View {
        EcosystemProfileAndSettingsSheet()
    }
}
