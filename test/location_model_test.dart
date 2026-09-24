import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/features/location/data/location_repository.dart';

void main() {
  test('shared location creates chat-safe payload', () {
    final expires = DateTime.utc(2026, 8, 27, 12);
    final x = SharedLocation(id: 'loc-1', mode: 'live', latitude: 6.9271, longitude: 79.8612, status: 'active', expiresAt: expires);
    final p = x.toMessagePayload();
    expect(p['location_share_id'], 'loc-1');
    expect(p['latitude'], 6.9271);
    expect(p['longitude'], 79.8612);
    expect(p['mode'], 'live');
    expect(p['expires_at'], contains('2026-08-27'));
  });
}
