# GoAAUP

Bus tracking and reservation app for AAUP.

## Firebase authentication (Admin + Driver)

The app uses **Firebase Authentication** (email/password) plus Firestore profile documents. Passwords are **never** stored or read from Firestore.

### Firestore collections (case-sensitive)

| Collection | Document ID | Fields |
|------------|-------------|--------|
| `admins` | Firebase Auth UID | `email`, `name` |
| `drivers` | Firebase Auth UID | `email`, `name` |

### One-time Admin migration

If your `admins` document uses a random ID (not the Auth UID):

1. In Firebase Console → **Authentication**, create or locate the admin user (e.g. `luna12@gmail.com`).
2. Copy the user **UID**.
3. In **Firestore**, create `admins/{uid}` with `{ "email": "luna12@gmail.com", "name": "Your Name" }` (add `name` to **admins**, not only **drivers**).
4. Delete the old admin document and remove any `password` field.
5. Deploy security rules: `firebase deploy --only firestore:rules`

### Driver accounts

Ensure a matching **Authentication** user exists and `drivers/{authUid}` contains `email` and `name`.

### Admin cannot log in?

1. Confirm the Firestore collection is **`admins`** (matches your Firebase data).
2. Create **`admins/{firebaseAuthUid}`** with `{ "email": "your@email.com" }` (UID from Authentication tab).
3. Deploy rules: `firebase deploy --only firestore:rules`
4. If you only have a `drivers/{uid}` document, use **Driver Login** until an `admins/{uid}` profile exists.

### Students

Students use the app as **guests** (no login) in this phase.

## Getting started

```bash
flutter pub get
flutter run
```
