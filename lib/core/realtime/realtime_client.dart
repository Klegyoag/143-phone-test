import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../storage/secure_store.dart';
import 'realtime_event.dart';

enum RealtimeConnectionState { disabled, connecting, connected, reconnecting, disconnected }

/// Laravel Reverb client using the Pusher protocol.
///
/// Configure production values with Dart defines:
/// --dart-define=REVERB_APP_KEY=...
/// --dart-define=REVERB_HOST=...
/// --dart-define=REVERB_PORT=443
/// --dart-define=REVERB_SCHEME=https
/// --dart-define=BROADCAST_AUTH_URL=https://api.example.com/broadcasting/auth
class RealtimeClient {
  RealtimeClient({required this.apiBaseUrl, required this.secureStore});

  final String apiBaseUrl;
  final SecureStore secureStore;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _states = StreamController<RealtimeConnectionState>.broadcast();
  final Set<String> _channels = <String>{};

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _socketId;
  bool _manualStop = false;
  int _retry = 0;

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<RealtimeConnectionState> get states => _states.stream;

  static const _appKey = String.fromEnvironment('REVERB_APP_KEY', defaultValue: '');
  static const _hostOverride = String.fromEnvironment('REVERB_HOST', defaultValue: '');
  static const _portOverride = String.fromEnvironment('REVERB_PORT', defaultValue: '');
  static const _schemeOverride = String.fromEnvironment('REVERB_SCHEME', defaultValue: '');
  static const _authOverride = String.fromEnvironment('BROADCAST_AUTH_URL', defaultValue: '');

  bool get enabled => _appKey.trim().isNotEmpty;
  bool get connected => _socketId != null;

  Future<void> connect({required Iterable<String> privateChannels}) async {
    _channels
      ..clear()
      ..addAll(privateChannels.where((e) => e.trim().isNotEmpty));
    _manualStop = false;
    if (!enabled) {
      _states.add(RealtimeConnectionState.disabled);
      return;
    }
    await _open(isReconnect: false);
  }

  Future<void> updateChannels(Iterable<String> privateChannels) async {
    _channels
      ..clear()
      ..addAll(privateChannels.where((e) => e.trim().isNotEmpty));
    if (connected) await _subscribeAll();
  }

  Future<void> _open({required bool isReconnect}) async {
    if (_manualStop) return;
    await _subscription?.cancel();
    try {
      _states.add(isReconnect ? RealtimeConnectionState.reconnecting : RealtimeConnectionState.connecting);
      final apiUri = Uri.parse(apiBaseUrl);
      final host = _hostOverride.isNotEmpty ? _hostOverride : apiUri.host;
      final scheme = _schemeOverride.isNotEmpty ? _schemeOverride : (apiUri.scheme == 'https' ? 'wss' : 'ws');
      final socketScheme = scheme == 'https' ? 'wss' : scheme == 'http' ? 'ws' : scheme;
      final parsedPort = int.tryParse(_portOverride);
      final port = parsedPort ?? (socketScheme == 'wss' ? 443 : 80);
      final uri = Uri(
        scheme: socketScheme,
        host: host,
        port: port,
        path: '/app/$_appKey',
        queryParameters: const {
          'protocol': '7',
          'client': '143-flutter',
          'version': '1.0',
          'flash': 'false',
        },
      );
      _socket = WebSocketChannel.connect(uri);
      _subscription = _socket!.stream.listen(_onMessage, onError: (_) => _scheduleReconnect(), onDone: _scheduleReconnect);
      _startHeartbeat();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> _onMessage(dynamic raw) async {
    if (raw is! String) return;
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      message = decoded.cast<String, dynamic>();
    } catch (_) {
      return;
    }

    final event = '${message['event'] ?? ''}';
    final channel = '${message['channel'] ?? ''}';
    final data = _decodeData(message['data']);

    if (event == 'pusher:connection_established') {
      _socketId = '${data['socket_id'] ?? ''}';
      _retry = 0;
      _states.add(RealtimeConnectionState.connected);
      await _subscribeAll();
      return;
    }
    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }
    if (event == 'pusher:error') {
      _events.add(RealtimeEvent(name: event, channel: channel, payload: data));
      return;
    }

    _events.add(RealtimeEvent(name: event, channel: channel, payload: data));
  }

  Map<String, dynamic> _decodeData(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      try {
        final value = jsonDecode(raw);
        if (value is Map) return value.cast<String, dynamic>();
        return {'value': value};
      } catch (_) {
        return {'value': raw};
      }
    }
    return <String, dynamic>{};
  }

  Future<void> _subscribeAll() async {
    final socketId = _socketId;
    if (socketId == null || socketId.isEmpty) return;
    for (final channel in _channels) {
      try {
        final auth = await _authorize(channel, socketId);
        _send({
          'event': 'pusher:subscribe',
          'data': {'auth': auth, 'channel': channel},
        });
      } catch (e) {
        _events.add(RealtimeEvent(name: 'client.subscription_error', channel: channel, payload: {'message': '$e'}));
      }
    }
  }

  Future<String> _authorize(String channel, String socketId) async {
    final apiUri = Uri.parse(apiBaseUrl);
    final origin = Uri(scheme: apiUri.scheme, host: apiUri.host, port: apiUri.hasPort ? apiUri.port : null).toString().replaceFirst(RegExp(r'/$'), '');
    final url = _authOverride.isNotEmpty ? _authOverride : '$origin/broadcasting/auth';
    final token = await secureStore.accessToken();
    if (token == null || token.isEmpty) throw StateError('No access token for realtime authorization.');
    final response = await Dio().post<dynamic>(
      url,
      data: {'socket_id': socketId, 'channel_name': channel},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ),
    );
    final body = response.data;
    if (body is Map && '${body['auth'] ?? ''}'.isNotEmpty) return '${body['auth']}';
    throw StateError('Realtime channel authorization failed.');
  }

  void _send(Map<String, dynamic> message) {
    try {
      _socket?.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 50), (_) {
      if (connected) _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  void _scheduleReconnect() {
    _socketId = null;
    if (_manualStop || !enabled) {
      _states.add(RealtimeConnectionState.disconnected);
      return;
    }
    _states.add(RealtimeConnectionState.reconnecting);
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: [1, 2, 4, 8, 15, 30][_retry.clamp(0, 5).toInt()]);
    _retry = (_retry + 1).clamp(0, 5).toInt();
    _reconnectTimer = Timer(delay, () => _open(isReconnect: true));
  }

  Future<void> disconnect() async {
    _manualStop = true;
    _socketId = null;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _subscription?.cancel();
    await _socket?.sink.close();
    _states.add(RealtimeConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
    await _states.close();
  }
}
