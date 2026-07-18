import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var cancellables = Set<AnyCancellable>()

    private var settingsWindow: NSWindow?

    private let websiteURL = URL(string: "https://binable.app")!

    override init() {
        super.init()
        setupStatusItem()
        observeStore()
        PickupStore.shared.refresh()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Binable")
        statusItem.button?.image?.isTemplate = true

        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    private func observeStore() {
        PickupStore.shared.$results
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        PickupStore.shared.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
    }

    func rebuildMenu() {
        menu.removeAllItems()

        let store = PickupStore.shared

        if store.isLoading {
            menu.addItem(NSMenuItem(title: "Lade Termine…", action: nil, keyEquivalent: ""))
        } else if AppSettings.shared.locations.isEmpty {
            let item = NSMenuItem(title: "Keine Standorte konfiguriert", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else if store.results.isEmpty {
            let item = NSMenuItem(title: "Noch keine Daten – bitte aktualisieren", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for result in store.results {
                addLocationSection(result)
            }
        }

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "Aktualisieren", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        if let refreshDate = store.lastRefresh {
            let f = RelativeDateTimeFormatter()
            f.locale = Locale(identifier: "de_DE")
            refreshItem.toolTip = "Zuletzt: \(f.localizedString(for: refreshDate, relativeTo: Date()))"
        }
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Einstellungen…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: "Über Binable", action: #selector(openWebsite), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    private func addLocationSection(_ result: LocationPickups) {
        let headerItem = NSMenuItem(title: result.location.displayName, action: nil, keyEquivalent: "")
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        headerItem.attributedTitle = NSAttributedString(string: result.location.displayName, attributes: attrs)
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        if let error = result.error {
            let errItem = NSMenuItem(title: "  ⚠ \(error)", action: nil, keyEquivalent: "")
            errItem.isEnabled = false
            menu.addItem(errItem)
        } else if result.entries.isEmpty {
            let emptyItem = NSMenuItem(title: "  Keine Termine gefunden", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for entry in result.entries {
                let icon = wasteIcon(for: entry.label)
                let title = "  \(icon)  \(entry.formattedDate)  –  \(entry.label)"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
    }

    private func wasteIcon(for label: String) -> String {
        let lower = label.lowercased()
        if lower.contains("restmüll") || lower.contains("restmuell") || lower.contains("rest") { return "🗑️" }
        if lower.contains("bio") || lower.contains("braun") { return "🟤" }
        if lower.contains("papier") || lower.contains("blau") || lower.contains("altpapier") { return "📦" }
        if lower.contains("gelb") || lower.contains("wertstoff") || lower.contains("leichtverpackung") { return "🟡" }
        if lower.contains("glas") { return "🟢" }
        if lower.contains("sperr") || lower.contains("sperrmüll") { return "📦" }
        if lower.contains("grün") || lower.contains("garten") || lower.contains("laub") { return "🌿" }
        return "♻️"
    }

    @objc private func refreshNow() {
        PickupStore.shared.refresh()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView()
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "Einstellungen"
            window.styleMask = [.titled, .closable]
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openWebsite() {
        NSWorkspace.shared.open(websiteURL)
    }

    // NSMenuDelegate — refresh data when user opens the menu
    nonisolated func menuWillOpen(_ menu: NSMenu) {
        Task { @MainActor in
            PickupStore.shared.refresh()
        }
    }
}
