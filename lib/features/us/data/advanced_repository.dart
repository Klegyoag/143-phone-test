import '../../../core/api/api_client.dart';

class AdvancedRepository {
  AdvancedRepository(this._api);
  final ApiClient _api;

  dynamic _data(Map<String, dynamic> r) => r['data'];
  Map<String, dynamic> _map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
  List<Map<String, dynamic>> _list(dynamic v) {
    if (v is Map && v['data'] is List) v = v['data'];
    return v is List
        ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> currentTogetherRoom() async =>
      _map(_data(await _api.get('/together-rooms/current')));
  Future<Map<String, dynamic>> createTogetherRoom(
          {String provider = 'youtube'}) async =>
      _map(_data(
          await _api.post('/together-rooms', data: {'provider': provider})));
  Future<Map<String, dynamic>> roomState(String id) async =>
      _map(_data(await _api.get('/together-rooms/$id/state')));
  Future<void> updateRoomState(String id, Map<String, dynamic> data) =>
      _api.patch('/together-rooms/$id/state', data: {'state': data});
  Future<List<Map<String, dynamic>>> roomQueue(String id) async =>
      _list(_data(await _api.get('/together-rooms/$id/queue')));
  Future<void> addQueueItem(String id, String url, {String? title}) {
    final provider = url.toLowerCase().contains('youtube') ||
            url.toLowerCase().contains('youtu.be')
        ? 'youtube'
        : 'media';
    return _api.post('/together-rooms/$id/queue', data: {
      'provider': provider,
      'media_id': url,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'metadata': {'source_url': url}
    });
  }

  Future<void> reorderQueue(String id, List<String> itemIds) => _api
      .patch('/together-rooms/$id/queue/reorder', data: {'item_ids': itemIds});
  Future<void> removeQueueItem(String id, String itemId) =>
      _api.delete('/together-rooms/$id/queue/$itemId');
  Future<void> joinTogetherRoom(String id) =>
      _api.post('/together-rooms/$id/join');
  Future<void> leaveTogetherRoom(String id) =>
      _api.post('/together-rooms/$id/leave');
  Future<void> resyncRoom(String id) => _api.post('/together-rooms/$id/resync');
  Future<Map<String, dynamic>> startCall(String type) async =>
      _map(_data(await _api.post('/calls', data: {'type': type})));
  Future<Map<String, dynamic>> call(String id) async =>
      _map(_data(await _api.get('/calls/$id')));
  Future<Map<String, dynamic>> acceptCall(String id) async =>
      _map(_data(await _api.post('/calls/$id/accept')));
  Future<Map<String, dynamic>> declineCall(String id) async =>
      _map(_data(await _api.post('/calls/$id/decline')));
  Future<Map<String, dynamic>> endCall(String id) async =>
      _map(_data(await _api.post('/calls/$id/end')));
  Future<List<Map<String, dynamic>>> iceServers() async =>
      _list(_data(await _api.get('/calls/ice-servers')));
  Future<List<Map<String, dynamic>>> incomingCalls() async =>
      _list(_data(await _api.get('/calls/incoming')));
  Future<void> publishCallOffer(String id, {required String sdp}) =>
      _api.post('/calls/$id/offer', data: {'sdp': sdp, 'type': 'offer'});
  Future<void> publishCallAnswer(String id, {required String sdp}) =>
      _api.post('/calls/$id/answer', data: {'sdp': sdp, 'type': 'answer'});
  Future<void> publishIceCandidate(String id,
          {required String candidate, String? sdpMid, int? sdpMLineIndex}) =>
      _api.post('/calls/$id/ice-candidates', data: {
        'candidate': candidate,
        if (sdpMid != null) 'sdp_mid': sdpMid,
        if (sdpMLineIndex != null) 'sdp_mline_index': sdpMLineIndex
      });

  Future<Map<String, dynamic>> insightOverview() async =>
      _map(_data(await _api.get('/insights/overview')));
  Future<Map<String, dynamic>> weeklyInsights() async =>
      _map(_data(await _api.get('/insights/weekly')));
  Future<Map<String, dynamic>> monthlyInsights() async =>
      _map(_data(await _api.get('/insights/monthly')));
  Future<Map<String, dynamic>> annualInsights() async =>
      _map(_data(await _api.get('/insights/annual')));

  Future<List<Map<String, dynamic>>> journeys() async =>
      _list(_data(await _api.get('/journeys')));
  Future<List<Map<String, dynamic>>> journeySessions() async =>
      _list(_data(await _api.get('/journey-sessions')));
  Future<Map<String, dynamic>> journey(String id) async =>
      _map(_data(await _api.get('/journeys/$id')));
  Future<Map<String, dynamic>> journeySession(String id) async =>
      _map(_data(await _api.get('/journey-sessions/$id')));
  Future<Map<String, dynamic>> startJourney(String id) async =>
      _map(_data(await _api.post('/journeys/$id/start')));
  Future<void> completeJourneyStep(String sessionId, String stepId) =>
      _api.post('/journey-sessions/$sessionId/steps/$stepId/complete');
  Future<void> completeJourney(String sessionId) =>
      _api.post('/journey-sessions/$sessionId/complete');

  Future<Map<String, dynamic>> aiSettings() async =>
      _map(_data(await _api.get('/ai/settings')));
  Future<void> updateAiSettings(Map<String, dynamic> data) =>
      _api.put('/ai/settings', data: data);
  Future<dynamic> aiSuggestion(String kind, {String? prompt}) async =>
      _data(await _api.post('/ai/suggestions/$kind', data: {
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim()
      }));

  Future<List<Map<String, dynamic>>> spotifyPlaylists() async =>
      _list(_data(await _api.get('/integrations/spotify/playlists')));
  Future<Map<String, dynamic>> spotifyNowPlaying() async =>
      _map(_data(await _api.get('/integrations/spotify/now-playing')));
  Future<dynamic> spotifyConnect() async =>
      _data(await _api.post('/integrations/spotify/connect'));

  Future<Map<String, dynamic>> privacyPermissions() async =>
      _map(_data(await _api.get('/privacy/permissions')));
  Future<void> updatePrivacyPermissions(Map<String, dynamic> data) =>
      _api.patch('/privacy/permissions', data: data);
  // /sessions returns one unified list; each id revokes the linked access+refresh pair.
  Future<List<Map<String, dynamic>>> sessions() async =>
      _list(_data(await _api.get('/sessions')));
  Future<void> revokeSession(String id) => _api.delete('/sessions/$id');
  Future<List<Map<String, dynamic>>> linkedDevices() async =>
      _list(_data(await _api.get('/linked-devices')));

  Future<Map<String, dynamic>> coupleMusic() async =>
      _map(_data(await _api.get('/couple-music')));
  Future<void> updateCoupleMusic(Map<String, dynamic> data) =>
      _api.put('/couple-music', data: data);
  Future<void> disconnectSpotify() => _api.delete('/integrations/spotify');
  Future<void> updateCoupleProfile(Map<String, dynamic> data) =>
      _api.patch('/couple-profile', data: data);

  Future<Map<String, dynamic>> widgetConfig() async =>
      _map(_data(await _api.get('/widgets/config')));
  Future<Map<String, dynamic>> widgetData() async =>
      _map(_data(await _api.get('/widgets/data')));
  Future<void> updateWidgetConfig(Map<String, dynamic> data) =>
      _api.put('/widgets/config', data: data);
  Future<void> widgetPing() => _api.post('/widgets/ping');

  Future<Map<String, dynamic>> backupStatus() async =>
      _map(_data(await _api.get('/backups/status')));
  Future<List<Map<String, dynamic>>> backups() async =>
      _list(_data(await _api.get('/backups')));
  Future<Map<String, dynamic>> createBackup(Map<String, dynamic> data) async =>
      _map(_data(await _api.post('/backups', data: data)));
  Future<void> restoreBackup(String id) => _api.post('/backups/$id/restore');
  Future<void> deleteBackup(String id) => _api.delete('/backups/$id');
  Future<Map<String, dynamic>> prepareMigration(
          Map<String, dynamic> data) async =>
      _map(_data(await _api.post('/migrations/device/prepare', data: data)));
  Future<Map<String, dynamic>> confirmMigration(
          Map<String, dynamic> data) async =>
      _map(_data(await _api.post('/migrations/device/confirm', data: data)));
  Future<Map<String, dynamic>> migrationStatus(String id) async =>
      _map(_data(await _api.get('/migrations/device/$id/status')));

  Future<Map<String, dynamic>> createLinkIntent(
          Map<String, dynamic> data) async =>
      _map(_data(await _api.post('/linked-devices/link-intents', data: data)));
  Future<Map<String, dynamic>> linkIntent(String id) async =>
      _map(_data(await _api.get('/linked-devices/link-intents/$id')));
  Future<Map<String, dynamic>> confirmLinkIntent(
          String id, Map<String, dynamic> data) async =>
      _map(_data(await _api.post('/linked-devices/link-intents/$id/confirm',
          data: data)));
  Future<Map<String, dynamic>> previewQrSession(
          String id, String token) async =>
      _map(_data(await _api.get('/linked-devices/qr-sessions/$id/preview',
          query: {'approval_token': token})));
  Future<Map<String, dynamic>> approveQrSession(
          String id, String token, String deviceName) async =>
      _map(_data(await _api.post('/linked-devices/qr-sessions/$id/approve',
          data: {
            'approval_token': token,
            'approving_device_name': deviceName
          })));
  Future<void> revokeLinkedDevice(String id) =>
      _api.delete('/linked-devices/$id');
}

extension ExpansionRepository on AdvancedRepository {
  Future<dynamic> rawGet(String path) async => (await _api.get(path))['data'];
  Future<dynamic> rawPost(String path, [Map<String, dynamic>? data]) async =>
      (await _api.post(path, data: data))['data'];
  Future<dynamic> rawPut(String path, Map<String, dynamic> data) async =>
      (await _api.put(path, data: data))['data'];
  Future<dynamic> rawPatch(String path, Map<String, dynamic> data) async =>
      (await _api.patch(path, data: data))['data'];
}
