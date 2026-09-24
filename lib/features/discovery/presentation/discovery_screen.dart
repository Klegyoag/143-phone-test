import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../data/discovery_repository.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final search = TextEditingController();
  Future<Map<String, List<Map<String, dynamic>>>>? searchFuture;
  String resultFilter = 'all';
  bool newestFirst = true;
  late Future<List<Map<String, dynamic>>> favoritesFuture;
  late Future<List<Map<String, dynamic>>> activityFuture;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    favoritesFuture = ref.read(discoveryRepositoryProvider).favorites();
    activityFuture = ref.read(discoveryRepositoryProvider).activity();
  }

  @override
  void dispose() {
    tabs.dispose();
    search.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = search.text.trim();
    if (q.length < 2) {
      setState(() => searchFuture = null);
      return;
    }
    setState(() => searchFuture = ref.read(discoveryRepositoryProvider).search(q));
  }

  void _reloadFavorites() => setState(() => favoritesFuture = ref.read(discoveryRepositoryProvider).favorites(allowCache: false));
  void _reloadActivity() => setState(() => activityFuture = ref.read(discoveryRepositoryProvider).activity(allowCache: false));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find in our world'),
        bottom: TabBar(
          controller: tabs,
          tabs: const [Tab(text: 'Search'), Tab(text: 'Favorites'), Tab(text: 'Activity')],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          _searchTab(),
          _favoritesTab(),
          _activityTab(),
        ],
      ),
    );
  }

  Widget _searchTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _runSearch(),
          decoration: InputDecoration(
            hintText: 'Search memories and messages…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(onPressed: _runSearch, icon: const Icon(Icons.arrow_forward_rounded)),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'all', label: Text('All')), ButtonSegment(value: 'memories', label: Text('Memories')), ButtonSegment(value: 'messages', label: Text('Messages'))], selected: {resultFilter}, onSelectionChanged: (v) => setState(() => resultFilter = v.first))),
          const SizedBox(width: 8),
          IconButton(tooltip: newestFirst ? 'Newest first' : 'Oldest first', onPressed: () => setState(() => newestFirst = !newestFirst), icon: Icon(newestFirst ? Icons.south_rounded : Icons.north_rounded)),
        ]),
      ),
      Expanded(
        child: searchFuture == null
            ? const AppEmptyState(icon: Icons.auto_stories_outlined, title: 'Find a little moment', message: 'Type at least two characters to search your shared memories and messages.')
            : FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                future: searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const AppLoadingState(label: 'Looking through your shared world…');
                  if (snapshot.hasError) return AppErrorState(message: '${snapshot.error}', onRetry: _runSearch);
                  final data = snapshot.data ?? const {'memories': <Map<String, dynamic>>[], 'messages': <Map<String, dynamic>>[]};
                  var memories = List<Map<String, dynamic>>.from(data['memories'] ?? const []);
                  var messages = List<Map<String, dynamic>>.from(data['messages'] ?? const []);
                  int cmp(Map<String, dynamic> a, Map<String, dynamic> b) => '${a['created_at'] ?? ''}'.compareTo('${b['created_at'] ?? ''}');
                  memories.sort((a,b) => newestFirst ? -cmp(a,b) : cmp(a,b));
                  messages.sort((a,b) => newestFirst ? -cmp(a,b) : cmp(a,b));
                  if (resultFilter == 'memories') messages = [];
                  if (resultFilter == 'messages') memories = [];
                  if (memories.isEmpty && messages.isEmpty) return const AppEmptyState(icon: Icons.search_off_rounded, title: 'Nothing found', message: 'Try another word or phrase.');
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      if (memories.isNotEmpty) ...[
                        const _Section('Memories'),
                        ...memories.map((m) => _SearchResultCard(
                              icon: Icons.photo_library_outlined,
                              title: '${m['title'] ?? 'Memory'}',
                              subtitle: '${m['type'] ?? 'memory'}',
                              onFavorite: '${m['id'] ?? ''}'.isEmpty ? null : () => _favorite('memory', m),
                            )),
                      ],
                      if (messages.isNotEmpty) ...[
                        const _Section('Messages'),
                        ...messages.map((m) => _SearchResultCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: '${m['body'] ?? 'Message'}',
                              subtitle: 'Shared message',
                              onFavorite: '${m['id'] ?? ''}'.isEmpty ? null : () => _favorite('message', m),
                            )),
                      ],
                    ],
                  );
                },
              ),
      ),
    ]);
  }

  Widget _favoritesTab() => RefreshIndicator(
        onRefresh: () async => _reloadFavorites(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const AppLoadingState(label: 'Opening your favorites…');
            if (snapshot.hasError) return AppErrorState(message: '${snapshot.error}', onRetry: _reloadFavorites);
            final items = snapshot.data ?? [];
            if (items.isEmpty) return const AppEmptyState(icon: Icons.favorite_border_rounded, title: 'No favorites yet', message: 'Save a memory or message from Search and it will stay close here.');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                final metadata = item['metadata'] is Map ? (item['metadata'] as Map).cast<String, dynamic>() : <String, dynamic>{};
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.blushStrong, child: Icon(Icons.favorite_rounded, color: AppColors.rose)),
                    title: Text('${metadata['title'] ?? metadata['preview'] ?? item['favoritable_type'] ?? 'Favorite'}'),
                    subtitle: Text('${item['favoritable_type'] ?? ''}'.replaceAll('_', ' ')),
                    trailing: IconButton(
                      tooltip: 'Remove favorite',
                      onPressed: () async {
                        await ref.read(discoveryRepositoryProvider).removeFavorite('${item['id']}');
                        _reloadFavorites();
                      },
                      icon: const Icon(Icons.favorite_rounded, color: AppColors.rose),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  Widget _activityTab() => RefreshIndicator(
        onRefresh: () async => _reloadActivity(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const AppLoadingState(label: 'Gathering recent activity…');
            if (snapshot.hasError) return AppErrorState(message: '${snapshot.error}', onRetry: _reloadActivity);
            final items = snapshot.data ?? [];
            if (items.isEmpty) return const AppEmptyState(icon: Icons.history_rounded, title: 'No recent activity', message: 'Shared actions will appear here when the backend records them.');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                final action = '${item['action'] ?? item['event'] ?? item['type'] ?? 'Activity'}';
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.blushStrong, child: Icon(Icons.history_rounded, color: AppColors.rose)),
                    title: Text(action.replaceAll('_', ' ')),
                    subtitle: Text('${item['created_at'] ?? item['occurred_at'] ?? ''}'),
                  ),
                );
              },
            );
          },
        ),
      );

  Future<void> _favorite(String type, Map<String, dynamic> item) async {
    try {
      await ref.read(discoveryRepositoryProvider).addFavorite(
        type: type,
        id: '${item['id']}',
        metadata: {
          'title': '${item['title'] ?? ''}',
          'preview': '${item['body'] ?? item['title'] ?? type}',
        },
      );
      _reloadFavorites();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to favorites ♡')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.wine)),
      );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.icon, required this.title, required this.subtitle, this.onFavorite});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onFavorite;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.blushStrong, child: Icon(icon, color: AppColors.rose)),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle),
          trailing: onFavorite == null ? null : IconButton(onPressed: onFavorite, icon: const Icon(Icons.favorite_border_rounded)),
        ),
      );
}
