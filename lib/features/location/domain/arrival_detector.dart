import 'dart:math' as math;

class ArrivalDestination {
  const ArrivalDestination({
    required this.latitude,
    required this.longitude,
    this.label,
    this.radiusMeters = 120,
  });

  final double latitude;
  final double longitude;
  final String? label;
  final double radiusMeters;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        if (label?.trim().isNotEmpty == true) 'label': label!.trim(),
      };

  factory ArrivalDestination.fromJson(Map<String, dynamic> json) =>
      ArrivalDestination(
        latitude: double.tryParse('${json['latitude'] ?? 0}') ?? 0,
        longitude: double.tryParse('${json['longitude'] ?? 0}') ?? 0,
        radiusMeters:
            double.tryParse('${json['radius_meters'] ?? 120}') ?? 120,
        label: json['label']?.toString(),
      );
}

class ArrivalDetector {
  const ArrivalDetector._();

  static double distanceMeters({
    required double latitude,
    required double longitude,
    required ArrivalDestination destination,
  }) {
    const earthRadiusMeters = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180.0;
    final lat1 = radians(latitude);
    final lat2 = radians(destination.latitude);
    final deltaLat = radians(destination.latitude - latitude);
    final deltaLon = radians(destination.longitude - longitude);
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static bool hasArrived({
    required double latitude,
    required double longitude,
    required ArrivalDestination destination,
  }) =>
      distanceMeters(
        latitude: latitude,
        longitude: longitude,
        destination: destination,
      ) <= destination.radiusMeters;
}
