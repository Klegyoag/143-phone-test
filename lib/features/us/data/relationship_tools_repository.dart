import '../../../core/api/api_client.dart';

class RelationshipToolsRepository {
  RelationshipToolsRepository(this._api);
  final ApiClient _api;

  dynamic _data(Map<String, dynamic> response) => response['data'];
  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is Map && value['data'] is List) value = value['data'];
    return value is List
        ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];
  }


  Future<List<Map<String, dynamic>>> pings() async =>
      _list(_data(await _api.get('/pings')));
  Future<Map<String, dynamic>> sendPing({String? note}) async =>
      _map(_data(await _api.post('/pings', data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()})));
  Future<void> reactToPing(String pingId, String reaction) =>
      _api.post('/pings/$pingId/reactions', data: {'reaction': reaction});

  Future<List<Map<String, dynamic>>> reminders() async =>
      _list(_data(await _api.get('/reminders')));
  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> values) async =>
      _map(_data(await _api.post('/reminders', data: values)));
  Future<void> deleteReminder(String id) => _api.delete('/reminders/$id');

  Future<List<Map<String, dynamic>>> checkIns() async =>
      _list(_data(await _api.get('/check-ins')));
  Future<Map<String, dynamic>> createCheckIn(Map<String, dynamic> values) async =>
      _map(_data(await _api.post('/check-ins', data: values)));

  Future<List<Map<String, dynamic>>> streaks() async =>
      _list(_data(await _api.get('/streaks')));

  Future<Map<String, dynamic>> preferences() async =>
      _map(_data(await _api.get('/preferences')));
  Future<Map<String, dynamic>> partnerPreferences() async =>
      _map(_data(await _api.get('/partner/preferences')));
  Future<void> savePreferences(Map<String, dynamic> values) =>
      _api.put('/preferences', data: {'preferences': values});
  Future<Map<String, dynamic>> loveLanguage() async =>
      _map(_data(await _api.get('/love-language')));
  Future<void> saveLoveLanguage(Map<String, dynamic> values) =>
      _api.put('/love-language', data: values);
  Future<List<Map<String, dynamic>>> romanticSuggestions() async =>
      _list(_data(await _api.get('/romantic-suggestions')));

  Future<Map<String, dynamic>> currentMood() async =>
      _map(_data(await _api.get('/moods/current')));
  Future<void> setMoodPrivacy(bool shared) =>
      _api.patch('/moods/privacy', data: {'shared': shared});
  Future<Map<String, dynamic>> sendMood({required String mood, String? note, String visibility = 'partner'}) async =>
      _map(_data(await _api.post('/moods', data: {
        'mood': mood,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'visibility': visibility,
      })));
  Future<Map<String, dynamic>> sendNeedYou({String? message}) async =>
      _map(_data(await _api.post('/need-you', data: {
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      })));
  Future<void> respondNeedYou(String id, {String response = "I'm here"}) =>
      _api.post('/need-you/$id/respond', data: {'response': response});

  Future<List<Map<String, dynamic>>> scheduledMessages() async =>
      _list(_data(await _api.get('/scheduled-messages')));
  Future<void> createScheduledMessage(Map<String, dynamic> values) =>
      _api.post('/scheduled-messages', data: values);
  Future<void> cancelScheduledMessage(String id) =>
      _api.delete('/scheduled-messages/$id');

  Future<List<Map<String, dynamic>>> surprises() async =>
      _list(_data(await _api.get('/surprises')));
  Future<void> createSurprise(Map<String, dynamic> values) =>
      _api.post('/surprises', data: values);
  Future<Map<String, dynamic>> unlockSurprise(String id) async =>
      _map(_data(await _api.post('/surprises/$id/unlock')));
  Future<void> deleteSurprise(String id) => _api.delete('/surprises/$id');

  Future<Map<String, dynamic>> currentCoolDown() async =>
      _map(_data(await _api.get('/cool-down/current')));
  Future<void> startCoolDown(Map<String, dynamic> values) =>
      _api.post('/cool-down', data: values);
  Future<void> endCoolDown(String id) => _api.delete('/cool-down/$id');
  Future<List<String>> reconnectionPrompts() async {
    final data = _data(await _api.get('/reconnection/prompts'));
    final raw = data is Map ? data['prompts'] : null;
    return raw is List ? raw.map((e) => '$e').toList() : <String>[];
  }
  Future<Map<String, dynamic>> startReconnection() async =>
      _map(_data(await _api.post('/reconnection/sessions')));
  Future<void> answerReconnection(String sessionId, String answer) =>
      _api.post('/reconnection/sessions/$sessionId/answers', data: {'answer': answer});
  Future<dynamic> revealReconnection(String sessionId) async =>
      _data(await _api.get('/reconnection/sessions/$sessionId/reveal'));

  Future<Map<String, dynamic>> generateDate({
    String? budget,
    String? mood,
    required String place,
    required int durationMinutes,
  }) async =>
      _map(_data(await _api.post('/date-generator/suggestions', data: {
        if (budget != null && budget.isNotEmpty) 'budget': budget,
        if (mood != null && mood.isNotEmpty) 'mood': mood,
        'place': place,
        'duration_minutes': durationMinutes,
      })));
  Future<List<Map<String, dynamic>>> dateHistory() async =>
      _list(_data(await _api.get('/date-generator/history')));

  Future<List<Map<String, dynamic>>> budgets() async =>
      _list(_data(await _api.get('/budgets')));
  Future<void> createBudget(Map<String, dynamic> values) =>
      _api.post('/budgets', data: values);
  Future<void> updateBudget(String id, Map<String, dynamic> values) =>
      _api.patch('/budgets/$id', data: values);
  Future<void> deleteBudget(String id) => _api.delete('/budgets/$id');
  Future<List<Map<String, dynamic>>> expenses() async =>
      _list(_data(await _api.get('/expenses')));
  Future<void> createExpense(Map<String, dynamic> values) =>
      _api.post('/expenses', data: values);
  Future<void> splitExpense(String id, Map<String, dynamic> values) =>
      _api.post('/expenses/$id/split', data: values);
  Future<Map<String, dynamic>> budgetPrivacy() async =>
      _map(_data(await _api.get('/budget-privacy')));
  Future<void> updateBudgetPrivacy(Map<String, dynamic> values) =>
      _api.put('/budget-privacy', data: values);

  Future<Map<String, dynamic>> insightStreaks() async =>
      _map(_data(await _api.get('/insights/streaks')));
  Future<Map<String, dynamic>> insightHighlights() async =>
      _map(_data(await _api.get('/insights/highlights')));
  Future<void> updateInsightPrivacy(Map<String, dynamic> values) =>
      _api.patch('/insights/privacy', data: values);
  Future<Map<String, dynamic>> createInsightShareCard(Map<String, dynamic> values) async =>
      _map(_data(await _api.post('/insights/share-cards', data: values)));
}
