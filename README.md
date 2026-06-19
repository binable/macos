# müll.io — macOS Menu Bar App

Native macOS Menu Bar App, die Abfuhrtermine von [müll.io](https://müll.io) anzeigt.

## Voraussetzungen

- macOS 15 (Sequoia) oder neuer
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & Run

### Schnellstart (CLI)

```bash
./build.sh
```

Das Script generiert das Xcode-Projekt, baut die App und signiert sie. Die App liegt danach unter:
`~/Library/Developer/Xcode/DerivedData/MullIO-*/Build/Products/Debug/müll.io.app`

Zum Starten:
```bash
open ~/Library/Developer/Xcode/DerivedData/MullIO-*/Build/Products/Debug/müll.io.app
```

### Manuell (Schritt für Schritt)

```bash
# 1. Xcode-Projekt generieren
cd MullIO && xcodegen generate

# 2. Bauen (ohne Signing — siehe Hinweis unten)
xcodebuild \
  -project MullIO.xcodeproj \
  -scheme MullIO \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

# 3. App signieren (zwei Schritte nötig)
APP=$(find ~/Library/Developer/Xcode/DerivedData/MullIO-*/Build/Products/Debug -name "*.app" | head -1)
codesign --force --sign - "$APP/Contents/MacOS/müll.io"
codesign --force --sign - "$APP"

# 4. Starten
open "$APP"
```

### In Xcode öffnen

```bash
cd MullIO && xcodegen generate
open MullIO.xcodeproj
```

### Hinweis: Signing auf macOS 26 (Tahoe)

Auf macOS 26 fügt Xcodes Build-System `-no_adhoc_codesign` zum Linker hinzu, sodass das
Binary absichtlich unsigniert bleibt und eine explizite Signing-Step erwartet. `codesign`
verweigert auf macOS 26 das Signieren eines App-Bundles, wenn das enthaltene Binary
noch keine Signatur trägt — der Bundle muss daher in zwei Schritten signiert werden
(erst Binary, dann Bundle). Das `build.sh` Script übernimmt das automatisch.

Wenn macOS Gatekeeper die heruntergeladene App blockiert:
```bash
xattr -cr /path/to/müll.io.app
```

## Release

Ein neues Release wird durch einen Git-Tag ausgelöst:

```bash
git tag 1.0.0
git push origin 1.0.0
```

Die GitHub Action baut die App automatisch in der Release-Konfiguration, signiert sie
(ad-hoc) und hängt ein ZIP-Archiv an das GitHub Release.

## Funktionen

- **Menu Bar Icon** (Mülleimer) — kein Dock-Icon, kein App-Switcher
- **Nächste Abfuhrtermine** pro Standort direkt im Menü
- **Mehrere Standorte** konfigurierbar (Straße, PLZ, Stadt, Land)
- **Fetch-Frequenz** einstellbar: 12 Stunden, täglich, 2-tägig
- **Launch at Login** via `SMAppService`
- **Optionaler API-Key** für müll.io-Accounts mit API-Zugriff

## API

Die App ruft `POST https://müll.io/api/fetch` auf:

```json
{
  "street": "Musterstraße",
  "houseNumber": "1",
  "zip": "12345",
  "city": "Berlin",
  "country": "DE"
}
```

## Projekt-Struktur

```
mull-io-macos/
├── build.sh                         CLI-Build-Script
├── .github/workflows/release.yml   GitHub Action (Tag → Release)
└── MullIO/
    ├── project.yml                  XcodeGen-Spec
    └── Sources/
        ├── App/
        │   ├── MullIOApp.swift      @main, NSApplicationDelegateAdaptor
        │   └── MenuBarController.swift  NSStatusItem + NSMenu + Fensterverwaltung
        ├── Models/
        │   ├── StoredLocation.swift
        │   ├── PickupResult.swift
        │   ├── FetchFrequency.swift
        │   └── AppSettings.swift    UserDefaults-Wrapper
        ├── Services/
        │   ├── APIService.swift     müll.io REST-Client
        │   ├── PickupStore.swift    @MainActor Datenhaltung + Auto-Refresh
        │   └── LaunchAtLoginService.swift  SMAppService-Wrapper
        ├── Views/
        │   ├── SettingsView.swift   Tabs: Standorte + Allgemein
        │   ├── AddLocationView.swift Sheet zum Hinzufügen
        │   └── AboutView.swift
        └── Resources/
            ├── Info.plist           LSUIElement = YES
            ├── MullIO.entitlements
            └── Assets.xcassets/
```
