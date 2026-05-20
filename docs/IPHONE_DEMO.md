# iPhone demo testing (Chicks)

Minimal steps to run the MVP on a **physical iPhone** for diploma demo.

## On Mac (one-time)

```bash
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode: pick your **Team**, set a unique **Bundle ID**, connect iPhone, press **Run**.

Or: `flutter run -d <device-id>`

## Before demo

- [ ] `.env` with `OPENAI_API_KEY` (rebuild after changes)
- [ ] Register account with real email
- [ ] Add 5–8 wardrobe photos on device
- [ ] Set profile avatar from gallery
- [ ] Complete color + body type quizzes

## Quick device check (~10 min)

| Feature | What to verify |
|---------|----------------|
| Onboarding | Splash → quizzes → main, no layout under notch |
| Tabs | Bottom nav clears home indicator |
| Chat | Keyboard opens; input visible; list scrolls; AI reply |
| Gallery | Profile avatar + wardrobe add from photos |
| Persistence | Force-quit app → reopen → data still there |
| Profile | Email, avatar, stats visible |

## If something breaks

- **Photos denied** → Settings → Chicks → Photos → allow
- **No AI reply** → internet + API key in `.env`
- **Plugins** → `flutter clean && flutter pub get && cd ios && pod install`

Native photo permission strings are in `ios/Runner/Info.plist` (required for gallery on device).
