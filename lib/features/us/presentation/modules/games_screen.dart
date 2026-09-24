import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'game_play_screen.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});
  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool loading = true;
  List<Map<String, dynamic>> games = [];
  List<Map<String, dynamic>> sessions = [];
  int xp = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final repo = ref.read(coupleLifeRepositoryProvider);
      final values = await Future.wait([repo.games(), repo.gameSessions(), repo.xp()]);
      games = values[0] as List<Map<String, dynamic>>;
      sessions = values[1] as List<Map<String, dynamic>>;
      xp = int.tryParse('${(values[2] as Map<String, dynamic>)['xp'] ?? 0}') ?? 0;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _play(Map<String, dynamic> game) async {
    final data = (game['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final key = '${data['key'] ?? game['key'] ?? game['type'] ?? game['slug'] ?? ''}';
    if (key.isEmpty) return;
    try {
      final session = await ref.read(coupleLifeRepositoryProvider).startGame(key);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => GamePlayScreen(game: {...game, 'key': key}, session: session)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Couple Games')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: loading
              ? const ListView(children: [SizedBox(height: 300), Center(child: CircularProgressIndicator())])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(28)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Play. Laugh. Learn each other. 🎲', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                        const SizedBox(height: 6),
                        const Text('Tiny games made for two — not for endless screen time.', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 14),
                        Row(children: [const Icon(Icons.auto_awesome_rounded, color: AppColors.rose), const SizedBox(width: 7), Text('$xp Couple XP', style: const TextStyle(fontWeight: FontWeight.w800))]),
                      ]),
                    ),
                    if (sessions.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: Text('${sessions.length} game session${sessions.length == 1 ? '' : 's'} in your history', style: const TextStyle(color: AppColors.muted))),
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameHistoryScreen(sessions: sessions))),
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: const Text('History'),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 18),
                    ...games.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _play(g),
                            child: Ink(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.divider)),
                              child: Row(children: [
                                Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.sports_esports_outlined, color: AppColors.rose)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${g['title'] ?? g['name'] ?? g['type'] ?? 'Couple game'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  const Text('Start a shared session, answer prompts, finish and earn Couple XP.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                ])),
                                const Icon(Icons.chevron_right),
                              ]),
                            ),
                          ),
                        )),
                  ],
                ),
        ),
      );
}

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key, required this.sessions});
  final List<Map<String, dynamic>> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordered = [...sessions]..sort((a, b) => '${b['created_at'] ?? b['completed_at'] ?? ''}'.compareTo('${a['created_at'] ?? a['completed_at'] ?? ''}'));
    return Scaffold(
      appBar: AppBar(title: const Text('Game History')),
      body: ordered.isEmpty
          ? const Center(child: Text('No game sessions yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: ordered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = ordered[index];
                final id = '${session['id'] ?? ''}';
                final title = _prettyGameKey('${session['type'] ?? session['game_key'] ?? 'couple-game'}');
                final completed = '${session['status'] ?? ''}' == 'completed';
                final when = '${session['completed_at'] ?? session['created_at'] ?? ''}';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.blush, child: Icon(completed ? Icons.check_rounded : Icons.sports_esports_outlined, color: AppColors.rose)),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${completed ? 'Completed' : 'In progress'}${when.isEmpty ? '' : ' • ${_shortDate(when)}'}'),
                    trailing: id.isEmpty ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: id.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameHistoryDetailScreen(sessionId: id, title: title, session: session))),
                  ),
                );
              },
            ),
    );
  }
}

class GameHistoryDetailScreen extends ConsumerWidget {
  const GameHistoryDetailScreen({super.key, required this.sessionId, required this.title, required this.session});
  final String sessionId, title;
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: FutureBuilder<Map<String, dynamic>>(
          future: ref.read(coupleLifeRepositoryProvider).gameResults(sessionId),
          builder: (context, snapshot) {
            final result = snapshot.data ?? const <String, dynamic>{};
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(child: ListTile(leading: const Icon(Icons.history_rounded, color: AppColors.rose), title: Text('${session['status'] ?? 'session'}'), subtitle: Text('${session['completed_at'] ?? session['created_at'] ?? ''}'))),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
                if (snapshot.hasError) const Text('Result detail is unavailable for this session right now.', style: TextStyle(color: AppColors.muted)),
                if (result.isNotEmpty) ...[
                  const Text('Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...result.entries.where((e) => !{'id', 'couple_space_id', 'user_id'}.contains(e.key)).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          tileColor: AppColors.blush.withValues(alpha: .35),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: Text(_prettyGameKey(e.key), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${e.value}'),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      );
}

String _prettyGameKey(String value) => value
    .replaceAll('-', ' ')
    .replaceAll('_', ' ')
    .split(' ')
    .where((e) => e.isNotEmpty)
    .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
    .join(' ');

String _shortDate(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}

