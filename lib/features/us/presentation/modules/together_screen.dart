import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../app/providers.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_events.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../calls/presentation/call_session_screen.dart';

class TogetherScreen extends ConsumerStatefulWidget {
  const TogetherScreen({super.key});

  @override
  ConsumerState<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends ConsumerState<TogetherScreen> {
  Map<String, dynamic> room = {};
  Map<String, dynamic> state = {};
  List<Map<String, dynamic>> queue = [];
  bool loading = true;
  bool savingState = false;
  bool applyingRemoteState = false;
  String createProvider = 'youtube';
  final url = TextEditingController();
  final title = TextEditingController();
  StreamSubscription<RealtimeEvent>? sub;
  YoutubePlayerController? youtube;
  String? youtubeVideoId;
  Timer? progressPublisher;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sub = ref.read(realtimeCoordinatorProvider).events.listen((event) {
        if ({
          RealtimeEvents.togetherStateUpdated,
          RealtimeEvents.togetherQueueUpdated,
          RealtimeEvents.togetherMemberJoined,
          RealtimeEvents.togetherMemberLeft,
          RealtimeEvents.togetherResyncRequested,
        }.contains(event.name)) {
          if (event.name == RealtimeEvents.togetherMemberJoined || event.name == RealtimeEvents.togetherMemberLeft) {
            final person = '${event.payload['display_name'] ?? event.payload['username'] ?? 'Your person'}';
            final joined = event.name == RealtimeEvents.togetherMemberJoined;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(joined ? '$person joined the room ♡' : '$person left the room')));
            }
          }
          _load(silent: true);
        }
      });
    });
    progressPublisher = Timer.periodic(const Duration(seconds: 5), (_) => _publishLivePosition());
  }

  @override
  void dispose() {
    sub?.cancel();
    progressPublisher?.cancel();
    youtube?.dispose();
    url.dispose();
    title.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);
    final repo = ref.read(advancedRepositoryProvider);
    try {
      room = await repo.currentTogetherRoom();
      if (room.isNotEmpty) {
        final id = '${room['id'] ?? ''}';
        if (id.isNotEmpty) {
          final values = await Future.wait([repo.roomState(id), repo.roomQueue(id)]);
          final rawState = values[0] as Map<String, dynamic>;
          state = rawState['data'] is Map ? (rawState['data'] as Map).cast<String, dynamic>() : rawState;
          queue = values[1] as List<Map<String, dynamic>>;
          _syncProviderFromState();
        }
      } else {
        state = {};
        queue = [];
        _disposeYoutube();
      }
    } catch (_) {
      if (room.isEmpty) {
        state = {};
        queue = [];
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> get _playback => state['playback'] is Map ? (state['playback'] as Map).cast<String, dynamic>() : <String, dynamic>{};
  String get _provider => '${state['provider'] ?? room['provider'] ?? _currentQueueItem?['provider'] ?? ''}'.toLowerCase();
  Map<String, dynamic>? get _currentQueueItem {
    final activeId = '${state['queue_item_id'] ?? state['current_queue_item_id'] ?? ''}';
    if (activeId.isNotEmpty) {
      for (final item in queue) {
        if ('${item['id'] ?? ''}' == activeId) return item;
      }
    }
    return queue.isEmpty ? null : queue.first;
  }

  String get _mediaSource {
    final item = _currentQueueItem;
    return '${state['media_id'] ?? state['url'] ?? item?['media_id'] ?? item?['url'] ?? (item?['metadata'] is Map ? (item!['metadata'] as Map)['source_url'] : '') ?? ''}';
  }

  bool get _isPlaying => _playback['state'] == 'playing' || state['is_playing'] == true || state['playing'] == true;
  double get _serverPosition => double.tryParse('${_playback['position'] ?? state['position_seconds'] ?? state['position'] ?? 0}') ?? 0;

  void _syncProviderFromState() {
    if (_provider != 'youtube') return;
    final source = _mediaSource;
    final videoId = YoutubePlayer.convertUrlToId(source) ?? (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(source) ? source : null);
    if (videoId == null) return;
    if (youtube == null || youtubeVideoId != videoId) {
      youtube?.dispose();
      youtubeVideoId = videoId;
      youtube = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(autoPlay: false, startAt: _serverPosition.round(), enableCaption: true),
      );
      youtube!.addListener(_youtubeListener);
    } else {
      final local = youtube!.value.position.inMilliseconds / 1000.0;
      if ((local - _serverPosition).abs() > 2.5 && !applyingRemoteState) {
        applyingRemoteState = true;
        youtube!.seekTo(Duration(milliseconds: (_serverPosition * 1000).round()));
        if (_isPlaying && !youtube!.value.isPlaying) youtube!.play();
        if (!_isPlaying && youtube!.value.isPlaying) youtube!.pause();
        applyingRemoteState = false;
      }
    }
  }

  void _youtubeListener() {
    if (!mounted || applyingRemoteState || youtube == null) return;
    setState(() {});
  }

  void _disposeYoutube() {
    youtube?.dispose();
    youtube = null;
    youtubeVideoId = null;
  }

  @override
  Widget build(BuildContext context) {
    final roomId = '${room['id'] ?? ''}';
    final duration = youtube?.metadata.duration.inSeconds.toDouble() ?? double.tryParse('${_playback['duration'] ?? state['duration_seconds'] ?? state['duration'] ?? 0}') ?? 0;
    final localPosition = youtube?.value.position.inMilliseconds.toDouble() != null ? (youtube!.value.position.inMilliseconds / 1000.0) : _serverPosition;
    final sliderMax = duration > 0 ? duration : 1;
    final members = room['members'] is List ? (room['members'] as List).whereType<Map>().toList() : <Map>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('togetherRoom')),
        actions: [
          if (roomId.isNotEmpty)
            IconButton(tooltip: context.l10n.t('refreshResync'), onPressed: () async { await ref.read(advancedRepositoryProvider).resyncRoom(roomId); await _load(); }, icon: const Icon(Icons.sync_rounded)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(28)),
                    child: Column(children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 34),
                      const SizedBox(height: 8),
                      Text(room.isEmpty ? context.l10n.t('startTogether') : context.l10n.t('youreTogether'), style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(room.isEmpty ? 'Watch or listen in sync, even from far away.' : 'Live shared state • ${_provider.isEmpty ? 'media' : _provider}', textAlign: TextAlign.center),
                      if (members.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: members.map((m) => Chip(avatar: const Icon(Icons.circle, size: 10, color: Colors.green), label: Text('${m['display_name'] ?? m['username'] ?? 'Partner'}'))).toList()),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (room.isEmpty) _createRoomCard() else ...[
                    if (_provider == 'youtube' && youtube != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: YoutubePlayer(
                          controller: youtube!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: AppColors.rose,
                          onReady: () => _syncProviderFromState(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else if (_provider == 'spotify')
                      _spotifyProviderCard()
                    else if (_mediaSource.isNotEmpty)
                      Card(child: ListTile(leading: const Icon(Icons.play_circle_outline_rounded, color: AppColors.rose), title: Text('${state['title'] ?? _currentQueueItem?['title'] ?? 'Shared media'}'), subtitle: Text('Provider playback for “$_provider” is isolated behind an integration boundary. Shared queue/state still remains synchronized.'))),
                    _nowPlayingCard(localPosition, duration, sliderMax),
                    const SizedBox(height: 14),
                    _queueComposer(),
                    const SizedBox(height: 22),
                    Row(children: [Expanded(child: Text(context.l10n.t('sharedQueue'), style: Theme.of(context).textTheme.titleLarge)), Text('${queue.length} item${queue.length == 1 ? '' : 's'}')]),
                    const SizedBox(height: 8),
                    if (queue.isEmpty)
                      Card(child: ListTile(leading: const Icon(Icons.queue_music_outlined), title: Text(context.l10n.t('queueEmpty')), subtitle: const Text('Add something you both want to watch or listen to.')))
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: queue.length,
                        onReorder: _reorder,
                        itemBuilder: (context, index) {
                          final item = queue[index];
                          final id = '${item['id'] ?? ''}';
                          final selected = id.isNotEmpty && id == '${state['queue_item_id'] ?? state['current_queue_item_id'] ?? ''}';
                          return Card(
                            key: ValueKey(id.isEmpty ? 'queue-$index' : id),
                            color: selected ? AppColors.blush : null,
                            child: ListTile(
                              leading: Icon(Icons.drag_handle_rounded, color: selected ? AppColors.rose : AppColors.muted),
                              title: Text('${item['title'] ?? item['media_id'] ?? item['url'] ?? 'Shared media'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${item['provider'] ?? item['type'] ?? 'media'}${selected ? ' · Now playing' : ''}'),
                              onTap: () => _selectQueueItem(item),
                              trailing: IconButton(tooltip: 'Remove', icon: const Icon(Icons.close_rounded), onPressed: () => _removeQueue(id)),
                            ),
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 26),
                  Text('Call each other', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('Microphone/camera capture uses WebRTC and the current Laravel backend now provides authenticated SDP/ICE signaling for private couple calls. Physical two-device interoperability still requires final device QA.'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => _call('audio'), icon: const Icon(Icons.call), label: const Text('Audio'))),
                    const SizedBox(width: 12),
                    Expanded(child: FilledButton.icon(onPressed: () => _call('video'), icon: const Icon(Icons.videocam), label: const Text('Video'))),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _createRoomCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Choose your room', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'youtube', icon: Icon(Icons.ondemand_video), label: Text('YouTube')), ButtonSegment(value: 'spotify', icon: Icon(Icons.music_note), label: Text('Spotify'))],
              selected: {createProvider},
              onSelectionChanged: (v) => setState(() => createProvider = v.first),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: _create, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Create Together Room')),
          ]),
        ),
      );

  Widget _spotifyProviderCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.music_note_rounded, color: AppColors.rose), SizedBox(width: 8), Text('Spotify Together', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
            const SizedBox(height: 8),
            Text('${state['title'] ?? _currentQueueItem?['title'] ?? 'Shared track'}'),
            const SizedBox(height: 8),
            const Text('143 synchronizes queue and playback intent. Direct Spotify playback requires the Spotify App Remote/native provider setup on each device.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _openSpotifySource, icon: const Icon(Icons.open_in_new), label: const Text('Open in Spotify')),
          ]),
        ),
      );

  Widget _nowPlayingCard(double position, double duration, double sliderMax) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text('${state['title'] ?? _currentQueueItem?['title'] ?? state['media_title'] ?? (_mediaSource.isEmpty ? 'Choose from your queue' : _mediaSource)}', style: Theme.of(context).textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis)),
              IconButton(tooltip: _isPlaying ? 'Pause together' : 'Play together', onPressed: savingState || _mediaSource.isEmpty ? null : () => _setPlayback(!_isPlaying, position), icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: AppColors.rose, size: 38)),
            ]),
            Slider(value: position.clamp(0, sliderMax), max: sliderMax, onChanged: duration > 0 ? (_) {} : null, onChangeEnd: duration > 0 ? (v) => _seek(v) : null),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_clock(position)), Text(duration > 0 ? _clock(duration) : 'Waiting for duration')]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () async { final id='${room['id']??''}'; if(id.isNotEmpty){await ref.read(advancedRepositoryProvider).resyncRoom(id); await _load(silent:true);} }, icon: const Icon(Icons.sync), label: const Text('Resync'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: _leave, icon: const Icon(Icons.exit_to_app_rounded), label: const Text('Leave'))),
            ]),
          ]),
        ),
      );

  Widget _queueComposer() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'YouTube / Spotify / media URL', prefixIcon: Icon(Icons.link_rounded))),
            const SizedBox(height: 10),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title (optional)', prefixIcon: Icon(Icons.title_rounded))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _add, icon: const Icon(Icons.queue_music), label: const Text('Add to shared queue'))),
          ]),
        ),
      );

  Future<void> _create() async {
    room = await ref.read(advancedRepositoryProvider).createTogetherRoom(provider: createProvider);
    await _load(silent: true);
  }

  Future<void> _leave() async {
    final id = '${room['id'] ?? ''}';
    if (id.isEmpty) return;
    await ref.read(advancedRepositoryProvider).leaveTogetherRoom(id);
    _disposeYoutube();
    if (mounted) setState(() { room = {}; state = {}; queue = []; });
  }

  Future<void> _setPlayback(bool playing, double position) async {
    final id = '${room['id'] ?? ''}';
    if (id.isEmpty) return;
    if (_provider == 'youtube' && youtube != null) {
      applyingRemoteState = true;
      playing ? youtube!.play() : youtube!.pause();
      applyingRemoteState = false;
    }
    setState(() => savingState = true);
    try {
      final duration = youtube?.metadata.duration.inSeconds ?? 0;
      await ref.read(advancedRepositoryProvider).updateRoomState(id, {
        ...state,
        'provider': _provider,
        'media_id': _mediaSource,
        'playback': {'state': playing ? 'playing' : 'paused', 'position': position.round(), if (duration > 0) 'duration': duration},
      });
      state = {...state, 'playback': {..._playback, 'state': playing ? 'playing' : 'paused', 'position': position.round(), if (duration > 0) 'duration': duration}};
    } finally {
      if (mounted) setState(() => savingState = false);
    }
  }

  Future<void> _seek(double position) async {
    if (_provider == 'youtube' && youtube != null) youtube!.seekTo(Duration(milliseconds: (position * 1000).round()));
    await _setPlayback(_isPlaying, position);
  }

  Future<void> _publishLivePosition() async {
    if (!mounted || !_isPlaying || savingState || applyingRemoteState || room.isEmpty) return;
    if (_provider != 'youtube' || youtube == null) return;
    final seconds = youtube!.value.position.inSeconds.toDouble();
    if ((seconds - _serverPosition).abs() < 3) return;
    await _setPlayback(true, seconds);
  }

  Future<void> _selectQueueItem(Map<String, dynamic> item) async {
    final id = '${room['id'] ?? ''}';
    final itemId = '${item['id'] ?? ''}';
    if (id.isEmpty || itemId.isEmpty) return;
    final source = '${item['media_id'] ?? item['url'] ?? (item['metadata'] is Map ? (item['metadata'] as Map)['source_url'] : '') ?? ''}';
    final provider = '${item['provider'] ?? (source.contains('youtu') ? 'youtube' : 'media')}';
    final nextState = <String, dynamic>{
      ...state,
      'provider': provider,
      'queue_item_id': itemId,
      'media_id': source,
      'title': '${item['title'] ?? 'Shared media'}',
      'playback': {'state': 'paused', 'position': 0},
    };
    await ref.read(advancedRepositoryProvider).updateRoomState(id, nextState);
    if (mounted) setState(() => state = nextState);
    _syncProviderFromState();
  }

  Future<void> _add() async {
    final value = url.text.trim();
    final id = '${room['id'] ?? ''}';
    if (value.isEmpty || id.isEmpty) return;
    await ref.read(advancedRepositoryProvider).addQueueItem(id, value, title: title.text.trim());
    url.clear();
    title.clear();
    await _load(silent: true);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to your shared queue')));
  }

  Future<void> _removeQueue(String itemId) async {
    final id = '${room['id'] ?? ''}';
    if (id.isEmpty || itemId.isEmpty) return;
    await ref.read(advancedRepositoryProvider).removeQueueItem(id, itemId);
    if (mounted) setState(() => queue.removeWhere((e) => '${e['id'] ?? ''}' == itemId));
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = [...queue];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    setState(() => queue = updated);
    final roomId = '${room['id'] ?? ''}';
    final ids = updated.map((e) => '${e['id'] ?? ''}').where((e) => e.isNotEmpty).toList();
    if (roomId.isEmpty || ids.length != updated.length) return;
    try {
      await ref.read(advancedRepositoryProvider).reorderQueue(roomId, ids);
    } catch (e) {
      await _load(silent: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reorder: $e')));
    }
  }

  Future<void> _openSpotifySource() async {
    final source = _mediaSource;
    if (source.isEmpty) return;
    final uri = Uri.tryParse(source);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String type) async {
    try {
      final call = await ref.read(advancedRepositoryProvider).startCall(type);
      final callId = '${call['id'] ?? ''}';
      if (!mounted || callId.isEmpty) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => CallSessionScreen(callId: callId, type: type, incoming: false)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _clock(double seconds) {
    final total = seconds.round();
    final min = total ~/ 60;
    final sec = total % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
