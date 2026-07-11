import 'package:meta_flutter_sdk_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows explicit SDK actions', (tester) async {
    await tester.pumpWidget(const MetaSdkExample());

    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Facebook Login'), findsOneWidget);
  });
}
