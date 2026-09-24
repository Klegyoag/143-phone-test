import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device QR schemes remain explicit', () {
    final link = Uri.parse(
        'onefourthree://device-link/11111111-1111-1111-1111-111111111111?token=abc');
    final migration = Uri.parse(
        'onefourthree://migration/22222222-2222-2222-2222-222222222222?token=xyz');
    expect(link.scheme, 'onefourthree');
    expect(link.host, 'device-link');
    expect(migration.host, 'migration');
  });
}
