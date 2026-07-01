# binable — macOS Menu Bar App

Native macOS menu bar app that shows waste-collection dates from [binable](https://binable.app).

## Requirements

- macOS 15 (Sequoia) or newer
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & Run

### Quick start (CLI)

```bash
./build.sh
```

The script generates the Xcode project, builds the app and signs it. The app is then located at:
`~/Library/Developer/Xcode/DerivedData/Binable-*/Build/Products/Debug/binable.app`

To launch it:
```bash
open ~/Library/Developer/Xcode/DerivedData/Binable-*/Build/Products/Debug/binable.app
```

### Manual (step by step)

```bash
# 1. Generate the Xcode project
cd Binable && xcodegen generate

# 2. Build (without signing — see the note below)
xcodebuild \
  -project Binable.xcodeproj \
  -scheme Binable \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

# 3. Sign the app (two steps required)
APP=$(find ~/Library/Developer/Xcode/DerivedData/Binable-*/Build/Products/Debug -name "*.app" | head -1)
codesign --force --sign - "$APP/Contents/MacOS/binable"
codesign --force --sign - "$APP"

# 4. Launch
open "$APP"
```

### Open in Xcode

```bash
cd Binable && xcodegen generate
open Binable.xcodeproj
```

### Note: Signing on macOS 26 (Tahoe)

On macOS 26 Xcode's build system adds `-no_adhoc_codesign` to the linker, so the
binary is intentionally left unsigned and an explicit signing step is expected. On
macOS 26 `codesign` refuses to sign an app bundle while the enclosed binary is still
unsigned — the bundle therefore has to be signed in two steps (first the binary, then
the bundle). The `build.sh` script does this automatically.

If macOS Gatekeeper blocks the downloaded app:
```bash
xattr -cr /path/to/binable.app
```

## Release

A new release is triggered by a Git tag:

```bash
git tag 1.0.0
git push origin 1.0.0
```

The GitHub Action automatically builds the app in the release configuration, signs it
(ad-hoc) and attaches a ZIP archive to the GitHub release.

## Features

- **Menu bar icon** (trash can) — no Dock icon, no app switcher
- **Upcoming collection dates** per location right in the menu
- **Multiple locations** configurable (street, ZIP, city, country)
- **Fetch frequency** adjustable: 12 hours, daily, every 2 days
- **Launch at login** via `SMAppService`
- **Optional API key** for binable accounts with API access

## API

The app calls `POST https://binable.app/api/fetch`:

```json
{
  "street": "Musterstraße",
  "houseNumber": "1",
  "zip": "12345",
  "city": "Berlin",
  "country": "DE"
}
```

## Project structure

```
binable-macos/
├── build.sh                         CLI build script
├── .github/workflows/release.yml   GitHub Action (tag → release)
└── Binable/
    ├── project.yml                  XcodeGen spec
    └── Sources/
        ├── App/
        │   ├── BinableApp.swift     @main, NSApplicationDelegateAdaptor
        │   └── MenuBarController.swift  NSStatusItem + NSMenu + window management
        ├── Models/
        │   ├── StoredLocation.swift
        │   ├── PickupResult.swift
        │   ├── FetchFrequency.swift
        │   └── AppSettings.swift    UserDefaults wrapper
        ├── Services/
        │   ├── APIService.swift     binable REST client
        │   ├── PickupStore.swift    @MainActor data store + auto refresh
        │   └── LaunchAtLoginService.swift  SMAppService wrapper
        ├── Views/
        │   ├── SettingsView.swift   Tabs: Locations + General
        │   ├── AddLocationView.swift Sheet for adding a location
        │   └── AboutView.swift
        └── Resources/
            ├── Info.plist           LSUIElement = YES
            ├── Binable.entitlements
            └── Assets.xcassets/
```
