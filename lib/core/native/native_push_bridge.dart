import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/notifications/data/push_device_repository.dart';

/// Native FCM/APNs bridge.
///
/// Privacy rule: [bootstrap] NEVER asks the operating system for notification
/// permission. It only restores an already-authorized Firebase session. The
/// user must explicitly call [requestPermissionAndActivate] from notification
/// settings or another contextual permission-introduction flow.
class NativePushBridge {
  NativePushBridge(this._repository);
  final PushDeviceRepository _repository;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  final _openedController = StreamController<Map<String, dynamic>>.broadcast();
  final _foregroundController = StreamController<Map<String, dynamic>>.broadcast();

  String? backendDeviceId;
  String? currentToken;
  String? lastError;
  bool initialized = false;
  AuthorizationStatus authorizationStatus = AuthorizationStatus.notDetermined;

  Stream<Map<String, dynamic>> get openedNotifications => _openedController.stream;
  Stream<Map<String, dynamic>> get foregroundNotifications => _foregroundController.stream;

  bool get permissionGranted =>
      authorizationStatus == AuthorizationStatus.authorized ||
      authorizationStatus == AuthorizationStatus.provisional;

  String get permissionLabel => switch (authorizationStatus) {
        AuthorizationStatus.authorized => 'authorized',
        AuthorizationStatus.provisional => 'provisional',
        AuthorizationStatus.denied => 'denied',
        AuthorizationStatus.notDetermined => 'not_determined',
      };

  /// Initializes Firebase without showing a permission dialog.
  Future<bool> bootstrap() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      authorizationStatus = settings.authorizationStatus;
      await _bindMessageStreams();
      if (permissionGranted) {
        await messaging.setAutoInitEnabled(true);
        await _activateTokenRegistration(messaging);
      } else {
        // Do not create/register a push token before the user opts in.
        await messaging.setAutoInitEnabled(false);
      }
      initialized = true;
      lastError = null;
      return true;
    } catch (e) {
      lastError = '$e';
      initialized = false;
      return false;
    }
  }

  /// Explicit user action: request OS permission and register the resulting
  /// FCM/APNs token with the Laravel backend only after permission is granted.
  Future<bool> requestPermissionAndActivate() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      authorizationStatus = settings.authorizationStatus;
      initialized = true;
      await _bindMessageStreams();
      if (!permissionGranted) {
        await messaging.setAutoInitEnabled(false);
        lastError = 'Notification permission denied.';
        return false;
      }
      await messaging.setAutoInitEnabled(true);
      await _activateTokenRegistration(messaging);
      lastError = null;
      return true;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  /// Kept for compatibility with older call sites. Unlike older milestones it
  /// no longer implicitly requests permission.
  @Deprecated('Use bootstrap() or requestPermissionAndActivate().')
  Future<bool> initialize() => bootstrap();

  Future<void> _bindMessageStreams() async {
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _openedController.add(_payload(m)),
    );
    _foregroundSub ??= FirebaseMessaging.onMessage.listen(
      (m) => _foregroundController.add(_payload(m)),
    );
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _openedController.add(_payload(initial));
    } catch (_) {
      // Optional restoration path; failure must not block the app.
    }
  }

  Map<String, dynamic> _payload(RemoteMessage message) => <String, dynamic>{
        ...message.data,
        if (message.notification?.title != null)
          '_notification_title': message.notification!.title,
        if (message.notification?.body != null)
          '_notification_body': message.notification!.body,
        if (message.messageId != null) '_message_id': message.messageId,
      };

  Future<void> _activateTokenRegistration(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    currentToken = token;
    if (token != null && token.isNotEmpty) await _safeRegister(token);
    _tokenSub ??= messaging.onTokenRefresh.listen((token) async {
      currentToken = token;
      await _safeRegister(token);
    });
  }

  Future<bool> registerCurrentToken() async {
    if (!permissionGranted) return false;
    final token = currentToken;
    if (token == null || token.isEmpty) return false;
    return _safeRegister(token);
  }

  Future<bool> _safeRegister(String token) async {
    try {
      await _register(token);
      lastError = null;
      return true;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  Future<void> _register(String token) async {
    final result = await _repository.register(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
      deviceName: Platform.isIOS ? 'iOS device' : 'Android device',
      metadata: {
        'client': 'flutter',
        'provider': 'firebase_messaging',
        'permission': permissionLabel,
      },
    );
    backendDeviceId = '${result['id'] ?? result['device_id'] ?? ''}';
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _openedSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedController.close();
    await _foregroundController.close();
  }
}
