# PennyPal Button Interaction & Route-Lifecycle Audit

## Purpose

This pass hardens interactive controls against Flutter widget-tree lifecycle errors, especially the Android assertion:

`'_dependents.isEmpty': is not true`

## Changes made

- Reworked the **Budget editor** from an inline `StatefulBuilder` bottom sheet into a dedicated stateful editor widget.
- Budget refresh now happens only after the bottom-sheet route has fully closed.
- Reworked **Quick Add transaction** so the sheet returns a result to its parent instead of showing snackbars or refreshing after `Navigator.pop`.
- Removed `setState` after closing the transaction sheet.
- Receipt-camera errors are caught and reported without breaking the transaction flow.
- Dashboard transaction actions now refresh and show messages from the parent screen after the sheet is closed.
- Admin lesson creation refreshes only after the dialog has closed.
- Savings goal popup-menu actions refresh after the menu route has settled and catch service errors.
- Transaction edit/delete refreshes are deferred until after dialog/dismiss animations.
- Assistant input now checks widget lifecycle before its initial state update.
- Existing Feedback and Support dialogs continue to show confirmation only after their dialogs have fully closed.

## Regression targets

The following controls should be exercised on Android:

1. Dashboard → Add transaction → save expense.
2. Dashboard → Add transaction → save income.
3. Dashboard → Add expense → choose every category → save.
4. Budget → Add monthly budget → enter `50000` → Save limit.
5. Budget → Add category limit → choose Food → enter `50000` → Save limit.
6. Budget → edit an existing limit → save.
7. Savings → Create goal.
8. Savings → Contribute → Add.
9. Savings → More → Mark complete / Archive / Restore / Delete.
10. Activity → edit transaction → Save.
11. Activity → swipe transaction → Delete.
12. Learning → open a lesson → Done.
13. Profile → Reports → refresh.
14. Profile → Feedback → Submit.
15. Profile → Support → Send.
16. Profile → Admin centre → Add lesson → Save.
17. Assistant → preset question and manual question.
18. Bottom navigation → repeatedly switch all tabs.
19. Dashboard → open Assistant/Profile repeatedly.
20. Rotate/resize the Android emulator/tablet and repeat the above where applicable.

## Lifecycle rule

No interactive flow should perform a parent `setState`, snackbar lookup, refresh, or other inherited-widget-dependent work from the child context immediately after that child calls `Navigator.pop`. Those actions are returned to or deferred by the parent after the route has settled.
