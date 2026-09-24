import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Conservative encrypted local fallback for album item metadata.
/// Signed media URLs are NEVER persisted; only media IDs and album item metadata.
class AlbumLocalCache {
  AlbumLocalCache([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  String _key(String albumId) => 'album_items_v1_$albumId';

  Future<void> write(String albumId, List<Map<String, dynamic>> items) async {
    final safe = items.map((item) {
      final copy = Map<String, dynamic>.from(item);
      copy.remove('url'); copy.remove('signed_url'); copy.remove('download_url');
      return copy;
    }).toList();
    await _storage.write(key: _key(albumId), value: jsonEncode(safe));
  }

  Future<List<Map<String, dynamic>>> read(String albumId) async {
    final raw = await _storage.read(key: _key(albumId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : [];
    } catch (_) { return []; }
  }

  Future<void> clear(String albumId) => _storage.delete(key: _key(albumId));
}
