# PennyPal Admin Account Setup

PennyPal follows the SRS rule that administrator accounts are preconfigured rather than created through the student registration screen.

## Firebase Authentication

1. Open Firebase Console for project `pennypal-ec854`.
2. Go to Authentication → Users.
3. Create the administrator email/password account.
4. Copy that user's Firebase UID.

## Firestore

Create a document in `/Users` using the Firebase UID as the document ID.

Canonical fields:

- `UserId` — string — the same Firebase UID
- `Role` — string — `admin`

The app also accepts a manually provisioned lowercase `role` field for compatibility, but `Role` is the canonical field used by PennyPal.

After saving the document, sign out of PennyPal and sign in with the administrator account. The Profile screen will display **Admin centre**.
