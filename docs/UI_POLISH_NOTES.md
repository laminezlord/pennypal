# PennyPal UI Polish Pass

## Navigation motion
- Main app sections now use a `PageView` so the bottom navigation remains fixed while page content slides horizontally.
- Standalone screens opened from dashboard/profile use `pennyPalRoute`, which enters from the left with a short fade.
- The bottom navigation/footer is outside the page transition and remains stationary.

## Visual polish
- Improved Material 3 navigation bar sizing, selected-state typography and icon treatment.
- Added subtle card elevation/shadows and a more polished app bar height.
- Added floating SnackBar styling.
- Improved Nigerian Naira formatting with thousands separators.
- Reduced the dashboard add action to a compact floating action button so it does not obscure budget content.
- Fixed narrow dashboard income/expense cards so they stretch to the available width on phones.

## Splash + Landing Pass

- Added an animated PennyPal splash screen with a rotating mint ring, breathing logo, and animated loading dots.
- Splash is intentionally held for a short, consistent 1.8-second presentation so the branding is visible before authentication routing.
- Added a responsive unauthenticated welcome/landing page before Login/Register.
- Landing page provides Get started and Sign in actions and keeps the SRS wording clear that PennyPal is a personal-finance learning and expense-management tool, not a bank/payment service.
- Existing left-slide route transition is preserved for Login/Register/Welcome navigation.
- Bottom navigation behavior inside the authenticated app remains unchanged; it is not routed through the landing transition.
