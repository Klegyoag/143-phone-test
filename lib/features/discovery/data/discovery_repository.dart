import '../../../core/api/api_client.dart';
import '../../../core/cache/local_cache.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._api, this._cache);
  final ApiClient _api;
  final LocalCache _cache;

  static const _favoritesCache = 'discovery_favorites';
  static const _activityCache = 'discovery_activity';

  dynamic _data(Map<String, dynamic> response) => response['data'];

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is Map && value['data'] is List) value = value['data'];
    return value is List
        ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];
  }

  Future<Map<String, List<Map<String, dynamic>>>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return {'memories': [], 'messages': []};
    final data = _data(await _api.get('/search', query: {'q': q}));
    final map = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    return {
      'memories': _list(map['memories']),
      'messages': _list(map['messages']),
    };
  }

  Future<List<Map<String, dynamic>>> favorites({bool allowCache = true}) async {
    try {
      final items = _list(_data(await _api.get('/favorites')));
      await _cache.putJson(_favoritesCache, items);
      return items;
    } catch (_) {
      if (!allowCache) rethrow;
      final cached = await _cache.getJson<List<dynamic>>(_favoritesCache, maxAge: const Duration(days: 7));
      return cached?.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() ?? [];
    }
  }

  Future<Map<String, dynamic>> addFavorite({
    required String type,
    required String id,
    Map<String, dynamic> metadata = const {},
  }) async {
    final data = _data(await _api.post('/favorites', data: {
      'type': type,
      'id': id,
      if (metadata.isNotEmpty) 'metadata': metadata,
    }));
    await _cache.remove(_favoritesCache);
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }

  Future<void> removeFavorite(String favoriteId) async {
    await _api.delete('/favorites/$favoriteId');
    await _cache.remove(_favoritesCache);
  }

  Future<List<Map<String, dynamic>>> activity({int limit = 50, bool allowCache = true}) async {
    try {
      final items = _list(_data(await _api.get('/activity', query: {'limit': limit.clamp(1, 100)})));
      await _cache.putJson(_activityCache, items);
      return items;
    } catch (_) {
      if (!allowCache) rethrow;
      final cached = await _cache.getJson<List<dynamic>>(_activityCache, maxAge: const Duration(days: 7));
      return cached?.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() ?? [];
    }
  }

  Future<Map<String, int>> unreadSummary() async {
    final data = _data(await _api.get('/unread-summary'));
    final map = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    return {
      'messages': int.tryParse('${map['messages'] ?? 0}') ?? 0,
      'notifications': int.tryParse('${map['notifications'] ?? 0}') ?? 0,
    };
  }
}
