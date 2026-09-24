import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted local fallback for calendar event photo-link metadata.
///
/// The current Laravel contract can attach/remove event photos but does not
/// expose a collection GET route. We therefore retain only the last known
/// media-link metadata locally. Signed/private media URLs are never persisted.
class CalendarPhotoLocalCache {
  CalendarPhotoLocalCache([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String eventId) => 'calendar_event_photos_v1_$eventId';

  Future<void> write(String eventId, List<Map<String, dynamic>> items) async {
    final safe = items.map((item) {
      final copy = Map<String, dynamic>.from(item)
        ..remove('url')
        ..remove('signed_url')
        ..remove('download_url');
      return copy;
    }).toList(growable: false);
    await _storage.write(key: _key(eventId), value: jsonEncode(safe));
  }

  Future<List<Map<String, dynamic>>> read(String eventId) async {
    final raw = await _storage.read(key: _key(eventId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> clear(String eventId) => _storage.delete(key: _key(eventId));
}
