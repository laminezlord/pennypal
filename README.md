# PennyPal — Professional Flutter Frontend

PennyPal is a cross-platform student personal-finance learning and expense-management app built around the provided PennyPal SRS.

## Stack
- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage foundation
- Firebase Messaging dependency/foundation
- fl_chart
- image_picker foundation

## Run

```powershell
flutter pub get
flutter run -d emulator-5554
```

For Web:

```powershell
flutter run -d chrome
```

## Firebase

The project is configured for Firebase project `pennypal-ec854`. Email/Password Authentication and Firestore must be enabled in Firebase Console.

`firestore.rules` contains ownership-based rules. Deploy them with the Firebase CLI after reviewing them for the competition environment.

## Important SRS boundaries

PennyPal does not connect to bank accounts, initiate payments, store card details, act as a wallet, or provide professional investment/financial advice. AI-style guidance is educational.

## Branding

The final visual system uses a deep navy + mint + sky palette. The PennyPal mark is a custom vector-style coin/P mark used consistently in the Flutter interface and generated Android/Web app icons.

## AI acknowledgement

The SRS requires AI tools used during development/design to be acknowledged. Record the exact tools and the parts where they were used in the final human-authored report. Do not submit the outline or this README as a substitute for the required report.

## Remaining pre-submission work

See `docs/SRS_IMPLEMENTATION_MATRIX.md`. The highest-priority remaining items are receipt capture/upload, real threshold notifications, optional AI categorisation, deeper admin analytics/content editing, deliberate offline/restore testing, and final cross-platform testing.

## SRS feature implementation notes

### Offline expenses
PennyPal keeps expense entries created without connectivity in a persistent local queue. Pending entries are displayed immediately and synchronized automatically when connectivity returns. Firestore persistence remains enabled for cached cloud data.

### Budget notifications
Budget threshold checks can produce local device notifications. Android 13+ notification permission is requested by the notification service. Notifications are intentionally educational spending alerts, not banking/payment notifications.

### Savings goals
Goals support target/current amounts, target dates, monthly contributions, estimated completion, progress milestones, badges, contribution updates, completion and archive/restore.

### Reports
Reports summarize income, expenses and balance, break spending down by category, and display monthly income-versus-expense trends.

## Button interaction hardening

The current build includes a widget-lifecycle hardening pass covering budget sheets, transaction sheets, dialogs, popup menus, navigation, and async button actions. See `docs/BUTTON_INTERACTION_AUDIT.md` for the regression checklist.


## Gemini / Firebase AI Logic

PennyPal Assistant uses the official Firebase AI Logic Flutter SDK (`firebase_ai`) with the Gemini Developer API. The app uses `gemini-3.8-flash` and a product-level system instruction to keep responses educational and within the PennyPal SRS scope. Firebase AI Logic keeps the Gemini API key out of the app; App Check protects client requests.

For local Android/iOS development, `main.dart` activates the Firebase App Check debug provider. The first Android run prints a debug App Check token in the console. Register that token in Firebase Console under **Security > App Check > Apps > Manage debug tokens** before testing Gemini when App Check enforcement is active.

### Gemini smoke test

1. Run `flutter clean` and `flutter pub get`.
2. Run `flutter analyze` and confirm there are no errors.
3. Run `flutter run -d emulator-5554`.
4. Open **PennyPal Assistant**.
5. Ask: `How can I reduce my food spending this month?`
6. A successful live response shows **Gemini • gemini-3.8-flash** above the answer.
7. If the request cannot reach Gemini, PennyPal shows **PennyPal fallback** instead; that is the graceful fallback required by the SRS, not a Gemini response.

Firebase's current Flutter documentation recommends `firebase_ai` + `firebase_app_check`, initializes the Gemini Developer API with `FirebaseAI.googleAI()`, and uses `generateContent()`/chat APIs with supported models such as `gemini-3.8-flash`.

## Current UI and platform pass

- Landing page simplified to clear **Get started / Sign in** actions with no anchor navigation or demo-only controls.
- Landing page now uses the same navy, blue, mint and light-canvas rhythm as the signed-in dashboard.
- Removed the animated three-dot/ring splash indicators; the splash is now a short logo-and-wordmark presentation.
- APK/launcher branding uses the same blue-and-white PennyPal mark as the in-app logo.
- Android/iOS development App Check is not activated in Flutter debug mode, so a debug App Check token does not block normal sign-in during development. Production builds use Play Integrity on Android and App Attest with DeviceCheck fallback on iOS.
- iOS setup is documented in `docs/IOS_BUILD_AND_FIREBASE_SETUP.md`. Actual iOS compilation and device testing must be performed on macOS/Xcode.
