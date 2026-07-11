library;

import 'package:flutter/services.dart';

import 'meta_flutter_sdk_platform_interface.dart';

export 'src/models.dart';
export 'src/meta_app_events.dart';

import 'src/models.dart';

/// Direct, explicit access to the native Facebook SDK on Android and iOS.
class MetaFlutterSdk {
  MetaFlutterSdk({MetaFlutterSdkPlatform? platform})
    : _platform = platform ?? MetaFlutterSdkPlatform.instance;

  static final MetaFlutterSdk instance = MetaFlutterSdk();

  final MetaFlutterSdkPlatform _platform;

  Future<MetaSdkInfo> initialize({
    MetaSdkConfiguration configuration = const MetaSdkConfiguration(),
  }) async {
    return _guard(() async {
      final value = await _platform.initialize(configuration.toMap());
      return MetaSdkInfo.fromMap(value);
    });
  }

  Future<void> setAutoLogAppEventsEnabled(bool enabled) =>
      _guard(() => _platform.setAutoLogAppEventsEnabled(enabled));

  Future<void> setAdvertiserIdCollectionEnabled(bool enabled) =>
      _guard(() => _platform.setAdvertiserIdCollectionEnabled(enabled));

  Future<void> setAdvertiserTrackingEnabled(bool enabled) =>
      _guard(() => _platform.setAdvertiserTrackingEnabled(enabled));

  Future<void> setDataProcessingOptions(
    List<String> options, {
    int country = 0,
    int state = 0,
  }) =>
      _guard(() => _platform.setDataProcessingOptions(options, country, state));

  Future<void> setFlushBehavior(MetaFlushBehavior behavior) =>
      _guard(() => _platform.setFlushBehavior(behavior.name));

  Future<void> logEvent(
    String name, {
    double? valueToSum,
    Map<String, Object?> parameters = const {},
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Event name cannot be empty.');
    }
    _validateParameters(parameters);
    return _guard(() => _platform.logEvent(name, valueToSum, parameters));
  }

  Future<void> flushEvents() => _guard(_platform.flushEvents);

  Future<MetaLoginResult> login({
    List<MetaLoginPermission> permissions = const [
      MetaLoginPermission.publicProfile,
      MetaLoginPermission.email,
    ],
    MetaLoginTracking tracking = MetaLoginTracking.enabled,
    String? nonce,
  }) async {
    return _guard(() async {
      final value = await _platform.login(
        permissions: permissions.map((e) => e.value).toList(),
        tracking: tracking.name,
        nonce: nonce,
      );
      return MetaLoginResult.fromMap(value);
    });
  }

  Future<void> logout() => _guard(_platform.logout);

  Future<MetaAccessToken?> get currentAccessToken async {
    return _guard(() async {
      final value = await _platform.currentAccessToken();
      return value == null ? null : MetaAccessToken.fromMap(value);
    });
  }

  Future<bool> get isLogged async {
    final token = await currentAccessToken;
    return token != null && !token.isExpired;
  }

  Future<String?> getAnonymousId() => _guard(_platform.getAnonymousId);

  Future<void> setUserId(String? userId) =>
      _guard(() => _platform.setUserId(userId));

  Future<MetaGraphResponse> graphRequest(
    String path, {
    MetaGraphMethod method = MetaGraphMethod.get,
    Map<String, Object?> parameters = const {},
    String? accessToken,
  }) async {
    if (path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'Graph path cannot be empty.');
    }
    _validateParameters(parameters);
    return _guard(() async {
      final value = await _platform.graphRequest(
        path: path,
        method: method.name.toUpperCase(),
        parameters: parameters,
        accessToken: accessToken,
      );
      return MetaGraphResponse.fromMap(value);
    });
  }

  static void _validateParameters(Map<String, Object?> parameters) {
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value != null &&
          value is! String &&
          value is! num &&
          value is! bool) {
        throw ArgumentError.value(
          value,
          'parameters[${entry.key}]',
          'Only String, num, bool, and null values are supported.',
        );
      }
    }
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      throw MetaSdkException(
        code: error.code,
        message: error.message ?? 'Native Meta SDK operation failed.',
        details: error.details,
      );
    }
  }
}

class MetaSdkException implements Exception {
  const MetaSdkException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'MetaSdkException($code): $message';
}
