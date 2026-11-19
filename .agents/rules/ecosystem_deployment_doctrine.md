# Ecosystem Deployment Doctrine: Autonome App-Kompilierung & Installation

## Verbindliches Mandat
1. **Autonomes Deployment:** Sobald Code-Aenderungen, Bugfixes, UI-Anpassungen oder Feature-Erweiterungen an einer oder mehreren Apps im Workspace (GrowWorkspace: NutriVaultApp, GrowFinance, GymApp, GrowStudy etc.) vorgenommen werden, ist der Agent verpflichtet, die betreffenden Applikationen ohne gesonderte Nutzeraufforderung eigenstaendig zu kompilieren (xcodebuild) und direkt auf dem physischen Referenzgeraet (iPhone 16 Pro Max, UDID: 00008140-001E292E0062201C) zu installieren.
2. **Befehlsstruktur fuer Builds:**
   Standard-Build-Aufruf mit Entwicklungszertifikat:
   xcodebuild -project <AppName>/<AppName>.xcodeproj -scheme <AppName> -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="Apple Development" DEVELOPMENT_TEAM=X83D9W2G74 build OTHER_SWIFT_FLAGS="-disable-sandbox"
3. **Befehlsstruktur fuer Device-Installation:**
   Installation via Apple devicectl:
   xcrun devicectl device install app --device 00008140-001E292E0062201C <Pfad_zum_Debug-iphoneos_App_Bundle>
4. **Kein Zwischenstopp:** Eine Aufgabe gilt erst dann als abgeschlossen, wenn das Deployment auf dem physischen Zielgeraet mit Exit-Code 0 verifiziert wurde.
