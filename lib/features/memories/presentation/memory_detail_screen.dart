import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/memory_repository.dart';
import 'memory_create_screen.dart';
import '../../chat/presentation/widgets/audio_message_player.dart';
import '../../chat/presentation/widgets/video_message_player.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});
  final String memoryId;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _State();
}

class _State extends ConsumerState<MemoryDetailScreen> {
  late Future<MemoryItem> memory;
  late Future<List<MemoryComment>> comments;
  final comment = TextEditingController();
  TimeCapsuleStatus? lockedStatus;
  Timer? countdownTimer;
  bool revealing = false;

  @override
  void initState() {
    super.initState();
    reload();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && lockedStatus?.revealAt != null) setState(() {});
    });
  }

  void reload() {
    lockedStatus = null;
    memory = ref.read(memoryRepositoryProvider).getOne(widget.memoryId).catchError((Object error) async {
      if (error is ApiException && (error.statusCode == 423 || error.code == 'time_capsule_locked')) {
        lockedStatus = await ref.read(memoryRepositoryProvider).capsuleStatus(widget.memoryId);
        if (mounted) setState(() {});
      }
      throw error;
    });
    comments = ref.read(memoryRepositoryProvider).comments(widget.memoryId);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: FutureBuilder<MemoryItem>(
          future: memory,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && lockedStatus == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError && lockedStatus != null) return _lockedCapsule(lockedStatus!);
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(onPressed: reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
                  ]),
                ),
              );
            }
            final m = snapshot.data!;
            return _memoryBody(m);
          },
        ),
      );

  Widget _memoryBody(MemoryItem m) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(onPressed: () => ref.read(memoryRepositoryProvider).react(widget.memoryId, '❤️'), icon: const Icon(Icons.favorite_border, color: AppColors.rose), tooltip: 'React'),
            IconButton(onPressed: () => _edit(m), icon: const Icon(Icons.edit_outlined), tooltip: 'Edit'),
            IconButton(onPressed: _share, icon: const Icon(Icons.ios_share_outlined), tooltip: 'Share'),
          ]),
          Icon(_icon(m.type), size: 42, color: AppColors.rose),
          const SizedBox(height: 12),
          Text(m.title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_label(m.type), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          if (m.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: m.tags.map((tag) => Chip(label: Text('#$tag'), visualDensity: VisualDensity.compact)).toList()),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: m.type == 'letter' ? AppColors.blush : Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: AppColors.divider)),
            child: Text(m.body, style: Theme.of(context).textTheme.bodyLarge),
          ),
          if (m.attachments.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Attached to this memory', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...m.attachments.map(_attachmentCard),
          ],
          if (m.location != null) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.blush, child: Icon(Icons.location_on_outlined, color: AppColors.rose)),
                title: Text(m.location!.label ?? 'Memory location'),
                subtitle: Text('${m.location!.latitude.toStringAsFixed(5)}, ${m.location!.longitude.toStringAsFixed(5)}'),
              ),
            ),
          ],
          if (m.type == 'time_capsule') ...[
            _capsuleOpenCard(m),
          ],
          const SizedBox(height: 24),
          Text('Little notes from us', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          FutureBuilder<List<MemoryComment>>(
            future: comments,
            builder: (context, c) {
              final list = c.data ?? [];
              return Column(children: [
                if (c.connectionState == ConnectionState.waiting) const LinearProgressIndicator(minHeight: 2),
                if (list.isEmpty && c.connectionState != ConnectionState.waiting)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No notes yet. Leave the first one.', style: TextStyle(color: AppColors.muted))),
                ...list.map((x) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(backgroundColor: AppColors.blush, child: Icon(Icons.favorite_outline, color: AppColors.rose, size: 18)),
                      title: Text(x.body),
                      subtitle: Text(x.createdAt?.toLocal().toString().split('.').first ?? ''),
                    )),
                Row(children: [
                  Expanded(child: TextField(controller: comment, decoration: const InputDecoration(hintText: 'Leave a little note…'))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _addComment, icon: const Icon(Icons.send_rounded)),
                ]),
              ]);
            },
          ),
        ],
      );

  Widget _attachmentCard(MemoryAttachment a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FutureBuilder<String?>(
            future: ref.read(mediaUrlCacheProvider).resolve(a.mediaId),
            builder: (context, signed) {
              if (signed.connectionState == ConnectionState.waiting) {
                return Container(height: 120, color: AppColors.blush, child: const Center(child: CircularProgressIndicator()));
              }
              final url = signed.data;
              if (url == null || url.isEmpty) {
                return _fileTile(a, a.isVideo ? Icons.play_circle_outline_rounded : a.isAudio ? Icons.graphic_eq_rounded : a.isDocument ? Icons.description_outlined : Icons.attach_file_rounded);
              }
              if (a.isImage) {
                return Image.network(
                  url,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fileTile(a, Icons.broken_image_outlined),
                );
              }
              if (a.isVideo) {
                return ColoredBox(
                  color: Colors.black,
                  child: Padding(padding: const EdgeInsets.all(8), child: VideoMessagePlayer(url: url)),
                );
              }
              if (a.isAudio) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: AudioMessagePlayer(url: url, foreground: AppColors.rose),
                );
              }
              if (a.isDocument) {
                return _fileTile(a, Icons.description_outlined, onOpen: () => _openAttachment(url));
              }
              return _fileTile(a, Icons.attach_file_rounded, onOpen: () => _openAttachment(url));
            },
          ),
        ),
      );

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('Could not open this attachment.');
    }
  }

  Widget _fileTile(MemoryAttachment a, IconData icon, {VoidCallback? onOpen}) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(backgroundColor: AppColors.blush, child: Icon(icon, color: AppColors.rose)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.filename, maxLines: 1, overflow: TextOverflow.ellipsis), Text(a.mime, style: const TextStyle(color: AppColors.muted, fontSize: 12))])),
          if (onOpen != null) IconButton(onPressed: onOpen, tooltip: 'Open attachment', icon: const Icon(Icons.open_in_new_rounded)),
        ]),
      );

  Widget _capsuleOpenCard(MemoryItem m) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(m.isLocked ? Icons.lock_outline : Icons.lock_open, color: AppColors.rose),
          const SizedBox(width: 10),
          Expanded(child: Text(m.isLocked ? 'This Time Capsule is locked.' : m.revealAt == null ? 'This Time Capsule is open.' : 'Revealed after ${_date(m.revealAt!)}.')),
        ]),
      );

  Widget _lockedCapsule(TimeCapsuleStatus status) {
    final remaining = status.revealAt?.difference(DateTime.now());
    final due = status.revealDue;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
            child: const Icon(Icons.lock_clock_outlined, size: 54, color: AppColors.rose),
          ),
          const SizedBox(height: 24),
          Text(due ? 'It’s time ♡' : 'A little memory is waiting', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            due ? 'The reveal time has arrived. Open the Time Capsule when you’re ready.' : 'This Time Capsule stays private until ${status.revealAt == null ? 'its reveal moment' : _date(status.revealAt!)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (!due && remaining != null) ...[
            const SizedBox(height: 24),
            Text(_countdown(remaining), style: const TextStyle(fontSize: 27, color: AppColors.rose, fontWeight: FontWeight.w800, letterSpacing: .8)),
            const Text('until reveal', style: TextStyle(color: AppColors.muted)),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: due && !revealing ? _reveal : null,
            icon: revealing ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
            label: Text(revealing ? 'Opening…' : 'Reveal Time Capsule'),
          ),
        ]),
      ),
    );
  }

  Future<void> _reveal() async {
    setState(() => revealing = true);
    try {
      await ref.read(memoryRepositoryProvider).revealCapsule(widget.memoryId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 42),
          title: const Text('A memory from the past ♡'),
          content: const Text('Your Time Capsule is open now.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('See it'))],
        ),
      );
      reload();
    } catch (e) {
      _snack('Could not reveal this Time Capsule: $e');
    } finally {
      if (mounted) setState(() => revealing = false);
    }
  }

  Future<void> _edit(MemoryItem m) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => MemoryCreateScreen(existing: m)));
    if (changed == true) reload();
  }

  Future<void> _share() async {
    try {
      final data = await ref.read(memoryRepositoryProvider).share(widget.memoryId);
      final link = '${data['deep_link'] ?? ''}';
      if (link.isEmpty) throw StateError('Share link was not returned.');
      await Clipboard.setData(ClipboardData(text: link));
      _snack('Private memory link copied. Only an authenticated partner in this couple space can open it.');
    } catch (e) {
      _snack('Could not create a private share: $e');
    }
  }

  Future<void> _addComment() async {
    if (comment.text.trim().isEmpty) return;
    try {
      await ref.read(memoryRepositoryProvider).addComment(widget.memoryId, comment.text.trim());
      comment.clear();
      reload();
    } catch (e) {
      _snack('Could not add note: $e');
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _label(String t) => {'moment': 'Moment', 'letter': 'Letter', 'time_capsule': 'Time Capsule', 'love_note': 'Love Note', 'promise': 'Promise', 'milestone': 'Milestone'}[t] ?? t;
  IconData _icon(String t) => switch (t) {'letter' => Icons.mail_outline, 'time_capsule' => Icons.hourglass_bottom_rounded, 'love_note' => Icons.favorite_border, 'promise' => Icons.handshake_outlined, 'milestone' => Icons.emoji_events_outlined, _ => Icons.photo_camera_back_outlined};
}

String _date(DateTime d) {
  final x = d.toLocal();
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')} ${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
}

String _countdown(Duration d) {
  if (d.isNegative) return '00:00:00';
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  return '${days > 0 ? '${days}d ' : ''}${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
