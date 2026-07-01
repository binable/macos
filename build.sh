#!/bin/zsh
set -e

cd "$(dirname "$0")/Binable"

xcodegen generate

xcodebuild \
  -project Binable.xcodeproj \
  -scheme Binable \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

APP=$(find ~/Library/Developer/Xcode/DerivedData/Binable-*/Build/Products/Debug -name "*.app" | head -1)

codesign --force --sign - "$APP/Contents/MacOS/binable"
codesign --force --sign - "$APP"

echo "\nBuild OK: $APP"
