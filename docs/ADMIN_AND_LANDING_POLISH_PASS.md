# Admin, Learning Video & Landing Motion Polish Pass

This pass addresses the runtime issues found during physical-device review.

## Admin
- Admin statistics are counts, not currency values.
- The main navigation replaces **Learn** with **Admin** for an admin account.
- Profile identifies an administrator as **PennyPal Admin** and shows an ADMIN badge.
- Admin Centre is also available as a footer-style settings card in Profile.
- Support requests use a clearer card layout and status pill.

## Learning content
- Admins can optionally attach a lesson video when publishing a lesson.
- Video files are stored under `learning_videos/{adminUid}/` in Firebase Storage.
- The Storage rules restrict lesson-video uploads to authenticated admin users.
- Students see a play indicator on lessons that contain a video and can watch the video inside the lesson dialog.
- Video playback uses Flutter's official `video_player` package, which supports Android, iOS and Web.

## Landing page
- The feature grid uses explicit row heights instead of an aspect ratio that caused bottom overflow on phones.
- Added a subtle animated bubble field behind the landing content.
- Existing gradient background motion remains, with the bubbles kept light enough not to distract from the content.

## Important verification
Run `flutter pub get` and `flutter analyze` on Windows after extracting this package. Then test the admin navigation, lesson-video upload, student video playback and the landing page on the Infinix device.
