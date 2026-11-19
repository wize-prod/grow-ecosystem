import Foundation
import Combine
import UIKit
import AuthenticationServices

public struct UserAccountProfile: Codable, Equatable {
    public var id: String
    public var displayName: String
    public var username: String
    public var userGoal: String
    public var initial: String
    public var googleAccountEmail: String
    public var isLoggedIn: Bool
    public var selectedCalendarIdentifier: String?
    public var targetKcal: Double
    public var targetProtein: Double
    public var targetCarbs: Double
    public var targetFat: Double
    public var targetWaterMl: Double
    public var isConfigured: Bool

    public var userKey: String {
        let clean = googleAccountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean.isEmpty || clean == "wize.prod6878@gmail.com" {
            return "primary_wize_prod"
        }
        return "user_" + clean.replacingOccurrences(of: "@", with: "_at_").replacingOccurrences(of: ".", with: "_")
    }

    public var isPrimaryAccount: Bool {
        return userKey == "primary_wize_prod"
    }

    public var roleDescription: String {
        if isPrimaryAccount {
            return "Hauptnutzer • Inhaber"
        } else {
            return "Tester • Kostenloser Vollzugriff"
        }
    }

    public enum CodingKeys: String, CodingKey {
        case id, displayName, username, userGoal, initial, googleAccountEmail
        case isLoggedIn, selectedCalendarIdentifier
        case targetKcal, targetProtein, targetCarbs, targetFat, targetWaterMl, isConfigured
    }

    public init(
        id: String,
        displayName: String,
        username: String = "GRID",
        userGoal: String = "Hypertrophie & Reha BWK Ulm",
        initial: String = "P",
        googleAccountEmail: String = "",
        isLoggedIn: Bool = false,
        selectedCalendarIdentifier: String? = nil,
        targetKcal: Double = 1950,
        targetProtein: Double = 160,
        targetCarbs: Double = 180,
        targetFat: Double = 50,
        targetWaterMl: Double = 2500,
        isConfigured: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.userGoal = userGoal
        self.initial = initial
        self.googleAccountEmail = googleAccountEmail
        self.isLoggedIn = isLoggedIn
        self.selectedCalendarIdentifier = selectedCalendarIdentifier
        self.targetKcal = targetKcal
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.targetWaterMl = targetWaterMl
        self.isConfigured = isConfigured
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.displayName = try c.decode(String.self, forKey: .displayName)
        self.username = (try? c.decode(String.self, forKey: .username)) ?? "GRID"
        self.userGoal = (try? c.decode(String.self, forKey: .userGoal)) ?? "Hypertrophie & Reha BWK Ulm"
        self.initial = (try? c.decode(String.self, forKey: .initial)) ?? "P"
        let email = (try? c.decode(String.self, forKey: .googleAccountEmail)) ?? ""
        self.googleAccountEmail = email
        self.isLoggedIn = (try? c.decode(Bool.self, forKey: .isLoggedIn)) ?? (!email.trimmingCharacters(in: .whitespaces).isEmpty)
        self.selectedCalendarIdentifier = try? c.decode(String.self, forKey: .selectedCalendarIdentifier)
        self.targetKcal = (try? c.decode(Double.self, forKey: .targetKcal)) ?? 1950
        self.targetProtein = (try? c.decode(Double.self, forKey: .targetProtein)) ?? 160
        self.targetCarbs = (try? c.decode(Double.self, forKey: .targetCarbs)) ?? 180
        self.targetFat = (try? c.decode(Double.self, forKey: .targetFat)) ?? 50
        self.targetWaterMl = (try? c.decode(Double.self, forKey: .targetWaterMl)) ?? 2500
        self.isConfigured = (try? c.decode(Bool.self, forKey: .isConfigured)) ?? true
    }

    public static func defaultProfile(forPad: Bool) -> UserAccountProfile {
        if forPad {
            return UserAccountProfile(
                id: "pad_account",
                displayName: "",
                username: "",
                userGoal: "Gesundheit & Vitalität",
                initial: "U",
                googleAccountEmail: "",
                isLoggedIn: false,
                selectedCalendarIdentifier: nil,
                targetKcal: 1800,
                targetProtein: 75,
                targetCarbs: 220,
                targetFat: 60,
                targetWaterMl: 2000,
                isConfigured: false
            )
        } else {
            return UserAccountProfile(
                id: "parris_account",
                displayName: "parris",
                username: "GRID",
                userGoal: "Hypertrophie & Reha BWK Ulm",
                initial: "P",
                googleAccountEmail: "wize.prod6878@gmail.com",
                isLoggedIn: true,
                selectedCalendarIdentifier: nil,
                targetKcal: 1950,
                targetProtein: 160,
                targetCarbs: 180,
                targetFat: 50,
                targetWaterMl: 2500,
                isConfigured: true
            )
        }
    }
}

@MainActor
public final class UserAccountService: ObservableObject {
    public static let shared = UserAccountService()

    private let userDefaultsKey = "nutrivault_active_user_account_profile"
    private let registeredProfilesKey = "nutrivault_registered_profiles_map"
    private let activeUserKeyDefaultsKey = "nutrivault_active_user_key"

    @Published public var registeredProfiles: [String: UserAccountProfile] = [:]
    @Published public var currentAccount: UserAccountProfile

    public var savedAccounts: [UserAccountProfile] {
        return Array(registeredProfiles.values).sorted { a, b in
            if a.userKey == "primary_wize_prod" { return true }
            if b.userKey == "primary_wize_prod" { return false }
            return a.displayName < b.displayName
        }
    }

    public var isLoggedIn: Bool {
        return currentAccount.isLoggedIn && !currentAccount.googleAccountEmail.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private init() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        var loadedProfiles: [String: UserAccountProfile] = [:]
        if let data = UserDefaults.standard.data(forKey: registeredProfilesKey),
           let map = try? JSONDecoder().decode([String: UserAccountProfile].self, from: data) {
            loadedProfiles = map
        }

        let defaultParris = UserAccountProfile.defaultProfile(forPad: isPad)
        if loadedProfiles["primary_wize_prod"] == nil {
            if let legacyData = UserDefaults.standard.data(forKey: userDefaultsKey),
               let legacyProfile = try? JSONDecoder().decode(UserAccountProfile.self, from: legacyData) {
                loadedProfiles[legacyProfile.userKey] = legacyProfile
            } else {
                loadedProfiles["primary_wize_prod"] = defaultParris
            }
        }
        self.registeredProfiles = loadedProfiles

        let savedActiveKey = UserDefaults.standard.string(forKey: activeUserKeyDefaultsKey) ?? "primary_wize_prod"
        if let active = loadedProfiles[savedActiveKey] {
            self.currentAccount = active
        } else if let parris = loadedProfiles["primary_wize_prod"] {
            self.currentAccount = parris
        } else {
            self.currentAccount = defaultParris
        }
        save()

        // Check if an existing device-assigned account exists in keychain / bridge
        if let sharedDeviceAccount = GrowSuiteBridge.shared.loadDeviceGoogleAccount(),
           !sharedDeviceAccount.email.isEmpty {
            let cleanEmail = sharedDeviceAccount.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !cleanEmail.isEmpty {
                let targetKey = (cleanEmail == "wize.prod6878@gmail.com") ? "primary_wize_prod" : ("user_" + cleanEmail.replacingOccurrences(of: "@", with: "_at_").replacingOccurrences(of: ".", with: "_"))
                if let existing = loadedProfiles[targetKey] {
                    var mod = existing
                    mod.isLoggedIn = true
                    mod.googleAccountEmail = cleanEmail
                    self.currentAccount = mod
                    self.registeredProfiles[targetKey] = mod
                    UserDefaults.standard.set(targetKey, forKey: activeUserKeyDefaultsKey)
                }
            }
        }

        // Listen for Darwin notification from other apps (e.g. GymApp / Grow)
        DarwinNotificationCenter.observe(DarwinNotificationCenter.deviceGoogleAccountUpdated) { [weak self] in
            guard let self = self else { return }
            if let sharedDeviceAccount = GrowSuiteBridge.shared.loadDeviceGoogleAccount() {
                self.applyDeviceAccount(sharedDeviceAccount)
            }
        }
    }

    private func applyDeviceAccount(_ devicePayload: SharedDeviceGoogleAccountPayload) {
        let cleanEmail = devicePayload.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanEmail.isEmpty {
            if currentAccount.isLoggedIn {
                currentAccount.isLoggedIn = false
                save()
            }
            return
        }

        if currentAccount.googleAccountEmail != cleanEmail || !currentAccount.isLoggedIn {
            self.logIn(
                email: cleanEmail,
                name: devicePayload.displayName,
                username: ""
            )
        }
    }

    public func logIn(email: String, name: String = "", username: String = "") {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else { return }

        // 1. Flush store for current active user before switching
        if LocalStore.isSharedInitialized {
            LocalStore.shared.flushAllSync()
        }

        // 2. Persist current account into registry
        registeredProfiles[currentAccount.userKey] = currentAccount

        // 3. Resolve target key
        let targetKey: String
        let isPrimary = cleanEmail == "wize.prod6878@gmail.com"
        if isPrimary {
            targetKey = "primary_wize_prod"
        } else {
            targetKey = "user_" + cleanEmail.replacingOccurrences(of: "@", with: "_at_").replacingOccurrences(of: ".", with: "_")
        }

        // 4. Retrieve or create target profile
        var targetProfile: UserAccountProfile
        if let existing = registeredProfiles[targetKey] {
            targetProfile = existing
            targetProfile.isLoggedIn = true
            targetProfile.googleAccountEmail = cleanEmail
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanName.isEmpty {
                targetProfile.displayName = cleanName
                targetProfile.initial = String(cleanName.prefix(1)).uppercased()
            }
        } else {
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let derivedName: String
            let derivedInitial: String
            let defaultGoal: String
            let defaultUser: String
            let targetKcal: Double
            let targetProtein: Double

            if cleanEmail.contains("mum") || cleanEmail.contains("mama") {
                derivedName = cleanName.isEmpty ? "Mama" : cleanName
                derivedInitial = "M"
                defaultGoal = "Vitalität & Ausgewogene Ernährung"
                defaultUser = "MAMA"
                targetKcal = 1800
                targetProtein = 110
            } else {
                derivedName = cleanName.isEmpty ? (cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Tester") : cleanName
                derivedInitial = String(derivedName.prefix(1)).uppercased()
                defaultGoal = "Gesunde Ernährung & Wohlbefinden"
                defaultUser = "TESTER"
                targetKcal = 2000
                targetProtein = 130
            }

            targetProfile = UserAccountProfile(
                id: UUID().uuidString,
                displayName: derivedName,
                username: username.isEmpty ? defaultUser : username,
                userGoal: defaultGoal,
                initial: derivedInitial,
                googleAccountEmail: cleanEmail,
                isLoggedIn: true,
                selectedCalendarIdentifier: nil,
                targetKcal: targetKcal,
                targetProtein: targetProtein,
                targetCarbs: 200,
                targetFat: 55,
                targetWaterMl: 2200,
                isConfigured: true
            )
        }

        self.currentAccount = targetProfile
        registeredProfiles[targetKey] = targetProfile
        UserDefaults.standard.set(targetKey, forKey: activeUserKeyDefaultsKey)
        save()

        // 5. Switch LocalStore sandbox to target user
        if LocalStore.isSharedInitialized {
            LocalStore.shared.switchUserContext()
        }

        // 6. Update GrowSuiteBridge
        GrowSuiteBridge.shared.saveDeviceGoogleAccount(
            email: cleanEmail,
            displayName: currentAccount.displayName,
            roleTag: isPrimary ? "Hauptnutzer" : "Tester (Freigeschaltet)"
        )
    }

    public func logOut() {
        // 1. Flush store for current active user
        if LocalStore.isSharedInitialized {
            LocalStore.shared.flushAllSync()
        }

        // 2. Mark profile logged out in registry, without deleting data
        currentAccount.isLoggedIn = false
        registeredProfiles[currentAccount.userKey] = currentAccount
        save()

        // 3. Clear bridge active account
        GrowSuiteBridge.shared.saveDeviceGoogleAccount(
            email: "",
            displayName: currentAccount.displayName,
            roleTag: "Abgemeldet"
        )
    }

    public static func isGoogleAccount(_ email: String) -> Bool {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard clean.contains("@") else { return false }
        let domain = clean.components(separatedBy: "@").last ?? ""
        return domain == "gmail.com" || domain == "googlemail.com" || domain.contains("google")
    }

    public func validateAndLogInGoogleAccount(email: String, name: String = "", username: String = "") -> (success: Bool, message: String) {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else {
            return (false, "Bitte gib eine Google-E-Mail-Adresse ein.")
        }
        guard Self.isGoogleAccount(clean) else {
            return (false, "Nur Google-Konten (@gmail.com oder @googlemail.com) sind für den Login zugelassen.")
        }
        logIn(email: clean, name: name, username: username)
        return (true, "")
    }

    public func switchToSavedAccount(userKey: String) {
        guard let target = registeredProfiles[userKey] else { return }
        let emailToUse = target.googleAccountEmail.isEmpty && userKey == "primary_wize_prod" ? "wize.prod6878@gmail.com" : target.googleAccountEmail
        logIn(email: emailToUse, name: target.displayName, username: target.username)
    }

    public func updateProfileDetails(
        name: String,
        username: String,
        goal: String,
        email: String,
        initial: String? = nil
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanName.isEmpty {
            currentAccount.displayName = cleanName
        }
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanUsername.isEmpty {
            currentAccount.username = cleanUsername
        }
        let cleanGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        currentAccount.userGoal = cleanGoal

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !cleanEmail.isEmpty {
            currentAccount.googleAccountEmail = cleanEmail
            currentAccount.isLoggedIn = true
        }

        if let initVal = initial, !initVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentAccount.initial = String(initVal.prefix(1)).uppercased()
        } else if !cleanName.isEmpty {
            currentAccount.initial = String(cleanName.prefix(1)).uppercased()
        }

        currentAccount.isConfigured = true
        save()

        if !cleanEmail.isEmpty {
            GrowSuiteBridge.shared.saveDeviceGoogleAccount(
                email: cleanEmail,
                displayName: currentAccount.displayName,
                roleTag: "Benutzer"
            )
        }
    }

    public func updateAccount(
        name: String,
        email: String,
        calendarId: String?,
        kcal: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        waterMl: Double? = nil
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            currentAccount.displayName = trimmedName
            currentAccount.initial = String(trimmedName.prefix(1)).uppercased()
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedEmail.isEmpty {
            currentAccount.googleAccountEmail = trimmedEmail
            currentAccount.isLoggedIn = true
        }
        currentAccount.selectedCalendarIdentifier = calendarId
        if let k = kcal, k > 0 { currentAccount.targetKcal = k }
        if let p = protein, p > 0 { currentAccount.targetProtein = p }
        if let c = carbs, c > 0 { currentAccount.targetCarbs = c }
        if let f = fat, f > 0 { currentAccount.targetFat = f }
        if let w = waterMl, w > 0 { currentAccount.targetWaterMl = w }
        currentAccount.isConfigured = true
        save()

        if !trimmedEmail.isEmpty {
            GrowSuiteBridge.shared.saveDeviceGoogleAccount(
                email: trimmedEmail,
                displayName: currentAccount.displayName,
                roleTag: "Benutzer"
            )
        }
    }

    public func setAvatarInitial(_ newInitial: String) {
        let clean = newInitial.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            currentAccount.initial = String(clean.prefix(1)).uppercased()
            save()
        }
    }

    public func resetAvatarInitial() {
        let name = currentAccount.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            currentAccount.initial = String(name.prefix(1)).uppercased()
        } else {
            currentAccount.initial = "P"
        }
        save()
    }

    public func resetAccount() {
        logOut()
    }

    public func simulatePasswordReset(for target: String) -> String {
        let clean = target.trimmingCharacters(in: .whitespacesAndNewlines)
        let destination = clean.contains("@") ? clean : (currentAccount.googleAccountEmail.isEmpty ? "\(clean)@googlemail.com" : currentAccount.googleAccountEmail)
        return "Anweisungen zum Zurücksetzen des Passworts wurden an \(destination) gesendet."
    }

    public func save() {
        registeredProfiles[currentAccount.userKey] = currentAccount
        if let regData = try? JSONEncoder().encode(registeredProfiles) {
            UserDefaults.standard.set(regData, forKey: registeredProfilesKey)
        }
        if let data = try? JSONEncoder().encode(currentAccount) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        UserDefaults.standard.set(currentAccount.userKey, forKey: activeUserKeyDefaultsKey)
    }
}
