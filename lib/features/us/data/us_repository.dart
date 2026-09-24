import '../../../core/api/api_client.dart';

class UsRepository {UsRepository(this._api); final ApiClient _api; dynamic data(Map<String,dynamic> r)=>r['data'];
Future<List<Map<String,dynamic>>> storyEvents()async{dynamic d=data(await _api.get('/story/events'));if(d is Map)d=d['data'];return d is List?d.whereType<Map>().map((e)=>e.cast<String,dynamic>()).toList():[];}
Future<Map<String,dynamic>?> addStoryEvent({required String title,String? body})async{final d=data(await _api.post('/story/events',data:{'title':title,'body':body,'type':'milestone'}));return d is Map?d.cast<String,dynamic>():null;}
Future<Map<String,dynamic>> achievements()async{final d=data(await _api.get('/achievements'));return d is Map?d.cast<String,dynamic>():{};}
Future<Map<String,dynamic>> achievementProgress()async{final d=data(await _api.get('/achievement-progress'));return d is Map?d.cast<String,dynamic>():{};}
Future<Map<String,dynamic>> achievement(String id)async{final d=data(await _api.get('/achievements/$id'));return d is Map?d.cast<String,dynamic>():{};}
Future<List<Map<String,dynamic>>> sharedLists()async{dynamic d=data(await _api.get('/shared-lists'));return d is List?d.whereType<Map>().map((e)=>e.cast<String,dynamic>()).toList():[];}
Future<Map<String,dynamic>?> createSharedList(String title,String type)async{final d=data(await _api.post('/shared-lists',data:{'title':title,'type':type}));return d is Map?d.cast<String,dynamic>():null;}
Future<List<Map<String,dynamic>>> listItems(String id)async{dynamic d=data(await _api.get('/shared-lists/$id/items'));return d is List?d.whereType<Map>().map((e)=>e.cast<String,dynamic>()).toList():[];}
Future<void> addListItem(String id,String title,{String status='want_to',String? type,bool secret=false})=>_api.post('/shared-lists/$id/items',data:{'title':title,'status':status,if(type!=null)'type':type,'secret_gift_planning':secret});
Future<void> updateListItem(String listId,String itemId,Map<String,dynamic> values)=>_api.patch('/shared-lists/$listId/items/$itemId',data:values);
Future<void> deleteListItem(String listId,String itemId)=>_api.delete('/shared-lists/$listId/items/$itemId');
Future<void> deleteSharedList(String id)=>_api.delete('/shared-lists/$id');
Future<Map<String,dynamic>> coupleProfile()async{final d=data(await _api.get('/couple-profile'));return d is Map?d.cast<String,dynamic>():{};}
Future<List<Map<String,dynamic>>> albums()async{dynamic d=data(await _api.get('/albums'));return d is List?d.whereType<Map>().map((e)=>e.cast<String,dynamic>()).toList():[];}
Future<Map<String,dynamic>?> createAlbum(String title)async{final d=data(await _api.post('/albums',data:{'title':title,'status':'active'}));return d is Map?d.cast<String,dynamic>():null;}
Future<Map<String,dynamic>> album(String id)async{final d=data(await _api.get('/albums/$id'));return d is Map?d.cast<String,dynamic>():{};}
Future<void> updateAlbum(String id,Map<String,dynamic> values)=>_api.patch('/albums/$id',data:values);
Future<void> deleteAlbum(String id)=>_api.delete('/albums/$id');
Future<Map<String,dynamic>> addAlbumPhoto(String id,String mediaId,{String? caption})async{final d=data(await _api.post('/albums/$id/photos',data:{'media_id':mediaId,if(caption?.isNotEmpty==true)'caption':caption}));return d is Map?d.cast<String,dynamic>():{};}
Future<List<Map<String,dynamic>>> albumPhotos(String id)async{final d=data(await _api.get('/albums/$id/photos'));return d is List?d.whereType<Map>().map((e)=>e.cast<String,dynamic>()).toList():<Map<String,dynamic>>[];}
Future<void> updateAlbumPhoto(String albumId,String photoId,Map<String,dynamic> values)=>_api.patch('/albums/$albumId/photos/$photoId',data:values);
Future<void> deleteAlbumPhoto(String albumId,String photoId)=>_api.delete('/albums/$albumId/photos/$photoId');
Future<void> lockAlbum(String id)=>_api.post('/albums/$id/lock');
Future<void> exportAlbum(String id)=>_api.post('/albums/$id/export');
Future<void> deleteStoryEvent(String id)=>_api.delete('/story/events/$id');
}

