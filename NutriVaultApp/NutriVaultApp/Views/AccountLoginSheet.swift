import SwiftUI
import EventKit
import AuthenticationServices

public struct AccountLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var accountService = UserAccountService.shared
    @ObservedObject private var calSync = CalendarSyncService.shared

    // Profile Details
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var userGoal: String = ""
    @State private var googleEmail: String = ""

    // Avatar Initial Editing
    @State private var showingEditInitialAlert: Bool = false
    @State private var customInitialInput: String = ""

    // Log Off Confirmation
    @State private var showingLogOutAlert: Bool = false

    // Goals & Calendar
    @State private var selectedCalendarId: String = ""
    @State private var kcalTarget: String = ""
    @State private var proteinTarget: String = ""
    @State private var carbsTarget: String = ""
    @State private var fatTarget: String = ""
    @State private var waterTarget: String = ""

    @State private var availableCalendars: [CalendarSyncService.AvailableCalendarInfo] = []
    @State private var isTestingSync: Bool = false
    @State private var testSyncMessage: String = ""

    public init() {}

    public var body: some View {
        if !accountService.isLoggedIn {
            NutriLoginView()
        } else {
            loggedInProfileView
        }
    }

    // MARK: - Logged In Profile View
    private var loggedInProfileView: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Avatar & Profile Header
                        avatarAndProfileSection

                        // 2. User Account Details
                        userAccountSection

                        // 3. Calendar Sync Section
                        calendarSyncSection

                        // 4. Nutritional Targets
                        personalNutritionalGoalsSection

                        // 5. Streamlined Log Off Action
                        logOutSection

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveChanges()
                        HapticFeedbackService.shared.commitSuccess()
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                }
            }
            .onAppear {
                loadCurrentAccount()
                refreshCalendars()
            }
            .alert("Avatar-Initial anpassen", isPresented: $showingEditInitialAlert) {
                TextField("Initial (z. B. P)", text: $customInitialInput)
                Button("Übernehmen") {
                    accountService.setAvatarInitial(customInitialInput)
                    customInitialInput = ""
                    HapticFeedbackService.shared.lightDetent()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Gib ein Zeichen oder einen Buchstaben für dein Profil-Avatar ein.")
            }
            .alert("Abmelden", isPresented: $showingLogOutAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Abmelden", role: .destructive) {
                    accountService.logOut()
                    HapticFeedbackService.shared.mechanicalClick()
                }
            } message: {
                Text("Möchtest du dich wirklich von diesem Konto abmelden?")
            }
        }
    }

    // MARK: - 1. Avatar & Profile Section
    private var avatarAndProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Theme.sageGreen, lineWidth: 2))

                    Text(accountService.currentAccount.initial)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }

                HStack(spacing: 10) {
                    Button {
                        customInitialInput = accountService.currentAccount.initial
                        showingEditInitialAlert = true
                        HapticFeedbackService.shared.lightDetent()
                    } label: {
                        Text("Ändern")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.bg)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.sageGreen))
                    }

                    Button {
                        accountService.resetAvatarInitial()
                        HapticFeedbackService.shared.lightDetent()
                    } label: {
                        Text("Entfernen")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.warmSand.opacity(0.12)))
                    }
                }

                Spacer()
            }
            .padding(.bottom, 4)

            // Name Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Name (Optional)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                TextField("Name eingeben", text: $displayName)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textPrimary)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }

            // Ziel Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Ziel (Optional)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                TextField("z. B. Hypertrophie & Reha BWK Ulm", text: $userGoal)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textPrimary)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }
        }
        .padding(14)
        .wellnessCard(borderColor: Theme.sageGreen.opacity(0.4))
    }

    // MARK: - 2. User Account Section
    private var userAccountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BENUTZERKONTO")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.sageGreen)
                .tracking(0.6)

            // Benutzername
            VStack(alignment: .leading, spacing: 5) {
                Text("Benutzername (Optional)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                TextField("GRID", text: $username)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }

            // E-Mail
            VStack(alignment: .leading, spacing: 5) {
                Text("E-Mail")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                HStack {
                    Text(accountService.currentAccount.googleAccountEmail)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("Aktiv")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.sageGreen.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }
        }
        .padding(14)
        .wellnessCard()
    }

    // MARK: - 3. Calendar Sync Section
    private var calendarSyncSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GOOGLE KALENDER SYNCHRONISATION")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.sageGreen)
                .tracking(0.6)

            if availableCalendars.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Keine aktiven Google-Kalender gefunden.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    Button("Kalenderberechtigung anfordern") {
                        Task {
                            _ = await calSync.requestAccess()
                            refreshCalendars()
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                }
                .padding(10)
                .background(Theme.surfaceElevated)
                .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zielkalender für Mahlzeiten-Einträge")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)

                    Picker("Kalender", selection: $selectedCalendarId) {
                        Text("Standardkalender").tag("")
                        ForEach(availableCalendars) { cal in
                            Text("\(cal.title) (\(cal.sourceTitle))").tag(cal.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                }

                Button {
                    runSyncTest()
                } label: {
                    HStack(spacing: 6) {
                        if isTestingSync {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.bg))
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(isTestingSync ? "Synchronisiere..." : "Test-Eintrag synchronisieren")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.sageGreen))
                }

                if !testSyncMessage.isEmpty {
                    Text(testSyncMessage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)
                        .padding(8)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .wellnessCard()
    }

    // MARK: - 4. Nutritional Targets
    private var personalNutritionalGoalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ERNÄHRUNGSZIELE & MAKRONÄHRSTOFFE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.sageGreen)
                .tracking(0.6)

            HStack(spacing: 10) {
                goalField(title: "Kalorien (kcal)", text: $kcalTarget)
                goalField(title: "Protein (g)", text: $proteinTarget)
            }

            HStack(spacing: 10) {
                goalField(title: "Kohlenhydrate (g)", text: $carbsTarget)
                goalField(title: "Fett (g)", text: $fatTarget)
            }

            goalField(title: "Wasser-Tagesziel (ml)", text: $waterTarget)
        }
        .padding(14)
        .wellnessCard()
    }

    private func goalField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            TextField("0", text: text)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .keyboardType(.numberPad)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - 5. Streamlined Log Off & Account Switching Section
    private var logOutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KONTOVERWALTUNG & WECHSEL")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.sageGreen)
                .tracking(0.6)

            // Status Badge
            HStack {
                Text(accountService.currentAccount.roleDescription)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(accountService.currentAccount.isPrimaryAccount ? Theme.sageGreen : Theme.warmSand)

                Spacer()

                Text("Sandbox Aktiv")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(10)
            .background(Theme.surfaceElevated)
            .cornerRadius(8)

            // Switch to other saved accounts on this device
            let otherAccounts = accountService.savedAccounts.filter { $0.userKey != accountService.currentAccount.userKey }
            if !otherAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GESPEICHERTE PROFILE (1-TAP WECHSEL)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)

                    ForEach(otherAccounts, id: \.userKey) { acc in
                        Button {
                            accountService.switchToSavedAccount(userKey: acc.userKey)
                            HapticFeedbackService.shared.commitSuccess()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acc.displayName.isEmpty ? acc.username : acc.displayName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)

                                    Text(acc.googleAccountEmail.isEmpty ? "Lokales Profil" : acc.googleAccountEmail)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Spacer()

                                Text("Laden")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.sageGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Theme.sageGreen.opacity(0.12))
                                    .cornerRadius(6)
                            }
                            .padding(10)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(8)
                        }
                    }
                }
            }

            Button {
                showingLogOutAlert = true
                HapticFeedbackService.shared.mechanicalClick()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Abmelden")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.88, green: 0.22, blue: 0.25))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .wellnessCard(borderColor: Theme.warmSand.opacity(0.3))
    }

    private func loadCurrentAccount() {
        let acc = accountService.currentAccount
        self.displayName = acc.displayName
        self.username = acc.username
        self.userGoal = acc.userGoal
        self.googleEmail = acc.googleAccountEmail
        self.selectedCalendarId = acc.selectedCalendarIdentifier ?? ""
        self.kcalTarget = String(format: "%.0f", acc.targetKcal)
        self.proteinTarget = String(format: "%.0f", acc.targetProtein)
        self.carbsTarget = String(format: "%.0f", acc.targetCarbs)
        self.fatTarget = String(format: "%.0f", acc.targetFat)
        self.waterTarget = String(format: "%.0f", acc.targetWaterMl)
    }

    private func refreshCalendars() {
        self.availableCalendars = calSync.getAvailableCalendars()
    }

    private func saveChanges() {
        accountService.updateProfileDetails(
            name: displayName,
            username: username,
            goal: userGoal,
            email: googleEmail
        )

        accountService.updateAccount(
            name: displayName,
            email: googleEmail,
            calendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId,
            kcal: Double(kcalTarget),
            protein: Double(proteinTarget),
            carbs: Double(carbsTarget),
            fat: Double(fatTarget),
            waterMl: Double(waterTarget)
        )
    }

    private func runSyncTest() {
        saveChanges()
        isTestingSync = true
        testSyncMessage = "Synchronisiere Test-Eintrag..."

        Task {
            let result = await calSync.syncTestEvent()
            self.isTestingSync = false
            self.testSyncMessage = result.message
        }
    }
}

// MARK: - Streamlined NutriLoginView (Google-Only Authentication)
public struct NutriLoginView: View {
    @ObservedObject private var accountService = UserAccountService.shared

    @State private var showingAddGoogleAccountSheet: Bool = false
    @State private var newGoogleEmailInput: String = ""
    @State private var newGoogleNameInput: String = ""
    @State private var validationErrorMessage: String = ""
    @State private var showValidationErrorAlert: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Branding Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Google-Anmeldung")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Theme.textPrimary)

                            Text("Growcery • Autorisierter Google-Zugang")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.top, 24)

                        // 1. Primary Action: Instant 1-Tap Sign In with wize.prod6878@gmail.com
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GOOGLE HAUPTKONTO (1-TAP ANMELDUNG)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.sageGreen)
                                .tracking(0.6)

                            Button {
                                loginAsWizeProd()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 34, height: 34)
                                        Text("G")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Als wize.prod6878@gmail.com anmelden")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Parris Campbell • Primäres Entwicklerkonto")
                                            .font(.system(size: 11))
                                            .opacity(0.85)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Theme.sageGreen)
                                .foregroundColor(Theme.bg)
                                .cornerRadius(12)
                            }

                            Text("Verifiziertes Google-Konto auf diesem Gerät. Direkte Anmeldung ohne externe Weiterleitung.")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .wellnessCard()

                        // 2. Saved Accounts on this Device
                        if accountService.savedAccounts.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("GESPEICHERTE GOOGLE-PROFILE AUF DIESEM GERÄT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                                    .tracking(0.6)

                                ForEach(accountService.savedAccounts, id: \.userKey) { acc in
                                    Button {
                                        accountService.switchToSavedAccount(userKey: acc.userKey)
                                        HapticFeedbackService.shared.commitSuccess()
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(acc.isPrimaryAccount ? Theme.sageGreen.opacity(0.15) : Theme.warmSand.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                Text(acc.initial)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(acc.isPrimaryAccount ? Theme.sageGreen : Theme.warmSand)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(acc.displayName.isEmpty ? acc.username : acc.displayName)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)

                                                Text(acc.googleAccountEmail.isEmpty ? acc.roleDescription : "\(acc.googleAccountEmail) • \(acc.roleDescription)")
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(Theme.textSecondary)
                                            }

                                            Spacer()

                                            Text("Aktivieren")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.sageGreen)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Theme.sageGreen.opacity(0.12))
                                                .cornerRadius(6)
                                        }
                                        .padding(12)
                                        .background(Theme.surfaceElevated)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                                    }
                                }

                                Text("Fortschritt und Daten bleiben für jedes Konto strikt getrennt.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .padding(14)
                            .wellnessCard()
                        }

                        // 3. Family / Tester Google Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("FAMILIEN- & TESTER-KONTEN (GOOGLE LOGIN)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.6)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ausschließlich Google-Authentifizierung:")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)

                                Text("Keine Registrierung über E-Mail/Passwort. Nur autorisierte Google-Konten (@gmail.com / @googlemail.com) haben Zugang. Für deine Mutter und Tester ist der vollständige Test-Pass aktiv, ohne dein Hauptkonto wize.prod6878@gmail.com zu überschreiben.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textSecondary)
                                    .lineSpacing(2)
                            }

                            // Preset Option: Mother / Family Tester Google Account
                            Button {
                                loginAsFamilyTester()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.warmSand.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Text("G")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Theme.warmSand)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Mutter / Familie Google-Testkonto")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("Kostenloser Vollzugriff • Isolierte Sandbox")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(Theme.textSecondary)
                                    }

                                    Spacer()

                                    Text("Anmelden")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.warmSand)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.warmSand.opacity(0.12))
                                        .cornerRadius(6)
                                }
                                .padding(12)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.warmSand.opacity(0.3), lineWidth: 1))
                            }

                            // Custom Google Account Input Trigger
                            Button {
                                showingAddGoogleAccountSheet = true
                                HapticFeedbackService.shared.lightDetent()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Weiteres Google-Konto anmelden (@gmail.com)")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }

                        }
                        .padding(14)
                        .wellnessCard()

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Google-Konto hinzufügen", isPresented: $showingAddGoogleAccountSheet) {
                TextField("Google-Adresse (@gmail.com)", text: $newGoogleEmailInput)
                TextField("Name (z. B. Mama)", text: $newGoogleNameInput)
                Button("Anmelden") {
                    handleCustomGoogleLogin()
                }
                Button("Abbrechen", role: .cancel) {
                    newGoogleEmailInput = ""
                    newGoogleNameInput = ""
                }
            } message: {
                Text("Gib die Google-Adresse (@gmail.com oder @googlemail.com) für das neue isolierte Profil ein.")
            }
            .alert("Google-Anmeldung", isPresented: $showValidationErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    private func loginAsWizeProd() {
        accountService.logIn(
            email: "wize.prod6878@gmail.com",
            name: "Parris Campbell",
            username: "wize.prod"
        )
        HapticFeedbackService.shared.commitSuccess()
    }

    private func loginAsFamilyTester() {
        accountService.logIn(
            email: "mama.grow@gmail.com",
            name: "Mama",
            username: "MAMA"
        )
        HapticFeedbackService.shared.commitSuccess()
    }

    private func handleCustomGoogleLogin() {
        let result = accountService.validateAndLogInGoogleAccount(
            email: newGoogleEmailInput,
            name: newGoogleNameInput
        )
        if result.success {
            newGoogleEmailInput = ""
            newGoogleNameInput = ""
            HapticFeedbackService.shared.commitSuccess()
        } else {
            validationErrorMessage = result.message
            showValidationErrorAlert = true
            HapticFeedbackService.shared.alertWarning()
        }
    }
}
