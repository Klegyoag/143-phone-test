import 'package:uuid/uuid.dart';
import '../../../core/api/api_client.dart';
import '../../../core/cache/local_cache.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.recoveryConfirmed = false,
    this.legalAccepted = false,
    this.recoveryCode,
  });

  final String accessToken;
  final String refreshToken;
  final bool recoveryConfirmed;
  final bool legalAccepted;
  final String? recoveryCode;
}

class AuthRepository {
  AuthRepository(this._api, this._cache);

  final ApiClient _api;
  final LocalCache _cache;
  final _uuid = const Uuid();

  Future<AuthSession> register({required String username, required String password}) async {
    final json = await _api.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'password_confirmation': password,
      },
      headers: {'Idempotency-Key': _uuid.v4()},
    );
    return _sessionFrom(json, includeRecoveryCode: true);
  }

  Future<AuthSession> login({required String username, required String password}) async {
    final json = await _api.post(
      '/auth/login',
      data: {'username': username, 'password': password},
      headers: {'Idempotency-Key': _uuid.v4()},
    );
    return _sessionFrom(json);
  }

  Future<void> confirmRecovery(String recoveryCode) async {
    final code = recoveryCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw const FormatException('Recovery code is required.');
    }
    await _api.post(
      '/auth/recovery/confirm',
      data: {'recovery_code': code},
      headers: {'Idempotency-Key': _uuid.v4()},
    );
  }


  Future<String> resetPasswordWithRecovery({required String username, required String recoveryCode, required String password}) async {
    final json = await _api.post('/auth/password/reset/recovery-code', data: {
      'username': username.trim(),
      'recovery_code': recoveryCode.trim().toUpperCase(),
      'password': password,
      'password_confirmation': password,
    }, headers: {'Idempotency-Key': _uuid.v4()});
    final data = json['data'];
    return data is Map ? '${data['recovery_code'] ?? ''}' : '';
  }

  Future<String> regenerateRecoveryCode(String currentPassword) async {
    final json = await _api.post('/auth/recovery-code/regenerate', data: {
      'current_password': currentPassword,
    }, headers: {'Idempotency-Key': _uuid.v4()});
    final data = json['data'];
    return data is Map ? '${data['recovery_code'] ?? ''}' : '';
  }

  Future<Map<String, dynamic>> recoveryStatus() => _api.get('/auth/recovery/status');

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', headers: {'Idempotency-Key': _uuid.v4()});
    } finally {
      await _api.secureStore.clearTokens();
      await _cache.clearAll();
    }
  }

  Future<void> persist(AuthSession session) {
    return _api.secureStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  AuthSession _sessionFrom(Map<String, dynamic> json, {bool includeRecoveryCode = false}) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    final setup = (data['setup'] is Map<String, dynamic>)
        ? data['setup'] as Map<String, dynamic>
        : <String, dynamic>{};
    return AuthSession(
      accessToken: (data['access_token'] ?? data['token'] ?? '').toString(),
      refreshToken: (data['refresh_token'] ?? '').toString(),
      recoveryConfirmed: setup['recovery_confirmed'] == true,
      legalAccepted: setup['legal_accepted'] == true || setup['legal_acceptance_complete'] == true,
      recoveryCode: includeRecoveryCode ? data['recovery_code']?.toString() : null,
    );
  }
}
