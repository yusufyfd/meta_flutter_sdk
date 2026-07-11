import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'meta_flutter_sdk_method_channel.dart';

abstract class MetaFlutterSdkPlatform extends PlatformInterface {
  MetaFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();
  static MetaFlutterSdkPlatform _instance = MethodChannelMetaFlutterSdk();

  static MetaFlutterSdkPlatform get instance => _instance;

  static set instance(MetaFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<Object?, Object?>> initialize(Map<String, Object?> configuration);
  Future<void> setAutoLogAppEventsEnabled(bool enabled);
  Future<void> setAdvertiserIdCollectionEnabled(bool enabled);
  Future<void> setAdvertiserTrackingEnabled(bool enabled);
  Future<void> setDataProcessingOptions(
    List<String> options,
    int country,
    int state,
  );
  Future<void> setFlushBehavior(String behavior);
  Future<void> logEvent(
    String name,
    double? valueToSum,
    Map<String, Object?> parameters,
  );
  Future<void> flushEvents();
  Future<Map<Object?, Object?>> login({
    required List<String> permissions,
    required String tracking,
    String? nonce,
  });
  Future<void> logout();
  Future<Map<Object?, Object?>?> currentAccessToken();
  Future<String?> getAnonymousId();
  Future<void> setUserId(String? userId);
  Future<Map<Object?, Object?>> graphRequest({
    required String path,
    required String method,
    required Map<String, Object?> parameters,
    String? accessToken,
  });
}
