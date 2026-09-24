import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/provider/provider_readiness.dart';
import 'package:one_four_three/core/security/e2ee_engine.dart';

void main() {
  test('default E2EE engine fails closed until security review', () async {
    const engine = SecurityReviewRequiredE2eeEngine();
    expect(engine.available, isFalse);
    final state = await engine.provisioningState();
    expect(state.ready, isFalse);
    expect(() => engine.encryptText(peerUserId: 'partner', plaintext: [1, 2, 3]), throwsA(isA<StateError>()));
  });

  test('provider readiness never treats E2EE as ready by default', () {
    final items = const ProviderReadiness().inspect();
    final e2ee = items.firstWhere((e) => e.name == 'E2EE');
    expect(e2ee.ready, isFalse);
    expect(e2ee.secretRequired, isTrue);
  });
}
