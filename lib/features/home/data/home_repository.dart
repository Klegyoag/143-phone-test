import '../../../core/api/api_client.dart';
import '../../../core/cache/local_cache.dart';
import 'package:uuid/uuid.dart';

class HomeBundle {
  const HomeBundle({
    required this.home,
    required this.daily,
    required this.relationship,
    required this.moods,
    this.invite,
    this.isFromCache = false,
  });

  final Map<String, dynamic> home;
  final Map<String, dynamic> daily;
  final Map<String, dynamic> relationship;
  final List<dynamic> moods;
  final Map<String, dynamic>? invite;
  final bool isFromCache;

  Map<String, dynamic> toJson() => {
        'home': home,
        'daily': daily,
        'relationship': relationship,
        'moods': moods,
        'invite': invite,
      };

  factory HomeBundle.fromJson(Map<String, dynamic> json,
          {bool fromCache = false}) =>
      HomeBundle(
        home: (json['home'] as Map?)?.cast<String, dynamic>() ?? {},
        daily: (json['daily'] as Map?)?.cast<String, dynamic>() ?? {},
        relationship:
            (json['relationship'] as Map?)?.cast<String, dynamic>() ?? {},
        moods: json['moods'] is List ? json['moods'] as List : const [],
        invite: (json['invite'] as Map?)?.cast<String, dynamic>(),
        isFromCache: fromCache,
      );
}

class HomeRepository {
  HomeRepository(this._api, this._cache);
  final ApiClient _api;
  final LocalCache _cache;
  final _uuid = const Uuid();
  static const _cacheKey = 'home_bundle';
  static const _inviteCacheKey = 'pending_partner_invite';

  dynamic _data(Map<String, dynamic> json) => json['data'];

  Future<HomeBundle> load() async {
    try {
      final results = await Future.wait([
        _api.get('/home'),
        _api.get('/daily/today'),
        _api.get('/couple-spaces/current/relationship'),
        _api.get('/moods'),
      ]);
      final bundle = HomeBundle(
        home: (_data(results[0]) as Map?)?.cast<String, dynamic>() ?? {},
        daily: (_data(results[1]) as Map?)?.cast<String, dynamic>() ?? {},
        relationship:
            (_data(results[2]) as Map?)?.cast<String, dynamic>() ?? {},
        moods: _data(results[3]) is List ? _data(results[3]) as List : const [],
        invite: await _inviteWhenPartnerMissing(
          (_data(results[0]) as Map?)?.cast<String, dynamic>() ?? {},
        ),
      );
      await _cache.putJson(_cacheKey, bundle.toJson());
      return bundle;
    } catch (_) {
      final cached = await _cache.getJson<dynamic>(_cacheKey,
          maxAge: const Duration(days: 2));
      if (cached is Map) {
        return HomeBundle.fromJson(cached.cast<String, dynamic>(),
            fromCache: true);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _inviteWhenPartnerMissing(
      Map<String, dynamic> home) async {
    final partner = home['partner'];
    if (partner is Map && partner.isNotEmpty) return null;
    final cached = await _cache.getJson<dynamic>(
      _inviteCacheKey,
      maxAge: const Duration(hours: 24),
    );
    if (cached is Map) return cached.cast<String, dynamic>();
    try {
      final response = await _api.post(
        '/couple-spaces/current/invites',
        headers: {'Idempotency-Key': _uuid.v4()},
      );
      final invite = (_data(response) as Map?)?.cast<String, dynamic>();
      if (invite != null) await _cache.putJson(_inviteCacheKey, invite);
      return invite;
    } catch (_) {
      return null;
    }
  }

  Future<void> setMood(String mood) =>
      _api.post('/moods', data: {'mood': mood, 'visibility': 'partner'});

  Future<void> sendPing({String kind = 'hug'}) =>
      _api.post('/pings', data: {'kind': kind});

  Future<void> sendWidgetPing({String kind = 'hug'}) =>
      _api.post('/widgets/ping', data: {'kind': kind});

  Future<Map<String, dynamic>> answerDaily(
      String questionId, String answer) async {
    final response = await _api
        .post('/daily/questions/$questionId/answers', data: {'answer': answer});
    return (response['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<List<Map<String, dynamic>>> dailyQuestionHistory() async {
    final response = await _api.get('/daily/questions/history');
    dynamic data = response['data'];
    if (data is Map && data['data'] is List) data = data['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> dailyAnswerArchive() async {
    final response = await _api.get('/daily/answers');
    dynamic data = response['data'];
    if (data is Map && data['data'] is List) data = data['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> dailyHistory() async {
    final response = await _api.get('/daily/history');
    dynamic data = response['data'];
    if (data is Map && data['data'] is List) data = data['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<void> completeDailyActivity(String activityId) =>
      _api.post('/daily/activities/$activityId/complete');

  Future<List<dynamic>> revealDaily(String questionId) async {
    final response = await _api.get('/daily/questions/$questionId/reveal');
    return response['data'] is List ? response['data'] as List : const [];
  }
}
