# PennyPal — Updated SRS Gap Analysis

## Completed in the current implementation pass

### Offline expense entry and synchronization
- A persistent local queue is stored with SharedPreferences.
- Expenses created with no network are immediately visible in PennyPal with a pending-sync state.
- The queue survives application restarts.
- Connectivity changes trigger synchronization automatically.
- A manual synchronization is also attempted during dashboard refresh.
- Offline records use deterministic local document IDs when synchronized, reducing duplicate risk on retries.
- The dashboard reports how many entries are waiting to sync.

### Spending threshold notifications
- Budget thresholds are evaluated after expense creation.
- Android/iOS local notifications are configured through `flutter_local_notifications`.
- Android 13+ notification permission is requested.
- Notifications use a dedicated PennyPal budget-alert channel.
- Repeated alerts are de-duplicated for the budget period, with a later alert when spending crosses 100%.

### Savings goals
- Target amount, current amount, target date and monthly contribution are stored.
- Contributions can be added directly to a goal.
- Progress is calculated from current versus target amount.
- Estimated completion is calculated from the remaining amount and monthly contribution.
- 25%, 50%, 75% and 100% milestones are presented.
- Progress badges are shown.
- Goals can be completed, archived, restored or deleted.
- A progress chart is displayed for each goal.

### Reports and spending trends
- Total income, total expenses and balance are calculated from transactions.
- Spending is grouped by category.
- Monthly income and expenses are grouped for trend analysis.
- A category pie chart is displayed.
- A monthly income-versus-expense line chart is displayed.
- The highest-spend category is surfaced.

## Remaining work

1. **Device verification** — run the new offline, notification, savings and report flows on the Android emulator and tablet.
2. **iOS verification** — the code is cross-platform, but an actual iOS simulator/device pass requires macOS/Xcode.
3. **Web regression** — verify the report/savings/offline-compatible UI on Web.
4. **Admin depth** — richer analytics, learning-content editing/deactivation and support resolution can be expanded.
5. **Live generative AI** — the current assistant is an educational deterministic fallback; a live model integration should only be added with a secure architecture and disclosed in the report.
6. **Submission packaging** — final release APK, report, diagrams, credentials, installation instructions and mandatory MP4.

## Important scope boundaries

PennyPal remains a student personal-finance learning and expense-management application. It does not connect to bank accounts, perform payments, store card details, provide investment recommendations, or claim to replace professional financial advice.
