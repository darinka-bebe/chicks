# Firebase Google Sign-In (Chicks)

The app uses **Firebase Auth** + **google_sign_in** for the login button. Wardrobe, chat, favorites, and profile sync to **Firestore** when signed in (Hive remains the local cache).

## Required files (not in git — add locally)

| Platform | File | Location |
|----------|------|----------|
| Android | `google-services.json` | `android/app/` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/` |

Download both from [Firebase Console](https://console.firebase.google.com) → Project settings → Your apps.

## Firebase Console

1. Enable **Authentication** → Sign-in method → **Google** → Enable.
2. Enable **Firestore Database** (production mode) and deploy `firestore.rules` from the repo root.
3. Android app: register package `com.example.chicks` (or your bundle ID).
4. Add **SHA-1** and **SHA-256** (debug + release):

```bash
cd android
./gradlew signingReport
```

Copy `SHA1` / `SHA-256` from the `debug` variant into Firebase → Android app settings.

5. iOS app: register bundle ID; download `GoogleService-Info.plist`.

## Firestore rules (обязательно для cloud sync)

Без правил синк падает с `permission-denied`.

**Вариант A — Firebase Console (быстро):**

1. [Firebase Console](https://console.firebase.google.com) → **Build** → **Firestore Database** → **Rules**
2. Вставь содержимое файла `firestore.rules` из корня репозитория:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Нажми **Publish**

**Вариант B — Firebase CLI:**

```bash
npm install -g firebase-tools
firebase login
firebase use --add   # выбери свой проект
firebase deploy --only firestore:rules
```

После публикации правил перезапусти приложение и войди снова — синк должен пройти.

## iOS Google Sign-In

In `GoogleService-Info.plist`, copy `REVERSED_CLIENT_ID` into Xcode → Runner → Info → URL Types (if not auto-added).

Or add to `ios/Runner/Info.plist` under `CFBundleURLTypes` (replace with your value):

```xml
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
```

## Run / rebuild (after Firebase channel errors)

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

**Package name** must be `com.example.chicks` in `android/app/build.gradle.kts` and in `google-services.json` (already matched).

Firebase initializes in `AppStartupGate` **after** `runApp()` so Android plugin channels are ready (fixes `FirebaseCoreHostApi.initializeCore` channel-error).

## Run

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Expected UX

1. Tap **Войти через Google** → Google account picker.
2. On success → navigate to main (no success snackbar).
3. Cancel → no error snackbar.
4. Error → one clear red snackbar (Russian).
5. Kill app → reopen → still signed in (Firebase session).
6. Profile shows **real Google email** and photo (or local avatar if set).

## Sign out

Profile → sign out → Firebase + Google session cleared → login screen. **Local wardrobe data is kept** on device for the next login on the same phone.

## Troubleshooting

| Error | Fix |
|-------|-----|
| `operation-not-allowed` | Enable Google provider in Firebase Auth |
| `invalid-credential` / `10:` | Wrong SHA-1 or outdated `google-services.json` |
| `API_KEY_INVALID` | Refresh config files from Firebase |
| iOS URL scheme | Add `REVERSED_CLIENT_ID` to URL types |
| Network | Device needs internet for first sign-in |
