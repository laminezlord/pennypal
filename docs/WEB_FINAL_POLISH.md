# PennyPal Web Final Polish

This pass keeps the existing PennyPal feature set and focuses on Web usability and presentation.

## Changes
- Fixed Web sign-in navigation: a successful Firebase sign-in now clears the auth route and opens the dashboard.
- Added a subtle navy/blue/mint gradient backdrop to the public landing page.
- Increased landing-page visual depth and spacing without changing the core PennyPal palette.
- Standardized the Record / Plan / Save / Learn cards to equal heights on desktop and mobile.
- Centered the dashboard content on large Web screens with a controlled maximum width.
- Kept the bottom navigation stable; it does not use page transitions.

## Web test
Run from `frontend`:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

If Flutter reports `OS Error: 112` / `not enough space on the disk`, free space on the Windows system drive or move `TEMP`/`TMP` to a drive with more space before rebuilding. That error is a Windows disk-space failure, not a PennyPal Firebase authentication error.
