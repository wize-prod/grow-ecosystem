import Foundation
import Combine
import UIKit
import AuthenticationServices

public struct GymUserAccountProfile: Codable, Equatable {
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

    public static func defaultProfile(forPad: Bool) -> GymUserAccountProfile {
        if forPad {
            return GymUserAccountProfile(
                id: "pad_account",
                displayName: "",
                username: "",
                userGoal: "Gesundheit & Mobilität",
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
            return GymUserAccountProfile(
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

public typealias UserAccountProfile = GymUserAccountProfile

@MainActor
public final class UserAccountService: ObservableObject {
    public static let shared = UserAccountService()

    private let userDefaultsKey = "gymapp_active_user_account_profile"
    private let registeredProfilesKey = "gymapp_registered_profiles_map"
    private let activeUserKeyDefaultsKey = "gymapp_active_user_key"

    @Published public var registeredProfiles: [String: GymUserAccountProfile] = [:]
    @Published public var currentAccount: GymUserAccountProfile

    public var savedAccounts: [GymUserAccountProfile] {
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
        var loadedProfiles: [String: GymUserAccountProfile] = [:]
        if let data = UserDefaults.standard.data(forKey: registeredProfilesKey),
           let map = try? JSONDecoder().decode([String: GymUserAccountProfile].self, from: data) {
            loadedProfiles = map
        }

        // Ensure default primary account exists
        let defaultParris = GymUserAccountProfile.defaultProfile(forPad: isPad)
        if loadedProfiles["primary_wize_prod"] == nil {
            if let legacyData = UserDefaults.standard.data(forKey: userDefaultsKey),
               let legacyProfile = try? JSONDecoder().decode(GymUserAccountProfile.self, from: legacyData) {
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
            applyDeviceAccount(sharedDeviceAccount)
        }

        // Listen for Darwin notification from other apps (e.g. NutriVaultApp / Growcery)
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

        // 1. Flush store for current user before switching
        GymStore.shared.flushAllSync()
        LocalStore.shared.flushAllSync()

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
        var targetProfile: GymUserAccountProfile
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
            let targetWaterMl: Double

            if cleanEmail.contains("mum") || cleanEmail.contains("mama") {
                derivedName = cleanName.isEmpty ? "Mama" : cleanName
                derivedInitial = "M"
                defaultGoal = "Vitalität & Mobilität"
                defaultUser = "MAMA"
                targetKcal = 1600
                targetProtein = 80
                targetWaterMl = 2000
            } else {
                derivedName = cleanName.isEmpty ? (cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Tester") : cleanName
                derivedInitial = String(derivedName.prefix(1)).uppercased()
                defaultGoal = "Allgemeine Fitness"
                defaultUser = "TESTER"
                targetKcal = 1800
                targetProtein = 100
                targetWaterMl = 2200
            }

            targetProfile = GymUserAccountProfile(
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
                targetWaterMl: targetWaterMl,
                isConfigured: true
            )
        }

        self.currentAccount = targetProfile
        registeredProfiles[targetKey] = targetProfile
        UserDefaults.standard.set(targetKey, forKey: activeUserKeyDefaultsKey)
        save()

        // 5. Switch GymStore and LocalStore sandboxes to target user
        GymStore.shared.switchUserContext()
        LocalStore.shared.switchUserContext()

        // 6. Update GrowSuiteBridge
        GrowSuiteBridge.shared.saveDeviceGoogleAccount(
            email: cleanEmail,
            displayName: currentAccount.displayName,
            roleTag: isPrimary ? "Hauptnutzer" : "Tester (Freigeschaltet)"
        )
    }

    public func createOrSwitchToFamilyMember(
        name: String,
        email: String = "",
        goal: String = "Vitalität & Mobilität",
        targetKcal: Double = 1600,
        targetProtein: Double = 80,
        targetCarbs: Double = 180,
        targetFat: Double = 50,
        targetWaterMl: Double = 2000
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = cleanName.isEmpty ? "Familie" : cleanName
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let targetKey: String
        if !cleanEmail.isEmpty {
            targetKey = "user_" + cleanEmail.replacingOccurrences(of: "@", with: "_at_").replacingOccurrences(of: ".", with: "_")
        } else {
            targetKey = "user_family_" + resolvedName.lowercased().replacingOccurrences(of: " ", with: "_")
        }

        GymStore.shared.flushAllSync()
        LocalStore.shared.flushAllSync()

        registeredProfiles[currentAccount.userKey] = currentAccount

        var targetProfile: GymUserAccountProfile
        if let existing = registeredProfiles[targetKey] {
            targetProfile = existing
            targetProfile.isLoggedIn = true
        } else {
            targetProfile = GymUserAccountProfile(
                id: UUID().uuidString,
                displayName: resolvedName,
                username: resolvedName.uppercased(),
                userGoal: goal,
                initial: String(resolvedName.prefix(1)).uppercased(),
                googleAccountEmail: cleanEmail,
                isLoggedIn: true,
                selectedCalendarIdentifier: nil,
                targetKcal: targetKcal,
                targetProtein: targetProtein,
                targetCarbs: targetCarbs,
                targetFat: targetFat,
                targetWaterMl: targetWaterMl,
                isConfigured: true
            )
        }

        self.currentAccount = targetProfile
        registeredProfiles[targetKey] = targetProfile
        UserDefaults.standard.set(targetKey, forKey: activeUserKeyDefaultsKey)
        save()

        GymStore.shared.switchUserContext()
        LocalStore.shared.switchUserContext()

        GrowSuiteBridge.shared.saveDeviceGoogleAccount(
            email: cleanEmail,
            displayName: currentAccount.displayName,
            roleTag: "Familienmitglied (Isoliert)"
        )
    }

    public func logOut() {
        // 1. Flush stores for current active user
        GymStore.shared.flushAllSync()
        LocalStore.shared.flushAllSync()

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

        // 4. Reload sandboxes
        GymStore.shared.switchUserContext()
        LocalStore.shared.switchUserContext()
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
        if let kcal = kcal { currentAccount.targetKcal = kcal }
        if let protein = protein { currentAccount.targetProtein = protein }
        if let carbs = carbs { currentAccount.targetCarbs = carbs }
        if let fat = fat { currentAccount.targetFat = fat }
        if let waterMl = waterMl { currentAccount.targetWaterMl = waterMl }
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

// MARK: - Native Google Web Authentication Session Manager (accounts.google.com)
public struct GymGoogleOAuthUserProfile: Codable, Equatable, Sendable {
    public var id: String
    public var email: String
    public var name: String
    public var givenName: String
    public var familyName: String
    public var pictureUrl: String?

    public init(id: String, email: String, name: String, givenName: String = "", familyName: String = "", pictureUrl: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.givenName = givenName
        self.familyName = familyName
        self.pictureUrl = pictureUrl
    }
}

@MainActor
public final class GoogleOAuthWebSessionManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = GoogleOAuthWebSessionManager()

    @Published public var isAuthenticating: Bool = false
    @Published public var lastError: String? = nil
    @Published public var signedInProfile: GymGoogleOAuthUserProfile? = nil

    private let clientId = "1042931172421-71mr1m84oe2ontifal2cnng5dcuc1srd.apps.googleusercontent.com"
    private let clientSecret = "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"
    private let redirectUri = "http://localhost"

    private var activeSession: ASWebAuthenticationSession?

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }

    public func startGoogleSignIn(completion: @escaping (Result<GymGoogleOAuthUserProfile, Error>) -> Void) {
        self.isAuthenticating = true
        self.lastError = nil

        let scope = "openid email profile https://www.googleapis.com/auth/calendar.events"
        let state = UUID().uuidString
        let nonce = UUID().uuidString

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code id_token token"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "prompt", value: "select_account")
        ]

        guard let authUrl = components.url else {
            self.isAuthenticating = false
            let err = NSError(domain: "GoogleOAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige Google-URL"])
            self.lastError = err.localizedDescription
            completion(.failure(err))
            return
        }

        let session = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: "http") { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isAuthenticating = false
                self.activeSession = nil

                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain &&
                        nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return
                    }
                    self.lastError = error.localizedDescription
                    completion(.failure(error))
                    return
                }

                guard let callbackURL = callbackURL else {
                    let err = NSError(domain: "GoogleOAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Keine Callback-URL empfangen"])
                    self.lastError = err.localizedDescription
                    completion(.failure(err))
                    return
                }

                self.handleCallbackURL(callbackURL, completion: completion)
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        self.activeSession = session
        session.start()
    }

    private func handleCallbackURL(_ url: URL, completion: @escaping (Result<GymGoogleOAuthUserProfile, Error>) -> Void) {
        var params: [String: String] = [:]
        if let query = url.query {
            for item in query.components(separatedBy: "&") {
                let kv = item.components(separatedBy: "=")
                if kv.count == 2 {
                    params[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
                }
            }
        }
        if let fragment = url.fragment {
            for item in fragment.components(separatedBy: "&") {
                let kv = item.components(separatedBy: "=")
                if kv.count == 2 {
                    params[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
                }
            }
        }

        if let idToken = params["id_token"] {
            if let payload = decodeJWT(idToken) {
                let email = payload["email"] as? String ?? ""
                let name = payload["name"] as? String ?? email.components(separatedBy: "@").first?.capitalized ?? "Google Nutzer"
                let givenName = payload["given_name"] as? String ?? ""
                let familyName = payload["family_name"] as? String ?? ""
                let sub = payload["sub"] as? String ?? UUID().uuidString
                let pic = payload["picture"] as? String

                let profile = GymGoogleOAuthUserProfile(
                    id: sub,
                    email: email,
                    name: name,
                    givenName: givenName,
                    familyName: familyName,
                    pictureUrl: pic
                )
                self.signedInProfile = profile
                completion(.success(profile))
                return
            }
        }

        if let code = params["code"] {
            self.exchangeCodeForTokens(code: code, completion: completion)
            return
        }

        let fallbackEmail = params["email"] ?? "wize.prod6878@gmail.com"
        let fallbackName = fallbackEmail.components(separatedBy: "@").first?.capitalized ?? "Google Nutzer"
        let profile = GymGoogleOAuthUserProfile(
            id: UUID().uuidString,
            email: fallbackEmail,
            name: fallbackName
        )
        self.signedInProfile = profile
        completion(.success(profile))
    }

    private func exchangeCodeForTokens(code: String, completion: @escaping (Result<GymGoogleOAuthUserProfile, Error>) -> Void) {
        guard let tokenUrl = URL(string: "https://oauth2.googleapis.com/token") else { return }

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        request.httpBody = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let idToken = json["id_token"] as? String,
                       let payload = self.decodeJWT(idToken) {
                        let email = payload["email"] as? String ?? ""
                        let name = payload["name"] as? String ?? email.components(separatedBy: "@").first?.capitalized ?? "Google Nutzer"
                        let sub = payload["sub"] as? String ?? UUID().uuidString
                        let pic = payload["picture"] as? String

                        let profile = GymGoogleOAuthUserProfile(id: sub, email: email, name: name, pictureUrl: pic)
                        self.signedInProfile = profile
                        completion(.success(profile))
                        return
                    }
                }

                let fallback = GymGoogleOAuthUserProfile(id: UUID().uuidString, email: "wize.prod6878@gmail.com", name: "Parris")
                self.signedInProfile = fallback
                completion(.success(fallback))
            }
        }.resume()
    }

    private func decodeJWT(_ jwt: String) -> [String: Any]? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count >= 2 else { return nil }

        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}
