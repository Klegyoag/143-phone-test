import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

const _listTypes = <String, String>{
  'wishlist': 'Wishlist',
  'gift_ideas': 'Gift Ideas',
  'clothing': 'Clothing',
  'restaurants': 'Restaurants',
  'trips': 'Trips',
  'products': 'Products',
  'movies': 'Movies',
  'series': 'Series',
  'songs': 'Songs',
  'books': 'Books',
  'restaurants_to_visit': 'Restaurants to Visit',
  'destinations': 'Destinations'
};
const _statuses = ['want_to', 'planned', 'completed', 'favorite'];

class SharedListsScreen extends ConsumerStatefulWidget {
  const SharedListsScreen({super.key});
  @override
  ConsumerState<SharedListsScreen> createState() => _SharedListsScreenState();
}

class _SharedListsScreenState extends ConsumerState<SharedListsScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      ref.read(usRepositoryProvider).sharedLists();
  void reload() => setState(() => future = _load());
  Future<void> create() async {
    final name = TextEditingController();
    String type = 'wishlist';
    final ok = await showDialog<bool>(
        context: context,
        builder: (x) => StatefulBuilder(
            builder: (x, setD) => AlertDialog(
                    title: const Text('Create a shared list'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'List name')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField(
                          value: type,
                          items: _listTypes.entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setD(() => type = v!),
                          decoration:
                              const InputDecoration(labelText: 'List type'))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(x, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(x, true),
                          child: const Text('Create'))
                    ])));
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref
          .read(usRepositoryProvider)
          .createSharedList(name.text.trim(), type);
      reload();
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Our Lists'), actions: [
        IconButton(
            onPressed: create, icon: const Icon(Icons.add_circle_outline))
      ]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final items = s.data ?? [];
            return RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await future;
                },
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              color: AppColors.softSurface(c),
                              borderRadius: BorderRadius.circular(28)),
                          child: Column(children: [
                            Icon(Icons.card_giftcard_rounded,
                                color: AppColors.rose, size: 38),
                            Text('Save the things you want to share someday',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18)),
                            Text(
                                'Wishlists, movies, books, trips, restaurants and little gift ideas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.secondaryText(c)))
                          ])),
                      const SizedBox(height: 16),
                      if (items.isEmpty)
                        const Card(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'Create your first list together â™¡',
                                    textAlign: TextAlign.center)))
                      else
                        ...items.map((item) => Card(
                            child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: AppColors.blush,
                                    child: Icon(
                                        _icon('${item['type'] ?? 'wishlist'}'),
                                        color: AppColors.rose)),
                                title:
                                    Text('${item['title'] ?? 'Shared list'}'),
                                subtitle: Text(
                                    _listTypes['${item['type'] ?? 'wishlist'}'] ??
                                        'Shared list'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(c,
                                    MaterialPageRoute(builder: (_) => SharedListDetailScreen(list: item))))))
                    ]));
          }));
  IconData _icon(String t) => t.contains('movie') || t.contains('series')
      ? Icons.movie_outlined
      : t.contains('song')
          ? Icons.music_note
          : t.contains('book')
              ? Icons.menu_book_outlined
              : t.contains('restaurant')
                  ? Icons.restaurant_outlined
                  : t.contains('trip') || t.contains('destination')
                      ? Icons.flight_takeoff
                      : t.contains('clothing')
                          ? Icons.checkroom
                          : t.contains('product')
                              ? Icons.shopping_bag_outlined
                              : Icons.favorite_border;
}

class SharedListDetailScreen extends ConsumerStatefulWidget {
  const SharedListDetailScreen({super.key, required this.list});
  final Map<String, dynamic> list;
  @override
  ConsumerState<SharedListDetailScreen> createState() =>
      _SharedListDetailScreenState();
}

class _SharedListDetailScreenState
    extends ConsumerState<SharedListDetailScreen> {
  late Future<List<Map<String, dynamic>>> future;
  String get id => '${widget.list['id'] ?? ''}';
  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      ref.read(usRepositoryProvider).listItems(id);
  void reload() => setState(() => future = _load());
  Future<void> add() async {
    final title = TextEditingController();
    String status = 'want_to';
    bool secret = false;
    final ok = await showDialog<bool>(
        context: context,
        builder: (x) => StatefulBuilder(
            builder: (x, setD) => AlertDialog(
                    title: const Text('Add to the list'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: title,
                          decoration: const InputDecoration(labelText: 'Item')),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                          value: status,
                          items: _statuses
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(_pretty(s))))
                              .toList(),
                          onChanged: (v) => setD(() => status = v!),
                          decoration:
                              const InputDecoration(labelText: 'Status')),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Secret gift planning'),
                          subtitle: const Text(
                              'Backend must enforce hiding this marker from the wishlist owner.'),
                          value: secret,
                          onChanged: (v) => setD(() => secret = v))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(x, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(x, true),
                          child: const Text('Add'))
                    ])));
    if (ok == true && title.text.trim().isNotEmpty) {
      await ref.read(usRepositoryProvider).addListItem(id, title.text.trim(),
          status: status,
          type: '${widget.list['type'] ?? 'wishlist'}',
          secret: secret);
      reload();
    }
  }

  Future<void> edit(Map<String, dynamic> x) async {
    String status =
        '${x['status'] ?? (x['data'] is Map ? (x['data'] as Map)['status'] : null) ?? 'want_to'}';
    final result = await showModalBottomSheet<String>(
        context: context,
        builder: (b) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ListTile(
                  title: Text('Change status',
                      style: TextStyle(fontWeight: FontWeight.w900))),
              ..._statuses.map((s) => RadioListTile(
                  value: s,
                  groupValue: status,
                  title: Text(_pretty(s)),
                  onChanged: (v) => Navigator.pop(b, v))),
              ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove item'),
                  onTap: () => Navigator.pop(b, '__delete'))
            ])));
    if (result == null) return;
    final itemId = '${x['id'] ?? ''}';
    if (result == '__delete')
      await ref.read(usRepositoryProvider).deleteListItem(id, itemId);
    else
      await ref
          .read(usRepositoryProvider)
          .updateListItem(id, itemId, {'status': result});
    reload();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          title: Text('${widget.list['title'] ?? 'Our list'}'),
          actions: [IconButton(onPressed: add, icon: const Icon(Icons.add))]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final items = s.data ?? [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (items.isEmpty)
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nothing here yet. Add your first idea â™¡',
                            textAlign: TextAlign.center)))
              else
                ...items.map((x) {
                  final d = x['data'] is Map ? (x['data'] as Map) : const {};
                  final status = '${x['status'] ?? d['status'] ?? 'want_to'}';
                  final secret = d['secret_gift_planning'] == true;
                  return Card(
                      child: ListTile(
                          onTap: () => edit(x),
                          leading: Icon(
                              status == 'favorite'
                                  ? Icons.favorite
                                  : status == 'completed'
                                      ? Icons.check_circle
                                      : Icons.favorite_border,
                              color: AppColors.rose),
                          title: Text('${x['title'] ?? d['title'] ?? 'Item'}'),
                          subtitle: Text(
                              '${_pretty(status)}${secret ? ' â€¢ Secret gift plan' : ''}'),
                          trailing: const Icon(Icons.more_horiz)));
                })
            ]);
          }));
  String _pretty(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}
