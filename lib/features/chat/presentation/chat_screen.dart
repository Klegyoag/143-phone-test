import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/realtime/realtime_events.dart';
import '../../../core/theme/app_colors.dart';
import '../../calls/presentation/call_session_screen.dart';
import '../../location/presentation/location_preview_screen.dart';
import 'widgets/audio_message_player.dart';
import 'widgets/video_message_player.dart';
import '../data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _State();
}

class _PendingBubble {
  _PendingBubble({required this.localId, required this.body, this.failed = false});
  final String localId, body;
  bool failed;
}

class _State extends ConsumerState<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final imagePicker = ImagePicker();
  final recorder = AudioRecorder();
  String conversationId = '', myUserId = '';
  List<ChatMessage> messages = [];
  final List<_PendingBubble> pending = [];
  bool loading = true, sendingAttachment = false, loadingOlder = false;
  String? nextCursor;
  Timer? timer;
  Timer? typingDebounce;
  Timer? partnerTypingExpiry;
  StreamSubscription? realtimeSub;
  ChatMessage? replying;
  bool typingPublished = false;
  bool partnerTyping = false;
  String partnerPresence = 'private couple chat';

  @override
  void initState() {
    super.initState();
    final rt = ref.read(realtimeCoordinatorProvider);
    rt.start();
    realtimeSub = rt.events.listen((event) {
      if (event.name == RealtimeEvents.presenceUpdated && '${event.payload['user_id'] ?? ''}' != myUserId) {
        if (mounted) setState(() => partnerPresence = '${event.payload['status'] ?? 'away'}');
        return;
      }
      if (event.name.startsWith('chat.message.')) {
        _refresh(silent: true);
        return;
      }
      if (event.name == RealtimeEvents.chatTypingStarted || event.name == RealtimeEvents.chatTypingStopped) {
        if ('${event.payload['conversation_id'] ?? ''}' != conversationId || '${event.payload['user_id'] ?? ''}' == myUserId) return;
        partnerTypingExpiry?.cancel();
        final active = event.name == RealtimeEvents.chatTypingStarted;
        if (mounted) setState(() => partnerTyping = active);
        if (active) {
          partnerTypingExpiry = Timer(const Duration(seconds: 5), () {
            if (mounted) setState(() => partnerTyping = false);
          });
        }
      }
    });
    input.addListener(_typingChanged);
    _init();
  }

  Future<void> _init() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      myUserId = await repo.currentUserId();
      conversationId = await repo.coupleConversationId();
      await _loadPresence();
      await _refresh();
      timer = Timer.periodic(const Duration(seconds: 25), (_) => _refresh(silent: true));
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadPresence() async {
    try {
      final rows = await ref.read(coupleRepositoryProvider).presence();
      for (final row in rows) {
        if ('${row['user_id'] ?? ''}' == myUserId) continue;
        partnerPresence = '${row['status'] ?? 'away'}';
        break;
      }
    } catch (_) {}
  }

  Future<void> _refresh({bool silent = false}) async {
    if (conversationId.isEmpty) return;
    try {
      final page = await ref.read(chatRepositoryProvider).messagesPage(conversationId, limit: 40);
      if (!mounted) return;
      setState(() {
        final newerIds = page.messages.map((e) => e.id).toSet();
        final older = messages.where((e) => !newerIds.contains(e.id)).toList();
        messages = [...older, ...page.messages]
          ..sort((a, b) => (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970)));
        nextCursor ??= page.nextCursor;
        loading = false;
      });
      await ref.read(chatRepositoryProvider).cacheMessages(conversationId, messages);
      await ref.read(chatRepositoryProvider).markRead(conversationId);
    } catch (_) {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  Future<void> _loadOlder() async {
    if (conversationId.isEmpty || nextCursor == null || loadingOlder) return;
    setState(() => loadingOlder = true);
    try {
      final page = await ref.read(chatRepositoryProvider).messagesPage(conversationId, cursor: nextCursor, limit: 40);
      if (!mounted) return;
      setState(() {
        final known = messages.map((e) => e.id).toSet();
        messages = [...page.messages.where((e) => !known.contains(e.id)), ...messages]
          ..sort((a, b) => (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970)));
        nextCursor = page.nextCursor;
      });
      await ref.read(chatRepositoryProvider).cacheMessages(conversationId, messages);
    } catch (e) {
      _snack('Could not load older messages: $e');
    } finally {
      if (mounted) setState(() => loadingOlder = false);
    }
  }

  void _typingChanged() {
    if (conversationId.isEmpty) return;
    typingDebounce?.cancel();
    if (input.text.trim().isNotEmpty && !typingPublished) {
      typingPublished = true;
      unawaited(ref.read(chatRepositoryProvider).typingStart(conversationId).catchError((_) {}));
    }
    typingDebounce = Timer(const Duration(milliseconds: 1200), () {
      if (!typingPublished || conversationId.isEmpty) return;
      typingPublished = false;
      unawaited(ref.read(chatRepositoryProvider).typingStop(conversationId).catchError((_) {}));
    });
  }

  Future<void> _send({String? retryBody}) async {
    final text = retryBody ?? input.text.trim();
    if (text.isEmpty || conversationId.isEmpty) return;
    if (retryBody == null) input.clear();
    if (typingPublished && conversationId.isNotEmpty) {
      typingPublished = false;
      unawaited(ref.read(chatRepositoryProvider).typingStop(conversationId).catchError((_) {}));
    }
    final local = _PendingBubble(localId: DateTime.now().microsecondsSinceEpoch.toString(), body: text);
    setState(() => pending.add(local));
    try {
      await ref.read(chatRepositoryProvider).send(conversationId, text, replyToId: replying?.id);
      replying = null;
      if (mounted) setState(() => pending.remove(local));
      await _refresh();
      _scrollBottom();
    } catch (_) {
      if (mounted) setState(() => local.failed = true);
    }
  }

  Future<void> _retry(_PendingBubble local) async {
    setState(() => pending.remove(local));
    await _send(retryBody: local.body);
  }

  Future<void> _actions(ChatMessage m) async {
    final own = m.senderId == myUserId;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.reply_rounded), title: const Text('Reply'), onTap: () => Navigator.pop(c, 'reply')),
          ListTile(leading: const Icon(Icons.favorite_border), title: const Text('React with ❤️'), onTap: () => Navigator.pop(c, 'heart')),
          if (own) ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit'), onTap: () => Navigator.pop(c, 'edit')),
          if (own) ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Delete', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(c, 'delete')),
        ]),
      ),
    );
    if (action == 'reply') setState(() => replying = m);
    if (action == 'heart') await ref.read(chatRepositoryProvider).react(m.id, '❤️');
    if (action == 'delete') {
      await ref.read(chatRepositoryProvider).delete(m.id);
      await _refresh();
    }
    if (action == 'edit') {
      final c = TextEditingController(text: m.body);
      final ok = await showDialog<bool>(
        context: context,
        builder: (x) => AlertDialog(
          title: const Text('Edit message'),
          content: TextField(controller: c, autofocus: true, maxLines: 4),
          actions: [TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(x, true), child: const Text('Save'))],
        ),
      );
      if (ok == true && c.text.trim().isNotEmpty) {
        await ref.read(chatRepositoryProvider).edit(m.id, c.text.trim());
        await _refresh();
      }
      c.dispose();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    typingDebounce?.cancel();
    partnerTypingExpiry?.cancel();
    if (typingPublished && conversationId.isNotEmpty) unawaited(ref.read(chatRepositoryProvider).typingStop(conversationId).catchError((_) {}));
    realtimeSub?.cancel();
    input.removeListener(_typingChanged);
    input.dispose();
    scroll.dispose();
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Your person ♡'), Text(partnerTyping ? 'typing…' : partnerPresence, style: const TextStyle(fontSize: 12, color: AppColors.muted))]),
          actions: [
            Consumer(builder: (context, ref, _) {
              final rt = ref.watch(realtimeCoordinatorProvider);
              return Tooltip(message: rt.connected ? 'Realtime connected' : (rt.enabled ? 'Realtime reconnecting' : 'Realtime not configured'), child: Icon(rt.connected ? Icons.bolt_rounded : Icons.bolt_outlined, color: rt.connected ? AppColors.rose : AppColors.muted));
            }),
            IconButton(onPressed: () => _startCall('audio'), icon: const Icon(Icons.call_outlined)),
            IconButton(onPressed: () => _startCall('video'), icon: const Icon(Icons.videocam_outlined)),
          ],
        ),
        body: Column(children: [
          Expanded(child: _chatBody()),
          if (partnerTyping)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 2),
              child: Align(alignment: Alignment.centerLeft, child: Text('Your person is typing…', style: TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic))),
            ),
          if (replying != null)
            Container(
              color: AppColors.blush,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [const Icon(Icons.reply, color: AppColors.rose, size: 18), const SizedBox(width: 8), Expanded(child: Text('Replying to: ${replying!.body}', maxLines: 1, overflow: TextOverflow.ellipsis)), IconButton(onPressed: () => setState(() => replying = null), icon: const Icon(Icons.close, size: 18))]),
            ),
          if (sendingAttachment) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: input,
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Message your person…',
                  prefixIcon: IconButton(onPressed: sendingAttachment ? null : _attachmentSheet, icon: const Icon(Icons.add_circle_outline)),
                  suffixIcon: IconButton(onPressed: () => _send(), icon: const Icon(Icons.send_rounded, color: AppColors.rose)),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _chatBody() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (conversationId.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Link your partner first to start your private chat.', textAlign: TextAlign.center)));
    return RefreshIndicator(
      onRefresh: () => _refresh(),
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        children: [
          if (nextCursor != null)
            Center(child: TextButton.icon(onPressed: loadingOlder ? null : _loadOlder, icon: loadingOlder ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.history_rounded), label: const Text('Load older messages'))),
          ...messages.map(_messageBubble),
          ...pending.map(_pendingBubble),
        ],
      ),
    );
  }

  Widget _messageBubble(ChatMessage m) {
    final own = m.senderId == myUserId;
    final replied = m.replyToId == null ? null : messages.where((x) => x.id == m.replyToId).firstOrNull;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _actions(m),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          decoration: BoxDecoration(
            color: own ? AppColors.rose : Colors.white,
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(own ? 20 : 5), bottomRight: Radius.circular(own ? 5 : 20)),
            border: own ? null : Border.all(color: AppColors.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (replied != null) _replyPreview(replied, own),
            _messageContent(m, own),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${m.editedAt != null ? 'edited • ' : ''}${_time(m.createdAt)}', style: TextStyle(fontSize: 10, color: own ? Colors.white70 : AppColors.muted)),
              if (own) ...[const SizedBox(width: 5), Icon(m.readByPartner ? Icons.done_all_rounded : Icons.done_rounded, size: 13, color: m.readByPartner ? Colors.white : Colors.white70)],
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _messageContent(ChatMessage m, bool own) {
    final textColor = own ? Colors.white : AppColors.ink;
    if (m.type == 'text') return Text(m.body, style: TextStyle(color: textColor));
    if (m.type == 'image' && m.mediaId != null) {
      return FutureBuilder<String?>(
        future: ref.read(mediaUrlCacheProvider).resolve(m.mediaId!),
        builder: (context, s) {
          if (s.data == null) return SizedBox(height: 150, width: 210, child: Center(child: CircularProgressIndicator(color: own ? Colors.white : AppColors.rose)));
          return GestureDetector(
            onTap: () => showDialog<void>(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(s.data!)))),
            child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(s.data!, width: 230, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _mediaFallback(m, own, Icons.broken_image_outlined))),
          );
        },
      );
    }
    if (m.type == 'video' && m.mediaId != null) {
      return FutureBuilder<String?>(
        future: ref.read(mediaUrlCacheProvider).resolve(m.mediaId!),
        builder: (context, s) => s.data == null
            ? const SizedBox(width: 230, height: 150, child: Center(child: CircularProgressIndicator()))
            : VideoMessagePlayer(url: s.data!),
      );
    }
    if (m.type == 'voice' && m.mediaId != null) {
      return FutureBuilder<String?>(
        future: ref.read(mediaUrlCacheProvider).resolve(m.mediaId!),
        builder: (context, s) => s.data == null
            ? const SizedBox(width: 220, height: 54, child: Center(child: CircularProgressIndicator()))
            : AudioMessagePlayer(url: s.data!, foreground: textColor),
      );
    }
    if (m.type == 'location') {
      final lat = double.tryParse('${m.payload['latitude'] ?? ''}');
      final lng = double.tryParse('${m.payload['longitude'] ?? ''}');
      if (lat != null && lng != null) {
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationPreviewScreen(latitude: lat, longitude: lng))),
          child: SizedBox(
            width: 220,
            child: Row(children: [
              Icon(Icons.location_on_rounded, color: textColor),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Shared location', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: TextStyle(color: textColor.withValues(alpha: .75), fontSize: 11)),
                const SizedBox(height: 3),
                Text('Tap to view map', style: TextStyle(color: textColor.withValues(alpha: .75), fontSize: 10)),
              ])),
            ]),
          ),
        );
      }
    }
    if (m.type == 'document' && m.mediaId != null) {
      return FutureBuilder<String?>(
        future: ref.read(mediaUrlCacheProvider).resolve(m.mediaId!),
        builder: (context, signed) {
          final url = signed.data;
          if (signed.connectionState == ConnectionState.waiting) {
            return const SizedBox(width: 210, height: 52, child: Center(child: CircularProgressIndicator()));
          }
          return InkWell(
            onTap: url == null || url.isEmpty ? null : () => _openSignedAttachment(url),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.description_outlined, color: textColor),
                const SizedBox(width: 10),
                Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.filename.isEmpty ? 'Document' : m.filename, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                  Text(url == null || url.isEmpty ? 'Preview unavailable' : 'Tap to open securely', style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: .75))),
                ])),
                if (url != null && url.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.open_in_new_rounded, size: 17, color: textColor)),
              ]),
            ),
          );
        },
      );
    }
    return _mediaFallback(
      m,
      own,
      m.type == 'video' ? Icons.play_circle_outline_rounded : m.type == 'voice' ? Icons.graphic_eq_rounded : m.type == 'location' ? Icons.location_on_outlined : m.type == 'document' ? Icons.description_outlined : Icons.attach_file_rounded,
    );
  }

  Future<void> _openSignedAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this attachment.')));
    }
  }

  Widget _mediaFallback(ChatMessage m, bool own, IconData icon) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: own ? Colors.white : AppColors.rose),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.filename.isEmpty ? m.type : m.filename, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: own ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600)), if (m.mime.isNotEmpty) Text(m.mime, style: TextStyle(fontSize: 10, color: own ? Colors.white70 : AppColors.muted))])),
      ]);

  Widget _replyPreview(ChatMessage replied, bool own) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (own ? Colors.white : AppColors.blush).withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
        child: Text(replied.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: own ? Colors.white70 : AppColors.muted)),
      );

  Widget _pendingBubble(_PendingBubble p) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          decoration: BoxDecoration(color: p.failed ? AppColors.peach : AppColors.rose.withValues(alpha: .75), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.body, style: TextStyle(color: p.failed ? AppColors.ink : Colors.white)),
            const SizedBox(height: 4),
            if (p.failed)
              InkWell(onTap: () => _retry(p), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error_outline, size: 14, color: Colors.redAccent), SizedBox(width: 5), Text('Failed • Tap to retry', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w700))]))
            else
              const Text('Sending…', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ]),
        ),
      );

  Future<void> _attachmentSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () => Navigator.pop(context, 'camera')),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photos'), onTap: () => Navigator.pop(context, 'photo')),
          ListTile(leading: const Icon(Icons.videocam_outlined), title: const Text('Video'), onTap: () => Navigator.pop(context, 'video')),
          ListTile(leading: const Icon(Icons.insert_drive_file_outlined), title: const Text('File'), onTap: () => Navigator.pop(context, 'file')),
          ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Document'), onTap: () => Navigator.pop(context, 'document')),
          ListTile(leading: const Icon(Icons.mic_none_rounded), title: const Text('Voice'), subtitle: const Text('Record a voice message'), onTap: () => Navigator.pop(context, 'voice')),
          ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Location'), subtitle: const Text('Share your current location with consent'), onTap: () => Navigator.pop(context, 'location')),
        ]),
      ),
    );
    if (action == null) return;
    if (action == 'camera') return _pickImage(ImageSource.camera);
    if (action == 'photo') return _pickImage(ImageSource.gallery);
    if (action == 'video') return _pickVideo();
    if (action == 'document') return _pickFile(allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf']);
    if (action == 'voice') return _recordVoice();
    if (action == 'location') return _shareLocation();
    return _pickFile();
  }

  Future<void> _recordVoice() async {
    if (!await recorder.hasPermission()) {
      _snack('Microphone permission is required to record a voice message.');
      return;
    }
    if (!mounted) return;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _VoiceRecorderSheet(recorder: recorder),
    );
    if (accepted != true) return;
    final path = await recorder.stop();
    if (path == null || path.isEmpty) return;
    final file = XFile(path);
    final bytes = await file.readAsBytes();
    await _uploadAndSend(file.name, 'audio/mp4', bytes, 'voice');
  }

  Future<void> _shareLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _snack('Location permission was not granted. You can enable it later in system settings.');
      return;
    }
    if (!mounted) return;
    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Wrap(children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 8), child: Text('Share location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Current location once'), subtitle: const Text('Sends one location point'), onTap: () => Navigator.pop(context, 'single')),
        ListTile(leading: const Icon(Icons.timer_outlined), title: const Text('Share for 15 minutes'), subtitle: const Text('Creates a consent-based temporary sharing session'), onTap: () => Navigator.pop(context, '15')),
        ListTile(leading: const Icon(Icons.schedule_outlined), title: const Text('Share for 1 hour'), subtitle: const Text('You can stop sharing at any time'), onTap: () => Navigator.pop(context, '60')),
      ])),
    );
    if (mode == null) return;
    setState(() => sendingAttachment = true);
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final minutes = int.tryParse(mode);
      final share = await ref.read(locationRepositoryProvider).create(
            latitude: position.latitude,
            longitude: position.longitude,
            mode: mode == 'single' ? 'single' : 'live',
            expiresAt: minutes == null ? null : DateTime.now().add(Duration(minutes: minutes)),
          );
      await ref.read(chatRepositoryProvider).send(
            conversationId,
            'Shared a location',
            type: 'location',
            replyToId: replying?.id,
            payload: share.toMessagePayload(),
          );
      replying = null;
      await _refresh();
      _scrollBottom();
    } catch (e) {
      _snack('Could not share location: $e');
    } finally {
      if (mounted) setState(() => sendingAttachment = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await imagePicker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    await _uploadAndSend(file.name, lookupMimeType(file.name) ?? 'image/jpeg', await file.readAsBytes(), 'image');
  }

  Future<void> _pickVideo() async {
    final file = await imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _uploadAndSend(file.name, lookupMimeType(file.name) ?? 'video/mp4', await file.readAsBytes(), 'video');
  }

  Future<void> _pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(type: allowedExtensions == null ? FileType.any : FileType.custom, allowedExtensions: allowedExtensions, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return _snack('Could not read that file.');
    final mime = lookupMimeType(file.name) ?? 'application/octet-stream';
    final type = allowedExtensions != null || mime == 'application/pdf' ? 'document' : mime.startsWith('image/') ? 'image' : mime.startsWith('video/') ? 'video' : mime.startsWith('audio/') ? 'voice' : 'file';
    await _uploadAndSend(file.name, mime, file.bytes!, type);
  }

  Future<void> _uploadAndSend(String filename, String mime, Uint8List bytes, String type) async {
    if (conversationId.isEmpty) return;
    setState(() => sendingAttachment = true);
    try {
      final media = await ref.read(mediaRepositoryProvider).upload(filename: filename, mime: mime, bytes: bytes, metadata: {'source': 'chat'});
      await ref.read(chatRepositoryProvider).send(
            conversationId,
            filename,
            type: type,
            replyToId: replying?.id,
            payload: {'media_id': media.id, 'filename': filename, 'mime': mime, 'size': bytes.length},
          );
      replying = null;
      await _refresh();
      _scrollBottom();
    } catch (e) {
      _snack('Upload or send failed: $e');
    } finally {
      if (mounted) setState(() => sendingAttachment = false);
    }
  }

  Future<void> _startCall(String type) async {
    try {
      final call = await ref.read(advancedRepositoryProvider).startCall(type);
      final id = '${call['id'] ?? ''}';
      if (id.isEmpty) throw StateError('Call id missing.');
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => CallSessionScreen(callId: id, type: type)));
    } catch (e) {
      _snack('Could not start call: $e');
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _time(DateTime? d) {
    if (d == null) return '';
    final x = d.toLocal();
    return '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
  }
}


class _VoiceRecorderSheet extends StatefulWidget {
  const _VoiceRecorderSheet({required this.recorder});
  final AudioRecorder recorder;

  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> {
  Timer? timer;
  Duration elapsed = Duration.zero;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await widget.recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: path);
    if (!mounted) return;
    setState(() => recording = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> cancel() async {
    timer?.cancel();
    await widget.recorder.cancel();
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> send() async {
    if (!recording || elapsed.inSeconds < 1) return;
    timer?.cancel();
    // The parent performs stop(), reads the produced file and uploads it.
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get time => '${elapsed.inMinutes.toString().padLeft(2, '0')}:${elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Voice message', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
              child: const Icon(Icons.mic_rounded, size: 42, color: AppColors.rose),
            ),
            const SizedBox(height: 12),
            Text(time, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            const Text('Recording… speak naturally ♡', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: cancel, icon: const Icon(Icons.delete_outline), label: const Text('Discard'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: elapsed.inSeconds < 1 ? null : send, icon: const Icon(Icons.send_rounded), label: const Text('Send'))),
            ]),
          ]),
        ),
      );
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
