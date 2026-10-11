# PennyPal Final Runtime Audit

## Scope

This audit covers the current PennyPal source package, with particular attention to:
- landing-page layout and mobile overflow
- dashboard navigation and admin role handling
- admin statistics and learning-content flow
- learning video playback/upload flow
- PennyPal AI loading/composer behaviour
- Firestore/Storage access paths
- offline/sync service stability
- deprecated or warning-prone non-auth source patterns

## Authentication protection

The student login and registration source files were intentionally left unchanged:
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`

Their source hashes were checked before and after the audit and remained identical.

The landing page (`welcome_screen.dart`) was allowed to receive layout-only fixes because it is not the login or registration form.

## Fixes in this audit

1. Removed the unused Flutter foundation import from `main.dart`.
2. Removed the unused public API that exposed a private `_PennyPalAppState` type from `app.dart`.
3. Made the connectivity subscription actively cancellable so it is not an unused field.
4. Updated non-auth opacity calls to `withValues(alpha: ...)`.
5. Updated non-auth `DropdownButtonFormField` instances to use `initialValue`.
6. Removed unnecessary budget list casts.
7. Renamed numeric `fold` accumulator variables that conflicted with visible type names.
8. Made the dashboard recent-transactions extraction type-safe without an unnecessary cast.
9. Increased the landing-page feature-card height on narrow screens and constrained feature descriptions to two lines with ellipsis. This addresses the previously observed `BOTTOM OVERFLOWED BY ... PIXELS` errors.
10. Added staggered reveal motion to the landing-page feature cards.
11. Preserved the existing PennyPal AI single pulsing-dot thinking indicator and compact keyboard-aware composer.
12. Preserved the existing admin entrance animations, role-aware navigation, student/support count formatting, and learning-video support.

## Static checks

- No Django/backend source remnants found.
- No `constTextStyle`, `constPennyPal`, `constBox`, or `PennyPalTheme.blue` tokens found.
- No deprecated Firebase App Check enum arguments (`androidProvider` / `appleProvider`) found.
- Login and registration source files unchanged.

## Windows verification required

The final verification must still be run with the project's Windows Flutter SDK:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d 115272543D002180
```

Runtime verification should specifically check the landing feature section, dashboard, Admin Centre, learning video dialog, PennyPal AI keyboard/composer, and navigation.
