import Foundation

enum FetchFrequency: String, CaseIterable, Identifiable {
    case twelveHours = "12h"
    case daily = "daily"
    case twoDays = "2days"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twelveHours: return "Alle 12 Stunden"
        case .daily: return "Täglich"
        case .twoDays: return "Alle 2 Tage"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .twelveHours: return 12 * 3_600
        case .daily:       return 24 * 3_600
        case .twoDays:     return 48 * 3_600
        }
    }
}
