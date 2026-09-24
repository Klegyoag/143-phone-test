import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/features/location/data/location_repository.dart';

void main() {
  test('shared location payload preserves explicit expiry', () {
    final expiry = DateTime.utc(2026, 8, 27, 12);
    final location = SharedLocation(id: 'loc-1', mode: 'live', latitude: 6.9, longitude: 79.8, status: 'active', expiresAt: expiry);
    expect(location.toMessagePayload()['expires_at'], expiry.toIso8601String());
    expect(location.toMessagePayload()['mode'], 'live');
  });
}
