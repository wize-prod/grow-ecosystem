import Foundation
import UIKit
import Combine

@MainActor
public final class GrowcerySyncService: ObservableObject {
    public static let shared = GrowcerySyncService()

    @Published public var syncState: GrowcerySyncState = GrowcerySyncState()
    @Published public var supplementState: SharedSupplementPayload = SharedSupplementPayload()
    @Published public var isGrowceryInstalled: Bool = false
    @Published public var syncStatusMessage: String = "Bereit fuer Synchronisation."
    @Published public var showGrowceryNotFoundAlert: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkGrowceryAvailability()
        observeHealthKit()
        setupLifecycleObservers()
        applySharedMacrosBridgeData()
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }

    public func checkGrowceryAvailability() {
        if let url = URL(string: "growcery://") {
            isGrowceryInstalled = UIApplication.shared.canOpenURL(url)
        }
    }

    private func observeHealthKit() {
        let health = HealthKitService.shared

        // Beobachte alle 4 Makros und Vitalwerte
        Publishers.CombineLatest4(health.$todayProteinGrams, health.$todayCaloriesConsumed, health.$todayCarbsGrams, health.$todayFatGrams)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] protein, calories, carbs, fat in
                guard let self = self else { return }
                // Wenn SharedMacrosBridge noch keine Daten hat oder HealthKit hoehere Werte liefert
                if self.syncState.caloriesConsumed <= 0 || calories > self.syncState.caloriesConsumed {
                    self.syncState.caloriesConsumed = calories
                }
                if self.syncState.proteinConsumedGrams <= 0 || protein > self.syncState.proteinConsumedGrams {
                    self.syncState.proteinConsumedGrams = protein
                }
                if self.syncState.carbsConsumedGrams <= 0 || carbs > self.syncState.carbsConsumedGrams {
                    self.syncState.carbsConsumedGrams = carbs
                }
                if self.syncState.fatConsumedGrams <= 0 || fat > self.syncState.fatConsumedGrams {
                    self.syncState.fatConsumedGrams = fat
                }
                self.syncState.restingHeartRateBpm = health.restingHeartRate
                self.syncState.activeCaloriesBurnedToday = health.activeEnergyBurnedToday
                self.syncState.lastSyncTimestamp = Date()
            }
            .store(in: &cancellables)
    }

    public func refreshData() {
        HealthKitService.shared.fetchAllHealthData()
        applySharedMacrosBridgeData()
        syncStatusMessage = "Ernaehrungsdaten aktualisiert."
    }

    public func applyIncomingMacros(protein: Double, calories: Double, carbs: Double, fat: Double) {
        syncState.proteinConsumedGrams = protein
        syncState.caloriesConsumed = calories
        syncState.carbsConsumedGrams = carbs
        syncState.fatConsumedGrams = fat
        syncState.lastSyncTimestamp = Date()
        syncStatusMessage = "Direktsynchronisation erfolgreich."
    }

    private func applySharedMacrosBridgeData() {
        self.supplementState = GrowSuiteBridge.shared.loadSupplements()

        // Water Hydration Sync
        let waterPayload = GrowSuiteBridge.shared.loadWater()
        if waterPayload.totalWaterMl > 0 {
            GymStore.shared.syncWaterFromBridge()
        }

        guard let payload = GrowSuiteBridge.shared.loadMacros() else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        // Nur Daten des heutigen Tages uebernehmen
        if payload.dateString == todayString || abs(payload.timestamp.timeIntervalSinceNow) < 86400 {
            syncState.proteinConsumedGrams = payload.protein
            syncState.caloriesConsumed = payload.calories
            syncState.carbsConsumedGrams = payload.carbs
            syncState.fatConsumedGrams = payload.fat
            if payload.proteinTarget > 0 { syncState.proteinTargetGrams = payload.proteinTarget }
            if payload.caloriesTarget > 0 { syncState.caloriesBudget = payload.caloriesTarget }
            syncState.lastSyncTimestamp = payload.timestamp
        }
    }

    public func isSupplementTaken(doseId: String) -> Bool {
        return supplementState.takenDoseIds[doseId] != nil
    }

    public func toggleSupplement(doseId: String) {
        let currentlyTaken = isSupplementTaken(doseId: doseId)
        GrowSuiteBridge.shared.markSupplement(doseId: doseId, isTaken: !currentlyTaken)
        self.supplementState = GrowSuiteBridge.shared.loadSupplements()
        HapticFeedback.selection()
    }

    public func openGrowcery(context: String = "dashboard") {
        guard let deepLink = URL(string: "growcery://open?source=gym&context=\(context)") else {
            showGrowceryNotFoundAlert = true
            return
        }

        UIApplication.shared.open(deepLink, options: [:]) { [weak self] success in
            if success {
                self?.syncStatusMessage = "Growcery geoeffnet."
                return
            }

            // Fallback 1: base growcery://
            if let base = URL(string: "growcery://") {
                UIApplication.shared.open(base, options: [:]) { baseSuccess in
                    if baseSuccess {
                        self?.syncStatusMessage = "Growcery geoeffnet."
                        return
                    }

                    // Fallback 2: nutrivault://
                    if let nv = URL(string: "nutrivault://") {
                        UIApplication.shared.open(nv, options: [:]) { nvSuccess in
                            if nvSuccess {
                                self?.syncStatusMessage = "Growcery geoeffnet."
                            } else {
                                self?.showGrowceryNotFoundAlert = true
                            }
                        }
                    } else {
                        self?.showGrowceryNotFoundAlert = true
                    }
                }
            } else {
                self?.showGrowceryNotFoundAlert = true
            }
        }
    }

    // Handshake fuer eingehende grow:// und gym:// URL-Aufrufe
    public func handleIncomingURL(_ url: URL) -> UUID? {
        guard url.scheme == "gym" || url.scheme == "grow" else { return nil }

        let host = url.host
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        if host == "syncMacros" {
            let p = Double(queryItems?.first(where: { $0.name == "protein" })?.value ?? "0") ?? 0
            let k = Double(queryItems?.first(where: { $0.name == "calories" || $0.name == "kcal" })?.value ?? "0") ?? 0
            let c = Double(queryItems?.first(where: { $0.name == "carbs" })?.value ?? "0") ?? 0
            let f = Double(queryItems?.first(where: { $0.name == "fat" })?.value ?? "0") ?? 0
            applyIncomingMacros(protein: p, calories: k, carbs: c, fat: f)
            return nil
        }

        if host == "start" || host == "workout" {
            if let idString = queryItems?.first(where: { $0.name == "templateId" || $0.name == "id" })?.value,
               let uuid = UUID(uuidString: idString) {
                return uuid
            }
        }
        return nil
    }
}
