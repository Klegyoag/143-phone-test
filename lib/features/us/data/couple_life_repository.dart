import '../../../core/api/api_client.dart';

class CoupleLifeRepository {
  CoupleLifeRepository(this._api);
  final ApiClient _api;

  dynamic _data(Map<String, dynamic> response) => response['data'];
  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is Map && value['data'] is List) value = value['data'];
    if (value is List) return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    return const [];
  }
  Map<String, dynamic> _map(dynamic value) => value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  Future<List<Map<String, dynamic>>> calendarEvents() async => _list(_data(await _api.get('/calendar/events')));
  Future<Map<String, dynamic>> calendarEvent(String id) async => _map(_data(await _api.get('/calendar/events/$id')));
  Future<void> createCalendarEvent({required String title, required DateTime startsAt, String type='date_night', String? note, String? location, bool recurring=false, String recurrence='none'}) => _api.post('/calendar/events', data:{'title':title,'type':type,'starts_at':startsAt.toUtc().toIso8601String(),'data':{'recurring':recurring,'recurrence':recurrence,if(note?.trim().isNotEmpty==true)'note':note!.trim(),if(location?.trim().isNotEmpty==true)'location':location!.trim()}});
  Future<void> updateCalendarEvent(String id, Map<String,dynamic> data) => _api.patch('/calendar/events/$id', data:data);
  Future<void> deleteCalendarEvent(String id) => _api.delete('/calendar/events/$id');
  Future<List<Map<String,dynamic>>> calendarComments(String id) async => _list(_data(await _api.get('/calendar/events/$id/comments')));
  Future<void> addCalendarComment(String id,String body)=>_api.post('/calendar/events/$id/comments',data:{'body':body});
  Future<void> completeCalendarEvent(String id)=>_api.post('/calendar/events/$id/complete');
  Future<void> convertCalendarEventToMemory(String id)=>_api.post('/calendar/events/$id/convert-to-memory');
  Future<void> addCalendarReflection(String id,String reflection)=>_api.post('/calendar/events/$id/reflection',data:{'reflection':reflection});
  Future<Map<String,dynamic>> addCalendarPhoto(String id,String mediaId) async => _map(_data(await _api.post('/calendar/events/$id/photos',data:{'media_id':mediaId})));
  Future<List<Map<String,dynamic>>> calendarPhotos(String id) async => _list(_data(await _api.get('/calendar/events/$id/photos')));
  Future<void> deleteCalendarPhoto(String id,String mediaId)=>_api.delete('/calendar/events/$id/photos/$mediaId');
  Future<List<Map<String,dynamic>>> reminders() async=>_list(_data(await _api.get('/reminders')));
  Future<Map<String,dynamic>> createReminder({required String title,required DateTime scheduledAt,String? calendarEventId,String type='calendar_event'}) async=>_map(_data(await _api.post('/reminders',data:{'title':title,'type':type,'scheduled_at':scheduledAt.toUtc().toIso8601String(),if(calendarEventId!=null)'calendar_event_id':calendarEventId,'data':{if(calendarEventId!=null)'calendar_event_id':calendarEventId}})));
  Future<void> deleteReminder(String id)=>_api.delete('/reminders/$id');

  Future<List<Map<String, dynamic>>> games() async => _list(_data(await _api.get('/games')));
  Future<List<Map<String, dynamic>>> gameSessions() async => _list(_data(await _api.get('/game-sessions')));
  Future<Map<String, dynamic>> startGame(String gameKey) async => _map(_data(await _api.post('/game-sessions', data: {'game_key': gameKey})));
  Future<void> submitGameAnswer(String sessionId, String answer, {required String questionKey}) => _api.post('/game-sessions/$sessionId/answers', data:{'answer':answer,'question_key':questionKey});
  Future<Map<String, dynamic>> completeGame(String sessionId) async => _map(_data(await _api.post('/game-sessions/$sessionId/complete')));
  Future<Map<String, dynamic>> gameSession(String sessionId) async => _map(_data(await _api.get('/game-sessions/$sessionId')));
  Future<Map<String, dynamic>> gameResults(String sessionId) async => _map(_data(await _api.get('/game-sessions/$sessionId/results')));
  Future<Map<String, dynamic>> xp() async => _map(_data(await _api.get('/xp')));

  Future<List<Map<String,dynamic>>> jars() async => _list(_data(await _api.get('/jars')));
  Future<void> createJar(String title,String type)=>_api.post('/jars',data:{'title':title,'type':type});
  Future<List<Map<String,dynamic>>> jarEntries(String jarId) async=>_list(_data(await _api.get('/jars/$jarId/entries')));
  Future<void> addJarEntry(String jarId,String body)=>_api.post('/jars/$jarId/entries',data:{'body':body});
  Future<void> editJarEntry(String jarId,String entryId,String body)=>_api.patch('/jars/$jarId/entries/$entryId',data:{'body':body});
  Future<void> deleteJarEntry(String jarId,String entryId)=>_api.delete('/jars/$jarId/entries/$entryId');
  Future<Map<String,dynamic>> randomJarPick(String jarId) async=>_map(_data(await _api.post('/jars/$jarId/random-pick')));

  Future<List<Map<String,dynamic>>> bucketItems() async=>_list(_data(await _api.get('/bucket-list')));
  Future<void> createBucketItem(String title,{DateTime? targetDate,String? location})=>_api.post('/bucket-list',data:{'title':title,'status':'active','data':{if(targetDate!=null)'target_date':targetDate.toIso8601String(),if(location?.trim().isNotEmpty==true)'location':location!.trim()}});
  Future<void> updateBucketItem(String id,Map<String,dynamic> data)=>_api.patch('/bucket-list/$id',data:data);
  Future<void> addBucketComment(String id,String body)=>_api.post('/bucket-list/$id/comments',data:{'body':body});
  Future<void> completeBucketItem(String id)=>_api.post('/bucket-list/$id/complete');
  Future<void> convertBucketToMilestone(String id)=>_api.post('/bucket-list/$id/convert-to-milestone');

  Future<List<Map<String,dynamic>>> goals() async=>_list(_data(await _api.get('/goals')));
  Future<void> createGoal(String title,{String type='shared',double? target})=>_api.post('/goals',data:{'title':title,'status':'active','type':type,'data':{if(target!=null)'target':target}});
  Future<void> addGoalProgress(String id,double value,{String? note})=>_api.post('/goals/$id/progress',data:{'value':value,if(note?.trim().isNotEmpty==true)'note':note!.trim()});
  Future<void> addGoalComment(String id,String body)=>_api.post('/goals/$id/comments',data:{'body':body});

  Future<Map<String,dynamic>> longDistance() async=>_map(_data(await _api.get('/long-distance')));
  Future<Map<String,dynamic>> partnerTime() async=>_map(_data(await _api.get('/long-distance/partner-time')));
  Future<Map<String,dynamic>> distance() async=>_map(_data(await _api.get('/long-distance/distance')));
  Future<dynamic> nextMeet() async=>_data(await _api.get('/long-distance/next-meet'));
  Future<void> setLongDistanceEnabled(bool enabled)=>_api.patch('/long-distance',data:{'enabled':enabled});
  Future<void> setNextMeet(DateTime date)=>_api.put('/long-distance/next-meet',data:{'next_meet':date.toIso8601String()});
  Future<List<Map<String,dynamic>>> travelItineraries() async=>_list(_data(await _api.get('/travel-itineraries')));
  Future<void> createTravelItinerary({required String title,required DateTime startsAt,String? flight,String? destination})=>_api.post('/travel-itineraries',data:{'title':title,'starts_at':startsAt.toIso8601String(),'data':{if(flight?.trim().isNotEmpty==true)'flight':flight!.trim(),if(destination?.trim().isNotEmpty==true)'destination':destination!.trim()}});
  Future<void> updateTravelItinerary(String id,Map<String,dynamic> data)=>_api.patch('/travel-itineraries/$id',data:data);
  Future<void> deleteTravelItinerary(String id)=>_api.delete('/travel-itineraries/$id');
  Future<Map<String,dynamic>> createVirtualDate({required String title,DateTime? startsAt}) async=>_map(_data(await _api.post('/virtual-dates',data:{'title':title,if(startsAt!=null)'starts_at':startsAt.toIso8601String()})));
  Future<Map<String,dynamic>> startCall({required String type}) async=>_map(_data(await _api.post('/calls',data:{'type':type})));
}
