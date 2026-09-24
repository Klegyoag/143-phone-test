import '../../../core/api/api_client.dart';


class MemoryLocation {
  const MemoryLocation({required this.latitude, required this.longitude, this.label, this.capturedAt});
  final double latitude, longitude;
  final String? label;
  final DateTime? capturedAt;

  factory MemoryLocation.fromJson(Map<String, dynamic> json) => MemoryLocation(
        latitude: double.tryParse('${json['latitude'] ?? json['lat'] ?? ''}') ?? 0,
        longitude: double.tryParse('${json['longitude'] ?? json['lng'] ?? json['lon'] ?? ''}') ?? 0,
        label: json['label']?.toString(),
        capturedAt: DateTime.tryParse('${json['captured_at'] ?? ''}'),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
        if (capturedAt != null) 'captured_at': capturedAt!.toUtc().toIso8601String(),
      };
}

class MemoryAttachment {
  const MemoryAttachment({
    required this.mediaId,
    required this.filename,
    required this.mime,
    required this.size,
  });

  final String mediaId;
  final String filename;
  final String mime;
  final int size;

  bool get isImage => mime.startsWith('image/');
  bool get isVideo => mime.startsWith('video/');
  bool get isAudio => mime.startsWith('audio/');
  bool get isDocument => mime == 'application/pdf' || mime.startsWith('text/');

  factory MemoryAttachment.fromJson(Map<String, dynamic> json) => MemoryAttachment(
        mediaId: '${json['media_id'] ?? ''}',
        filename: '${json['filename'] ?? 'attachment'}',
        mime: '${json['mime'] ?? 'application/octet-stream'}',
        size: int.tryParse('${json['size'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'media_id': mediaId,
        'filename': filename,
        'mime': mime,
        'size': size,
      };
}

class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.isLocked,
    required this.revealAt,
  });

  final String id, type, title;
  final Map<String, dynamic> content;
  final List<String> tags;
  final DateTime? createdAt, revealAt;
  final bool isLocked;

  String get body => '${content['body'] ?? ''}';

  MemoryLocation? get location {
    final raw = content['location'];
    if (raw is! Map) return null;
    final parsed = MemoryLocation.fromJson(raw.cast<String, dynamic>());
    return parsed.latitude == 0 && parsed.longitude == 0 ? null : parsed;
  }

  List<MemoryAttachment> get attachments {
    final raw = content['attachments'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MemoryAttachment.fromJson(e.cast<String, dynamic>()))
        .where((e) => e.mediaId.isNotEmpty)
        .toList();
  }

  factory MemoryItem.fromJson(Map<String, dynamic> j) => MemoryItem(
        id: '${j['id'] ?? ''}',
        type: '${j['type'] ?? 'moment'}',
        title: '${j['title'] ?? 'Untitled memory'}',
        content: (j['content'] as Map?)?.cast<String, dynamic>() ?? {},
        tags: (j['tags'] is List)
            ? (j['tags'] as List).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList()
            : const [],
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
        revealAt: DateTime.tryParse('${j['reveal_at'] ?? ''}'),
        isLocked: j['is_locked'] == true,
      );
}

class MemoryComment {
  const MemoryComment({required this.id, required this.userId, required this.body, required this.createdAt});
  final String id, userId, body;
  final DateTime? createdAt;
  factory MemoryComment.fromJson(Map<String, dynamic> j) => MemoryComment(
        id: '${j['id'] ?? ''}',
        userId: '${j['user_id'] ?? ''}',
        body: '${j['body'] ?? ''}',
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
      );
}

class TimeCapsuleStatus {
  const TimeCapsuleStatus({required this.locked, required this.revealAt, required this.revealedAt});
  final bool locked;
  final DateTime? revealAt, revealedAt;
  bool get revealDue => revealAt == null || !DateTime.now().isBefore(revealAt!);
  factory TimeCapsuleStatus.fromJson(Map<String, dynamic> j) => TimeCapsuleStatus(
        locked: j['locked'] == true,
        revealAt: DateTime.tryParse('${j['reveal_at'] ?? ''}'),
        revealedAt: DateTime.tryParse('${j['revealed_at'] ?? ''}'),
      );
}

class MemoryRepository {
  MemoryRepository(this._api);
  final ApiClient _api;

  Future<List<MemoryItem>> list({String? type, String? q}) async {
    final json = await _api.get('/memories', query: {
      'limit': 50,
      if (type != null && type != 'all') 'type': type,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    });
    dynamic rows = json['data'];
    if (rows is Map) rows = rows['data'];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => MemoryItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<MemoryItem>> drafts() async {
    final d = (await _api.get('/memories/drafts'))['data'];
    if (d is! List) return [];
    return d.whereType<Map>().map((e) => MemoryItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<MemoryItem> getOne(String id) async {
    final d = (await _api.get('/memories/$id'))['data'];
    return MemoryItem.fromJson(((d as Map?) ?? {}).cast<String, dynamic>());
  }

  Future<MemoryItem> create({
    required String type,
    String? title,
    String? body,
    List<String> tags = const [],
    List<MemoryAttachment> attachments = const [],
    MemoryLocation? location,
    bool draft = false,
    DateTime? revealAt,
  }) async {
    final json = await _api.post('/memories', data: {
      'type': type,
      'title': title,
      'content': {
        'body': body ?? '',
        'attachments': attachments.map((e) => e.toJson()).toList(),
        if (location != null) 'location': location.toJson(),
      },
      'tags': tags,
      'is_draft': draft,
      if (revealAt != null) 'reveal_at': revealAt.toUtc().toIso8601String(),
    });
    return MemoryItem.fromJson(((json['data'] as Map?) ?? {}).cast<String, dynamic>());
  }

  Future<MemoryItem> update(
    String id, {
    String? title,
    String? body,
    List<String>? tags,
    List<MemoryAttachment>? attachments,
    MemoryLocation? location,
    bool clearLocation = false,
    bool? draft,
    DateTime? revealAt,
  }) async {
    final json = await _api.patch('/memories/$id', data: {
      if (title != null) 'title': title,
      if (body != null || attachments != null || location != null || clearLocation)
        'content': {
          if (body != null) 'body': body,
          if (attachments != null) 'attachments': attachments.map((e) => e.toJson()).toList(),
          if (location != null) 'location': location.toJson(),
          if (clearLocation) 'location': null,
        },
      if (tags != null) 'tags': tags,
      if (draft != null) 'is_draft': draft,
      if (revealAt != null) 'reveal_at': revealAt.toUtc().toIso8601String(),
    });
    return MemoryItem.fromJson(((json['data'] as Map?) ?? {}).cast<String, dynamic>());
  }

  Future<void> delete(String id) => _api.delete('/memories/$id');
  Future<List<MemoryComment>> comments(String id) async {
    final d = (await _api.get('/memories/$id/comments'))['data'];
    if (d is! List) return [];
    return d.whereType<Map>().map((e) => MemoryComment.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> addComment(String id, String body) => _api.post('/memories/$id/comments', data: {'body': body});
  Future<void> react(String id, String reaction) => _api.post('/memories/$id/reactions', data: {'reaction': reaction});
  Future<void> unreact(String id, String reaction) => _api.delete('/memories/$id/reactions/${Uri.encodeComponent(reaction)}');
  Future<Map<String, dynamic>> share(String id) async => ((await _api.post('/memories/$id/share'))['data'] as Map?)?.cast<String, dynamic>() ?? {};
  Future<void> lockCapsule(String id) => _api.post('/time-capsules/$id/lock');
  Future<void> scheduleCapsule(String id, DateTime at) => _api.post('/time-capsules/$id/schedule', data: {'reveal_at': at.toUtc().toIso8601String()});
  Future<MemoryItem> revealCapsule(String id) async {
    final data = (await _api.post('/time-capsules/$id/reveal'))['data'];
    return MemoryItem.fromJson(((data as Map?) ?? {}).cast<String, dynamic>());
  }

  Future<TimeCapsuleStatus> capsuleStatus(String id) async {
    final data = (await _api.get('/time-capsules/$id/status'))['data'];
    return TimeCapsuleStatus.fromJson(((data as Map?) ?? {}).cast<String, dynamic>());
  }
}
