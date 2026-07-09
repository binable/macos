import SwiftUI

struct AboutView: View {

    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)

            Text("Binable")
                .font(.largeTitle.bold())

            Text("Version \(version)")
                .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 6) {
                Text("Deine Abfuhrtermine — immer dabei.")
                    .multilineTextAlignment(.center)

                Text("binable verbindet dich mit den offiziellen Abfuhrdaten deines Landkreises oder deiner Stadt. Über 300 Standorte in Deutschland, Österreich und der Schweiz.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .padding(.horizontal)

            Divider()

            HStack(spacing: 20) {
                Link("Website", destination: URL(string: "https://binable.app")!)
                Link("Datenschutz", destination: URL(string: "https://binable.app/datenschutz")!)
                Link("Impressum", destination: URL(string: "https://binable.app/impressum")!)
            }
            .font(.callout)
        }
        .padding(30)
        .frame(width: 380)
    }
}
