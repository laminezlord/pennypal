#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "== PennyPal iOS setup =="
command -v flutter >/dev/null || { echo "Flutter is not installed or not on PATH."; exit 1; }
command -v flutterfire >/dev/null || { echo "FlutterFire CLI is not installed. Run: dart pub global activate flutterfire_cli"; exit 1; }

# Generate the official Flutter iOS host project while preserving the existing Dart app.
flutter create --platforms=ios --org com.pennypal .

# Configure Firebase for the iOS app. This will ask you to select/register the iOS app.
flutterfire configure --project=pennypal-ec854 --platforms=ios

flutter pub get

# Install native dependencies if CocoaPods is available. Newer Flutter versions may use SPM;
# this is harmless when the project has no Podfile.
if command -v pod >/dev/null && [ -f ios/Podfile ]; then
  (cd ios && pod install)
fi

# Open the workspace/project for signing and device deployment.
if [ -f ios/Runner.xcworkspace ]; then
  open ios/Runner.xcworkspace
else
  open ios/Runner.xcodeproj
fi

echo
 echo "PennyPal iOS host project is ready."
echo "In Xcode: Runner -> Signing & Capabilities -> select your Apple ID/Team."
echo "Connect the iPhone, trust the Mac, enable Developer Mode on the iPhone, then run: flutter devices"
echo "Finally run: flutter run -d <YOUR_IOS_DEVICE_ID>"
