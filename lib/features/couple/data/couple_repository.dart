import 'package:uuid/uuid.dart';
import '../../../core/api/api_client.dart';

class CoupleRepository {
  CoupleRepository(this._api);
  final ApiClient _api;
  final _uuid = const Uuid();

  Map<String, dynamic>? _data(Map<String, dynamic> json) => json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;

  Future<Map<String, dynamic>?> current() async => _data(await _api.get('/couple-spaces/current'));

  Future<Map<String, dynamic>> create({String? name}) async {
    final json = await _api.post('/couple-spaces', data: {'name': name}, headers: {'Idempotency-Key': _uuid.v4()});
    return _data(json) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createInvite() async {
    final json = await _api.post('/couple-spaces/current/invites', headers: {'Idempotency-Key': _uuid.v4()});
    return _data(json) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> preview(String token) async {
    final json = await _api.get('/couple-invites/$token/preview');
    return _data(json) ?? <String, dynamic>{};
  }

  Future<void> acceptToken(String token) async {
    await _api.post('/couple-invites/$token/accept', headers: {'Idempotency-Key': _uuid.v4()});
  }


  Future<Map<String, dynamic>?> relationship() async =>
      _data(await _api.get('/couple-spaces/current/relationship'));

  Future<Map<String, dynamic>> updateRelationship(Map<String, dynamic> values) async =>
      _data(await _api.patch('/couple-spaces/current/relationship', data: values)) ?? <String, dynamic>{};

  Future<List<Map<String, dynamic>>> presence() async {
    final raw = (await _api.get('/couple-spaces/current/presence'))['data'];
    return raw is List ? raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
  }

  Future<void> leaveCurrent() => _api.delete('/couple-spaces/current/membership');

  Future<void> revokeInvite(String inviteId) =>
      _api.post('/couple-invites/$inviteId/revoke', headers: {'Idempotency-Key': _uuid.v4()});

  Future<Map<String, dynamic>> regenerateInvite(String inviteId) async =>
      _data(await _api.post('/couple-invites/$inviteId/regenerate', headers: {'Idempotency-Key': _uuid.v4()})) ?? <String, dynamic>{};

  Future<void> joinCode(String code) async {
    await _api.post('/couple-spaces/join/code', data: {'code': code.trim()}, headers: {'Idempotency-Key': _uuid.v4()});
  }
}
