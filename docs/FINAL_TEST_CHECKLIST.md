# PennyPal — Final Test Checklist

## Android

- [ ] `flutter doctor` shows Android toolchain ready.
- [ ] Android emulator/device is detected by `flutter devices`.
- [ ] `flutter clean` completes.
- [ ] `flutter pub get` completes.
- [ ] `flutter run -d emulator-5554` launches without Dart compilation errors.
- [ ] Registration creates Firebase Auth + Firestore profile.
- [ ] Login/logout works.
- [ ] Add income works.
- [ ] Add expense works.
- [ ] Edit/delete transaction works.
- [ ] Search/type/category filtering works.
- [ ] Monthly and category budgets work.
- [ ] Threshold alert appears after crossing the configured threshold.
- [ ] Savings goal create/edit/delete/progress works.
- [ ] Learning content opens.
- [ ] Reports render without chart errors.
- [ ] Receipt camera/upload works on a real Android camera-capable device.
- [ ] Assistant fallback responds.
- [ ] Feedback and support submissions work.
- [ ] Student cannot access admin-only actions.
- [ ] Admin account can access Admin Centre.
- [ ] Sign out returns to login.

## Offline / sync

- [ ] Launch while online and allow Firestore cache to initialize.
- [ ] Turn off network.
- [ ] Add an expense.
- [ ] Close/reopen the app while offline.
- [ ] Restore network.
- [ ] Confirm the transaction reaches Firestore once connectivity returns.

## Web

- [ ] `flutter run -d chrome` launches.
- [ ] Login/registration work.
- [ ] Dashboard layout is readable at desktop and narrow widths.
- [ ] All navigation destinations open.
- [ ] Charts and dialogs do not overflow.
- [ ] Firebase Web auth/firestore access works.

## Submission

- [ ] Final release APK generated.
- [ ] Source ZIP includes README and Firebase configuration required by the project.
- [ ] Final report is human-reviewed and explains architecture, database design, testing and limitations.
- [ ] Test/demo credentials are documented where required.
- [ ] Mandatory MP4 demonstrates the required functionality.
