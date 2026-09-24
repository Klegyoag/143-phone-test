import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class JourneysScreen extends ConsumerStatefulWidget {
  const JourneysScreen({super.key});
  @override
  ConsumerState<JourneysScreen> createState() => _S();
}

class _S extends ConsumerState<JourneysScreen> {
  bool loading = true;
  List<Map<String, dynamic>> catalog = [], sessions = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = ref.read(advancedRepositoryProvider);
      final x = await Future.wait([r.journeys(), r.journeySessions()]);
      catalog = x[0];
      sessions = x[1];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic>? _sessionFor(String jid) {
    for (final s in sessions) {
      if ('${s['parent_id'] ?? s['journey_id']}' == jid) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Guided Journeys')),
      body: RefreshIndicator(
          onRefresh: _load,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                  children: [
                      Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppColors.blush, AppColors.peach]),
                              borderRadius: BorderRadius.circular(26)),
                          child: const Column(children: [
                            Icon(Icons.route_outlined,
                                color: AppColors.rose, size: 38),
                            SizedBox(height: 8),
                            Text('Small steps, taken together ♡',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 19)),
                            SizedBox(height: 5),
                            Text(
                                'Supportive, non-diagnostic guided experiences.',
                                style: TextStyle(color: AppColors.muted))
                          ])),
                      const SizedBox(height: 16),
                      ...catalog.map((j) {
                        final id = '${j['id'] ?? j['uuid'] ?? ''}';
                        final s = _sessionFor(id);
                        return Card(
                            child: Padding(
                                padding: const EdgeInsets.all(17),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.favorite_outline,
                                            color: AppColors.rose),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                '${j['title'] ?? j['name'] ?? 'Couple Journey'}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16)))
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(
                                          '${j['description'] ?? 'A guided experience for the two of you.'}',
                                          style: const TextStyle(
                                              color: AppColors.muted)),
                                      const SizedBox(height: 12),
                                      if (s != null)
                                        LinearProgressIndicator(
                                            value: _progress(s),
                                            minHeight: 6,
                                            borderRadius:
                                                BorderRadius.circular(99)),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.icon(
                                              onPressed: () => _open(j, s),
                                              icon: Icon(s == null
                                                  ? Icons.play_arrow
                                                  : Icons.arrow_forward),
                                              label: Text(s == null
                                                  ? 'Start journey'
                                                  : 'Continue journey')))
                                    ])));
                      })
                    ])));
  double _progress(Map<String, dynamic> s) {
    final data = s['data'] is Map ? (s['data'] as Map) : const {};
    final done = (data['completed_steps'] as num?)?.toDouble() ?? 0;
    final total = (data['total_steps'] as num?)?.toDouble() ?? 7;
    return total <= 0 ? 0 : (done / total).clamp(0, 1);
  }

  Future<void> _open(Map<String, dynamic> j, Map<String, dynamic>? s) async {
    var session = s;
    if (session == null) {
      session =
          await ref.read(advancedRepositoryProvider).startJourney('${j['id']}');
    }
    if (!mounted) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                JourneyDetailScreen(journey: j, session: session!)));
    _load();
  }
}

class JourneyDetailScreen extends ConsumerStatefulWidget {
  const JourneyDetailScreen(
      {super.key, required this.journey, required this.session});
  final Map<String, dynamic> journey, session;
  @override
  ConsumerState<JourneyDetailScreen> createState() => _JD();
}

class _JD extends ConsumerState<JourneyDetailScreen> {
  late Map<String, dynamic> session;
  @override
  void initState() {
    super.initState();
    session = widget.session;
  }

  List<Map<String, dynamic>> get steps {
    final raw = widget.journey['steps'] ??
        (widget.journey['data'] is Map
            ? (widget.journey['data'] as Map)['steps']
            : null);
    if (raw is List)
      return raw.asMap().entries.map((e) {
        if (e.value is Map) return (e.value as Map).cast<String, dynamic>();
        return {'id': 'step-${e.key + 1}', 'title': '${e.value}'};
      }).toList();
    return List.generate(
        _fallbackDays(),
        (i) => {
              'id': 'day-${i + 1}',
              'title': 'Day ${i + 1}',
              'body': _fallbackBody(i)
            });
  }

  int _fallbackDays() {
    final t = '${widget.journey['title'] ?? ''}'.toLowerCase();
    return t.contains('30') ? 30 : 7;
  }

  String _fallbackBody(int i) => [
        'Share one thing you appreciate today.',
        'Ask one curious question and listen without fixing.',
        'Choose a small memory to revisit together.',
        'Plan fifteen minutes of undistracted time.',
        'Send a warm note for no special reason.',
        'Name one thing you are looking forward to.',
        'Celebrate the effort you both made.'
      ][i % 7];
  Set<String> get completed {
    final d = session['data'] is Map ? (session['data'] as Map) : const {};
    final x = d['completed_step_ids'];
    return x is List ? x.map((e) => '$e').toSet() : <String>{};
  }

  Future<void> _completeStep(String id) async {
    await ref
        .read(advancedRepositoryProvider)
        .completeJourneyStep('${session['id']}', id);
    setState(() => session = {
          ...session,
          'data': {
            ...(session['data'] is Map
                ? (session['data'] as Map).cast<String, dynamic>()
                : <String, dynamic>{}),
            'completed_step_ids': [...completed, id]
          }
        });
  }

  Future<void> _finish() async {
    await ref
        .read(advancedRepositoryProvider)
        .completeJourney('${session['id']}');
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Journey complete ♡'),
                content: const Text(
                    'You made space for each other. That is worth celebrating.'),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Celebrate'))
                ]));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) {
    final all = steps;
    final done = completed;
    return Scaffold(
        appBar: AppBar(title: Text('${widget.journey['title'] ?? 'Journey'}')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(
              '${widget.journey['description'] ?? 'Take this journey one small step at a time.'}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          LinearProgressIndicator(
              value: all.isEmpty ? 0 : done.length / all.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99)),
          const SizedBox(height: 8),
          Text('${done.length} of ${all.length} steps',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 18),
          ...all.map((s) {
            final id = '${s['id'] ?? s['key'] ?? 'step-${all.indexOf(s) + 1}'}';
            final isDone = done.contains(id);
            return Card(
                child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor:
                            isDone ? AppColors.rose : AppColors.blush,
                        child: Icon(
                            isDone ? Icons.check : Icons.favorite_outline,
                            color: isDone ? Colors.white : AppColors.rose)),
                    title: Text('${s['title'] ?? s['name'] ?? 'Today’s step'}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${s['body'] ?? s['description'] ?? ''}'),
                    trailing: isDone
                        ? null
                        : TextButton(
                            onPressed: () => _completeStep(id),
                            child: const Text('Done'))));
          }),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: done.length >= all.length ? _finish : null,
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('Complete journey'))
        ]));
  }
}
