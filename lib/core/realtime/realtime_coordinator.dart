import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../sync/sync_coordinator.dart';
import 'realtime_client.dart';
import 'realtime_event.dart';

class RealtimeCoordinator extends ChangeNotifier {
  RealtimeCoordinator(this._api, this._sync)
      : _client = RealtimeClient(apiBaseUrl: _api.baseUrl, secureStore: _api.secureStore);

  final ApiClient _api;
  final SyncCoordinator _sync;
  final RealtimeClient _client;
  final _events = StreamController<RealtimeEvent>.broadcast();

  StreamSubscription<RealtimeEvent>? _eventSub;
  StreamSubscription<RealtimeConnectionState>? _stateSub;
  RealtimeConnectionState state = RealtimeConnectionState.disconnected;
  String userId = '';
  String coupleSpaceId = '';
  bool _started = false;

  Stream<RealtimeEvent> get events => _events.stream;
  bool get enabled => _client.enabled;
  bool get connected => state == RealtimeConnectionState.connected;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _eventSub ??= _client.events.listen(_events.add);
    _stateSub ??= _client.states.listen((next) async {
      final wasConnected = connected;
      state = next;
      notifyListeners();
      if (!wasConnected && next == RealtimeConnectionState.connected) {
        await _sync.reconcileAfterReconnect();
      }
    });

    try {
      final me = (await _api.get('/me'))['data'];
      if (me is Map) userId = '${me['id'] ?? ''}';
    } catch (_) {}
    try {
      final couple = (await _api.get('/couple-spaces/current'))['data'];
      if (couple is Map) coupleSpaceId = '${couple['id'] ?? couple['couple_space_id'] ?? ''}';
    } catch (_) {
      coupleSpaceId = '';
    }
    try {
      await _client.connect(privateChannels: [
        if (userId.isNotEmpty) 'private-user.$userId',
        if (coupleSpaceId.isNotEmpty) 'private-couple.$coupleSpaceId',
      ]);
      if (coupleSpaceId.isNotEmpty) await setPresence('online', metadata: {'client': 'flutter'});
    } catch (_) {
      // API screens continue to work using HTTP/polling if realtime is unavailable.
    }
  }

  Future<void> reconnect() async {
    try {
      final me = (await _api.get('/me'))['data'];
      if (me is Map) userId = '${me['id'] ?? ''}';
    } catch (_) {}
    try {
      final couple = (await _api.get('/couple-spaces/current'))['data'];
      if (couple is Map) coupleSpaceId = '${couple['id'] ?? couple['couple_space_id'] ?? ''}';
    } catch (_) {
      coupleSpaceId = '';
    }
    try {
      await _client.connect(privateChannels: [
        if (userId.isNotEmpty) 'private-user.$userId',
        if (coupleSpaceId.isNotEmpty) 'private-couple.$coupleSpaceId',
      ]);
    } catch (_) {}
  }

  Future<void> refreshIdentityAndChannels() async {
    try {
      final me = (await _api.get('/me'))['data'];
      if (me is Map) userId = '${me['id'] ?? ''}';
      final couple = (await _api.get('/couple-spaces/current'))['data'];
      if (couple is Map) coupleSpaceId = '${couple['id'] ?? couple['couple_space_id'] ?? ''}';
      await _client.updateChannels([
        if (userId.isNotEmpty) 'private-user.$userId',
        if (coupleSpaceId.isNotEmpty) 'private-couple.$coupleSpaceId',
      ]);
    } catch (_) {}
  }

  Future<void> setPresence(String status, {Map<String, dynamic>? metadata}) async {
    try {
      await _api.put('/presence', data: {'status': status, 'metadata': metadata ?? {}});
    } catch (_) {}
  }

  Future<void> onAppLifecycle(AppLifecycleState lifecycle) async {
    switch (lifecycle) {
      case AppLifecycleState.resumed:
        await setPresence('online');
        if (!_started) await start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        await setPresence('away');
        break;
      case AppLifecycleState.detached:
        await setPresence('offline');
        break;
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    await setPresence('offline');
    await _client.disconnect();
    _started = false;
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _stateSub?.cancel();
    _client.dispose();
    _events.close();
    super.dispose();
  }
}
