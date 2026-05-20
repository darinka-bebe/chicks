# iOS (Chicks)

## Quick start on Mac

```bash
flutter pub get
cd ios && pod install && cd ..
open Runner.xcworkspace
```

Select your iPhone, set **Signing Team**, press Run.

Full steps: [../docs/IOS_DEPLOYMENT_CHECKLIST.md](../docs/IOS_DEPLOYMENT_CHECKLIST.md)

## Key files

| File | Role |
|------|------|
| `Runner/Info.plist` | Permissions, portrait, status bar |
| `Podfile` | CocoaPods + `permission_handler` flags |
| `Runner/PrivacyInfo.xcprivacy` | App Store privacy manifest |
| `Runner/Assets.xcassets/AppIcon.appiconset/` | Home screen icons |

## Bundle ID

Default: `com.example.chicks` — change in Xcode before TestFlight.
