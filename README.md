# Khuc Tam Giao Flutter App

Flutter mobile app synced with the Laravel website/admin API. The codebase contains the public customer app and the admin collaborator app.

## Stack

- Flutter stable, Dart 3.11+
- `flutter_bloc` for state
- `go_router` for navigation
- `dio` for API calls and token refresh
- `cached_network_image` for remote images
- `flutter_secure_storage` for admin tokens
- `shared_preferences` for locale/device id cache
- Native iOS/Android notification and universal link bridges via `MethodChannel` / `EventChannel`

## API Base URL

The API base URL is configured with a Dart define:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api/v1
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api/v1
flutter build ios --release --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```

Default fallback is `https://your-domain.com/api/v1` in `lib/core/constants/api_paths.dart`.

For local development on a real device or simulator, do not use `localhost` unless it points to the device itself. Use a reachable LAN host, emulator host, or tunnel URL.

## Universal Links

Universal links are separate from push notifications. They are used for sharing normal website/app URLs such as:

```text
https://your-domain.com/services/full-service-planning
https://your-domain.com/blog/wedding-checklist
khuctamgiao://services/full-service-planning
```

Current Dart bridge:

- Method channel: `khuctamgiao/universal_links`
- Event channel: `khuctamgiao/universal_links/events`
- Dart file: `lib/features/universal_links/universal_link_bridge.dart`

### Android Setup

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<data android:scheme="https" android:host="your-domain.com" />
```

Change `your-domain.com` to the real website domain.

Host Android App Links verification file:

```text
https://your-domain.com/.well-known/assetlinks.json
```

It must contain the Android package name and release signing certificate SHA-256 fingerprint.

### iOS Setup

Update `ios/Runner/Runner.entitlements`:

```xml
<string>applinks:your-domain.com</string>
<string>applinks:www.your-domain.com</string>
```

Change these to the real website domain(s).

In Apple Developer / Xcode, enable Associated Domains for the app identifier.

Host Apple verification file:

```text
https://your-domain.com/.well-known/apple-app-site-association
```

Serve it as JSON without `.json` extension and without redirects.

## Native Notifications

Firebase Messaging is not used in Flutter. Notification handling is native and exposed to Dart with channels.

Current Dart bridge:

- Method channel: `khuctamgiao/notifications`
- Event channel: `khuctamgiao/notifications/events`
- Dart file: `lib/features/notifications/native_notification_bridge.dart`

Supported methods:

- `requestPermission`
- `getDeviceToken`
- `getInitialNotification`
- `clearInitialNotification`

Expected notification payload should include one of:

```json
{
  "url": "/services/full-service-planning"
}
```

or:

```json
{
  "data": {
    "url": "/blog/wedding-checklist"
  }
}
```

The app maps those URLs to `go_router` routes.

### Android Notification Notes

- `POST_NOTIFICATIONS` permission is declared for Android 13+.
- Native handler reads notification `Intent` extras and forwards payload to Dart.
- If a notification provider is added later, keep forwarding tap extras to `MainActivity`.

### iOS Notification Notes

- `UIBackgroundModes` includes `remote-notification`.
- APNs permission and APNs device token are handled in `AppDelegate.swift`.
- A real physical iOS device is required to fully test APNs.
- Configure Push Notifications capability and APNs key/certificate in Apple Developer if sending real remote notifications.

## Backend Notes

Before connecting the app to hosted Laravel:

```bash
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

Public APIs use locale:

```text
?locale=en
?locale=vi
Accept-Language: en|vi
```

Admin access token refresh is handled by the Dio interceptor. If refresh fails, local tokens are cleared.

## Build And Check

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```

Release iOS builds require valid signing, bundle id, capabilities, and provisioning profile.

## CI/CD With Fastlane

Two wrapper scripts are available:

```bash
scripts/deploy_firebase.sh
scripts/deploy_stores.sh
```

They run these Fastlane lanes:

```bash
bundle exec fastlane firebase
bundle exec fastlane stores
```

Install Ruby dependencies first, or let the scripts run `bundle install`:

```bash
bundle install
```

### Firebase App Distribution

Use this for tester/internal builds:

```bash
scripts/deploy_firebase.sh
```

Required ENV:

```bash
export API_BASE_URL=https://your-domain.com/api/v1
export FIREBASE_ANDROID_APP_ID=1:xxx:android:xxx
export FIREBASE_IOS_APP_ID=1:xxx:ios:xxx
export FIREBASE_TESTER_GROUPS=internal-testers
export RELEASE_NOTES="Build from CI"
```

Optional ENV:

```bash
export FIREBASE_TESTERS=person@example.com,team@example.com
export FIREBASE_ANDROID_ARTIFACT=aab # or apk
export IOS_FIREBASE_EXPORT_METHOD=ad-hoc
export SKIP_CHECKS=1
```

Firebase auth must be available to Fastlane. In CI, use one of:

```bash
export FIREBASE_TOKEN=...
```

or authenticate the runner with the Firebase CLI/service account strategy used by your CI.

### Google Play + Apple Store/TestFlight

Use this for store deployment:

```bash
scripts/deploy_stores.sh
```

Required Android ENV:

```bash
export ANDROID_PACKAGE_NAME=com.thuongag.khuctamgiao
export GOOGLE_PLAY_JSON_KEY_PATH=/secure/path/google-play-service-account.json
export ANDROID_KEYSTORE_PATH=/secure/path/release.keystore
export ANDROID_KEYSTORE_PASSWORD=...
export ANDROID_KEY_ALIAS=...
export ANDROID_KEY_PASSWORD=...
```

Required iOS ENV:

```bash
export IOS_BUNDLE_ID=com.it36vn.khuctamgiao
export APP_STORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey.json
export APPLE_TEAM_ID=...
export ASC_TEAM_ID=...
```

Common store ENV:

```bash
export API_BASE_URL=https://your-domain.com/api/v1
export GOOGLE_PLAY_TRACK=internal
export GOOGLE_PLAY_RELEASE_STATUS=draft
export IOS_STORE_EXPORT_METHOD=app-store
```

Optional App Store submission:

```bash
export SUBMIT_TO_APP_REVIEW=1
export APP_STORE_AUTOMATIC_RELEASE=false
export APP_STORE_SKIP_METADATA=true
export APP_STORE_SKIP_SCREENSHOTS=true
```

By default, the `stores` lane uploads Android to the configured Google Play track and uploads iOS to TestFlight. It only submits to App Review when `SUBMIT_TO_APP_REVIEW=1`.

### CI/CD Notes

- Do not commit keystores, service account JSON, App Store Connect API keys, or Firebase tokens.
- Android release signing is read from ENV in `android/app/build.gradle.kts`. Without `ANDROID_KEYSTORE_PATH`, local release builds fall back to debug signing for developer convenience.
- Google Play requires an `.aab` signed with the release key.
- iOS store deployment needs valid signing, App Store Connect API key, bundle id, capabilities, and provisioning profile.
- The Firebase lane builds Android and iOS in one run. Use `fastlane firebase_android` or `fastlane firebase_ios` for platform-specific deployment.
- The store lane deploys both platforms. Use `fastlane google_play` or `fastlane apple_store` for platform-specific deployment.

## Important Placeholders To Replace

- `https://your-domain.com/api/v1` in run/build `--dart-define`
- `your-domain.com` in `android/app/src/main/AndroidManifest.xml`
- `your-domain.com` and `www.your-domain.com` in `ios/Runner/Runner.entitlements`
- Android application id / package if publishing
- iOS bundle identifier if publishing
- App icons, display name, and signing credentials

## Current Scope Notes

- Media list is present; full media upload UI can be expanded later.
- Dynamic admin content/settings forms are generated from API field config.
- Slug/path fields should remain readonly because the backend generates them.
