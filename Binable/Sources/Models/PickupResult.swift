import Foundation

// Decodes the binable API response dynamically via typeMap keys.
struct BinableResponse: Decodable {
    let entries: [PickupEntry]

    private struct WasteTypeData: Decodable {
        let dates: [String]
    }

    private struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        let typeMap = try container.decode([String: String].self, forKey: AnyKey(stringValue: "typeMap")!)
        var result: [PickupEntry] = []
        for (typeKey, label) in typeMap {
            guard let key = AnyKey(stringValue: typeKey),
                  let data = try? container.decodeIfPresent(WasteTypeData.self, forKey: key)
            else { continue }
            for date in data.dates {
                result.append(PickupEntry(date: date, label: label))
            }
        }
        self.entries = result
    }
}

struct PickupEntry: Codable, Hashable {
    let date: String
    let label: String

    var parsedDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "de_DE")
        return f.date(from: date)
    }

    var formattedDate: String {
        guard let d = parsedDate else { return date }
        let f = DateFormatter()
        f.dateStyle = .short
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: d)
    }
}

struct LocationPickups: Identifiable {
    let id: UUID
    let location: StoredLocation
    var entries: [PickupEntry]
    var error: String?
    var lastFetched: Date?
    /// True when the displayed entries come from the cache because the latest fetch failed.
    var isStale: Bool = false
}

/// Last successfully fetched pickups for a location, persisted so they survive
/// restarts and network outages.
struct CachedPickups: Codable {
    var entries: [PickupEntry]
    var fetchedAt: Date
}
