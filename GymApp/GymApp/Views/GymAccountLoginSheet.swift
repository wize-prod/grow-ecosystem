import SwiftUI
import EventKit
import AuthenticationServices

public struct GymAccountLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userAccount = UserAccountService.shared
    @ObservedObject private var calendarSync = CalendarSyncService.shared

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

    // Calendar
    @State private var selectedCalendarId: String = ""
    @State private var availableCalendars: [GymAvailableCalendarInfo] = []

    public init() {}

    public var body: some View {
        if !userAccount.isLoggedIn {
            GymLoginView()
        } else {
            loggedInProfileView
        }
    }

    // MARK: - Logged In Profile View
    private var loggedInProfileView: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Avatar & Profile Section
                        avatarAndProfileSection

                        // 2. User Account Section
                        userAccountSection

                        // 3. Calendar Selection Section
                        calendarSelectionSection

                        // 4. Streamlined Log Off Action
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
                    .foregroundColor(GymTheme.textMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveAndDismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(GymTheme.strongBlue)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
            .alert("Avatar-Initial anpassen", isPresented: $showingEditInitialAlert) {
                TextField("Initial (z. B. P)", text: $customInitialInput)
                Button("Übernehmen") {
                    userAccount.setAvatarInitial(customInitialInput)
                    customInitialInput = ""
                    HapticFeedback.light()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Gib ein Zeichen oder einen Buchstaben für dein Profil-Avatar ein.")
            }
            .alert("Abmelden", isPresented: $showingLogOutAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Abmelden", role: .destructive) {
                    userAccount.logOut()
                    HapticFeedback.medium()
                }
            } message: {
                Text("Möchtest du dich wirklich von diesem Konto abmelden?")
            }
        }
    }

    private func loadCurrentValues() {
        let acc = userAccount.currentAccount
        self.displayName = acc.displayName
        self.username = acc.username
        self.userGoal = acc.userGoal
        self.googleEmail = acc.googleAccountEmail
        self.selectedCalendarId = acc.selectedCalendarIdentifier ?? ""
        self.availableCalendars = calendarSync.getAvailableCalendars()
    }

    private func saveAndDismiss() {
        userAccount.updateProfileDetails(
            name: displayName,
            username: username,
            goal: userGoal,
            email: googleEmail
        )

        userAccount.updateAccount(
            name: displayName,
            email: googleEmail,
            calendarId: selectedCalendarId.isEmpty ? nil : selectedCalendarId
        )

        Task {
            if calendarSync.isAuthorized {
                await calendarSync.fetchUpcomingWorkouts()
            }
        }

        HapticFeedback.success()
        dismiss()
    }

    // MARK: - 1. Avatar & Profile Section
    private var avatarAndProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(GymTheme.surfaceElevated)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(GymTheme.strongBlue, lineWidth: 2))

                    Text(userAccount.currentAccount.initial)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }

                HStack(spacing: 10) {
                    Button {
                        customInitialInput = userAccount.currentAccount.initial
                        showingEditInitialAlert = true
                        HapticFeedback.light()
                    } label: {
                        Text("Ändern")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(GymTheme.strongBlue))
                    }

                    Button {
                        userAccount.resetAvatarInitial()
                        HapticFeedback.light()
                    } label: {
                        Text("Entfernen")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.warmSand)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(GymTheme.warmSand.opacity(0.12)))
                    }
                }

                Spacer()
            }
            .padding(.bottom, 4)

            // Name Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Name (Optional)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)

                TextField("Name eingeben", text: $displayName)
                    .font(.system(size: 14))
                    .foregroundColor(GymTheme.textPrimary)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(GymTheme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            // Ziel Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Ziel (Optional)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)

                TextField("z. B. Hypertrophie & Reha BWK Ulm", text: $userGoal)
                    .font(.system(size: 14))
                    .foregroundColor(GymTheme.textPrimary)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(GymTheme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }
        }
        .padding(14)
        .somaCard()
    }

    // MARK: - 2. User Account Section
    private var userAccountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BENUTZERKONTO")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.strongBlue)
                .tracking(0.6)

            // Benutzername
            VStack(alignment: .leading, spacing: 5) {
                Text("Benutzername (Optional)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)

                TextField("GRID", text: $username)
                    .font(.system(size: 14))
                    .foregroundColor(GymTheme.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(GymTheme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }

            // E-Mail
            VStack(alignment: .leading, spacing: 5) {
                Text("E-Mail")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)

                HStack {
                    Text(userAccount.currentAccount.googleAccountEmail)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                    Spacer()
                    Text("Aktiv")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.strongBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GymTheme.strongBlue.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(GymTheme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
            }
        }
        .padding(14)
        .somaCard()
    }

    // MARK: - 3. Calendar Selection Section
    private var calendarSelectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GOOGLE KALENDER WORKOUT-SYNC")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.strongBlue)
                .tracking(0.6)

            if availableCalendars.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Keine aktiven Google-Kalender gefunden.")
                        .font(.system(size: 12))
                        .foregroundColor(GymTheme.textSecondary)
                    Button("Kalenderberechtigung anfordern") {
                        Task {
                            _ = await calendarSync.requestAccess()
                            loadCurrentValues()
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GymTheme.strongBlue)
                }
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zielkalender für Workouts & Regeneration")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GymTheme.textSecondary)

                    Picker("Kalender", selection: $selectedCalendarId) {
                        Text("Standardkalender").tag("")
                        ForEach(availableCalendars) { cal in
                            Text("\(cal.title) (\(cal.sourceTitle))").tag(cal.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(GymTheme.surfaceElevated))
                }
            }
        }
        .padding(14)
        .somaCard()
    }

    // MARK: - 4. Streamlined Log Off & Account Switching Section
    private var logOutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KONTOVERWALTUNG & WECHSEL")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.strongBlue)
                .tracking(0.6)

            // Status Badge
            HStack {
                Text(userAccount.currentAccount.roleDescription)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(userAccount.currentAccount.isPrimaryAccount ? GymTheme.strongBlue : GymTheme.warmSand)

                Spacer()

                Text("Sandbox Aktiv")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)
            }
            .padding(10)
            .background(GymTheme.surfaceElevated)
            .cornerRadius(8)

            // Switch to other saved accounts on this device
            let otherAccounts = userAccount.savedAccounts.filter { $0.userKey != userAccount.currentAccount.userKey }
            if !otherAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GESPEICHERTE PROFILE (1-TAP WECHSEL)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)

                    ForEach(otherAccounts, id: \.userKey) { acc in
                        Button {
                            userAccount.switchToSavedAccount(userKey: acc.userKey)
                            HapticFeedback.success()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acc.displayName.isEmpty ? acc.username : acc.displayName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(GymTheme.textPrimary)

                                    Text(acc.googleAccountEmail.isEmpty ? "Lokales Profil" : acc.googleAccountEmail)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(GymTheme.textSecondary)
                                }

                                Spacer()

                                Text("Laden")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(GymTheme.strongBlue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(GymTheme.strongBlue.opacity(0.12))
                                    .cornerRadius(6)
                            }
                            .padding(10)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(8)
                        }
                    }
                }
            }

            Button {
                showingLogOutAlert = true
                HapticFeedback.medium()
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
        .somaCard()
    }
}

// MARK: - Streamlined GymLoginView (Google-Only Authentication)
public struct GymLoginView: View {
    @ObservedObject private var userAccount = UserAccountService.shared
    @ObservedObject private var googleAuth = GoogleOAuthWebSessionManager.shared

    @State private var showingAddGoogleAccountSheet: Bool = false
    @State private var newGoogleEmailInput: String = ""
    @State private var newGoogleNameInput: String = ""
    @State private var validationErrorMessage: String = ""
    @State private var showValidationErrorAlert: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Branding Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Google-Anmeldung")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(GymTheme.textPrimary)

                            Text("Grow Athletics • Autorisierter Google-Zugang")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(GymTheme.textSecondary)
                        }
                        .padding(.top, 24)

                        // 1. Primary Action: Instant 1-Tap Google Sign In with wize.prod6878@gmail.com
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GOOGLE HAUPTKONTO (1-TAP ANMELDUNG)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.strongBlue)
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
                                .background(GymTheme.strongBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Text("Verifiziertes Google-Konto auf diesem Gerät. Direkte Anmeldung ohne externe Weiterleitung.")
                                .font(.system(size: 11))
                                .foregroundColor(GymTheme.textMuted)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .somaCard()

                        // 2. Saved Google Accounts on this Device
                        if userAccount.savedAccounts.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("GESPEICHERTE GOOGLE-PROFILE AUF DIESEM GERÄT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .tracking(0.6)

                                ForEach(userAccount.savedAccounts, id: \.userKey) { acc in
                                    Button {
                                        userAccount.switchToSavedAccount(userKey: acc.userKey)
                                        HapticFeedback.success()
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(acc.isPrimaryAccount ? GymTheme.strongBlue.opacity(0.15) : GymTheme.warmSand.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                Text(acc.initial)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(acc.isPrimaryAccount ? GymTheme.strongBlue : GymTheme.warmSand)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(acc.displayName.isEmpty ? acc.username : acc.displayName)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(GymTheme.textPrimary)

                                                Text(acc.googleAccountEmail.isEmpty ? acc.roleDescription : "\(acc.googleAccountEmail) • \(acc.roleDescription)")
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(GymTheme.textSecondary)
                                            }

                                            Spacer()

                                            Text("Aktivieren")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(GymTheme.strongBlue)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(GymTheme.strongBlue.opacity(0.12))
                                                .cornerRadius(6)
                                        }
                                        .padding(12)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
                                    }
                                }

                                Text("Fortschritt und Daten bleiben für jedes Konto strikt getrennt.")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(GymTheme.textMuted)
                            }
                            .padding(14)
                            .somaCard()
                        }

                        // 3. Family / Tester Google Sign-In Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("FAMILIEN- & TESTER-KONTEN (GOOGLE LOGIN)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.warmSand)
                                .tracking(0.6)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ausschließlich Google-Authentifizierung:")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.textPrimary)

                                Text("Keine Registrierung über E-Mail/Passwort. Nur autorisierte Google-Konten (@gmail.com / @googlemail.com) haben Zugang. Für deine Mutter und Tester ist der vollständige Test-Pass aktiv, ohne dein Hauptkonto wize.prod6878@gmail.com zu überschreiben.")
                                    .font(.system(size: 11))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .lineSpacing(2)
                            }

                            // Preset Option: Mother / Family Tester Google Account
                            Button {
                                loginAsFamilyTester()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(GymTheme.warmSand.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Text("G")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(GymTheme.warmSand)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Mutter / Familie Google-Testkonto")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(GymTheme.textPrimary)
                                        Text("Kostenloser Vollzugriff • Isolierte Sandbox")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(GymTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text("Anmelden")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(GymTheme.warmSand)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(GymTheme.warmSand.opacity(0.12))
                                        .cornerRadius(6)
                                }
                                .padding(12)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.warmSand.opacity(0.3), lineWidth: 1))
                            }

                            // Custom Google Account Input Trigger
                            Button {
                                showingAddGoogleAccountSheet = true
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Weiteres Google-Konto anmelden (@gmail.com)")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(GymTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
                            }

                            Divider()
                                .background(GymTheme.border.opacity(0.6))
                                .padding(.vertical, 2)

                            // Optional Web OAuth Flow
                            Button {
                                startGoogleSignInFlow()
                            } label: {
                                HStack(spacing: 8) {
                                    if googleAuth.isAuthenticating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: GymTheme.textSecondary))
                                    } else {
                                        Text("G")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    Text(googleAuth.isAuthenticating ? "Verbinde..." : "Über Google Web-Login verbinden")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(GymTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .disabled(googleAuth.isAuthenticating)
                        }
                        .padding(14)
                        .somaCard()

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
        userAccount.logIn(
            email: "wize.prod6878@gmail.com",
            name: "Parris Campbell",
            username: "wize.prod"
        )
        HapticFeedback.success()
    }

    private func loginAsFamilyTester() {
        userAccount.createOrSwitchToFamilyMember(
            name: "Mama",
            email: "mama.grow@gmail.com",
            goal: "Vitalität & Mobilität",
            targetKcal: 1600,
            targetProtein: 80,
            targetCarbs: 180,
            targetFat: 50,
            targetWaterMl: 2000
        )
        HapticFeedback.success()
    }

    private func handleCustomGoogleLogin() {
        let result = userAccount.validateAndLogInGoogleAccount(
            email: newGoogleEmailInput,
            name: newGoogleNameInput
        )
        if result.success {
            newGoogleEmailInput = ""
            newGoogleNameInput = ""
            HapticFeedback.success()
        } else {
            validationErrorMessage = result.message
            showValidationErrorAlert = true
            HapticFeedback.medium()
        }
    }

    private func startGoogleSignInFlow() {
        HapticFeedback.medium()
        googleAuth.startGoogleSignIn { result in
            switch result {
            case .success(let profile):
                userAccount.logIn(email: profile.email, name: profile.name)
                HapticFeedback.success()
            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == ASWebAuthenticationSessionErrorDomain &&
                    nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    return
                }
                self.validationErrorMessage = "Google Web-Login fehlgeschlagen: \(error.localizedDescription). Du kannst dich direkt oben mit deinem Google-Konto anmelden."
                self.showValidationErrorAlert = true
            }
        }
    }
}
