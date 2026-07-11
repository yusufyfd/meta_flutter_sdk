# meta_flutter_sdk

Explicit, privacy-aware Flutter access to Facebook's native Android and iOS
SDKs. The package does not hide native errors or force automatic event
collection.

## Supported features

- Explicit SDK initialization
- Facebook Login, including iOS Limited Login
- Current access token and permission details
- Custom App Events, value-to-sum, flush, and flush behavior
- Auto event logging, advertiser ID collection, and advertiser tracking flags
- Data Processing Options / Limited Data Use
- Raw GET, POST, and DELETE Graph API requests
- CocoaPods and Swift Package Manager metadata

Native SDK versions are intentionally pinned:

- Android: `com.facebook.android:facebook-android-sdk:18.2.3`
- iOS: `FBSDKCoreKit` and `FBSDKLoginKit` `18.0.3`

## Install

```yaml
dependencies:
  meta_flutter_sdk:
    path: ../meta-flutter-sdk
```

### Android configuration

Add credentials to `android/app/src/main/res/values/strings.xml`:

```xml
<resources>
    <string name="facebook_app_id">YOUR_APP_ID</string>
    <string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
</resources>
```

Add the following inside `<application>` in the app's `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id" />
<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token" />

<!-- Recommended when consent must be collected before initialization. -->
<meta-data
    android:name="com.facebook.sdk.AutoInitEnabled"
    android:value="false" />
<meta-data
    android:name="com.facebook.sdk.AutoLogAppEventsEnabled"
    android:value="false" />
<meta-data
    android:name="com.facebook.sdk.AdvertiserIDCollectionEnabled"
    android:value="false" />
```

The native SDK contributes its activities and provider through manifest
merging. Do not put an app secret in the application.

### iOS configuration

Add the app ID, client token, display name, and URL scheme to the app's
`Info.plist`:

```xml
<key>FacebookAppID</key>
<string>YOUR_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>YOUR_DISPLAY_NAME</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>fbYOUR_APP_ID</string></array>
  </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fb-messenger-share-api</string>
</array>

<!-- Recommended when consent must be collected first. -->
<key>FacebookAutoInitEnabled</key>
<false/>
<key>FacebookAutoLogAppEventsEnabled</key>
<false/>
<key>FacebookAdvertiserIDCollectionEnabled</key>
<false/>
```

The plugin does not show Apple's App Tracking Transparency prompt. The host
app owns that UX and must only enable tracking in accordance with the ATT
status and its privacy policy.

## Explicit initialization

```dart
final meta = MetaFlutterSdk.instance;

final info = await meta.initialize(
  configuration: const MetaSdkConfiguration(
    autoLogAppEventsEnabled: false,
    advertiserIdCollectionEnabled: false,
    flushBehavior: MetaFlushBehavior.explicitOnly,
  ),
);
```

When consent is granted, flags can be changed independently:

```dart
await meta.setAutoLogAppEventsEnabled(true);
await meta.setAdvertiserIdCollectionEnabled(true);
```

`setAdvertiserTrackingEnabled` is iOS-only. On current iOS/Meta SDK versions,
the effective value can be derived from ATT status; calling this method never
requests ATT permission.

## App Events

```dart
await meta.logEvent(
  'checkout_completed',
  valueToSum: 49.90,
  parameters: {
    'currency': 'TRY',
    'item_count': 2,
    'used_coupon': true,
  },
);

await meta.flushEvents();
```

Event and Graph parameters accept `String`, `num`, `bool`, or `null` values.

## Login

```dart
final login = await meta.login(
  permissions: const ['public_profile', 'email'],
);

if (login.isSuccess) {
  print(login.accessToken?.userId);
} else {
  print('${login.error?.code}: ${login.error?.message}');
  print(login.error?.details); // Can be null for user cancellation.
}
```

iOS Limited Login returns an OpenID Connect authentication token instead of a
Graph access token:

```dart
final login = await meta.login(
  tracking: MetaLoginTracking.limited,
  nonce: cryptographicallySecureNonce,
);

final oidcToken = login.authenticationToken;
```

Limited Login is rejected as unsupported on Android rather than silently
falling back to tracking-enabled login.

## Graph API

```dart
final response = await meta.graphRequest(
  '/me',
  parameters: const {'fields': 'id,name,email'},
);

final json = response.json;
```

Use an app backend for app-secret-protected requests, token exchange, token
validation, and webhooks. An app secret must never be shipped in Flutter code.

## Error handling

```dart
try {
  await meta.flushEvents();
} on MetaSdkException catch (error) {
  print('${error.code}: ${error.message}');
  print(error.details);
}
```

Native error codes and details are preserved. Invalid Dart parameter shapes
throw `ArgumentError` before crossing the platform channel.
