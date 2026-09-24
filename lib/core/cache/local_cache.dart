import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// App-private JSON cache for authorized API response data.
///
/// Access/refresh tokens, E2EE keys, raw private media and signed media URLs
/// are deliberately excluded from this cache.
class LocalCache {
  static const _prefix = '143_cache_v1_';

  Future<void> putJson(String key, Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode({
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'value': value,
    }));
  }

  Future<T?> getJson<T>(String key, {Duration? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map) return null;
      final savedAt = DateTime.tryParse('${envelope['saved_at'] ?? ''}');
      if (maxAge != null && savedAt != null && DateTime.now().toUtc().difference(savedAt) > maxAge) {
        return null;
      }
      return envelope['value'] as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
