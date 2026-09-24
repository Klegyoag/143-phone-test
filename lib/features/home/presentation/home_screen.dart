import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../discovery/presentation/discovery_screen.dart';
import '../data/home_repository.dart';
import 'daily_connection_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<HomeBundle> future;
  StreamSubscription? realtimeSub;

  @override
  void initState() {
    super.initState();
    future = ref.read(homeRepositoryProvider).load();
    realtimeSub = ref.read(realtimeCoordinatorProvider).events.listen((event) {
      const refreshEvents = {
        'presence.updated',
        'couple.relationship.updated',
        'memory.created',
        'memory.updated',
        'memory.deleted',
        'ping.received',
        'notification.created',
        'calendar.event.updated',
        'daily.reveal.ready',
        'mood.updated',
        'achievement.unlocked',
        'scheduled_message.delivered',
        'surprise.unlocked',
      };
      if (refreshEvents.contains(event.name) && mounted) reload();
    });
  }

  @override
  void dispose() {
    realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    setState(() => future = ref.read(homeRepositoryProvider).load());
  }

  Future<void> _answerDaily(Map<String, dynamic> daily) async {
    final question = daily['question'];
    if (question is! Map || '${question['id'] ?? ''}'.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today’s question is not ready yet.')));
      return;
    }

    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Today for us ♡'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Write your answer…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save answer')),
        ],
      ),
    );

    if (ok == true && controller.text.trim().isNotEmpty) {
      final result = await ref
          .read(homeRepositoryProvider)
          .answerDaily('${question['id']}', controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['reveal_ready'] == true
              ? 'Both answers are ready to reveal ♡'
              : 'Saved privately until both of you answer.'),
        ),
      );
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: reload,
          child: FutureBuilder<HomeBundle>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(children: const [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator())
                ]);
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    const JournalCard(
                      child: Column(children: [
                        Icon(Icons.cloud_off_rounded,
                            color: AppColors.rose, size: 40),
                        SizedBox(height: 12),
                        Text('Couldn’t load your little world.'),
                      ]),
                    ),
                    TextButton(
                        onPressed: reload, child: const Text('Try again')),
                  ],
                );
              }

              final bundle = snapshot.data!;
              final home = bundle.home;
              final partner =
                  (home['partner'] as Map?)?.cast<String, dynamic>();
              final name =
                  '${partner?['display_name'] ?? partner?['username'] ?? 'My Love'}';
              final memories = home['recent_memories'] is List
                  ? home['recent_memories'] as List
                  : const [];
              final relationshipSettings =
                  (bundle.relationship['settings'] is Map
                      ? bundle.relationship['settings']
                      : bundle.relationship) as Map?;
              final anniversary =
                  '${bundle.relationship['anniversary_date'] ?? relationshipSettings?['anniversary_date'] ?? ''}';
              final unread =
                  int.tryParse('${home['unread_notifications'] ?? 0}') ?? 0;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                children: [
                  if (bundle.isFromCache) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: AppColors.blush,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Row(children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 18, color: AppColors.rose),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Showing your last saved view while offline. Pull to refresh when you reconnect.',
                                style: TextStyle(fontSize: 12)))
                      ]),
                    ),
                  ],
                  _Header(
                    name: name,
                    unread: unread,
                    onSearch: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DiscoveryScreen()),
                    ),
                    onNotifications: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MoodPicker(
                    onMood: (mood) async {
                      await ref.read(homeRepositoryProvider).setMood(mood);
                      reload();
                    },
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('♡  TODAY FOR US'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _DailyCard(
                              data: bundle.daily,
                              onAnswer: () => _answerDaily(bundle.daily))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PartnerMoodCard(
                          moods: bundle.moods,
                          partnerName: name,
                          onPing: () async {
                            await ref.read(homeRepositoryProvider).sendPing();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('A little hug was sent ♡')));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SpecialDayCard(anniversary: anniversary),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                          child: _SectionTitle('♡  MEMORIES FOR YOU')),
                      Text('${memories.length} recent',
                          style: const TextStyle(color: AppColors.rose)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 145,
                    child: memories.isEmpty
                        ? const JournalCard(
                            child: Center(
                                child: Text(
                                    'Your shared moments will appear here.')))
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: memories
                                .whereType<Map>()
                                .map((e) =>
                                    _MemoryPreview(e.cast<String, dynamic>()))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  const JournalCard(
                    color: AppColors.blush,
                    child: Row(children: [
                      Icon(Icons.format_quote_rounded, color: AppColors.rose),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              'Every little moment with you is worth keeping.',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Icon(Icons.favorite_border_rounded,
                          color: AppColors.rose),
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.name,
      required this.unread,
      required this.onSearch,
      required this.onNotifications});
  final String name;
  final int unread;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning,\n$name ♡',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            const Text('Your private little world, together.',
                style: TextStyle(color: AppColors.muted)),
          ]),
        ),
        Row(children: [
          IconButton.filledTonal(
            tooltip: 'Search, favorites & activity',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, color: AppColors.wine),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onNotifications,
            child: Stack(
              children: [
                const CircleAvatar(
                    radius: 23,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.notifications_none_rounded,
                        color: AppColors.wine)),
                if (unread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.rose,
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9)),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.onMood});
  final ValueChanged<String> onMood;
  static const moods = [
    ('😊', 'Happy'),
    ('🥰', 'Loved'),
    ('😌', 'Calm'),
    ('🥺', 'Missing'),
    ('🤩', 'Excited')
  ];

  @override
  Widget build(BuildContext context) {
    return JournalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How are you feeling today?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: moods
              .map((mood) => InkWell(
                    onTap: () => onMood(mood.$2.toLowerCase()),
                    child: Column(children: [
                      CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.blushStrong,
                          child: Text(mood.$1,
                              style: const TextStyle(fontSize: 22))),
                      const SizedBox(height: 5),
                      Text(mood.$2,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ]),
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
          color: AppColors.wine));
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.data, required this.onAnswer});
  final Map<String, dynamic> data;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    String text = 'What small thing made you think of me today?';
    final question = data['question'];
    if (question is Map)
      text =
          '${question['body'] ?? question['question'] ?? question['text'] ?? question['title'] ?? text}';
    final answered = data['my_answer'] != null;
    return JournalCard(
      color: AppColors.blush,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Daily Question',
            style:
                TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(text, maxLines: 5, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: FilledButton(
                  onPressed: answered
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DailyConnectionScreen()))
                      : onAnswer,
                  child: Text(answered ? 'Reveal / Open ♡' : 'Answer →'))),
        ]),
      ]),
    );
  }
}

class _PartnerMoodCard extends StatelessWidget {
  const _PartnerMoodCard(
      {required this.moods, required this.partnerName, required this.onPing});
  final List moods;
  final String partnerName;
  final VoidCallback onPing;

  @override
  Widget build(BuildContext context) {
    String mood = 'Thinking of you';
    if (moods.isNotEmpty && moods.first is Map)
      mood = '${(moods.first as Map)['type'] ?? mood}';
    return JournalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Partner Mood',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('$partnerName is feeling',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 4),
        Text('$mood ♡',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.rose)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onPing, child: const Text('Send a Hug')),
      ]),
    );
  }
}

class _SpecialDayCard extends StatelessWidget {
  const _SpecialDayCard({required this.anniversary});
  final String anniversary;
  @override
  Widget build(BuildContext context) => JournalCard(
        color: AppColors.blush,
        child: Row(children: [
          const CircleAvatar(
              radius: 27,
              backgroundColor: Colors.white,
              child: Icon(Icons.calendar_month_rounded, color: AppColors.rose)),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Next Special Day',
                  style: TextStyle(color: AppColors.rose)),
              Text('Anniversary ♡',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                  anniversary.isEmpty
                      ? 'Add your anniversary date'
                      : anniversary,
                  style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
          const Icon(Icons.favorite_rounded, color: AppColors.rose),
        ]),
      );
}

class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview(this.memory);
  final Map<String, dynamic> memory;
  @override
  Widget build(BuildContext context) => Container(
        width: 125,
        margin: const EdgeInsets.only(right: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 94,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.blushStrong, AppColors.peach]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
                child: Icon(Icons.favorite_rounded,
                    color: AppColors.rose, size: 34)),
          ),
          const SizedBox(height: 6),
          Text('${memory['title'] ?? 'Little moment'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${memory['type'] ?? 'memory'}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      );
}
