import '../../features/media/data/media_repository.dart';

class _Entry {
  _Entry(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
}

/// In-memory cache for short-lived authorized media URLs.
/// Signed URLs are intentionally not persisted to disk.
class MediaUrlCache {
  MediaUrlCache(this._media);
  final MediaRepository _media;
  final Map<String, _Entry> _entries = {};

  Future<String?> resolve(String mediaId, {Duration maxAge = const Duration(minutes: 4)}) async {
    final existing = _entries[mediaId];
    if (existing != null && existing.expiresAt.isAfter(DateTime.now())) return existing.url;
    final url = await _media.temporaryUrl(mediaId);
    if (url != null && url.isNotEmpty) {
      _entries[mediaId] = _Entry(url, DateTime.now().add(maxAge));
    }
    return url;
  }

  void invalidate(String mediaId) => _entries.remove(mediaId);
  void clear() => _entries.clear();
}
