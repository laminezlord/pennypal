# PennyPal — SRS implementation matrix

This matrix tracks implementation against the PennyPal SRS. A feature marked **implemented** means the source contains the intended workflow; device-specific verification is still recorded separately in `FINAL_TEST_CHECKLIST.md`.

| SRS area | Status | Current implementation |
|---|---|---|
| Student registration | Implemented | Firebase Email/Password registration with name, email, mobile and password validation |
| Student login/logout | Implemented | Firebase Authentication + auth-state routing |
| Dashboard | Implemented | Income, expenses, balance, budget usage, quick actions, recent activity and offline-pending indicator |
| Income/expense CRUD | Implemented | Firestore-backed add/edit/delete flows |
| Required categories | Implemented | Food, Transport, Education, Shopping, Entertainment, Bills, Savings, Miscellaneous |
| Search/filter history | Implemented | Transaction history supports search/type/category filtering |
| Monthly budget | Implemented | Monthly total budget and progress |
| Category spending limits | Implemented | Category-specific budgets stored in Firestore |
| Overspending / threshold alerts | Implemented | Threshold evaluation plus Android/iOS local notification delivery; alert is de-duplicated per budget period |
| Savings goals | Implemented | Target, current amount, target date, monthly contribution, progress, estimated completion, milestones, badges, contributions, completion and archive/restore |
| Savings charts | Implemented | Goal progress chart plus milestone/progress presentation |
| Learning | Implemented | Firestore-backed learning content, search and reader dialog |
| About | Implemented | In-app explanation of purpose and scope |
| Feedback | Implemented | Rating/comments saved to Firestore; Android lifecycle crash in confirmation flow was fixed |
| Contact support | Implemented | Support requests saved to Firestore with safe dialog lifecycle handling |
| Reports / spending trends | Implemented | Category pie chart, monthly income/expense trend, totals, balance and highest-spend category |
| AI budgeting chatbot | Partially implemented | Educational deterministic assistant/fallback is available; live external generative-AI integration remains optional implementation work |
| AI expense categorization | Optional | SRS marks this optional; not required for the core workflow |
| Receipt image capture | Implemented | Camera/gallery capture + Firebase Storage upload while online; offline expense saving is not blocked by receipt upload |
| Admin role | Partially implemented | Role-aware Admin Centre includes users, support and lesson creation; richer analytics/content moderation can be expanded later |
| Offline-first expense entry | Implemented | Persistent local queue using SharedPreferences, offline transaction display, automatic connectivity-triggered synchronization, retry-safe deterministic IDs and pending-sync indicator |
| Security / privacy | Implemented baseline | Firestore ownership rules and Storage receipt rules included; final deployment/permission test still required |
| Android | Implemented | Flutter Android build and emulator verified |
| Web | Implemented/configured | Shared Flutter Web configuration included; full regression pass remains |
| Tablets | Implemented/configured | Responsive layouts and tablet NavigationRail architecture included; regression pass remains |
| iOS | Architecture-ready | Shared Flutter codebase and notification package support are prepared; actual iOS simulator/device verification requires macOS/Xcode |
| Database design | Implemented | Firestore collections plus SQL reference schema |
| Documentation | In progress | README, matrix, gap analysis, report outline and test checklist included; final human-authored report remains |
| APK | Buildable | Generate the final release APK after regression testing |
| Demo video | Remaining | Record mandatory MP4 after the stable feature set is verified |
| Credentials | Remaining | Prepare required demo/test credentials for submission |
