import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/features/location/domain/arrival_detector.dart';

void main() {
  test('arrival detector recognizes a point inside the radius', () {
    const destination = ArrivalDestination(
      latitude: 6.9271,
      longitude: 79.8612,
      radiusMeters: 150,
    );
    expect(
      ArrivalDetector.hasArrived(
        latitude: 6.9272,
        longitude: 79.8613,
        destination: destination,
      ),
      isTrue,
    );
  });

  test('arrival detector keeps a distant point outside the radius', () {
    const destination = ArrivalDestination(
      latitude: 6.9271,
      longitude: 79.8612,
      radiusMeters: 120,
    );
    expect(
      ArrivalDetector.hasArrived(
        latitude: 7.2906,
        longitude: 80.6337,
        destination: destination,
      ),
      isFalse,
    );
  });

  test('destination payload remains backend-compatible', () {
    const destination = ArrivalDestination(
      latitude: 6.9271,
      longitude: 79.8612,
      label: 'Home',
      radiusMeters: 120,
    );
    expect(destination.toJson()['latitude'], 6.9271);
    expect(destination.toJson()['radius_meters'], 120);
    expect(destination.toJson()['label'], 'Home');
  });
}
