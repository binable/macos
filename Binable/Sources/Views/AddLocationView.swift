import SwiftUI

struct AddLocationView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared

    @State private var label = ""
    @State private var street = ""
    @State private var houseNumber = ""
    @State private var zip = ""
    @State private var city = ""
    @State private var country = "DE"

    private var isValid: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty &&
        !houseNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !zip.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !country.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Standort hinzufügen")
                .font(.headline)
                .padding([.horizontal, .top], 20)
                .padding(.bottom, 16)

            Form {
                TextField("Bezeichnung (z. B. Zuhause)", text: $label)

                Divider()

                TextField("Straße *", text: $street)
                TextField("Hausnummer *", text: $houseNumber)
                TextField("PLZ *", text: $zip)
                TextField("Stadt *", text: $city)

                Picker("Land *", selection: $country) {
                    Text("Deutschland (DE)").tag("DE")
                    Text("Österreich (AT)").tag("AT")
                    Text("Schweiz (CH)").tag("CH")
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Abbrechen", role: .cancel) { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Hinzufügen") {
                    let loc = StoredLocation(
                        label: label,
                        street: street,
                        houseNumber: houseNumber,
                        zip: zip,
                        city: city,
                        country: country
                    )
                    settings.locations.append(loc)
                    dismiss()
                }
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(20)
        }
        .frame(width: 420)
    }
}
