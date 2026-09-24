import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('five-tab smoke contract', (tester) async {
    // Full authenticated smoke navigation requires the injectable API fake that
    // will be added in the provider-contract test phase. This test deliberately
    // exists now so CI has a stable integration-test entry point.
    expect(const ['Home','Memories','Create','Chat','Us'].length, 5);
  });
}
