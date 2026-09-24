import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device QR schemes remain explicit', () {
    final link = Uri.parse('143://device-link/11111111-1111-1111-1111-111111111111?token=abc');
    final migration = Uri.parse('143://migration/22222222-2222-2222-2222-222222222222?token=xyz');
    expect(link.scheme, '143');
    expect(link.host, 'device-link');
    expect(migration.host, 'migration');
  });
}
