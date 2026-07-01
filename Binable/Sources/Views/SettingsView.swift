import SwiftUI
import ServiceManagement

struct SettingsView: View {

    @ObservedObject private var settings = AppSettings.shared
    @State private var showAddSheet = false

    var body: some View {
        TabView {
            locationsTab
                .tabItem { Label("Standorte", systemImage: "mappin.and.ellipse") }
            generalTab
                .tabItem { Label("Allgemein", systemImage: "gear") }
        }
        .padding(20)
        .frame(width: 520, height: 400)
        .sheet(isPresented: $showAddSheet) {
            AddLocationView()
        }
    }

    private var locationsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if settings.locations.isEmpty {
                ContentUnavailableView(
                    "Keine Standorte",
                    systemImage: "mappin.slash",
                    description: Text("Füge einen Standort hinzu, um Abfuhrtermine zu sehen.")
                )
            } else {
                List {
                    ForEach(settings.locations) { loc in
                        LocationRow(location: loc)
                    }
                    .onDelete { offsets in
                        settings.locations.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        settings.locations.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.inset)
            }
            HStack {
                Spacer()
                Button("Standort hinzufügen", systemImage: "plus") {
                    showAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var generalTab: some View {
        Form {
            Section {
                Picker("Aktualisierung", selection: $settings.fetchFrequency) {
                    ForEach(FetchFrequency.allCases) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Beim Systemstart öffnen", isOn: $settings.launchAtLogin)
            }

            Section("API (optional)") {
                SecureField("API-Key (optional)", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                Text("Nur erforderlich wenn dein Account API-Zugriff benötigt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct LocationRow: View {
    let location: StoredLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(location.label.isEmpty ? "Standort" : location.label)
                .font(.headline)
            Text("\(location.street) \(location.houseNumber), \(location.zip) \(location.city) (\(location.country))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
