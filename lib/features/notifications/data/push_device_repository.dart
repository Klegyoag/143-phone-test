import '../../../core/api/api_client.dart';

class PushDeviceRepository {
  PushDeviceRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> register({
    required String token,
    required String platform,
    String? deviceName,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _api.post('/push-devices', data: {
      'token': token,
      'platform': platform,
      if (deviceName != null && deviceName.isNotEmpty) 'device_name': deviceName,
      'metadata': metadata ?? {},
    });
    final data = response['data'];
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }

  Future<void> remove(String deviceId) => _api.delete('/push-devices/$deviceId');
}
