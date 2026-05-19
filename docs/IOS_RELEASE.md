# iOS: сборка и публикация в App Store

## Предварительные требования

- macOS с **Xcode 15+** и **Flutter 3.7+**
- Apple Developer Program (платная подписка)
- Настроенный проект Firebase

## 1. Firebase и Google Sign-In

```bash
# Установка FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure
```

Скопируйте конфиги:

```bash
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
# Замените содержимое на файл из Firebase Console
```

В `ios/Runner/Info.plist` подставьте:

- `REVERSED_CLIENT_ID` → `CFBundleURLSchemes`
- `CLIENT_ID` → `GIDClientID`

Создайте `.env` из шаблона:

```bash
cp .env.example .env
```

## 2. Зависимости и иконки

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
cd ios && pod install && cd ..
```

Открывайте **`ios/Runner.xcworkspace`** (не `.xcodeproj`).

## 3. Запуск на симуляторе / устройстве

```bash
flutter run -d ios
# или
open ios/Runner.xcworkspace
```

В Xcode: выберите Team → Signing & Capabilities → Automatic signing.

## 4. Сборка IPA для App Store

```bash
flutter build ipa --release
```

Или через Xcode: **Product → Archive → Distribute App → App Store Connect**.

С `ExportOptions.plist` (замените `YOUR_APPLE_TEAM_ID`):

```bash
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```

IPA появится в `build/ios/ipa/`.

## 5. Загрузка в App Store Connect

### Transporter / Xcode

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → создайте приложение.
2. Bundle ID: `com.example.chicks` (или ваш production ID).
3. Xcode Organizer → **Distribute App** → Upload.

### CLI (altool / notarytool)

```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa \
  -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

## 6. Чеклист перед публикацией

| Пункт | Статус |
|-------|--------|
| Реальный `GoogleService-Info.plist` в Runner | ☐ |
| `firebase_options.dart` с production ключами | ☐ |
| `.env` с `SERVER_CLIENT_ID` и `IOS_CLIENT_ID` | ☐ |
| Иконки 1024×1024 во всех размерах | ☐ |
| Privacy strings в Info.plist | ☐ |
| `PrivacyInfo.xcprivacy` | ☐ |
| Скриншоты App Store (6.7", 6.5", 5.5") | ☐ |
| Политика конфиденциальности (URL) | ☐ |
| Тест Google Sign-In на реальном iPhone | ☐ |
| `ITSAppUsesNonExemptEncryption = false` | ☑ |
| Версия в `pubspec.yaml` (`version: x.y.z+build`) | ☐ |

## Push-уведомления (опционально)

В проекте пока нет `firebase_messaging`. Для push:

1. Добавьте `firebase_messaging` в `pubspec.yaml`.
2. В Xcode включите **Push Notifications** capability.
3. Раскомментируйте `aps-environment` в `ios/Runner/Runner.entitlements`.
4. Загрузите APNs key в Firebase Console.

## Известные зависимости (iOS-совместимы)

| Пакет | iOS |
|-------|-----|
| firebase_core / auth / firestore / storage | ✅ |
| google_sign_in 7.x | ✅ |
| image_picker | ✅ (permissions в Info.plist) |
| cached_network_image | ✅ |
| go_router | ✅ |
| connectivity_plus | ✅ |
