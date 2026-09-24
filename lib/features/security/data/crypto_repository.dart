import '../../../core/api/api_client.dart';

/// Backend transport boundary for E2EE public key material.
///
/// This repository deliberately does NOT generate private keys or encrypt chat
/// payloads. A reviewed client crypto engine must generate private material on
/// device and keep it in platform-secure storage. Only public bundles/prekeys
/// should be sent through these methods.
class CryptoRepository {
  CryptoRepository(this._api);
  final ApiClient _api;

  dynamic _data(Map<String, dynamic> r) => r['data'];

  List<Map<String, dynamic>> _list(dynamic v) {
    if (v is Map && v['data'] is List) v = v['data'];
    return v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> deviceKeyStatus() async => _list(_data(await _api.get('/crypto/devices/keys/status')));

  Future<Map<String, dynamic>> registerPublicBundle({
    required String deviceId,
    required Map<String, dynamic> identityKey,
    Map<String, dynamic>? signedPrekey,
  }) async {
    final d = _data(await _api.post('/crypto/devices/keys', data: {
      'device_id': deviceId,
      'identity_key': identityKey,
      if (signedPrekey != null) 'signed_prekey': signedPrekey,
    }));
    return d is Map ? d.cast<String, dynamic>() : <String, dynamic>{};
  }

  Future<void> updateSignedPrekey({required String deviceId, required Map<String, dynamic> signedPrekey}) =>
      _api.put('/crypto/devices/keys/signed-prekey', data: {'device_id': deviceId, 'signed_prekey': signedPrekey});

  Future<void> uploadOneTimePrekeys({required String deviceId, required List<Map<String, dynamic>> prekeys}) =>
      _api.post('/crypto/devices/keys/one-time-prekeys', data: {'device_id': deviceId, 'prekeys': prekeys});

  Future<List<Map<String, dynamic>>> userKeyBundle(String userId) async =>
      _list(_data(await _api.get('/crypto/users/$userId/key-bundle')));
}
