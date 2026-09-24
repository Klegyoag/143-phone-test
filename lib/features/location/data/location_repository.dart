import '../../../core/api/api_client.dart';

class SharedLocation {
  const SharedLocation({
    required this.id,
    required this.mode,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.expiresAt,
    this.destination,
  });

  final String id;
  final String mode;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime? expiresAt;
  final Map<String, dynamic>? destination;

  factory SharedLocation.fromJson(Map<String, dynamic> json) => SharedLocation(
        id: '${json['id'] ?? ''}',
        mode: '${json['mode'] ?? 'single'}',
        latitude: double.tryParse('${json['latitude'] ?? 0}') ?? 0,
        longitude: double.tryParse('${json['longitude'] ?? 0}') ?? 0,
        status: '${json['status'] ?? 'active'}',
        expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}'),
        destination: json['destination'] is Map ? (json['destination'] as Map).cast<String, dynamic>() : null,
      );

  Map<String, dynamic> toMessagePayload() => {
        'location_share_id': id,
        'latitude': latitude,
        'longitude': longitude,
        'mode': mode,
        if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
        if (destination != null) 'destination': destination,
      };
}

class LocationRepository {
  LocationRepository(this._api);
  final ApiClient _api;

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      (response['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  Future<SharedLocation> create({
    required double latitude,
    required double longitude,
    String mode = 'single',
    DateTime? expiresAt,
    Map<String, dynamic>? destination,
  }) async {
    final response = await _api.post('/location-shares', data: {
      'mode': mode,
      'latitude': latitude,
      'longitude': longitude,
      if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
      if (destination != null) 'destination': destination,
      'metadata': {'source': 'flutter'},
    });
    return SharedLocation.fromJson(_data(response));
  }

  Future<SharedLocation> get(String id) async =>
      SharedLocation.fromJson(_data(await _api.get('/location-shares/$id')));

  Future<void> update(String id, double latitude, double longitude) =>
      _api.patch('/location-shares/$id', data: {'latitude': latitude, 'longitude': longitude});

  Future<void> stop(String id) => _api.delete('/location-shares/$id');

  Future<Map<String, dynamic>> status(String id) async =>
      _data(await _api.get('/location-shares/$id/status'));
}
