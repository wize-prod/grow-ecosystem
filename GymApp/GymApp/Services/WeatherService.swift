import Foundation
import CoreLocation
import SwiftUI
import Combine

public struct WeatherData: Codable, Equatable, Sendable {
    public let temperature: Double
    public let highTemp: Double
    public let lowTemp: Double
    public let rainProbability: Int
    public let weatherCode: Int
    public let locationName: String
    public let timestamp: Date

    public var sfSymbolName: String {
        switch weatherCode {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "snowflake"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}

private struct OpenMeteoResponse: Codable {
    struct Current: Codable {
        let temperature_2m: Double
        let weather_code: Int
    }
    struct Daily: Codable {
        let temperature_2m_max: [Double]?
        let temperature_2m_min: [Double]?
        let precipitation_probability_max: [Int]?
    }

    let current: Current?
    let daily: Daily?
}

@MainActor
public final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = WeatherService()

    @Published public var currentWeather: WeatherData?
    @Published public var isUpdating: Bool = false
    @Published public var lastErrorMessage: String? = nil

    private let locationManager = CLLocationManager()
    private let userDefaultsKey = "cached_grow_weather"
    private var lastFetchTime: Date?
    private var geocoder = CLGeocoder()
    private var currentLocationName: String = "Standort"
    private var updateTimer: AnyCancellable?

    override private init() {
        super.init()
        loadCachedWeather()
        setupLocationManager()
        setupPeriodicTimer()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1500.0 // Update every 1.5 km of movement
        
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    private func setupPeriodicTimer() {
        // Automatically check and refresh weather every 20 minutes (1200 seconds)
        updateTimer = Timer.publish(every: 1200.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
    }

    // MARK: - CLLocationManagerDelegate
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                self.refresh()
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            // Limit network updates to at most once every 10 minutes unless forced
            if let last = self.lastFetchTime, Date().timeIntervalSince(last) < 600.0 {
                return
            }
            self.fetchWeatherForLocation(location)
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastErrorMessage = error.localizedDescription
            // Keep existing cached weather intact on failure
        }
    }

    // MARK: - Weather Fetching via Open-Meteo API
    public func refresh() {
        if let location = locationManager.location {
            fetchWeatherForLocation(location)
        } else {
            locationManager.requestLocation()
        }
    }

    private func fetchWeatherForLocation(_ location: CLLocation) {
        isUpdating = true
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Reverse geocoding to get city/town name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality ?? placemarks?.first?.name {
                Task { @MainActor in
                    self?.currentLocationName = city
                }
            }
        }

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(String(format: "%.4f", lat))&longitude=\(String(format: "%.4f", lon))&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto"

        guard let url = URL(string: urlString) else {
            isUpdating = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12.0
        request.cachePolicy = .reloadIgnoringLocalCacheData

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    await MainActor.run {
                        self.isUpdating = false
                    }
                    return
                }

                let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

                guard let current = decoded.current else {
                    await MainActor.run {
                        self.isUpdating = false
                    }
                    return
                }

                let temp = current.temperature_2m
                let code = current.weather_code
                let high = decoded.daily?.temperature_2m_max?.first ?? temp
                let low = decoded.daily?.temperature_2m_min?.first ?? temp
                let rainProb = decoded.daily?.precipitation_probability_max?.first ?? 0

                let weather = WeatherData(
                    temperature: temp,
                    highTemp: high,
                    lowTemp: low,
                    rainProbability: rainProb,
                    weatherCode: code,
                    locationName: self.currentLocationName,
                    timestamp: Date()
                )

                await MainActor.run {
                    self.currentWeather = weather
                    self.lastFetchTime = Date()
                    self.isUpdating = false
                    self.saveWeatherToCache(weather)
                }
            } catch {
                await MainActor.run {
                    self.isUpdating = false
                    self.lastErrorMessage = error.localizedDescription
                    // Do not clear currentWeather; offline cache is retained!
                }
            }
        }
    }

    // MARK: - Offline Caching
    private func saveWeatherToCache(_ weather: WeatherData) {
        if let data = try? JSONEncoder().encode(weather) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadCachedWeather() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let cached = try? JSONDecoder().decode(WeatherData.self, from: data) {
            self.currentWeather = cached
        }
    }
}
