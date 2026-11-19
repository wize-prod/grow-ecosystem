# Future Roadmap Backlog: NutriVault / Growcery

> [!NOTE] ARCHITECTURAL SPECIFICATION & HOLD STATUS
> The following features have been paused on hold and decoupled from active builds to preserve runtime stability, security, and build integrity.

---

## 1. Apple HealthKit Integration

### Status: On Hold (Entitlement Blocked)
* **Root Cause:** Provisioning profile lacks the `com.apple.developer.healthkit` capability. Under iOS sandboxing, querying or writing to `HKHealthStore` without an active entitlement signed by Apple Developer Portal immediately triggers a runtime crash or silent access denial (`Error Domain=com.apple.healthkit Code=4 "Missing com.apple.developer.healthkit entitlement"`).
* **Preconditions for Re-Activation:**
  1. Login to Apple Developer Member Center (`developer.apple.com`).
  2. In Identifiers -> `com.nkembi.nutrivault`, enable the **HealthKit** capability.
  3. Regenerate the `iOS Team Provisioning Profile: com.nkembi.nutrivault` and download/import it into Xcode.
  4. In `NutriVaultApp.entitlements`, add:
     ```xml
     <key>com.apple.developer.healthkit</key>
     <true/>
     <key>com.apple.developer.healthkit.access</key>
     <array/>
     ```
  5. In `Info.plist`, ensure usage descriptions remain present:
     - `NSHealthShareUsageDescription`
     - `NSHealthUpdateUsageDescription`
* **Implementation Blueprint:**
  - `HealthKitService.swift` is already architected to query active energy burned (`HKQuantityTypeIdentifier.activeEnergyBurned`), dietary water (`HKQuantityTypeIdentifier.dietaryWater`), and sleep analysis (`HKCategoryTypeIdentifier.sleepAnalysis`).
  - Once the entitlement is provisioned, `HealthKitService.shared.requestAuthorization()` can be invoked on first launch.

---

## 2. Google OAuth 2.0 Native Authentication

### Status: On Hold (Lax Loopback Redirect Architecture)
* **Root Cause:** Current implementation relied on a local embedded HTTP loopback listener (`http://localhost:8080/oauth2callback`). On iOS devices, background app policies, ATS (App Transport Security), and port binding restrictions render `http://localhost` unreliable, unstable, and insecure.
* **Preconditions for Re-Activation:**
  1. Configure Google Cloud Console OAuth 2.0 Client ID as **iOS Application** (not Web Application):
     - Bundle Identifier: `com.nkembi.nutrivault`
     - Reversed Client ID scheme: `com.googleusercontent.apps.CLIENT_ID`
  2. Implement RFC 8252 (OAuth 2.0 for Native Apps) with **PKCE (Proof Key for Code Exchange)** using Apple's official `ASWebAuthenticationSession`.
* **Implementation Blueprint:**
  - Create a custom URL scheme in `NutriVaultApp-Info.plist`:
    ```xml
    <key>CFBundleURLTypes</key>
    <array>
      <dict>
        <key>CFBundleURLSchemes</key>
        <array>
          <string>com.googleusercontent.apps.CLIENT_ID</string>
        </array>
      </dict>
    </array>
    ```
  - Use `ASWebAuthenticationSession` with `prefersEphemeralWebBrowserSession: false` to complete the token exchange without running a local HTTP server.
  - Store refresh and access tokens securely in the iOS Keychain (`kSecClassGenericPassword`).

