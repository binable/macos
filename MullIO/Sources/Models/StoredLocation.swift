import Foundation

struct StoredLocation: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var label: String
    var street: String
    var houseNumber: String
    var zip: String
    var city: String
    var country: String

    var displayName: String {
        label.isEmpty ? "\(street) \(houseNumber), \(zip) \(city)" : label
    }
}
