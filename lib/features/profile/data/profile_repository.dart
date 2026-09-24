import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/cache/local_cache.dart';

class ProfileRepository {
  ProfileRepository(this._api, this._cache);
  final ApiClient _api;
  final LocalCache _cache;

  Map<String, dynamic> _map(dynamic v) => v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
  dynamic _data(Map<String, dynamic> r) => r['data'];

  Future<Map<String, dynamic>> me() async => _map(_data(await _api.get('/me')));
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> payload) async => _map(_data(await _api.patch('/me', data: payload)));
  Future<Map<String, dynamic>> preferences() async => _map(_data(await _api.get('/me/preferences')));
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> payload) async => _map(_data(await _api.patch('/me/preferences', data: {'preferences': payload})));
  Future<Map<String, dynamic>> securitySettings() async => _map(_data(await _api.get('/security/settings')));
  Future<Map<String, dynamic>> updateSecuritySettings(Map<String, dynamic> payload) async => _map(_data(await _api.patch('/security/settings', data: payload)));

  Future<Map<String, dynamic>> uploadPhoto({required String filename, required List<int> bytes}) async {
    final response = await _api.postMultipart('/me/photo', fieldName: 'photo', filename: filename, bytes: Uint8List.fromList(bytes));
    return _map(_data(response));
  }
  Future<Map<String, dynamic>?> profilePhoto() async {
    final d = _data(await _api.get('/me/photo'));
    return d is Map ? d.cast<String, dynamic>() : null;
  }
  Future<void> deletePhoto() async { await _api.delete('/me/photo'); }
  Future<Map<String, dynamic>> blockUser(String userId) async => _map(_data(await _api.post('/blocks', data: {'blocked_user_id': userId, 'user_id': userId})));
  Future<void> unblockUser(String userId) async { await _api.delete('/blocks/$userId'); }
  Future<Map<String, dynamic>> reportUser({required String userId, required String reason, String? details}) async => _map(_data(await _api.post('/reports', data: {'reported_user_id': userId, 'user_id': userId, 'reason': reason, if (details != null && details.isNotEmpty) 'details': details, 'body': details})));

  Future<void> changePassword({required String currentPassword, required String password}) async {
    await _api.post('/auth/password/change', data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': password,
    });
  }
  Future<void> logoutAll() async {
    await _api.post('/auth/logout-all');
    await _api.secureStore.clearTokens();
    await _cache.clearAll();
  }
  Future<void> deleteAccount({String? password}) async {
    await _api.delete('/account', data: {if (password != null && password.isNotEmpty) 'password': password});
    await _api.secureStore.clearTokens();
    await _cache.clearAll();
  }
}
