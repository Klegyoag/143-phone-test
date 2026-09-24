import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> catalog = const [];
  List<Map<String, dynamic>> unlocked = const [];
  Map<String, dynamic> progress = const {};

  static const _healthyDescriptions = <String, String>{
    'first-memory': 'Save your first shared memory together.',
    '100-pings': 'Reach 100 little pings of connection over time.',
    '30-day-streak': 'Celebrate a 30-day connection streak without pressure.',
    '100-memories': 'Build a collection of 100 meaningful memories.',
    'game-night': 'Complete a couple game together.',
    'first-trip': 'Celebrate your first shared trip milestone.',
    '50-love-notes': 'Share 50 love notes over your relationship journey.',
    'anniversary': 'Mark an anniversary together.',
    'shared-goal': 'Complete a shared goal as a team.',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final repo = ref.read(usRepositoryProvider);
      final values = await Future.wait([repo.achievements(), repo.achievementProgress()]);
      final data = values[0];
      if (!mounted) return;
      setState(() {
        catalog = (data['catalog'] is List ? data['catalog'] as List : const []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        unlocked = (data['unlocked'] is List ? data['unlocked'] as List : const []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        progress = values[1];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load achievements: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _key(Map<String, dynamic> row) {
    final data = row['data'];
    if (data is Map && data['key'] != null) return '${data['key']}';
    return '${row['type'] ?? row['key'] ?? ''}';
  }

  Map<String, dynamic>? _unlockFor(Map<String, dynamic> item) {
    final id = '${item['id'] ?? ''}';
    final key = _key(item);
    for (final row in unlocked) {
      final parent = '${row['parent_id'] ?? row['achievement_id'] ?? ''}';
      final type = '${row['type'] ?? ''}';
      final data = row['data'];
      final unlockKey = data is Map ? '${data['key'] ?? data['achievement_key'] ?? ''}' : '';
      if ((id.isNotEmpty && parent == id) || (key.isNotEmpty && (type == key || unlockKey == key))) return row;
    }
    return null;
  }

  Future<void> _showDetail(Map<String, dynamic> item) async {
    final unlock = _unlockFor(item);
    final key = _key(item);
    final title = '${item['title'] ?? item['name'] ?? 'Couple achievement'}';
    final description = '${item['body'] ?? item['description'] ?? _healthyDescriptions[key] ?? 'A healthy connection milestone for the two of you.'}';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: unlock != null ? AppColors.blushStrong : Colors.grey.shade100,
              child: Icon(unlock != null ? Icons.favorite_rounded : Icons.lock_outline_rounded, color: unlock != null ? AppColors.rose : AppColors.muted, size: 34),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.45)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.blush.withValues(alpha: .55), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(unlock != null ? Icons.celebration_outlined : Icons.favorite_border_rounded, color: AppColors.rose),
                const SizedBox(width: 12),
                Expanded(child: Text(unlock != null ? 'Unlocked together${unlock['created_at'] != null ? ' • ${unlock['created_at']}' : ''}' : 'Keep connecting naturally. There is no pressure to chase this reward.', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('143 rewards healthy connection — never time spent in the app.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = (progress['unlocked_count'] as num?)?.toInt() ?? unlocked.length;
    final total = (progress['total'] as num?)?.toInt() ?? catalog.length;
    final ratio = total <= 0 ? 0.0 : (unlockedCount / total).clamp(0.0, 1.0).toDouble();
    final history = [...unlocked]..sort((a, b) => '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}'));

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), backgroundColor: Colors.transparent),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(28)),
              child: Column(children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.rose, size: 44),
                const SizedBox(height: 8),
                Text('$unlockedCount of $total little wins together', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Achievement progress ${(ratio * 100).round()} percent',
                  child: ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: ratio, minHeight: 9, backgroundColor: Colors.white.withValues(alpha: .55))),
                ),
                const SizedBox(height: 10),
                const Text('Celebrate memories, kindness, shared goals and time together — not screen time.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Achievement collection', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            if (loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (catalog.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Achievement catalog will appear here when the backend is seeded.')))
            else
              ...catalog.map((item) {
                final unlock = _unlockFor(item);
                final key = _key(item);
                final title = '${item['title'] ?? item['name'] ?? 'Couple achievement'}';
                final body = '${item['body'] ?? item['description'] ?? _healthyDescriptions[key] ?? ''}';
                return Card(
                  child: Semantics(
                    button: true,
                    label: '$title. ${unlock != null ? 'Unlocked' : 'Locked'}',
                    child: ListTile(
                      onTap: () => _showDetail(item),
                      leading: CircleAvatar(
                        backgroundColor: unlock != null ? AppColors.blushStrong : Colors.grey.shade100,
                        child: Icon(unlock != null ? Icons.favorite_rounded : Icons.lock_outline, color: unlock != null ? AppColors.rose : AppColors.muted),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: body.isEmpty ? null : Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: unlock != null ? const Icon(Icons.check_circle_rounded, color: AppColors.rose) : const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 22),
            const Text('Unlocked history', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Your shared milestones will be remembered here ♡', style: TextStyle(color: AppColors.muted))))
            else
              ...history.take(12).map((row) {
                final parent = '${row['parent_id'] ?? ''}';
                Map<String, dynamic>? item;
                for (final candidate in catalog) {
                  if ('${candidate['id'] ?? ''}' == parent) { item = candidate; break; }
                }
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.rose),
                    title: Text('${item?['title'] ?? row['type'] ?? 'Achievement unlocked'}'),
                    subtitle: Text('${row['created_at'] ?? row['occurred_at'] ?? ''}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
