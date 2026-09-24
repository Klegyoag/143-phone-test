import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/features/us/domain/long_distance_time_utils.dart';

void main() {
  test('extracts positive and negative ISO offsets', () {
    expect(LongDistanceTimeUtils.utcOffsetMinutesFromIso('2026-08-27T12:00:00+05:30'), 330);
    expect(LongDistanceTimeUtils.utcOffsetMinutesFromIso('2026-08-27T12:00:00-04:00'), -240);
  });

  test('formats timezone difference without diagnosing location', () {
    expect(
      LongDistanceTimeUtils.timezoneDifferenceLabel(
        partnerIso: '2026-08-27T12:00:00+05:30',
        localOffset: const Duration(hours: 2),
      ),
      'Partner is 3h 30m ahead',
    );
  });

  test('formats flight countdown', () {
    final now = DateTime(2026, 8, 27, 10);
    expect(LongDistanceTimeUtils.countdown(now, DateTime(2026, 8, 29, 15)), '2d 5h');
  });
}
