import '../api/api_client.dart';

class SyncCoordinator {
  SyncCoordinator(this._api);
  final ApiClient _api;

  String? lastCursor;
  DateTime? lastReconciledAt;

  Future<void> reconcileAfterReconnect() async {
    try {
      final state = await _api.get('/sync/state');
      final data = state['data'];
      if (data is Map) lastCursor = data['cursor']?.toString();
      await _api.post('/sync/reconcile', data: {if (lastCursor != null) 'cursor': lastCursor});
      lastReconciledAt = DateTime.now();
    } catch (_) {
      // Sync is best-effort. Individual screens still retain retry controls.
    }
  }
}
