# Meta Flutter SDK

A privacy-aware Flutter plugin for Facebook Login, App Events, access tokens,
and Graph API requests on Android and iOS.

`meta_flutter_sdk` provides a small, typed Dart API over Meta's native Facebook
SDKs. It gives the application explicit control over SDK initialization and
data-collection settings, preserves native errors, supports iOS Limited Login,
and uses the modern iOS `UIScene` lifecycle.

> This is a community package and is not an official Meta or Facebook product.

## Features

- Explicit Facebook SDK initialization
- Standard Facebook Login on Android and iOS
- Limited Login with an OpenID Connect token on iOS
- Structured login outcomes for success, cancellation, and native failure
- Current access token, expiration dates, and permission details
- Login status and logout helpers
- Custom and standard App Events
- Event values, parameters, manual flushing, and configurable flush behavior
- Anonymous App Events ID and custom user ID support
- Auto App Event logging and advertiser ID collection controls
- Advertiser tracking control on iOS
- Data Processing Options, including Limited Data Use
- Raw Graph API `GET`, `POST`, and `DELETE` requests
- CocoaPods and Swift Package Manager support on iOS
- Bundled iOS privacy manifest
- `UIScene` lifecycle and Facebook Login callback support on iOS

## Platform support

| Capability | Android | iOS |
| --- | :---: | :---: |
| Minimum platform | API 24 | iOS 13 |
| Explicit initialization | ✅ | ✅ |
| Standard Facebook Login | ✅ | ✅ |
| iOS Limited Login | — | ✅ |
| Access token and permissions | ✅ | ✅ |
| App Events | ✅ | ✅ |
| Data Processing Options | ✅ | ✅ |
| Advertiser ID collection control | ✅ | ✅ |
| Advertiser tracking control | — | ✅ |
| Graph API requests | ✅ | ✅ |

The native dependencies are pinned so builds remain predictable:

- Android Facebook SDK: `18.2.3`
- iOS Facebook SDK: `18.0.3`

## Requirements

- Flutter `3.38.0` or newer
- Dart `3.12.2` or newer
- Android API level 24 or newer
- iOS 13.0 or newer
- A Meta developer application with Android and/or iOS configured
- A Facebook App ID and client token

Before testing Login, configure your Android package name, Android key hashes,
and/or iOS bundle identifier in the
[Meta App Dashboard](https://developers.facebook.com/apps/). People who are not
app administrators, developers, or testers can only log in after the Meta app
and the required permissions are available for public use.

## Installation

Add the package to your Flutter application:

```shell
flutter pub add meta_flutter_sdk
```

Or add it manually to `pubspec.yaml`:

```yaml
dependencies:
  meta_flutter_sdk: ^0.4.0
```

Then import the public library:

```dart
import 'package:meta_flutter_sdk/meta_flutter_sdk.dart';
```

## Platform configuration

### Android

Create or update `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Your App Name</string>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

Add the following entries inside the `<application>` element in
`android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="@string/app_name"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">

    <meta-data
        android:name="com.facebook.sdk.ApplicationId"
        android:value="@string/facebook_app_id" />
    <meta-data
        android:name="com.facebook.sdk.ClientToken"
        android:value="@string/facebook_client_token" />

    <!-- Recommended for consent-first initialization. -->
    <meta-data
        android:name="com.facebook.sdk.AutoInitEnabled"
        android:value="false" />
    <meta-data
        android:name="com.facebook.sdk.AutoLogAppEventsEnabled"
        android:value="false" />
    <meta-data
        android:name="com.facebook.sdk.AdvertiserIDCollectionEnabled"
        android:value="false" />

    <!-- Keep the rest of your application configuration here. -->
</application>
```

The Facebook Android SDK contributes its activities and provider through
Android manifest merging. You do not need to copy those declarations into your
application.

In the Meta App Dashboard, make sure that:

- The Android package name matches your `applicationId`.
- The default activity matches your Flutter activity.
- Development and release key hashes are registered.
- Facebook Login is enabled for your Meta app.

### iOS

Add your Facebook configuration and URL scheme to
`ios/Runner/Info.plist`, inside the root `<dict>`:

```xml
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>YOUR_APP_NAME</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>fbauth2</string>
    <string>fbshareextension</string>
</array>

<!-- Recommended for consent-first initialization. -->
<key>FacebookAutoInitEnabled</key>
<false/>
<key>FacebookAutoLogAppEventsEnabled</key>
<false/>
<key>FacebookAdvertiserIDCollectionEnabled</key>
<false/>
```

Replace `YOUR_FACEBOOK_APP_ID` in both locations. For example, if the App ID is
`123456789`, the URL scheme must be `fb123456789`.

In the Meta App Dashboard, make sure that the configured iOS bundle identifier
exactly matches the application's `PRODUCT_BUNDLE_IDENTIFIER`.

The plugin supports Flutter's `UIScene` lifecycle and forwards scene-based URL
callbacks to the Facebook SDK. Applications generated by current Flutter
versions do not need custom AppDelegate or SceneDelegate forwarding code for
this plugin.

### App Tracking Transparency on iOS

This package does not display Apple's App Tracking Transparency prompt. The
host application owns the consent experience. Request permission using your
preferred ATT package, then update the Meta setting only when it is appropriate
for your application and privacy policy:

```dart
await MetaFlutterSdk.instance.setAdvertiserTrackingEnabled(true);
```

Calling this method changes the Meta SDK setting; it does not request system
permission. On Android, this method throws a `MetaSdkException` with the code
`unsupported`.

## Quick start

Initialize the SDK before using Login, App Events, or Graph API methods:

```dart
import 'package:meta_flutter_sdk/meta_flutter_sdk.dart';

final meta = MetaFlutterSdk.instance;

Future<void> configureMetaSdk() async {
  final info = await meta.initialize(
    configuration: const MetaSdkConfiguration(
      autoInitialize: true,
      autoLogAppEventsEnabled: false,
      advertiserIdCollectionEnabled: false,
      flushBehavior: MetaFlushBehavior.automatic,
    ),
  );

  print('Meta SDK ${info.sdkVersion} initialized on ${info.platform}');
}
```

`initialize()` returns a `MetaSdkInfo` containing the platform, native SDK
version, and initialization state.

## Privacy-first initialization

For applications that must collect consent before activating the native SDK,
disable automatic initialization in the platform files as shown above. You can
also explicitly keep initialization and collection disabled from Dart:

```dart
final info = await meta.initialize(
  configuration: const MetaSdkConfiguration(
    autoInitialize: false,
    autoLogAppEventsEnabled: false,
    advertiserIdCollectionEnabled: false,
  ),
);

print(info.initialized); // false
```

After consent is available, initialize the SDK and enable only the settings
your application needs:

```dart
await meta.initialize(
  configuration: const MetaSdkConfiguration(
    autoInitialize: true,
    autoLogAppEventsEnabled: true,
    advertiserIdCollectionEnabled: true,
  ),
);
```

Settings can also be changed independently:

```dart
await meta.setAutoLogAppEventsEnabled(true);
await meta.setAdvertiserIdCollectionEnabled(true);
await meta.setFlushBehavior(MetaFlushBehavior.explicitOnly);
```

### Initialization options

| Option | Type | Description |
| --- | --- | --- |
| `autoInitialize` | `bool` | Initializes the native SDK when `true`. Defaults to `true`. |
| `autoLogAppEventsEnabled` | `bool?` | Enables or disables automatic App Event logging. `null` keeps the native setting. |
| `advertiserIdCollectionEnabled` | `bool?` | Controls advertiser identifier collection. `null` keeps the native setting. |
| `advertiserTrackingEnabled` | `bool?` | Controls advertiser tracking on iOS. Unsupported on Android. |
| `flushBehavior` | `MetaFlushBehavior?` | Selects automatic or explicit-only event flushing. |

## Facebook Login

### Standard Login

Standard Login is supported on both Android and iOS:

```dart
final result = await meta.login(
  permissions: const [
    MetaLoginPermission.publicProfile,
    MetaLoginPermission.email,
  ],
);

if (result.isSuccess) {
  final token = result.accessToken!;
  print('User ID: ${token.userId}');
  print('Granted: ${result.grantedPermissions}');
  print('Declined: ${result.declinedPermissions}');
} else if (result.cancelled) {
  print(result.error?.message ?? 'Login was cancelled.');
} else if (result.isFailure) {
  print('${result.error!.code}: ${result.error!.message}');
  print(result.error!.details);
}
```

The default permissions are `publicProfile` and `email`. The package also
provides typed values for `userFriends`, `userBirthday`, `userGender`,
`userLink`, `userLocation`, and `userAgeRange`.

Some permissions require App Review and additional configuration in the Meta
App Dashboard. A requested permission is not guaranteed to be granted, so
always inspect `grantedPermissions` and `declinedPermissions`.

### Login result states

`MetaLoginResult` represents three normal native Login outcomes:

| State | Check | Error |
| --- | --- | --- |
| Success | `result.isSuccess` | `null` |
| User cancellation | `result.cancelled` | `login_cancelled` |
| Native Login failure | `result.isFailure` | `login_failed` with platform diagnostics when available |

`MetaLoginError.details` is platform-specific and nullable. Cancellation is a
normal outcome and usually has no native diagnostic details.

Configuration and platform errors that happen before the native Login flow
starts, such as `no_activity`, `login_in_progress`, or `unsupported`, are
reported as `MetaSdkException`.

### Limited Login on iOS

Limited Login returns an OpenID Connect authentication token and is useful when
the iOS tracking status requires a limited authentication flow. Generate a
cryptographically secure nonce in your application and pass it to `login()`:

```dart
final result = await meta.login(
  tracking: MetaLoginTracking.limited,
  nonce: secureNonce,
);

if (result.isSuccess) {
  final oidcToken = result.authenticationToken;
  print('Authentication token: $oidcToken');
}
```

Validate the authentication token and nonce on a trusted backend before using
them to establish an application session. Limited Login is iOS-only. Requesting
it on Android throws `MetaSdkException(code: 'unsupported', ...)` rather than
silently changing to Standard Login.

## Access tokens and logout

Read the current Standard Login access token:

```dart
final token = await meta.currentAccessToken;

if (token != null && !token.isExpired) {
  print(token.token);
  print(token.userId);
  print(token.applicationId);
  print(token.permissions);
  print(token.declinedPermissions);
  print(token.expiredPermissions);
  print(token.expiresAt);
  print(token.dataAccessExpiresAt);
}
```

Use the convenience login-state getter when working with Standard Login:

```dart
final loggedIn = await meta.isLogged;
```

`isLogged` checks for a non-expired Facebook access token. Limited Login uses
an authentication token instead, so manage your Limited Login session through
your backend rather than relying on `isLogged`.

Log out and clear the native Login session:

```dart
await meta.logout();
```

Access tokens and authentication tokens are credentials. Do not log them in
production, commit them to source control, or send them to untrusted services.

## App Events

Log a custom event with optional parameters and a value to sum:

```dart
await meta.logEvent(
  'checkout_completed',
  valueToSum: 49.90,
  parameters: const {
    'currency': 'USD',
    'item_count': 2,
    'used_coupon': true,
  },
);
```

The package includes constants for common Meta App Event names:

```dart
await meta.logEvent(
  MetaAppEvents.purchased,
  valueToSum: 49.90,
  parameters: const {'currency': 'USD'},
);

await meta.logEvent(MetaAppEvents.completedRegistration);
await meta.logEvent(MetaAppEvents.viewedContent);
```

Available constants include ad click, ad impression, completed registration,
completed tutorial, contact, customize product, donate, find location, rated,
schedule, searched, start trial, submit application, subscribe, viewed content,
added payment info, added to cart, added to wishlist, initiated checkout,
purchased, achieved level, unlocked achievement, and spent credits.

Event parameters accept flat `String`, `num`, `bool`, or `null` values. Nested
maps, lists, and custom objects are rejected with `ArgumentError` before the
method reaches the native SDK.

### Flush behavior

Use automatic flushing for the native SDK's default behavior:

```dart
await meta.setFlushBehavior(MetaFlushBehavior.automatic);
```

Or keep events queued until your application explicitly flushes them:

```dart
await meta.setFlushBehavior(MetaFlushBehavior.explicitOnly);

await meta.logEvent('offline_action_completed');
await meta.flushEvents();
```

### User and anonymous identifiers

Associate App Events with an application-specific user ID:

```dart
await meta.setUserId('your-internal-user-id');
```

Clear it when the application user signs out:

```dart
await meta.setUserId(null);
```

Read the anonymous App Events identifier assigned by the native SDK:

```dart
final anonymousId = await meta.getAnonymousId();
```

Do not pass email addresses, phone numbers, access tokens, or other sensitive
data as event names, parameters, or custom user IDs unless your use complies
with Meta's terms, applicable law, and your disclosed privacy policy.

## Data Processing Options

Configure Data Processing Options before logging events. For example, Limited
Data Use can be enabled with:

```dart
await meta.setDataProcessingOptions(
  const ['LDU'],
  country: 0,
  state: 0,
);
```

Clear Data Processing Options with an empty list:

```dart
await meta.setDataProcessingOptions(const []);
```

The meaning of the option, country, and state values is defined by Meta and can
change independently of this package. Confirm the correct values for your use
case in Meta's current documentation and with your privacy or legal team.

## Graph API

Make a `GET` request using the current access token:

```dart
final response = await meta.graphRequest(
  '/me',
  parameters: const {'fields': 'id,name,email'},
);

print(response.statusCode);
print(response.body);
print(response.json);
```

Select another supported HTTP method when needed:

```dart
final response = await meta.graphRequest(
  '/me/some_edge',
  method: MetaGraphMethod.post,
  parameters: const {'message': 'Example value'},
);
```

Pass a token explicitly instead of using the current token:

```dart
final response = await meta.graphRequest(
  '/me',
  accessToken: tokenFromYourSecureSession,
);
```

Supported methods are `GET`, `POST`, and `DELETE`. Graph parameters use the
same flat value rules as App Event parameters. `response.body` contains the raw
response text and `response.json` decodes it with `jsonDecode`.

Graph API failures throw `MetaSdkException` with the code `graph_error`. On
Android, details can include the Graph error type, code, subcode, and raw body.

Use a trusted backend for app-secret-protected requests, token exchange, token
validation, webhooks, and privileged business operations. Never place a Meta
app secret in a Flutter application.

## Error handling

Operations that fail before producing a normal result throw
`MetaSdkException`:

```dart
try {
  await meta.flushEvents();
} on MetaSdkException catch (error) {
  print('Code: ${error.code}');
  print('Message: ${error.message}');
  print('Details: ${error.details}');
} on ArgumentError catch (error) {
  print('Invalid Dart argument: $error');
}
```

| Error code | Typical meaning |
| --- | --- |
| `native_error` | A native SDK or platform operation failed. |
| `graph_error` | The Graph API returned an error. |
| `serialization_error` | An iOS Graph response could not be serialized. |
| `no_activity` | Android Login was requested without a foreground Activity. |
| `login_in_progress` | Another Android Login request is already active. |
| `unsupported` | The requested feature is not available on the platform. |

Native detail objects are preserved when they can safely cross Flutter's
platform channel. `MetaSdkException.details` and `MetaLoginError.details` are
nullable, so application error handling must not assume they are present.

## API overview

| API | Purpose |
| --- | --- |
| `initialize()` | Applies configuration and optionally initializes the native SDK. |
| `setAutoLogAppEventsEnabled()` | Controls automatic App Event logging. |
| `setAdvertiserIdCollectionEnabled()` | Controls advertiser identifier collection. |
| `setAdvertiserTrackingEnabled()` | Controls advertiser tracking on iOS. |
| `setDataProcessingOptions()` | Applies Meta Data Processing Options. |
| `setFlushBehavior()` | Selects automatic or explicit event flushing. |
| `logEvent()` | Logs a custom or standard App Event. |
| `flushEvents()` | Immediately flushes queued App Events. |
| `login()` | Starts Standard Login or iOS Limited Login. |
| `logout()` | Clears the native Facebook Login session. |
| `currentAccessToken` | Returns the current Standard Login access token. |
| `isLogged` | Checks for a current, non-expired access token. |
| `getAnonymousId()` | Returns the native App Events anonymous identifier. |
| `setUserId()` | Sets or clears an application-specific App Events user ID. |
| `graphRequest()` | Performs a raw Graph API request. |

## Troubleshooting

### Login opens but does not return to the app on iOS

- Confirm that `CFBundleURLTypes` contains `fbYOUR_FACEBOOK_APP_ID`.
- Confirm that `FacebookAppID` contains the same App ID without the `fb` prefix.
- Confirm that the bundle identifier matches the Meta App Dashboard.
- Rebuild the application after changing `Info.plist`.

The package already registers for Flutter's `UIScene` and legacy application
lifecycle callbacks. Do not add duplicate Facebook URL forwarding unless your
application has another integration that explicitly requires it.

### Android Login fails for release builds

- Register the release signing key hash in the Meta App Dashboard.
- Confirm that the release `applicationId` matches the configured package name.
- Confirm that the client token belongs to the same Meta app as the App ID.
- Make sure the SDK has been initialized before calling `login()`.

### Login works only for app administrators or testers

Check the Meta app's mode, configured test users and roles, App Review status,
and permission availability. This behavior is controlled by Meta rather than
the Flutter plugin.

### `unsupported` is thrown on Android

iOS Limited Login and advertiser tracking status are iOS-only features. Use
Standard Login and advertiser ID collection controls on Android.

### App Events are not visible immediately

- Confirm that SDK initialization completed successfully.
- Check whether `MetaFlushBehavior.explicitOnly` is active.
- Call `flushEvents()` when using explicit-only behavior.
- Confirm your collection settings and consent state.
- Allow for processing time in Meta's event tools.

## Privacy and security responsibilities

This package exposes controls; it does not decide when collection is lawful or
appropriate for your application. Application developers are responsible for:

- Presenting consent and privacy notices where required.
- Respecting ATT and other platform privacy requirements.
- Enabling collection only in accordance with user choices.
- Declaring data use accurately in Google Play and App Store submissions.
- Following Meta Platform Terms and applicable law.
- Protecting access tokens, authentication tokens, and user identifiers.
- Keeping app secrets and privileged credentials on a trusted backend.

Review Meta's current platform documentation before releasing an application,
because dashboard settings, permission requirements, and privacy obligations
can change independently of this package.

## Additional resources

- [Complete example](https://github.com/yusufyfd/meta_flutter_sdk/tree/main/example)
- [Issue tracker](https://github.com/yusufyfd/meta_flutter_sdk/issues)
- [Meta for Developers](https://developers.facebook.com/)
- [Meta App Dashboard](https://developers.facebook.com/apps/)
- [Flutter package documentation](https://docs.flutter.dev/packages-and-plugins/using-packages)

## Contributing

Bug reports and focused pull requests are welcome. When reporting an issue,
include the Flutter version, platform and OS version, plugin version, native
error code, and a minimal reproduction. Do not include access tokens, client
tokens, app secrets, personal data, or other credentials.

## License

This package is available under the license in the
[LICENSE](https://github.com/yusufyfd/meta_flutter_sdk/blob/main/LICENSE) file.
