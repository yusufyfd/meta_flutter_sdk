import 'package:meta_flutter_sdk/meta_flutter_sdk.dart';
import 'package:meta_flutter_sdk/meta_flutter_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMetaSdkPlatform extends MetaFlutterSdkPlatform {
  Map<String, Object?>? configuration;
  String? eventName;
  Map<String, Object?>? eventParameters;

  @override
  Future<Map<Object?, Object?>> initialize(
    Map<String, Object?> configuration,
  ) async {
    this.configuration = configuration;
    return {'platform': 'test', 'sdkVersion': '18.0.0', 'initialized': true};
  }

  @override
  Future<void> logEvent(
    String name,
    double? valueToSum,
    Map<String, Object?> parameters,
  ) async {
    eventName = name;
    eventParameters = parameters;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('initialize forwards explicit configuration', () async {
    final platform = FakeMetaSdkPlatform();
    final sdk = MetaFlutterSdk(platform: platform);

    final info = await sdk.initialize(
      configuration: const MetaSdkConfiguration(
        autoLogAppEventsEnabled: false,
        flushBehavior: MetaFlushBehavior.explicitOnly,
      ),
    );

    expect(info.platform, 'test');
    expect(info.initialized, isTrue);
    expect(platform.configuration?['autoLogAppEventsEnabled'], isFalse);
    expect(platform.configuration?['flushBehavior'], 'explicitOnly');
  });

  test('logEvent forwards supported values', () async {
    final platform = FakeMetaSdkPlatform();
    final sdk = MetaFlutterSdk(platform: platform);

    await sdk.logEvent('checkout', parameters: {'items': 2, 'coupon': true});

    expect(platform.eventName, 'checkout');
    expect(platform.eventParameters, {'items': 2, 'coupon': true});
  });

  test('logEvent rejects nested parameter values', () {
    final sdk = MetaFlutterSdk(platform: FakeMetaSdkPlatform());

    expect(
      () => sdk.logEvent('bad', parameters: {'nested': <String, String>{}}),
      throwsArgumentError,
    );
  });

  test('access token preserves permissions and dates', () {
    final token = MetaAccessToken.fromMap({
      'token': 'secret',
      'userId': '42',
      'applicationId': '7',
      'permissions': ['email'],
      'declinedPermissions': <String>[],
      'expiredPermissions': <String>[],
      'expiresAt': 1000,
      'dataAccessExpiresAt': 2000,
    });

    expect(token.userId, '42');
    expect(token.permissions, ['email']);
    expect(token.expiresAt, DateTime.fromMillisecondsSinceEpoch(1000));
  });

  test('login cancellation preserves a nullable error detail', () {
    final result = MetaLoginResult.fromMap({
      'cancelled': true,
      'accessToken': null,
      'authenticationToken': null,
      'grantedPermissions': <String>[],
      'declinedPermissions': <String>[],
      'error': {
        'code': 'login_cancelled',
        'message': 'The user cancelled Facebook Login.',
        'details': null,
      },
    });

    expect(result.cancelled, isTrue);
    expect(result.isSuccess, isFalse);
    expect(result.isFailure, isFalse);
    expect(result.error?.code, 'login_cancelled');
    expect(result.error?.details, isNull);
  });

  test('login failure preserves native error details', () {
    final result = MetaLoginResult.fromMap({
      'cancelled': false,
      'accessToken': null,
      'authenticationToken': null,
      'grantedPermissions': <String>[],
      'declinedPermissions': <String>[],
      'error': {
        'code': 'login_failed',
        'message': 'Native login failed.',
        'details': {'nativeCode': 42},
      },
    });

    expect(result.isFailure, isTrue);
    expect(result.error?.message, 'Native login failed.');
    expect(result.error?.details, {'nativeCode': 42});
  });

  test('limited login authentication token counts as success', () {
    final result = MetaLoginResult.fromMap({
      'cancelled': false,
      'accessToken': null,
      'authenticationToken': 'oidc-token',
      'grantedPermissions': <String>[],
      'declinedPermissions': <String>[],
      'error': null,
    });

    expect(result.isSuccess, isTrue);
    expect(result.isFailure, isFalse);
  });
}
