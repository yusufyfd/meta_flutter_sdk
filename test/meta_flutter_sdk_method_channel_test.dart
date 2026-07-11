import 'package:flutter/services.dart';
import 'package:meta_flutter_sdk/meta_flutter_sdk_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.yusufdemir/meta_flutter_sdk');
  final platform = MethodChannelMetaFlutterSdk();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize uses the stable channel contract', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'initialize');
          expect(
            (call.arguments as Map<Object?, Object?>)['autoInitialize'],
            true,
          );
          return {
            'platform': 'android',
            'sdkVersion': '18.2.3',
            'initialized': true,
          };
        });

    final value = await platform.initialize({'autoInitialize': true});
    expect(value['sdkVersion'], '18.2.3');
  });
}
