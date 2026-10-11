# PennyPal iOS — Mac + iPhone setup

The Dart application is shared with Android/Web. The native iOS host project must be generated on macOS because Flutter's iOS toolchain requires Xcode.

## One-time Mac setup

1. Install Xcode.
2. Open Xcode once and install its iOS components.
3. Run:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license
```

4. Install Flutter and FlutterFire CLI if needed:

```bash
dart pub global activate flutterfire_cli
```

## Generate and configure PennyPal

From the `frontend` folder:

```bash
chmod +x IOS_SETUP_ON_MAC.sh
./IOS_SETUP_ON_MAC.sh
```

The script runs the official Flutter iOS project generation and then:

```bash
flutterfire configure --project=pennypal-ec854 --platforms=ios
```

When prompted, register/select PennyPal's iOS app in Firebase. This generates the real `GoogleService-Info.plist`; do not invent or reuse an Android Firebase config for iOS.

## Xcode signing

Open `ios/Runner.xcworkspace`.

- Runner target → Signing & Capabilities
- Enable Automatically manage signing
- Select the Apple ID/team used for development
- Keep the bundle identifier consistent with the Firebase iOS registration

## iPhone Developer Mode

On the iPhone:

1. Connect it to the Mac by USB.
2. Unlock it and tap **Trust** when asked.
3. Settings → Privacy & Security → Developer Mode → On.
4. Restart the iPhone if prompted.
5. In Xcode, select the iPhone as the run destination.

Then:

```bash
flutter devices
flutter run -d <IOS_DEVICE_ID>
```

A free personal Apple Developer account can be used for device testing; App Store/TestFlight distribution has additional Apple requirements.

## iOS permissions used by PennyPal

PennyPal can use the camera/photo picker for optional receipt capture. The iOS `Info.plist` should therefore contain the appropriate camera/photo usage descriptions after the iOS host is generated. If Flutter's generated plist does not include them, add:

```xml
<key>NSCameraUsageDescription</key>
<string>PennyPal uses the camera to optionally attach receipt images to transactions.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PennyPal uses your photo library when you choose a receipt image.</string>
```

## Firebase App Check / Gemini

The development build intentionally does not let a failed Android debug App Check token block ordinary Firebase Authentication. For iOS Gemini/App Check testing, configure the appropriate Firebase App Check development provider only if Firebase AI Logic requires it for the selected project configuration. Do not ship a debug token in a release build.

## Important

An actual `.app`/`.ipa` cannot be produced on Windows. Flutter's official iOS toolchain requires macOS + Xcode. This project is prepared so the Mac can generate the native iOS host and immediately build/run the same PennyPal Dart code on an iPhone.
