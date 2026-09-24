import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});
  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  Map<String, dynamic> now = {}, music = {}, profile = {};
  List<Map<String, dynamic>> playlists = [];
  bool loading = true, saving = false;
  final fields = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    tabs.dispose();
    for (final c in fields.values) c.dispose();
    super.dispose();
  }

  TextEditingController _c(String key, [String fallback = '']) =>
      fields.putIfAbsent(key, () => TextEditingController(text: fallback));

  Future<void> _load() async {
    setState(() => loading = true);
    final r = ref.read(advancedRepositoryProvider);
    try {
      profile = await ref.read(usRepositoryProvider).coupleProfile();
      try { music = await r.coupleMusic(); } catch (_) { music = {}; }
      try { now = await r.spotifyNowPlaying(); } catch (_) { now = {}; }
      try { playlists = await r.spotifyPlaylists(); } catch (_) { playlists = []; }
      final m = music['data'] is Map ? (music['data'] as Map).cast<String, dynamic>() : music;
      final p = profile['profile'] is Map ? (profile['profile'] as Map).cast<String, dynamic>() : profile;
      _set('our_song', '${m['our_song'] ?? ''}');
      _set('first_song', '${m['first_song'] ?? ''}');
      _set('current_song', '${m['current_song'] ?? ''}');
      _set('wedding_song', '${m['wedding_song'] ?? ''}');
      _set('favorite_playlist', '${m['favorite_playlist'] ?? ''}');
      _set('couple_name', '${p['couple_name'] ?? p['name'] ?? ''}');
      _set('nickname', '${p['relationship_nickname'] ?? ''}');
      _set('quote', '${p['relationship_quote'] ?? ''}');
      _set('cover_media_id', '${p['cover_media_id'] ?? ''}');
      _set('avatar_media_id', '${p['avatar_media_id'] ?? ''}');
      _set('chat_wallpaper_media_id', '${p['chat_wallpaper_media_id'] ?? ''}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _set(String key, String value) {
    final c = _c(key);
    if (c.text != value) c.text = value;
  }

  Future<void> _saveMusic() async {
    setState(() => saving = true);
    try {
      await ref.read(advancedRepositoryProvider).updateCoupleMusic({
        'our_song': _c('our_song').text.trim(),
        'first_song': _c('first_song').text.trim(),
        'current_song': _c('current_song').text.trim(),
        'wedding_song': _c('wedding_song').text.trim(),
        'favorite_playlist': _c('favorite_playlist').text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Our music identity saved.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => saving = true);
    try {
      await ref.read(advancedRepositoryProvider).updateCoupleProfile({
        'couple_name': _c('couple_name').text.trim(),
        'relationship_nickname': _c('nickname').text.trim(),
        'relationship_quote': _c('quote').text.trim(),
        'cover_media_id': _c('cover_media_id').text.trim(),
        'avatar_media_id': _c('avatar_media_id').text.trim(),
        'chat_wallpaper_media_id': _c('chat_wallpaper_media_id').text.trim(),
        'theme': selectedTheme,
        'gradient': selectedGradient,
        'icon_style': selectedIcon,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couple-space style saved.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String selectedTheme = 'soft_journal';
  String selectedGradient = 'rose_peach';
  String selectedIcon = 'heart';

  Future<void> _connectSpotify() async {
    try {
      final result = await ref.read(advancedRepositoryProvider).spotifyConnect();
      final map = result is Map ? result.cast<String, dynamic>() : <String, dynamic>{};
      final url = map['authorize_url']?.toString();
      if (url == null || url.isEmpty) throw StateError('Spotify authorization URL was not returned.');
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) throw StateError('Could not open Spotify authorization.');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish authorization in Spotify, then return here and refresh.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _disconnect() async {
    try {
      await ref.read(advancedRepositoryProvider).disconnectSpotify();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spotify disconnected.')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: const Text('Our Music & Style'),
          bottom: TabBar(controller: tabs, tabs: const [Tab(text: 'Music'), Tab(text: 'Our Space')]),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: tabs, children: [_musicTab(c), _styleTab(c)]),
      );

  Widget _musicTab(BuildContext c) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(26)),
            child: Column(children: [
              const Icon(Icons.music_note_rounded, color: AppColors.rose, size: 34),
              const SizedBox(height: 10),
              Text('${_nested(now, 'item', 'name') ?? now['track_name'] ?? now['name'] ?? 'Nothing playing right now'}', style: Theme.of(c).textTheme.titleLarge, textAlign: TextAlign.center),
              Text('${now['artist_name'] ?? now['artist'] ?? 'Your shared soundtrack'}', style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: _connectSpotify, icon: const Icon(Icons.link), label: const Text('Connect Spotify'))),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: _disconnect, tooltip: 'Disconnect Spotify', icon: const Icon(Icons.link_off)),
          ]),
          const SizedBox(height: 20),
          Text('Our music identity', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 8),
          _field('Our Song', 'our_song', Icons.favorite_rounded),
          _field('First song', 'first_song', Icons.first_page_rounded),
          _field('Current song', 'current_song', Icons.graphic_eq_rounded),
          _field('Wedding song', 'wedding_song', Icons.celebration_outlined),
          _field('Favorite shared playlist', 'favorite_playlist', Icons.queue_music_rounded),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: saving ? null : _saveMusic, icon: const Icon(Icons.save_outlined), label: const Text('Save our music')),
          const SizedBox(height: 24),
          Text('Spotify playlists', style: Theme.of(c).textTheme.titleLarge),
          if (playlists.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Connect Spotify to browse private/collaborative playlists.', style: TextStyle(color: AppColors.muted))),
          ...playlists.map((p) => Card(child: ListTile(leading: const Icon(Icons.album, color: AppColors.rose), title: Text('${p['name'] ?? 'Playlist'}'), subtitle: Text('${_nested(p, 'tracks', 'total') ?? p['tracks_total'] ?? p['track_count'] ?? ''} tracks')))),
        ]),
      );

  Widget _styleTab(BuildContext c) => ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: _gradient(selectedGradient), borderRadius: BorderRadius.circular(28)),
          child: Column(children: [
            const CircleAvatar(radius: 34, backgroundColor: Colors.white70, child: Icon(Icons.favorite_rounded, color: AppColors.rose, size: 34)),
            const SizedBox(height: 10),
            Text(_c('couple_name').text.isEmpty ? 'Our little world' : _c('couple_name').text, style: Theme.of(c).textTheme.titleLarge),
            Text(_c('quote').text.isEmpty ? 'A private digital home for two.' : _c('quote').text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 18),
        _field('Couple name', 'couple_name', Icons.favorite_border),
        _field('Relationship nickname', 'nickname', Icons.auto_awesome),
        _field('Relationship quote', 'quote', Icons.format_quote),
        const SizedBox(height: 10),
        Text('Theme', style: Theme.of(c).textTheme.titleMedium),
        Wrap(spacing: 8, children: ['soft_journal', 'midnight_rose', 'warm_cream'].map((e) => ChoiceChip(label: Text(e.replaceAll('_', ' ')), selected: selectedTheme == e, onSelected: (_) => setState(() => selectedTheme = e))).toList()),
        const SizedBox(height: 12),
        Text('Couple gradient', style: Theme.of(c).textTheme.titleMedium),
        Wrap(spacing: 8, children: ['rose_peach', 'lavender_blush', 'sunset'].map((e) => ChoiceChip(label: Text(e.replaceAll('_', ' ')), selected: selectedGradient == e, onSelected: (_) => setState(() => selectedGradient = e))).toList()),
        const SizedBox(height: 12),
        Text('Couple icon', style: Theme.of(c).textTheme.titleMedium),
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'heart', icon: Icon(Icons.favorite), label: Text('Heart')), ButtonSegment(value: 'spark', icon: Icon(Icons.auto_awesome), label: Text('Spark')), ButtonSegment(value: 'home', icon: Icon(Icons.home_rounded), label: Text('Home'))], selected: {selectedIcon}, onSelectionChanged: (v) => setState(() => selectedIcon = v.first)),
        const SizedBox(height: 18),
        ExpansionTile(title: const Text('Private media IDs'), subtitle: const Text('Use media IDs returned by the private upload pipeline for cover/avatar/wallpaper.'), childrenPadding: const EdgeInsets.only(bottom: 12), children: [_field('Couple cover media ID', 'cover_media_id', Icons.photo_outlined), _field('Couple avatar media ID', 'avatar_media_id', Icons.account_circle_outlined), _field('Chat wallpaper media ID', 'chat_wallpaper_media_id', Icons.wallpaper_rounded)]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: saving ? null : _saveProfile, icon: const Icon(Icons.palette_outlined), label: const Text('Apply couple-space style')),
        const SizedBox(height: 10),
        const Text('Custom styles must keep readable contrast. The Soft Journal identity remains the default and accessibility settings take precedence.', style: TextStyle(color: AppColors.muted)),
      ]);

  Widget _field(String label, String key, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: _c(key), decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))),
      );

  dynamic _nested(Map<String, dynamic> source, String parent, String key) {
    final value = source[parent];
    return value is Map ? value[key] : null;
  }

  LinearGradient _gradient(String key) => switch (key) {
        'lavender_blush' => const LinearGradient(colors: [Color(0xFFF0E8F5), Color(0xFFF8E4EB)]),
        'sunset' => const LinearGradient(colors: [Color(0xFFFFE6D8), Color(0xFFF7D1DB)]),
        _ => const LinearGradient(colors: [AppColors.blush, AppColors.peach]),
      };
}
