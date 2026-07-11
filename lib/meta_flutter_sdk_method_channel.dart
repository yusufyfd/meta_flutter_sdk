import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'meta_flutter_sdk_platform_interface.dart';

class MethodChannelMetaFlutterSdk extends MetaFlutterSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('dev.yusufdemir/meta_flutter_sdk');

  @override
  Future<Map<Object?, Object?>> initialize(
    Map<String, Object?> configuration,
  ) async => (await methodChannel.invokeMapMethod<Object?, Object?>(
    'initialize',
    configuration,
  ))!;

  @override
  Future<void> setAutoLogAppEventsEnabled(bool enabled) => methodChannel
      .invokeMethod<void>('setAutoLogAppEventsEnabled', {'enabled': enabled});

  @override
  Future<void> setAdvertiserIdCollectionEnabled(bool enabled) =>
      methodChannel.invokeMethod<void>('setAdvertiserIdCollectionEnabled', {
        'enabled': enabled,
      });

  @override
  Future<void> setAdvertiserTrackingEnabled(bool enabled) => methodChannel
      .invokeMethod<void>('setAdvertiserTrackingEnabled', {'enabled': enabled});

  @override
  Future<void> setDataProcessingOptions(
    List<String> options,
    int country,
    int state,
  ) => methodChannel.invokeMethod<void>('setDataProcessingOptions', {
    'options': options,
    'country': country,
    'state': state,
  });

  @override
  Future<void> setFlushBehavior(String behavior) => methodChannel
      .invokeMethod<void>('setFlushBehavior', {'behavior': behavior});

  @override
  Future<void> logEvent(
    String name,
    double? valueToSum,
    Map<String, Object?> parameters,
  ) => methodChannel.invokeMethod<void>('logEvent', {
    'name': name,
    'valueToSum': valueToSum,
    'parameters': parameters,
  });

  @override
  Future<void> flushEvents() => methodChannel.invokeMethod<void>('flushEvents');

  @override
  Future<Map<Object?, Object?>> login({
    required List<String> permissions,
    required String tracking,
    String? nonce,
  }) async => (await methodChannel.invokeMapMethod<Object?, Object?>('login', {
    'permissions': permissions,
    'tracking': tracking,
    'nonce': nonce,
  }))!;

  @override
  Future<void> logout() => methodChannel.invokeMethod<void>('logout');

  @override
  Future<Map<Object?, Object?>?> currentAccessToken() =>
      methodChannel.invokeMapMethod<Object?, Object?>('currentAccessToken');

  @override
  Future<Map<Object?, Object?>> graphRequest({
    required String path,
    required String method,
    required Map<String, Object?> parameters,
    String? accessToken,
  }) async =>
      (await methodChannel.invokeMapMethod<Object?, Object?>('graphRequest', {
        'path': path,
        'method': method,
        'parameters': parameters,
        'accessToken': accessToken,
      }))!;
}
