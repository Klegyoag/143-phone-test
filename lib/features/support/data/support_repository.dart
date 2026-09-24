import '../../../core/api/api_client.dart';

class SupportRepository {
  SupportRepository(this._api);
  final ApiClient _api;

  dynamic _data(Map<String, dynamic> r) => r['data'];
  List<Map<String, dynamic>> _list(dynamic v) {
    if (v is Map && v['data'] is List) v = v['data'];
    return v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
  }
  Map<String, dynamic> _map(dynamic v) => v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  Future<List<Map<String, dynamic>>> legalDocuments() async => _list(_data(await _api.get('/legal/documents')));
  Future<Map<String, dynamic>> legalDocument(String type) async => _map(_data(await _api.get('/legal/documents/$type')));
  Future<Map<String, dynamic>> bootstrap() async => _map(_data(await _api.get('/bootstrap')));

  Future<List<Map<String, dynamic>>> exports() async => _list(_data(await _api.get('/exports')));
  Future<Map<String, dynamic>> requestExport(String format) async => _map(_data(await _api.post('/exports', data: {'format': format})));
  Future<Map<String, dynamic>> export(String id) async => _map(_data(await _api.get('/exports/$id')));
  Future<Map<String, dynamic>> exportDownload(String id) async => _map(_data(await _api.get('/exports/$id/download')));

  Future<List<Map<String, dynamic>>> helpArticles() async => _list(_data(await _api.get('/help/articles')));
  Future<Map<String, dynamic>> helpArticle(String id) async => _map(_data(await _api.get('/help/articles/$id')));
  Future<List<Map<String, dynamic>>> tickets() async => _list(_data(await _api.get('/support/tickets')));
  Future<Map<String, dynamic>> createTicket({required String subject, required String message}) async => _map(_data(await _api.post('/support/tickets', data: {'title': subject, 'body': message, 'subject': subject, 'message': message})));
  Future<void> feedback({required String message, int? rating}) => _api.post('/feedback', data: {'body': message, 'message': message, if (rating != null) 'rating': rating});
  Future<Map<String, dynamic>> about() async => _map(_data(await _api.get('/about')));
  Future<List<Map<String, dynamic>>> releaseNotes() async => _list(_data(await _api.get('/release-notes')));
}
