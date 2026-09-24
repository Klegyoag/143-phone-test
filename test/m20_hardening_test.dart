import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/navigation/deep_link_target.dart';

void main() {
  group('Milestone 31 hardening', () {
    test('widget Quick Ping deep link opens confirmation route', () {
      final target =
          DeepLinkTarget.fromUri(Uri.parse('onefourthree://widget/ping'));
      expect(target.location, '/widget-ping');
      expect(target.tabIndex, 0);
    });

    test('call notification deep link preserves call context', () {
      final target = DeepLinkTarget.fromPayload({
        'type': 'incoming_call',
        'call_id': 'call-42',
        'call_type': 'video'
      });
      expect(target.location, contains('/call/call-42'));
      expect(target.location, contains('type=video'));
      expect(target.tabIndex, 3);
    });
  });
}
