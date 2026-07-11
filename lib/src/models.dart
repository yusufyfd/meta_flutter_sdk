import 'dart:convert';

enum MetaFlushBehavior { automatic, explicitOnly }

enum MetaLoginTracking { enabled, limited }

enum MetaGraphMethod { get, post, delete }

enum MetaLoginPermission {
  publicProfile('public_profile'),
  email('email'),
  userFriends('user_friends'),
  userBirthday('user_birthday'),
  userGender('user_gender'),
  userLink('user_link'),
  userLocation('user_location'),
  userAgeRange('user_age_range');

  const MetaLoginPermission(this.value);
  final String value;
}

class MetaSdkConfiguration {
  const MetaSdkConfiguration({
    this.autoInitialize = true,
    this.autoLogAppEventsEnabled,
    this.advertiserIdCollectionEnabled,
    this.advertiserTrackingEnabled,
    this.flushBehavior,
  });

  final bool autoInitialize;
  final bool? autoLogAppEventsEnabled;
  final bool? advertiserIdCollectionEnabled;
  final bool? advertiserTrackingEnabled;
  final MetaFlushBehavior? flushBehavior;

  Map<String, Object?> toMap() => {
    'autoInitialize': autoInitialize,
    'autoLogAppEventsEnabled': autoLogAppEventsEnabled,
    'advertiserIdCollectionEnabled': advertiserIdCollectionEnabled,
    'advertiserTrackingEnabled': advertiserTrackingEnabled,
    'flushBehavior': flushBehavior?.name,
  };
}

class MetaSdkInfo {
  const MetaSdkInfo({
    required this.platform,
    required this.sdkVersion,
    required this.initialized,
  });

  factory MetaSdkInfo.fromMap(Map<Object?, Object?> map) => MetaSdkInfo(
    platform: map['platform']! as String,
    sdkVersion: map['sdkVersion']! as String,
    initialized: map['initialized']! as bool,
  );

  final String platform;
  final String sdkVersion;
  final bool initialized;
}

class MetaAccessToken {
  const MetaAccessToken({
    required this.token,
    required this.userId,
    required this.applicationId,
    required this.permissions,
    required this.declinedPermissions,
    required this.expiredPermissions,
    required this.expiresAt,
    this.dataAccessExpiresAt,
  });

  factory MetaAccessToken.fromMap(Map<Object?, Object?> map) => MetaAccessToken(
    token: map['token']! as String,
    userId: map['userId']! as String,
    applicationId: map['applicationId']! as String,
    permissions: _strings(map['permissions']),
    declinedPermissions: _strings(map['declinedPermissions']),
    expiredPermissions: _strings(map['expiredPermissions']),
    expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt']! as int),
    dataAccessExpiresAt: map['dataAccessExpiresAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            map['dataAccessExpiresAt']! as int,
          ),
  );

  final String token;
  final String userId;
  final String applicationId;
  final List<String> permissions;
  final List<String> declinedPermissions;
  final List<String> expiredPermissions;
  final DateTime expiresAt;
  final DateTime? dataAccessExpiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class MetaLoginResult {
  const MetaLoginResult._({
    required this.cancelled,
    this.accessToken,
    this.authenticationToken,
    this.grantedPermissions = const [],
    this.declinedPermissions = const [],
    this.error,
  });

  factory MetaLoginResult.fromMap(Map<Object?, Object?> map) =>
      MetaLoginResult._(
        cancelled: map['cancelled']! as bool,
        accessToken: map['accessToken'] == null
            ? null
            : MetaAccessToken.fromMap(
                map['accessToken']! as Map<Object?, Object?>,
              ),
        authenticationToken: map['authenticationToken'] as String?,
        grantedPermissions: _strings(map['grantedPermissions']),
        declinedPermissions: _strings(map['declinedPermissions']),
        error: map['error'] == null
            ? null
            : MetaLoginError.fromMap(map['error']! as Map<Object?, Object?>),
      );

  final bool cancelled;
  final MetaAccessToken? accessToken;

  /// The OpenID Connect token returned by iOS Limited Login.
  final String? authenticationToken;
  final List<String> grantedPermissions;
  final List<String> declinedPermissions;
  final MetaLoginError? error;

  bool get isSuccess =>
      !cancelled &&
      error == null &&
      (accessToken != null || authenticationToken != null);

  bool get isFailure => error != null && !cancelled;
}

class MetaLoginError {
  const MetaLoginError({
    required this.code,
    required this.message,
    this.details,
  });

  factory MetaLoginError.fromMap(Map<Object?, Object?> map) => MetaLoginError(
    code: map['code']! as String,
    message: map['message']! as String,
    details: map['details'],
  );

  final String code;
  final String message;

  /// Platform-specific diagnostic data. This can be null, particularly when
  /// the user deliberately cancels login.
  final Object? details;
}

class MetaGraphResponse {
  const MetaGraphResponse({required this.statusCode, required this.body});

  factory MetaGraphResponse.fromMap(Map<Object?, Object?> map) =>
      MetaGraphResponse(
        statusCode: map['statusCode']! as int,
        body: map['body']! as String,
      );

  final int statusCode;
  final String body;

  Object? get json => jsonDecode(body);
}

List<String> _strings(Object? value) =>
    (value as List<Object?>? ?? const []).cast<String>();
