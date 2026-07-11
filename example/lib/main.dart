import 'package:flutter/material.dart';
import 'package:meta_flutter_sdk/meta_flutter_sdk.dart';

void main() => runApp(const MetaSdkExample());

class MetaSdkExample extends StatefulWidget {
  const MetaSdkExample({super.key});

  @override
  State<MetaSdkExample> createState() => _MetaSdkExampleState();
}

class _MetaSdkExampleState extends State<MetaSdkExample> {
  final sdk = MetaFlutterSdk.instance;
  String status = 'Not initialized';

  Future<void> initialize() async {
    try {
      final info = await sdk.initialize(
        configuration: const MetaSdkConfiguration(
          autoLogAppEventsEnabled: false,
          advertiserIdCollectionEnabled: false,
          flushBehavior: MetaFlushBehavior.explicitOnly,
        ),
      );
      setState(() => status = '${info.platform} / SDK ${info.sdkVersion}');
    } on MetaSdkException catch (error) {
      setState(() => status = '${error.code}: ${error.message}');
    }
  }

  Future<void> login() async {
    try {
      final login = await sdk.login();
      setState(() {
        if (login.cancelled) {
          status = login.error?.message ?? 'Login cancelled';
        } else if (login.isFailure) {
          status = '${login.error!.code}: ${login.error!.message}';
        } else {
          status = 'User: ${login.accessToken?.userId}';
        }
      });
    } on MetaSdkException catch (error) {
      setState(() => status = '${error.code}: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Meta Flutter SDK')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(status),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: initialize,
                child: const Text('Initialize'),
              ),
              FilledButton(
                onPressed: login,
                child: const Text('Facebook Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
