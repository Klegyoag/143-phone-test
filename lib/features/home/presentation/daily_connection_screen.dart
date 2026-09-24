import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';
import '../data/home_repository.dart';

class DailyConnectionScreen extends ConsumerStatefulWidget {
  const DailyConnectionScreen({super.key});

  @override
  ConsumerState<DailyConnectionScreen> createState() => _DailyConnectionScreenState();
}

class _DailyConnectionScreenState extends ConsumerState<DailyConnectionScreen> {
  late Future<HomeBundle> today;
  bool revealLoading = false;
  List<dynamic>? revealed;

  @override
  void initState() {
    super.initState();
    today = ref.read(homeRepositoryProvider).load();
  }

  void reload() => setState(() {
        revealed = null;
        today = ref.read(homeRepositoryProvider).load();
      });

  Future<void> answer(String questionId) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your private answer ♡'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write what you really want to share…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save privately')),
        ],
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    await ref.read(homeRepositoryProvider).answerDaily(questionId, controller.text.trim());
    if (mounted) reload();
  }

  Future<void> reveal(String questionId) async {
    setState(() => revealLoading = true);
    try {
      revealed = await ref.read(homeRepositoryProvider).revealDaily(questionId);
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => revealLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Today for Us')),
        body: FutureBuilder<HomeBundle>(
          future: today,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: FilledButton.tonal(onPressed: reload, child: const Text('Try again')));
            }
            final daily = snapshot.data!.daily;
            final q = (daily['question'] as Map?)?.cast<String, dynamic>();
            final myAnswer = (daily['my_answer'] as Map?)?.cast<String, dynamic>();
            final activities = daily['activities'] is List ? daily['activities'] as List : const [];
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('One little moment for the two of you ♡', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      SizedBox(height: 7),
                      Text('Answers stay private until both partners have responded.', style: TextStyle(color: AppColors.muted)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (q == null)
                    const JournalCard(child: Text('Today’s question is still being prepared.'))
                  else
                    JournalCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('DAILY QUESTION', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: AppColors.rose, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text('${q['body'] ?? q['title'] ?? 'A question for you both'}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 14),
                        if (myAnswer != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.blush.withValues(alpha: .55), borderRadius: BorderRadius.circular(16)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Your answer', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text('${myAnswer['body'] ?? ''}'),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: revealLoading ? null : () => reveal('${q['id']}'),
                              icon: revealLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
                              label: const Text('Reveal our answers'),
                            ),
                          ),
                        ] else
                          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => answer('${q['id']}'), child: const Text('Answer privately'))),
                      ]),
                    ),
                  if (revealed != null) ...[
                    const SizedBox(height: 16),
                    _RevealCard(answers: revealed!),
                  ],
                  if (activities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Little things for today', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    ...activities.whereType<Map>().map((raw) {
                      final a = raw.cast<String, dynamic>();
                      final completed = '${a['status'] ?? ''}' == 'completed';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: JournalCard(
                          child: Row(children: [
                            CircleAvatar(backgroundColor: AppColors.blush, child: Icon(completed ? Icons.check_rounded : Icons.favorite_border, color: AppColors.rose)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${a['title'] ?? a['body'] ?? 'Daily connection'}', style: const TextStyle(fontWeight: FontWeight.w700)), if (a['body'] != null && a['title'] != null) Text('${a['body']}', style: const TextStyle(color: AppColors.muted))])),
                            if (!completed) TextButton(onPressed: () async { await ref.read(homeRepositoryProvider).completeDailyActivity('${a['id']}'); reload(); }, child: const Text('Done')),
                          ]),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyArchiveScreen(showAnswers: false))), icon: const Icon(Icons.history_rounded), label: const Text('Question history'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyArchiveScreen(showAnswers: true))), icon: const Icon(Icons.book_outlined), label: const Text('Answer archive'))),
                  ]),
                ],
              ),
            );
          },
        ),
      );
}

class _RevealCard extends StatefulWidget {
  const _RevealCard({required this.answers});
  final List<dynamic> answers;
  @override
  State<_RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<_RevealCard> with SingleTickerProviderStateMixin {
  late final AnimationController c;
  @override
  void initState() { super.initState(); c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward(); }
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: c, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: .96, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
          child: JournalCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: Icon(Icons.favorite_rounded, color: AppColors.rose, size: 38)),
              const Center(child: Text('Both of you answered ♡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              const SizedBox(height: 14),
              ...widget.answers.asMap().entries.map((entry) {
                final map = entry.value is Map ? (entry.value as Map).cast<String, dynamic>() : const <String, dynamic>{};
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: entry.key.isEven ? AppColors.blush : AppColors.peach, borderRadius: BorderRadius.circular(16)),
                  child: Text('${map['body'] ?? map['answer'] ?? ''}'),
                );
              }),
            ]),
          ),
        ),
      );
}

class DailyArchiveScreen extends ConsumerWidget {
  const DailyArchiveScreen({super.key, required this.showAnswers});
  final bool showAnswers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = showAnswers ? ref.read(homeRepositoryProvider).dailyAnswerArchive() : ref.read(homeRepositoryProvider).dailyQuestionHistory();
    return Scaffold(
      appBar: AppBar(title: Text(showAnswers ? 'Daily Answer Archive' : 'Daily Question History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return const Center(child: Text('Nothing here yet. Your daily history will grow gently over time.'));
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = rows[i];
              return JournalCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r['title'] ?? r['body'] ?? r['type'] ?? 'Daily connection'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (showAnswers && r['body'] != null) ...[const SizedBox(height: 6), Text('${r['body']}')],
                const SizedBox(height: 5),
                Text('${r['scheduled_at'] ?? r['created_at'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]));
            },
          );
        },
      ),
    );
  }
}
