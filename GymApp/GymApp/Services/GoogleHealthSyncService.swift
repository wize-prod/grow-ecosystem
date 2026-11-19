import Foundation
import UIKit
import Combine

@MainActor
public final class GoogleHealthSyncService: ObservableObject {
    public static let shared = GoogleHealthSyncService()

    public let targetAccountEmail = "wize.prod6878@gmail.com"

    @Published public var isGoogleFitAppInstalled: Bool = false
    @Published public var isConnected: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTimestamp: Date? = nil
    @Published public var statusMessage: String = "Initialisiere..."

    // Bindung an verifizierte Vital- und Makrodaten aus HealthKit
    @Published public var syncedProteinGrams: Double = 0.0
    @Published public var syncedCaloriesConsumed: Double = 0.0
    @Published public var syncedCarbsGrams: Double = 0.0
    @Published public var syncedFatGrams: Double = 0.0

    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkGoogleFitAvailability()
        observeHealthKitService()
    }

    public func checkGoogleFitAvailability() {
        if let url = URL(string: "googlefit://") {
            self.isGoogleFitAppInstalled = UIApplication.shared.canOpenURL(url)
        } else {
            self.isGoogleFitAppInstalled = false
        }
        updateStatus()
    }

    private func observeHealthKitService() {
        let hk = HealthKitService.shared

        Publishers.CombineLatest4(hk.$isAuthorized, hk.$isSyncing, hk.$lastSyncTimestamp, hk.$statusMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized, syncing, timestamp, hkStatus in
                guard let self = self else { return }
                self.isConnected = authorized
                self.isSyncing = syncing
                self.lastSyncTimestamp = timestamp
                self.updateStatus(hkStatus: hkStatus)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(hk.$todayProteinGrams, hk.$todayCaloriesConsumed, hk.$todayCarbsGrams, hk.$todayFatGrams)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] protein, calories, carbs, fat in
                guard let self = self else { return }
                self.syncedProteinGrams = protein
                self.syncedCaloriesConsumed = calories
                self.syncedCarbsGrams = carbs
                self.syncedFatGrams = fat
            }
            .store(in: &cancellables)
    }

    private func updateStatus(hkStatus: String? = nil) {
        if isConnected {
            if isGoogleFitAppInstalled {
                self.statusMessage = "Google Fit & Apple Health 2-Wege-Sync aktiv (\(targetAccountEmail))."
            } else {
                self.statusMessage = "HealthKit autorisiert. Google Fit synchronisiert automatisch ueber Apple Health."
            }
        } else {
            self.statusMessage = "HealthKit nicht autorisiert. Bitte Berechtigungen freigeben."
        }
    }

    public func openGoogleFitApp() {
        if let url = URL(string: "googlefit://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let appStoreURL = URL(string: "https://apps.apple.com/app/google-fit-activity-tracker/id1433864494") {
            UIApplication.shared.open(appStoreURL)
        }
    }

    public func syncDailyMacros(protein: Double, calories: Double, carbs: Double = 0.0, fat: Double = 0.0) async -> Bool {
        isSyncing = true
        statusMessage = "Schreibe Makros in HealthKit..."

        let success = await HealthKitService.shared.writeDietaryMacros(
            protein: protein,
            calories: calories,
            carbs: carbs,
            fat: fat
        )

        self.isSyncing = false
        if success {
            self.lastSyncTimestamp = Date()
            updateStatus()
            HapticFeedback.success()
        }
        return success
    }

    public func refreshData() {
        HealthKitService.shared.fetchAllHealthData()
    }
}
