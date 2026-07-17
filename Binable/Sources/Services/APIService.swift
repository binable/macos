import Foundation

enum APIError: LocalizedError {
    case networkError(Error)
    case httpError(Int, String?)
    case decodingError(Error)
    case noLocations

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Netzwerkfehler: \(e.localizedDescription)"
        case .httpError(let code, let message):
            let base: String
            switch code {
            case 404:      base = "Für diese Adresse wurde kein Abfuhrkalender gefunden (HTTP 404)"
            case 401, 403: base = "API-Schlüssel ungültig oder fehlt (HTTP \(code))"
            case 429:      base = "Zu viele Anfragen – bitte API-Schlüssel hinterlegen oder später erneut versuchen (HTTP 429)"
            default:       base = "Server-Fehler (HTTP \(code))"
            }
            if let message, !message.isEmpty {
                return "\(base): \(message)"
            }
            return base
        case .decodingError:       return "Antwort konnte nicht gelesen werden"
        case .noLocations:         return "Keine Standorte konfiguriert"
        }
    }
}

actor APIService {

    static let shared = APIService()

    private let baseURL = "https://binable.app/api/fetch"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }

    func fetchPickups(for location: StoredLocation, apiKey: String?) async throws -> [PickupEntry] {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            request.setValue("ApiKey \(key)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: String] = [
            "street": location.street,
            "houseNumber": location.houseNumber,
            "zip": location.zip,
            "city": location.city,
            "country": location.country
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.httpError(0, nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode, Self.serverMessage(from: data))
        }

        do {
            return try JSONDecoder().decode(BinableResponse.self, from: data).entries
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Extracts the server's error explanation (e.g. {"error": "..."}) so it can be surfaced instead of a bare status code.
    private static func serverMessage(from data: Data) -> String? {
        if let obj = try? JSONDecoder().decode([String: String].self, from: data),
           let message = obj["error"], !message.isEmpty {
            return message
        }
        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return String(trimmed.prefix(200)) }
        }
        return nil
    }
}
