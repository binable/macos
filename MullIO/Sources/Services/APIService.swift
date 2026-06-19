import Foundation

enum APIError: LocalizedError {
    case networkError(Error)
    case httpError(Int)
    case decodingError(Error)
    case noLocations

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Netzwerkfehler: \(e.localizedDescription)"
        case .httpError(let code): return "Server-Fehler (HTTP \(code))"
        case .decodingError:       return "Antwort konnte nicht gelesen werden"
        case .noLocations:         return "Keine Standorte konfiguriert"
        }
    }
}

actor APIService {

    static let shared = APIService()

    private let baseURL = "https://xn--mll-hoa.io/api/fetch"
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

        if let key = apiKey, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
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
            throw APIError.httpError(0)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(MullIOResponse.self, from: data).entries
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
