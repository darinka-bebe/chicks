# Firebase Google Sign-In (Chicks)

The app uses **Firebase Auth** + **google_sign_in** for the login button. Local data (wardrobe, quizzes, favorites, dislikes, avatar file) stays on the device and is restored after login/restart.

## Required files (not in git — add locally)

| Platform | File | Location |
|----------|------|----------|
| Android | `google-services.json` | `android/app/` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/` |

Download both from [Firebase Console](https://console.firebase.google.com) → Project settings → Your apps.

## Firebase Console

1. Enable **Authentication** → Sign-in method → **Google** → Enable.
2. Android app: register package `com.example.chicks` (or your bundle ID).
3. Add **SHA-1** and **SHA-256** (debug + release):

```bash
cd android
./gradlew signingReport
```

Copy `SHA1` / `SHA-256` from the `debug` variant into Firebase → Android app settings.

4. iOS app: register bundle ID; download `GoogleService-Info.plist`.

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
