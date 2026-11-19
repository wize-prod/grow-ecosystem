import SwiftUI
import Combine
import AuthenticationServices

// MARK: - Unified Consumer-Grade Profile & Settings Sheet (Grow Multi-Tenant Architecture)
public struct EcosystemProfileAndSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    @ObservedObject private var userAccount = UserAccountService.shared
    @ObservedObject private var tvCasting = WorkoutTVCastingManager.shared
    @StateObject private var healthService = HealthKitService.shared

    @State private var showingAddProfileSheet = false
    @State private var showingEditProfileSheet = false
    @State private var showingEditMacrosSheet = false
    @State private var showingMeasurements = false
    @State private var showingResetConfirmationAlert = false
    @State private var showingLogOutAlert = false
    @State private var showingBackupSuccessAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Clean Consumer Hero Profile Card
                        heroProfileCard

                        // 2. Multi-Tenant Accounts & Profile Switcher
                        accountsAndProfilesSection

                        // 3. Individual Physiologie & Ziele des aktiven Profils
                        individualTargetsSection

                        // 4. System & Vernetzung (Funktional, keine Status-Show)
                        systemAndConnectivitySection

                        // 5. Konto-Aktionen & Backup
                        accountAndBackupSection

                        // 6. Diskrete Daten-Hygiene & App-Info
                        dataHygieneAndFooterSection

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
            .sheet(isPresented: $showingAddProfileSheet) {
                AddProfileSheet()
            }
            .sheet(isPresented: $showingEditProfileSheet) {
                GymAccountLoginSheet()
            }
            .sheet(isPresented: $showingEditMacrosSheet) {
                EditMacroTargetSheet()
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
                Text("Dies loescht alle absolvierten Einheiten und Koerper-Messungen fuer das aktive Profil und setzt saemtliche Leistungs-Standards zurueck.")
            }
            .alert("Abmelden", isPresented: $showingLogOutAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Abmelden", role: .destructive) {
                    userAccount.logOut()
                    HapticFeedback.medium()
                }
            } message: {
                Text("Moechtest du dich wirklich vom aktiven Profil abmelden?")
            }
            .alert("Backup erfolgreich", isPresented: $showingBackupSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Die lokalen Profildaten und Trainingsprotokolle wurden atomar im SQLite WAL gesichert.")
            }
        }
    }

    // MARK: - 1. Clean Consumer Hero Profile Card
    private var heroProfileCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(GymTheme.surfaceElevated)
                .frame(width: 58, height: 58)
                .overlay(
                    Text(userAccount.currentAccount.initial)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                )
                .overlay(Circle().stroke(GymTheme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(userAccount.currentAccount.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)

                    if userAccount.currentAccount.isPrimaryAccount {
                        Text("Inhaber")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GymTheme.strongBlue.opacity(0.18))
                            .foregroundColor(GymTheme.strongBlue)
                            .cornerRadius(4)
                    }
                }

                Text(userAccount.currentAccount.userGoal)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(GymTheme.textSecondary)

                Text(userAccount.currentAccount.googleAccountEmail.isEmpty ? "Lokales Profil" : userAccount.currentAccount.googleAccountEmail)
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                HapticFeedback.light()
                showingEditProfileSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(GymTheme.surfaceElevated)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(GymTheme.border, lineWidth: 0.8))
            }
        }
        .padding(14)
        .somaCard()
    }

    // MARK: - 2. Multi-Tenant Accounts & Profile Switcher
    private var accountsAndProfilesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("KONTEN & PROFILE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
                    .tracking(0.8)

                Spacer()

                Text("\(userAccount.savedAccounts.count) Registriert")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
            }

            VStack(spacing: 0) {
                ForEach(userAccount.savedAccounts, id: \.userKey) { account in
                    let isCurrent = account.userKey == userAccount.currentAccount.userKey

                    Button {
                        if !isCurrent {
                            HapticFeedback.selection()
                            userAccount.switchToSavedAccount(userKey: account.userKey)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(isCurrent ? GymTheme.strongBlue.opacity(0.15) : GymTheme.surfaceElevated)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Text(account.initial)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isCurrent ? GymTheme.strongBlue : GymTheme.textPrimary)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(GymTheme.textPrimary)

                                Text(account.userGoal)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(GymTheme.strongBlue)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)

                    if account.userKey != userAccount.savedAccounts.last?.userKey {
                        Divider()
                            .background(GymTheme.border.opacity(0.6))
                            .padding(.leading, 60)
                    }
                }

                Divider()
                    .background(GymTheme.border.opacity(0.6))

                // Action: Add new family profile or account
                Button {
                    HapticFeedback.light()
                    showingAddProfileSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(GymTheme.strongBlue)

                        Text("Neues Profil oder Konto anlegen")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(GymTheme.strongBlue)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textMuted)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                }
                .buttonStyle(.plain)
            }
            .somaCard()
        }
    }

    // MARK: - 3. Individual Physiologie & Ziele
    private var individualTargetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INDIVIDUELLE ZIELE (\(userAccount.currentAccount.displayName.uppercased()))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .tracking(0.8)

            VStack(spacing: 0) {
                // Measurements Row
                Button {
                    HapticFeedback.light()
                    showingMeasurements = true
                } label: {
                    settingsRow(
                        icon: "ruler",
                        title: "Koerpermasse & Reha-Messungen",
                        subtitle: "Tagesgewicht, Bauchumfang & viszerale Parameter",
                        badge: nil
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .background(GymTheme.border.opacity(0.6))
                    .padding(.leading, 48)

                // Macro Target Configuration Row
                Button {
                    HapticFeedback.light()
                    showingEditMacrosSheet = true
                } label: {
                    settingsRow(
                        icon: "fork.knife",
                        title: "Ernaehrungs- & Makro-Ziele",
                        subtitle: "\(Int(userAccount.currentAccount.targetKcal)) kcal • \(Int(userAccount.currentAccount.targetProtein)) g Protein • \(Int(userAccount.currentAccount.targetWaterMl)) ml",
                        badge: nil
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .background(GymTheme.border.opacity(0.6))
                    .padding(.leading, 48)

                // Training Goal Row
                Button {
                    HapticFeedback.light()
                    showingEditProfileSheet = true
                } label: {
                    settingsRow(
                        icon: "figure.walk",
                        title: "Trainings-Fokus & Reha-Bedingung",
                        subtitle: userAccount.currentAccount.userGoal,
                        badge: nil
                    )
                }
                .buttonStyle(.plain)
            }
            .somaCard()
        }
    }

    // MARK: - 4. System & Vernetzung
    private var systemAndConnectivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VERNETZUNG & HARDWARE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .tracking(0.8)

            VStack(spacing: 0) {
                // Apple Health Toggle
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 32, height: 32)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                            .foregroundColor(GymTheme.terracotta)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)
                        Text(healthService.isAuthorized ? "Workouts & Vitalwerte synchron" : "Berechtigung anfordern")
                            .font(.system(size: 10.5))
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { healthService.isAuthorized },
                        set: { enable in
                            if enable && !healthService.isAuthorized {
                                healthService.checkAndRequestAuthorization()
                            }
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)

                Divider()
                    .background(GymTheme.border.opacity(0.6))
                    .padding(.leading, 48)

                // SmartTV Stream Row
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 32, height: 32)
                        Image(systemName: "tv")
                            .font(.system(size: 13))
                            .foregroundColor(GymTheme.strongBlue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SmartTV HUD Stream")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)
                        Text(tvCasting.activeSSEClientCount > 0 ? "Live-Stream aktiv (\(tvCasting.activeSSEClientCount) TV)" : "Server-Sent Events auf Port 8080")
                            .font(.system(size: 10.5))
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Spacer()

                    Text(tvCasting.activeSSEClientCount > 0 ? "Aktiv" : "Bereit")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(tvCasting.activeSSEClientCount > 0 ? GymTheme.accentGreen.opacity(0.18) : GymTheme.surfaceElevated)
                        .foregroundColor(tvCasting.activeSSEClientCount > 0 ? GymTheme.accentGreen : GymTheme.textMuted)
                        .cornerRadius(4)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
            }
            .somaCard()
        }
    }

    // MARK: - 5. Konto-Aktionen & Backup
    private var accountAndBackupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KONTO & SICHERUNG")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
                .tracking(0.8)

            VStack(spacing: 0) {
                // Local Backup
                Button {
                    HapticFeedback.success()
                    GymStore.shared.flushAllSync()
                    LocalStore.shared.flushAllSync()
                    showingBackupSuccessAlert = true
                } label: {
                    settingsRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Lokale Datensicherung",
                        subtitle: "Atomarer Snapshot im SQLite Write-Ahead-Log",
                        badge: "WAL"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .background(GymTheme.border.opacity(0.6))
                    .padding(.leading, 48)

                // Log out
                Button {
                    HapticFeedback.medium()
                    showingLogOutAlert = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(GymTheme.surfaceElevated)
                                .frame(width: 32, height: 32)
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 13))
                                .foregroundColor(GymTheme.terracotta)
                        }

                        Text("Abmelden")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.terracotta)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }
                .buttonStyle(.plain)
            }
            .somaCard()
        }
    }

    // MARK: - 6. Diskrete Daten-Hygiene & Footer
    private var dataHygieneAndFooterSection: some View {
        VStack(spacing: 16) {
            // Discrete reset link instead of giant red banner
            Button {
                HapticFeedback.medium()
                showingResetConfirmationAlert = true
            } label: {
                Text("Lokalen Fortschritt fuer dieses Profil zuruecksetzen")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GymTheme.textMuted)
                    .underline()
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text("Grow iOS v1.0.0 (Build 2026.11)")
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)

                Text("Bundle ID: com.nkembi.somagym • Multi-Tenant Portable Architecture")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Helper Settings Row
    private func settingsRow(icon: String, title: String, subtitle: String, badge: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GymTheme.surfaceElevated)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(GymTheme.strongBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GymTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(GymTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if let badge = badge {
                Text(badge)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(GymTheme.surfaceElevated)
                    .foregroundColor(GymTheme.textMuted)
                    .cornerRadius(4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(GymTheme.textMuted)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

// MARK: - Add Individual Profile Sheet (Multi-User Onboarding)
public struct AddProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userAccount = UserAccountService.shared

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var selectedGoal: String = "Gelenkschonung & Mobilitaet"
    @State private var targetKcal: Double = 1600
    @State private var targetProtein: Double = 80
    @State private var targetWaterMl: Double = 2000

    private let availableGoals = [
        "Gelenkschonung & Mobilitaet",
        "Hypertrophie & Muskelaufbau",
        "Gewichtsmanagement & Vitalitaet",
        "Kardiologische Reha & Ausdauer",
        "Allgemeine Fitness"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("NEUES MITGLIED / PROFIL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textMuted)
                            .tracking(0.8)

                        // Basic Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Name oder Pseudonym")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)

                            TextField("z. B. Mama, Sarah, Alex", text: $name)
                                .font(.system(size: 14))
                                .padding(10)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))

                            Text("E-Mail / Google-Adresse (Optional)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)
                                .padding(.top, 4)

                            TextField("name@gmail.com", text: $email)
                                .font(.system(size: 14))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(10)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
                        }
                        .padding(14)
                        .somaCard()

                        // Health Goal & Conditions Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Physiologischer Fokus & Reha-Bedingung")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)

                            Picker("Fokus", selection: $selectedGoal) {
                                ForEach(availableGoals, id: \.self) { goal in
                                    Text(goal).tag(goal)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(8)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(8)
                        }
                        .padding(14)
                        .somaCard()

                        // Macro Targets Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Individuelle Zielwerte")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Energie-Budget:")
                                        .font(.system(size: 12))
                                        .foregroundColor(GymTheme.textSecondary)
                                    Spacer()
                                    Text("\(Int(targetKcal)) kcal")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(GymTheme.textPrimary)
                                }
                                Slider(value: $targetKcal, in: 1200...3500, step: 50)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Protein-Ziel:")
                                        .font(.system(size: 12))
                                        .foregroundColor(GymTheme.textSecondary)
                                    Spacer()
                                    Text("\(Int(targetProtein)) g")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(GymTheme.accentGreen)
                                }
                                Slider(value: $targetProtein, in: 50...240, step: 5)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Hydration:")
                                        .font(.system(size: 12))
                                        .foregroundColor(GymTheme.textSecondary)
                                    Spacer()
                                    Text("\(Int(targetWaterMl)) ml")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(GymTheme.strongBlue)
                                }
                                Slider(value: $targetWaterMl, in: 1500...4000, step: 100)
                            }
                        }
                        .padding(14)
                        .somaCard()

                        // Create Button
                        Button {
                            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let finalName = cleanName.isEmpty ? "Neues Profil" : cleanName
                            userAccount.createOrSwitchToFamilyMember(
                                name: finalName,
                                email: email,
                                goal: selectedGoal,
                                targetKcal: targetKcal,
                                targetProtein: targetProtein,
                                targetWaterMl: targetWaterMl
                            )
                            HapticFeedback.success()
                            dismiss()
                        } label: {
                            Text("Profil anlegen & sofort aktivieren")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(GymTheme.strongBlue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Profil hinzufuegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(GymTheme.textMuted)
                }
            }
        }
    }
}

// MARK: - Edit Macro Target Sheet
public struct EditMacroTargetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userAccount = UserAccountService.shared

    @State private var targetKcal: Double = 1950
    @State private var targetProtein: Double = 160
    @State private var targetWaterMl: Double = 2500

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("ZIELWERTE FUER \(userAccount.currentAccount.displayName.uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textMuted)
                        .tracking(0.8)

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tages-Energie-Budget:")
                                    .font(.system(size: 12))
                                    .foregroundColor(GymTheme.textSecondary)
                                Spacer()
                                Text("\(Int(targetKcal)) kcal")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.textPrimary)
                            }
                            Slider(value: $targetKcal, in: 1200...4000, step: 25)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Protein-Ziel:")
                                    .font(.system(size: 12))
                                    .foregroundColor(GymTheme.textSecondary)
                                Spacer()
                                Text("\(Int(targetProtein)) g")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.accentGreen)
                            }
                            Slider(value: $targetProtein, in: 40...250, step: 5)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Hydration:")
                                    .font(.system(size: 12))
                                    .foregroundColor(GymTheme.textSecondary)
                                Spacer()
                                Text("\(Int(targetWaterMl)) ml")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.strongBlue)
                            }
                            Slider(value: $targetWaterMl, in: 1000...5000, step: 100)
                        }
                    }
                    .padding(16)
                    .somaCard()

                    Spacer()

                    Button {
                        userAccount.updateAccount(
                            name: userAccount.currentAccount.displayName,
                            email: userAccount.currentAccount.googleAccountEmail,
                            calendarId: userAccount.currentAccount.selectedCalendarIdentifier,
                            kcal: targetKcal,
                            protein: targetProtein,
                            waterMl: targetWaterMl
                        )
                        HapticFeedback.success()
                        dismiss()
                    } label: {
                        Text("Aenderungen speichern")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.strongBlue)
                            .cornerRadius(10)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Ziele anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .foregroundColor(GymTheme.textMuted)
                }
            }
            .onAppear {
                targetKcal = userAccount.currentAccount.targetKcal
                targetProtein = userAccount.currentAccount.targetProtein
                targetWaterMl = userAccount.currentAccount.targetWaterMl
            }
        }
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
