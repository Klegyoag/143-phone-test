import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';
import '../data/memory_repository.dart';
import 'memory_create_screen.dart';
import 'memory_detail_screen.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});
  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  String type = 'all';
  late Future<List<MemoryItem>> future;
  StreamSubscription? realtimeSub;

  @override
  void initState() {
    super.initState();
    future = _load();
    realtimeSub = ref.read(realtimeCoordinatorProvider).events.listen((event) {
      if (event.name.startsWith('memory.') || event.name == 'time_capsule.revealed') reload();
    });
  }

  @override
  void dispose() { realtimeSub?.cancel(); super.dispose(); }

  Future<List<MemoryItem>> _load() => ref.read(memoryRepositoryProvider).list(type: type);
  void reload() => setState(() => future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () async {
              final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const MemoryCreateScreen()));
              if (created == true) reload();
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          children: [
            Text('All the little things worth keeping.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['all', 'moment', 'letter', 'time_capsule', 'love_note', 'promise', 'milestone']
                    .map((x) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_label(x)),
                            selected: type == x,
                            onSelected: (_) {
                              type = x;
                              reload();
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<MemoryItem>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return JournalCard(
                    child: Column(children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.rose, size: 36),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}', textAlign: TextAlign.center),
                      TextButton(onPressed: reload, child: const Text('Retry')),
                    ]),
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const JournalCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.photo_library_outlined, color: AppColors.rose),
                      title: Text('No memories here yet'),
                      subtitle: Text('Create your first moment, letter or Time Capsule.'),
                    ),
                  );
                }
                return Column(
                  children: list
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryDetailScreen(memoryId: m.id))),
                              child: _Tile(
                                memory: m,
                                onDelete: () async {
                                  await ref.read(memoryRepositoryProvider).delete(m.id);
                                  reload();
                                },
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _label(String x) => {
        'all': 'All',
        'moment': 'Moments',
        'letter': 'Letters',
        'time_capsule': 'Capsules',
        'love_note': 'Love Notes',
        'promise': 'Promises',
        'milestone': 'Milestones',
      }[x] ??
      x;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.memory, required this.onDelete});
  final MemoryItem memory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final body = '${memory.content['body'] ?? ''}';
    return JournalCard(
      color: memory.type == 'letter' ? AppColors.blush : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: AppColors.blushStrong, child: Icon(_icon(memory.type), color: AppColors.rose)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(memory.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
              ],
              const SizedBox(height: 7),
              Text(memory.createdAt?.toLocal().toString().split('.').first ?? '', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
            onSelected: (_) => onDelete(),
          ),
        ],
      ),
    );
  }

  IconData _icon(String t) => switch (t) {
        'letter' => Icons.mail_outline,
        'time_capsule' => Icons.hourglass_bottom_rounded,
        'love_note' => Icons.favorite_border,
        'promise' => Icons.handshake_outlined,
        'milestone' => Icons.emoji_events_outlined,
        _ => Icons.photo_camera_back_outlined,
      };
}
