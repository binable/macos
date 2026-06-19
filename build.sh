#!/bin/zsh
set -e

cd "$(dirname "$0")/MullIO"

xcodegen generate

xcodebuild \
  -project MullIO.xcodeproj \
  -scheme MullIO \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

APP=$(find ~/Library/Developer/Xcode/DerivedData/MullIO-*/Build/Products/Debug -name "*.app" | head -1)

codesign --force --sign - "$APP/Contents/MacOS/müll.io"
codesign --force --sign - "$APP"

echo "\nBuild OK: $APP"
