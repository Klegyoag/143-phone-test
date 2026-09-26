import '../../../core/api/api_client.dart';
import '../../../core/cache/local_cache.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.type,
    required this.payload,
    required this.replyToId,
    required this.createdAt,
    required this.editedAt,
    this.receipts = const [],
  });

  final String id, senderId, body, type;
  final Map<String, dynamic> payload;
  final String? replyToId;
  final DateTime? createdAt, editedAt;
  final List<Map<String, dynamic>> receipts;

  String? get mediaId => payload['media_id']?.toString();
  String get filename => '${payload['filename'] ?? body}';
  String get mime => '${payload['mime'] ?? ''}';
  int get size => int.tryParse('${payload['size'] ?? 0}') ?? 0;
  bool get hasMedia => mediaId != null && mediaId!.isNotEmpty;
  bool get readByPartner => receipts.any((r) => r['read_at'] != null);

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: '${j['id'] ?? ''}',
        senderId: '${j['sender_id'] ?? ''}',
        body: '${j['body'] ?? ''}',
        type: '${j['type'] ?? 'text'}',
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        replyToId: j['reply_to_id']?.toString(),
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
        editedAt: DateTime.tryParse('${j['edited_at'] ?? ''}'),
        receipts: j['receipts'] is List
            ? (j['receipts'] as List)
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList()
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'body': body,
        'type': type,
        'payload': payload,
        'reply_to_id': replyToId,
        'created_at': createdAt?.toUtc().toIso8601String(),
        'edited_at': editedAt?.toUtc().toIso8601String(),
        'receipts': receipts,
      };
}

class ChatPage {
  const ChatPage({required this.messages, required this.nextCursor});
  final List<ChatMessage> messages;
  final String? nextCursor;
  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}

class ChatRepository {
  ChatRepository(this._api, this._cache);
  final ApiClient _api;
  final LocalCache _cache;
  dynamic _data(Map<String, dynamic> j) => j['data'];

  Future<String> currentUserId() async {
    final d = _data(await _api.get('/me'));
    return d is Map ? '${d['id'] ?? ''}' : '';
  }

  Future<String> coupleConversationId() async {
    final d = _data(await _api.get('/conversations/couple'));
    return d is Map ? '${d['id'] ?? ''}' : '';
  }

  Future<ChatPage> messagesPage(String conversationId,
      {String? cursor, int limit = 40}) async {
    final d =
        _data(await _api.get('/conversations/$conversationId/messages', query: {
      'limit': limit,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    }));
    dynamic rows = d;
    String? next;
    if (d is Map) {
      rows = d['data'];
      next = d['next_cursor']?.toString();
    }
    if (rows is! List) return ChatPage(messages: const [], nextCursor: next);
    final list = rows
        .whereType<Map>()
        .map((e) => ChatMessage.fromJson(e.cast<String, dynamic>()))
        .toList();
    list.sort((a, b) => (a.createdAt ?? DateTime(1970))
        .compareTo(b.createdAt ?? DateTime(1970)));
    return ChatPage(messages: list, nextCursor: next);
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final key = 'chat_$conversationId';
    try {
      final page = await messagesPage(conversationId, limit: 50);
      await _cache.putJson(key, page.messages.map((e) => e.toJson()).toList());
      return page.messages;
    } catch (_) {
      final cached =
          await _cache.getJson<dynamic>(key, maxAge: const Duration(days: 3));
      if (cached is List) {
        final list = cached
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(e.cast<String, dynamic>()))
            .toList();
        list.sort((a, b) => (a.createdAt ?? DateTime(1970))
            .compareTo(b.createdAt ?? DateTime(1970)));
        return list;
      }
      rethrow;
    }
  }

  Future<void> cacheMessages(
          String conversationId, List<ChatMessage> messages) =>
      _cache.putJson(
          'chat_$conversationId', messages.map((e) => e.toJson()).toList());

  Future<List<ChatMessage>> cachedMessages(String conversationId) async {
    final cached = await _cache.getJson<dynamic>('chat_$conversationId',
        maxAge: const Duration(days: 3));
    if (cached is! List) return const [];
    return cached
        .whereType<Map>()
        .map((row) => ChatMessage.fromJson(row.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(1970))
          .compareTo(b.createdAt ?? DateTime(1970)));
  }

  Future<ChatMessage> send(
    String conversationId,
    String body, {
    String? replyToId,
    String type = 'text',
    Map<String, dynamic>? payload,
  }) async {
    final j = await _api.post('/conversations/$conversationId/messages', data: {
      'type': type,
      'body': body,
      'payload': payload ?? {},
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return ChatMessage.fromJson(
        ((_data(j) as Map?) ?? {}).cast<String, dynamic>());
  }

  Future<void> edit(String id, String body) =>
      _api.patch('/messages/$id', data: {'body': body});
  Future<void> delete(String id) => _api.delete('/messages/$id');
  Future<void> react(String id, String reaction) =>
      _api.post('/messages/$id/reactions', data: {'reaction': reaction});
  Future<void> unreact(String id, String reaction) =>
      _api.delete('/messages/$id/reactions/${Uri.encodeComponent(reaction)}');
  Future<void> markRead(String conversationId) =>
      _api.post('/conversations/$conversationId/read');
  Future<void> markMessageRead(String id) => _api.post('/messages/$id/read');
  Future<void> typingStart(String conversationId) =>
      _api.post('/conversations/$conversationId/typing/start');
  Future<void> typingStop(String conversationId) =>
      _api.post('/conversations/$conversationId/typing/stop');

  Future<int> unreadCount(String conversationId) async {
    final d =
        _data(await _api.get('/conversations/$conversationId/unread-count'));
    return d is Map ? int.tryParse('${d['count'] ?? 0}') ?? 0 : 0;
  }
}
