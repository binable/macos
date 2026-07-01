import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    private let locationsKey   = "storedLocations"
    private let frequencyKey   = "fetchFrequency"
    private let apiKeyKey      = "apiKey"
    private let launchAtLoginKey = "launchAtLogin"

    @Published var locations: [StoredLocation] {
        didSet { save() }
    }

    @Published var fetchFrequency: FetchFrequency {
        didSet {
            UserDefaults.standard.set(fetchFrequency.rawValue, forKey: frequencyKey)
        }
    }

    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: launchAtLoginKey)
            LaunchAtLoginService.shared.setEnabled(launchAtLogin)
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([StoredLocation].self, from: data) {
            locations = decoded
        } else {
            locations = []
        }

        let rawFreq = UserDefaults.standard.string(forKey: frequencyKey) ?? ""
        fetchFrequency = FetchFrequency(rawValue: rawFreq) ?? .daily

        apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        launchAtLogin = UserDefaults.standard.bool(forKey: launchAtLoginKey)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(data, forKey: locationsKey)
        }
    }
}
