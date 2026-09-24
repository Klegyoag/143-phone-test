import '../../../core/api/api_client.dart';

class AppNotification {
  const AppNotification({required this.id, required this.title, required this.body, required this.type, required this.readAt, required this.createdAt, required this.actionData});
  final String id, title, body, type;
  final DateTime? readAt, createdAt;
  final Map<String,dynamic> actionData;
  bool get isRead => readAt != null;
  factory AppNotification.fromJson(Map<String,dynamic> j) {
    final nested=j['action_data']??j['data']??j['metadata'];
    return AppNotification(
      id:'${j['id']??''}',title:'${j['title']??'Notification'}',body:'${j['body']??''}',type:'${j['type']??''}',
      readAt:DateTime.tryParse('${j['read_at']??''}'),createdAt:DateTime.tryParse('${j['created_at']??''}'),
      actionData:nested is Map?nested.cast<String,dynamic>():<String,dynamic>{},
    );
  }
  Map<String,dynamic> get navigationPayload => <String,dynamic>{'type':type,...actionData};
}

class NotificationRepository {
  NotificationRepository(this._api); final ApiClient _api;
  Future<List<AppNotification>> list() async {
    final r=await _api.get('/notifications',query:{'limit':100}); dynamic d=r['data']; if(d is Map)d=d['data'];
    if(d is! List)return []; return d.whereType<Map>().map((e)=>AppNotification.fromJson(e.cast<String,dynamic>())).toList();
  }
  Future<int> unreadCount() async {final d=(await _api.get('/notifications/unread-count'))['data']; return d is Map ? int.tryParse('${d['count']??0}')??0:0;}
  Future<void> read(String id)=>_api.post('/notifications/$id/read');
  Future<void> readAll()=>_api.post('/notifications/read-all');
  Future<Map<String,dynamic>> preferences() async {final d=(await _api.get('/notification-preferences'))['data'];return d is Map?d.cast<String,dynamic>():<String,dynamic>{};}
  Future<Map<String,dynamic>> updatePreferences(Map<String,dynamic> values) async {final d=(await _api.put('/notification-preferences',data:{'preferences':values}))['data'];return d is Map?d.cast<String,dynamic>():<String,dynamic>{};}
}
