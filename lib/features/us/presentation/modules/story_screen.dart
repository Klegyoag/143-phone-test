import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key});
  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  bool loading = true;
  List<Map<String, dynamic>> story = [], albums = [];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = ref.read(usRepositoryProvider);
      final x = await Future.wait([r.storyEvents(), r.albums()]);
      story = x[0];
      albums = x[1];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _ask(String title, String label) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(title),
        content: TextField(
            controller: c, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(x), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(x, c.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _add() async {
    if (tabs.index == 0) {
      final t = await _ask('Add to Our Story', 'Milestone title');
      if (t?.isNotEmpty == true)
        await ref.read(usRepositoryProvider).addStoryEvent(title: t!);
    } else {
      final t = await _ask('New collaborative album', 'Album title');
      if (t?.isNotEmpty == true)
        await ref.read(usRepositoryProvider).createAlbum(t!);
    }
    await _load();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: const Text('Our Story'),
          bottom: TabBar(
              controller: tabs,
              tabs: const [Tab(text: 'Timeline'), Tab(text: 'Albums')]),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: TabBarView(
                    controller: tabs, children: [_timeline(), _albums()]),
              ),
        floatingActionButton:
            FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      );

  Widget _timeline() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
        children: story.isEmpty
            ? [
                const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: Text('Your story starts here â™¡')))
              ]
            : story.asMap().entries.map((entry) {
                final i = entry.key, x = entry.value;
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.rose),
                          child: const Icon(Icons.favorite,
                              color: Colors.white, size: 11),
                        ),
                        if (i < story.length - 1)
                          Container(
                              width: 2,
                              height: 94,
                              color: AppColors.blushStrong),
                      ]),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Card(
                          child: ListTile(
                            title: Text(
                                '${x['title'] ?? x['type'] ?? 'Our moment'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            subtitle: Text(
                                '${x['body'] ?? x['occurred_at'] ?? x['created_at'] ?? ''}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  await ref
                                      .read(usRepositoryProvider)
                                      .deleteStoryEvent('${x['id']}');
                                  _load();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete'))
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]);
              }).toList(),
      );

  Widget _albums() => GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final a = albums[i];
          return InkWell(
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(album: a)));
              _load();
            },
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient(context),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    child: Center(
                      child: Icon(
                        '${a['status']}' == 'locked'
                            ? Icons.lock_rounded
                            : Icons.photo_library_outlined,
                        color: AppColors.rose,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${a['title'] ?? 'Our Album'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        Text('${a['status'] ?? 'shared'}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ]),
                ),
              ]),
            ),
          );
        },
      );
}

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({super.key, required this.album});
  final Map<String, dynamic> album;
  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final _picker = ImagePicker();
  bool loading = true, working = false;
  Map<String, dynamic> album = {};
  List<Map<String, dynamic>> photos = [];
  String sort = 'date';
  final Map<String, String?> _urls = {};

  String get albumId => '${widget.album['id']}';
  String get coverMediaId {
    final data = album['data'];
    if (data is Map && data['cover_media_id'] != null)
      return '${data['cover_media_id']}';
    return '${album['cover_media_id'] ?? ''}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      album = await ref.read(usRepositoryProvider).album(albumId);
      photos = await ref.read(usRepositoryProvider).albumPhotos(albumId);
      // Encrypted local metadata is only an offline fallback. Signed URLs are never persisted.
      if (photos.isEmpty)
        photos = await ref.read(albumLocalCacheProvider).read(albumId);
      if (photos.isNotEmpty)
        await ref.read(albumLocalCacheProvider).write(albumId, photos);
      await _resolveVisibleUrls();
      _sort();
    } catch (_) {
      album = widget.album;
      photos = await ref.read(albumLocalCacheProvider).read(albumId);
      await _resolveVisibleUrls();
      _sort();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _mediaId(Map<String, dynamic> p) =>
      '${p['media_id'] ?? (p['data'] is Map ? p['data']['media_id'] : '')}';
  bool _favorite(Map<String, dynamic> p) =>
      p['favorite'] == true ||
      (p['data'] is Map && p['data']['favorite'] == true);

  Future<void> _resolveVisibleUrls() async {
    for (final p in photos.take(24)) {
      final id = _mediaId(p);
      if (id.isEmpty || _urls.containsKey(id)) continue;
      try {
        _urls[id] = await ref.read(mediaUrlCacheProvider).resolve(id);
      } catch (_) {
        _urls[id] = null;
      }
    }
  }

  Map<String, dynamic>? _photoLocation(Map<String, dynamic> p) {
    final media = p['media'];
    if (media is! Map) return null;
    final metadata = media['metadata'];
    if (metadata is! Map) return null;
    final location = metadata['location'];
    if (location is! Map) return null;
    final lat = location['latitude'];
    final lng = location['longitude'];
    if (lat is! num || lng is! num) return null;
    return {'latitude': lat.toDouble(), 'longitude': lng.toDouble()};
  }

  Future<Map<String, dynamic>?> _optionalUploadLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      };
    } catch (_) {
      return null;
    }
  }

  void _sort() {
    if (sort == 'favorite') {
      photos.sort(
          (a, b) => (_favorite(b) ? 1 : 0).compareTo(_favorite(a) ? 1 : 0));
    } else if (sort == 'location') {
      photos.sort((a, b) {
        final al = _photoLocation(a), bl = _photoLocation(b);
        if (al == null && bl == null) {
          return '${b['created_at'] ?? ''}'
              .compareTo('${a['created_at'] ?? ''}');
        }
        if (al == null) return 1;
        if (bl == null) return -1;
        final lat =
            (al['latitude'] as double).compareTo(bl['latitude'] as double);
        if (lat != 0) return lat;
        return (al['longitude'] as double).compareTo(bl['longitude'] as double);
      });
    } else {
      photos.sort((a, b) =>
          '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}'));
    }
  }

  Future<void> _addPhotos() async {
    final selected = await _picker.pickMultiImage(imageQuality: 92);
    if (selected.isEmpty) return;
    setState(() => working = true);
    try {
      final uploadLocation = await _optionalUploadLocation();
      for (final file in selected) {
        final Uint8List bytes = await file.readAsBytes();
        final upload = await ref.read(mediaRepositoryProvider).upload(
          filename: file.name,
          mime: file.mimeType ?? 'image/jpeg',
          bytes: bytes,
          metadata: {
            'source': 'album',
            'album_id': albumId,
            if (uploadLocation != null) 'location': uploadLocation,
          },
        );
        final item = await ref
            .read(usRepositoryProvider)
            .addAlbumPhoto(albumId, upload.id);
        if (item.isNotEmpty) {
          photos.insert(0, item);
          await ref.read(albumLocalCacheProvider).write(albumId, photos);
          try {
            _urls[upload.id] =
                await ref.read(mediaUrlCacheProvider).resolve(upload.id);
          } catch (_) {}
        }
      }
      if (mounted)
        setState(() {
          _sort();
        });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add photo: $e')));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _setCover(Map<String, dynamic> p) async {
    final mediaId = _mediaId(p);
    if (mediaId.isEmpty) return;
    setState(() => working = true);
    try {
      await ref
          .read(usRepositoryProvider)
          .updateAlbum(albumId, {'cover_media_id': mediaId});
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Album cover updated.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update cover: $e')));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _editPhoto(Map<String, dynamic> p) async {
    final c = TextEditingController(text: '${p['body'] ?? p['caption'] ?? ''}');
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: c,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Photo caption')),
          SwitchListTile(
              value: _favorite(p),
              title: const Text('Favorite photo'),
              onChanged: (v) => Navigator.pop(
                  ctx, {'caption': c.text.trim(), 'favorite': v})),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, {'caption': c.text.trim(), 'favorite': _favorite(p)}),
              child: const Text('Save caption')),
        ]),
      ),
    );
    if (result == null) return;
    await ref
        .read(usRepositoryProvider)
        .updateAlbumPhoto(albumId, '${p['id']}', result);
    await _load();
  }

  Future<void> _deletePhoto(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Remove photo?'),
                    content: const Text(
                        'The photo will be removed from this album. The underlying private media is not silently deleted.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Remove'))
                    ])) ??
        false;
    if (!ok) return;
    await ref
        .read(usRepositoryProvider)
        .deleteAlbumPhoto(albumId, '${p['id']}');
    photos.removeWhere((x) => '${x['id']}' == '${p['id']}');
    await ref.read(albumLocalCacheProvider).write(albumId, photos);
    await _load();
  }

  Future<void> _slideshow([int initial = 0]) async {
    if (photos.isEmpty) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AlbumSlideshowScreen(
                photos: photos, urls: _urls, initialIndex: initial)));
  }

  Future<void> _action(Future<void> Function() f, String msg) async {
    setState(() => working = true);
    try {
      await f();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      await _load();
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Text('${album['title'] ?? widget.album['title'] ?? 'Album'}'),
          actions: [
            IconButton(
                onPressed: photos.isEmpty ? null : () => _slideshow(),
                tooltip: 'Slideshow',
                icon: const Icon(Icons.slideshow_rounded))
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            gradient: AppColors.heroGradient(context),
                            borderRadius: BorderRadius.circular(26)),
                        child: Row(children: [
                          if (coverMediaId.isNotEmpty &&
                              (_urls[coverMediaId] ?? '').isNotEmpty)
                            ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(_urls[coverMediaId]!,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.collections_outlined,
                                        size: 40,
                                        color: AppColors.rose)))
                          else
                            const Icon(Icons.collections_outlined,
                                size: 40, color: AppColors.rose),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('${photos.length} memories',
                                    style: Theme.of(c).textTheme.titleLarge),
                                Text(
                                    '${album['status'] ?? 'shared'} â€¢ private couple album',
                                    style:
                                        const TextStyle(color: AppColors.muted))
                              ])),
                        ]),
                      ),
                      if (working)
                        const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: LinearProgressIndicator()),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ActionChip(
                            avatar: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18),
                            label: const Text('Add photos'),
                            onPressed: _addPhotos),
                        ActionChip(
                            avatar: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Private lock'),
                            onPressed: () => _action(
                                () => ref
                                    .read(usRepositoryProvider)
                                    .lockAlbum(albumId),
                                'Album locked')),
                        ActionChip(
                            avatar:
                                const Icon(Icons.download_outlined, size: 18),
                            label: const Text('Export'),
                            onPressed: () => _action(
                                () => ref
                                    .read(usRepositoryProvider)
                                    .exportAlbum(albumId),
                                'Album export requested')),
                        ChoiceChip(
                            label: const Text('Newest'),
                            selected: sort == 'date',
                            onSelected: (_) => setState(() {
                                  sort = 'date';
                                  _sort();
                                })),
                        ChoiceChip(
                            label: const Text('Favorites'),
                            selected: sort == 'favorite',
                            onSelected: (_) => setState(() {
                                  sort = 'favorite';
                                  _sort();
                                })),
                        ChoiceChip(
                            label: const Text('Location'),
                            selected: sort == 'location',
                            onSelected: (_) => setState(() {
                                  sort = 'location';
                                  _sort();
                                })),
                      ]),
                      const SizedBox(height: 16),
                      if (photos.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 64),
                            child: Column(children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 52, color: AppColors.rose),
                              SizedBox(height: 12),
                              Text(
                                  'Add your first photo to this shared album.'),
                              SizedBox(height: 6),
                              Text(
                                  'Photos stay private and use short-lived media URLs.',
                                  style: TextStyle(color: AppColors.muted))
                            ]))
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10),
                          itemCount: photos.length,
                          itemBuilder: (_, i) {
                            final p = photos[i],
                                id = _mediaId(p),
                                url = _urls[id];
                            return GestureDetector(
                              onTap: () => _slideshow(i),
                              onLongPress: () => _editPhoto(p),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(fit: StackFit.expand, children: [
                                  if (url != null && url.isNotEmpty)
                                    Image.network(url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _photoFallback())
                                  else
                                    _photoFallback(),
                                  Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Row(children: [
                                        if (_favorite(p))
                                          const CircleAvatar(
                                              radius: 15,
                                              backgroundColor:
                                                  Color(0xE6FFFFFF),
                                              child: Icon(Icons.favorite,
                                                  size: 17,
                                                  color: AppColors.rose)),
                                        PopupMenuButton<String>(
                                          icon: const CircleAvatar(
                                              radius: 15,
                                              backgroundColor:
                                                  Color(0xE6FFFFFF),
                                              child: Icon(Icons.more_horiz,
                                                  size: 17)),
                                          onSelected: (v) {
                                            if (v == 'cover') _setCover(p);
                                            if (v == 'edit') _editPhoto(p);
                                            if (v == 'delete') _deletePhoto(p);
                                          },
                                          itemBuilder: (_) => [
                                            PopupMenuItem(
                                                value: 'cover',
                                                child: Row(children: [
                                                  Icon(coverMediaId == id
                                                      ? Icons
                                                          .photo_album_rounded
                                                      : Icons
                                                          .photo_album_outlined),
                                                  const SizedBox(width: 10),
                                                  Text(coverMediaId == id
                                                      ? 'Current cover'
                                                      : 'Set as album cover')
                                                ])),
                                            const PopupMenuItem(
                                                value: 'edit',
                                                child:
                                                    Text('Caption & favorite')),
                                            const PopupMenuItem(
                                                value: 'delete',
                                                child:
                                                    Text('Remove from album')),
                                          ],
                                        ),
                                      ])),
                                  if ('${p['body'] ?? ''}'.isNotEmpty)
                                    Positioned(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                        child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(7),
                                                child: Text('${p['body']}',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11))))),
                                ]),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 18),
                      const Card(
                          child: ListTile(
                              leading: Icon(Icons.cloud_done_outlined,
                                  color: AppColors.rose),
                              title: Text('Synced private album'),
                              subtitle: Text(
                                  'Album photos reload from the Laravel backend. Temporary signed media URLs are resolved only when needed and are never stored as permanent locators.'))),
                      const SizedBox(height: 10),
                      Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.blush,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Row(children: [
                            Icon(Icons.face_retouching_natural,
                                color: AppColors.rose),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    'Face grouping remains opt-in and on-device only. No face-analysis data is uploaded. A reviewed local model is still required before enabling it.'))
                          ])),
                    ]),
              ),
      );

  Widget _photoFallback() => Container(
      color: AppColors.blush,
      child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.rose, size: 42)));
}

class AlbumSlideshowScreen extends StatefulWidget {
  const AlbumSlideshowScreen(
      {super.key,
      required this.photos,
      required this.urls,
      this.initialIndex = 0});
  final List<Map<String, dynamic>> photos;
  final Map<String, String?> urls;
  final int initialIndex;
  @override
  State<AlbumSlideshowScreen> createState() => _AlbumSlideshowScreenState();
}

class _AlbumSlideshowScreenState extends State<AlbumSlideshowScreen> {
  late final PageController controller =
      PageController(initialPage: widget.initialIndex);
  late int index = widget.initialIndex;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF171012),
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text('${index + 1} / ${widget.photos.length}')),
        body: PageView.builder(
          controller: controller,
          onPageChanged: (v) => setState(() => index = v),
          itemCount: widget.photos.length,
          itemBuilder: (_, i) {
            final p = widget.photos[i];
            final data = p['data'] is Map ? p['data'] as Map : const {};
            final id = '${p['media_id'] ?? data['media_id'] ?? ''}';
            final url = widget.urls[id];
            return Column(children: [
              Expanded(
                  child: InteractiveViewer(
                      minScale: .8,
                      maxScale: 4,
                      child: Center(
                          child: url != null && url.isNotEmpty
                              ? Image.network(url, fit: BoxFit.contain)
                              : const Icon(Icons.broken_image_outlined,
                                  size: 70, color: Colors.white54)))),
              if ('${p['body'] ?? ''}'.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                    child: Text('${p['body']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16))),
            ]);
          },
        ),
      );
}
