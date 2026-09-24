import '../../../core/api/api_client.dart';

class LegalDocumentInfo {
  const LegalDocumentInfo({
    required this.id,
    required this.type,
    required this.version,
    required this.title,
    required this.content,
  });
  final String id;
  final String type;
  final String version;
  final String title;
  final String content;

  factory LegalDocumentInfo.fromJson(Map<String, dynamic> json) =>
      LegalDocumentInfo(
        id: '${json['id'] ?? ''}',
        type: '${json['type'] ?? ''}',
        version: '${json['version'] ?? ''}',
        title: '${json['title'] ?? json['type'] ?? ''}',
        content: '${json['content'] ?? ''}',
      );
}

class LegalState {
  const LegalState(
      {required this.requiredDocuments, required this.acceptedDocumentIds});
  final List<LegalDocumentInfo> requiredDocuments;
  final Set<String> acceptedDocumentIds;
  bool get acceptanceRequired =>
      requiredDocuments.any((doc) => !acceptedDocumentIds.contains(doc.id));
}

class LegalRepository {
  LegalRepository(this._api);
  final ApiClient _api;

  Future<LegalState> currentState() async {
    final docsResponse = await _api.get('/legal/documents');
    final consentsResponse = await _api.get('/consents');
    final docsRaw = docsResponse['data'];
    final consentsRaw = consentsResponse['data'];

    final docs = (docsRaw is List ? docsRaw : const <dynamic>[])
        .whereType<Map>()
        .map((e) => LegalDocumentInfo.fromJson(e.cast<String, dynamic>()))
        .where((d) =>
            d.id.isNotEmpty &&
            (d.type.toLowerCase().contains('term') ||
                d.type.toLowerCase().contains('privacy')))
        .toList();

    final accepted = <String>{};
    if (consentsRaw is List) {
      for (final item in consentsRaw.whereType<Map>()) {
        final map = item.cast<String, dynamic>();
        final document = map['document'];
        final id =
            '${map['legal_document_id'] ?? (document is Map ? document['id'] : '')}';
        final acceptedAt = map['accepted_at'];
        final revokedAt = map['revoked_at'];
        if (id.isNotEmpty && acceptedAt != null && revokedAt == null)
          accepted.add(id);
      }
    }
    return LegalState(requiredDocuments: docs, acceptedDocumentIds: accepted);
  }

  Future<void> accept(LegalDocumentInfo document) async {
    await _api.post('/consents',
        data: {'legal_document_id': document.id, 'accepted': true});
  }
}
