import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService extends ChangeNotifier {
  AppLockService({LocalAuthentication? auth, FlutterSecureStorage? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _enabledKey = 'app_lock_enabled';
  static const _biometricKey = 'app_lock_biometric';
  static const _pinHashKey = 'app_lock_pin_hash';

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  bool enabled = false;
  bool biometricEnabled = false;
  bool hasPin = false;
  bool locked = false;
  bool initialized = false;
  int failedAttempts = 0;
  DateTime? blockedUntil;

  Future<void> initialize() async {
    enabled = (await _storage.read(key: _enabledKey)) == 'true';
    biometricEnabled = (await _storage.read(key: _biometricKey)) == 'true';
    hasPin = (await _storage.read(key: _pinHashKey))?.isNotEmpty == true;
    locked = enabled;
    initialized = true;
    notifyListeners();
  }

  String _hash(String pin) => sha256.convert(utf8.encode('143-local-pin::$pin')).toString();

  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    if (value && !hasPin && !biometricEnabled) {
      throw StateError('Set a PIN or enable device authentication before turning on App Lock.');
    }
    enabled = value;
    await _storage.write(key: _enabledKey, value: '$value');
    if (!value) locked = false;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      throw StateError('Use a 4 to 6 digit PIN.');
    }
    await _storage.write(key: _pinHashKey, value: _hash(pin));
    hasPin = true;
    failedAttempts = 0;
    blockedUntil = null;
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    hasPin = false;
    if (!biometricEnabled) await setEnabled(false);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    if (value && !await canUseBiometrics()) {
      throw StateError('Biometric/device authentication is not available on this device.');
    }
    biometricEnabled = value;
    await _storage.write(key: _biometricKey, value: '$value');
    notifyListeners();
  }

  Duration get retryAfter {
    final until = blockedUntil;
    if (until == null) return Duration.zero;
    final d = until.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  void lock() {
    if (!enabled) return;
    locked = true;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    if (retryAfter > Duration.zero) return false;
    final expected = await _storage.read(key: _pinHashKey);
    if (expected != null && expected == _hash(pin)) {
      failedAttempts = 0;
      blockedUntil = null;
      locked = false;
      notifyListeners();
      return true;
    }
    failedAttempts += 1;
    if (failedAttempts >= 5) {
      blockedUntil = DateTime.now().add(const Duration(seconds: 30));
      failedAttempts = 0;
    }
    notifyListeners();
    return false;
  }

  Future<bool> unlock() async {
    if (!enabled) {
      locked = false;
      notifyListeners();
      return true;
    }
    if (!biometricEnabled) return false;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your private 143 space',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true, useErrorDialogs: true),
      );
      if (ok) {
        failedAttempts = 0;
        blockedUntil = null;
        locked = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}
