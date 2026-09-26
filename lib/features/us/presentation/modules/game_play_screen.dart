import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/journal_card.dart';

class GamePrompt {
  const GamePrompt(this.key, this.question, {this.options = const []});
  final String key;
  final String question;
  final List<String> options;
}

class CoupleGameBank {
  static List<GamePrompt> forKey(String key) => switch (key) {
        'this-or-that' => const [
            GamePrompt('weekend_1', 'Perfect weekend together?',
                options: ['Cozy at home', 'Go somewhere new']),
            GamePrompt('food_1', 'Pick one for date night',
                options: ['Cook together', 'Try a restaurant']),
            GamePrompt('memory_1', 'Which sounds better?',
                options: ['Take photos', 'Stay in the moment']),
            GamePrompt('travel_1', 'Choose your escape',
                options: ['Mountains', 'Beach']),
            GamePrompt('night_1', 'Tonight?', options: ['Movie', 'Music']),
          ],
        'would-you-rather' => const [
            GamePrompt('wyr_1',
                'Would you rather recreate your favorite date or plan a completely new one?',
                options: ['Recreate it', 'Something new']),
            GamePrompt('wyr_2',
                'Would you rather get a handwritten note or a surprise voice message?',
                options: ['Handwritten note', 'Voice message']),
            GamePrompt('wyr_3',
                'Would you rather take a spontaneous day trip or have a slow day at home?',
                options: ['Day trip', 'Slow day']),
          ],
        'who-is-more-likely' => const [
            GamePrompt(
                'likely_1', 'Who is more likely to remember a tiny detail?',
                options: ['Me', 'My partner']),
            GamePrompt('likely_2', 'Who is more likely to plan a surprise?',
                options: ['Me', 'My partner']),
            GamePrompt('likely_3',
                'Who is more likely to start laughing at the wrong moment?',
                options: ['Me', 'My partner']),
          ],
        'emoji-guess' => const [
            GamePrompt(
                'emoji_1', 'Guess the shared memory from these emojis: 🌧️☕❤️'),
            GamePrompt('emoji_2',
                'Describe one of your favorite moments using only emojis.'),
            GamePrompt('emoji_3',
                'Which shared song do these emojis remind you of? 🎧🌙✨'),
          ],
        'finish-my-sentence' => const [
            GamePrompt('finish_1', 'I feel most connected to you when…'),
            GamePrompt('finish_2', 'One little thing you do that I love is…'),
            GamePrompt('finish_3', 'Our next tiny adventure should be…'),
          ],
        'rapid-fire' => const [
            GamePrompt('rapid_1', 'Favorite shared snack?'),
            GamePrompt('rapid_2', 'One place you want to go together?'),
            GamePrompt('rapid_3', 'Morning date or night date?'),
            GamePrompt(
                'rapid_4', 'One word for your favorite memory together?'),
            GamePrompt('rapid_5', 'Who sends more emojis?'),
          ],
        'two-truths-and-a-lie' => const [
            GamePrompt('truth_1',
                'Write two true things and one playful lie about yourself. Your partner can guess later.'),
            GamePrompt(
                'truth_2', 'Write two true memories and one invented one.'),
          ],
        'relationship-bingo' => const [
            GamePrompt('bingo_1', 'Have you taken a photo together this month?',
                options: ['Yes', 'Not yet']),
            GamePrompt(
                'bingo_2', 'Have you tried something new together recently?',
                options: ['Yes', 'Not yet']),
            GamePrompt('bingo_3',
                'Have you told each other one specific appreciation this week?',
                options: ['Yes', 'Not yet']),
            GamePrompt('bingo_4', 'Have you planned your next date?',
                options: ['Yes', 'Not yet']),
          ],
        _ => const [
            GamePrompt(
                'q1', 'What small thing always makes your partner smile?'),
            GamePrompt('q2',
                'What would your partner choose for a perfect quiet evening?'),
            GamePrompt('q3', 'Name a shared memory you both still talk about.'),
            GamePrompt('q4',
                'What is one thing your partner has been excited about lately?'),
            GamePrompt('q5',
                'What date idea would your partner probably choose today?'),
          ],
      };
}

class GamePlayScreen extends ConsumerStatefulWidget {
  const GamePlayScreen({super.key, required this.game, required this.session});
  final Map<String, dynamic> game;
  final Map<String, dynamic> session;

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  int index = 0;
  bool submitting = false;
  final controller = TextEditingController();
  late final String gameKey;
  late final String sessionId;
  late final List<GamePrompt> prompts;
  final Map<String, String> answers = {};

  @override
  void initState() {
    super.initState();
    gameKey =
        '${widget.game['key'] ?? widget.game['type'] ?? widget.game['slug'] ?? ''}';
    sessionId = '${widget.session['id'] ?? ''}';
    prompts = CoupleGameBank.forKey(gameKey);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit(String answer) async {
    if (answer.trim().isEmpty || sessionId.isEmpty || submitting) return;
    final prompt = prompts[index];
    setState(() => submitting = true);
    try {
      await ref
          .read(coupleLifeRepositoryProvider)
          .submitGameAnswer(sessionId, answer.trim(), questionKey: prompt.key);
      answers[prompt.key] = answer.trim();
      controller.clear();
      if (index < prompts.length - 1) {
        setState(() => index++);
      } else {
        final completed = await ref
            .read(coupleLifeRepositoryProvider)
            .completeGame(sessionId);
        if (!mounted) return;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameResultScreen(
              title:
                  '${widget.game['title'] ?? widget.game['name'] ?? 'Couple Game'}',
              sessionId: sessionId,
              localAnswers: answers,
              xpAwarded: int.tryParse('${completed['xp_awarded'] ?? 0}') ?? 0,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save answer: $e')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = prompts[index];
    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${widget.game['title'] ?? widget.game['name'] ?? 'Couple Game'}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                    child: LinearProgressIndicator(
                        value: (index + 1) / prompts.length,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 12),
                Text('${index + 1}/${prompts.length}',
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: JournalCard(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.favorite_rounded,
                          color: AppColors.rose, size: 38),
                      const SizedBox(height: 14),
                      Text(prompt.question,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 24),
                      if (prompt.options.isNotEmpty)
                        ...prompt.options.map((option) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                      onPressed: submitting
                                          ? null
                                          : () => submit(option),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Text(option)))),
                            ))
                      else ...[
                        TextField(
                            controller: controller,
                            minLines: 2,
                            maxLines: 5,
                            decoration: const InputDecoration(
                                hintText: 'Your answer…')),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: submitting
                                    ? null
                                    : () => submit(controller.text),
                                child: Text(submitting
                                    ? 'Saving…'
                                    : 'Lock in answer'))),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                          'Your answer is saved to this shared game session.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 11, color: AppColors.muted)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameResultScreen extends ConsumerWidget {
  const GameResultScreen(
      {super.key,
      required this.title,
      required this.sessionId,
      required this.localAnswers,
      required this.xpAwarded});
  final String title;
  final String sessionId;
  final Map<String, String> localAnswers;
  final int xpAwarded;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Game Complete')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: ref.read(coupleLifeRepositoryProvider).gameResults(sessionId),
          builder: (context, snapshot) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: AppColors.heroGradient(context),
                    borderRadius: BorderRadius.circular(28)),
                child: Column(children: [
                  const Icon(Icons.celebration_rounded,
                      color: AppColors.rose, size: 48),
                  const SizedBox(height: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('+$xpAwarded Couple XP',
                      style: const TextStyle(
                          color: AppColors.rose, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('A little more knowing, laughing and connecting ♡',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted)),
                ]),
              ),
              const SizedBox(height: 18),
              const Text('Your answers',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...localAnswers.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: JournalCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(e.key,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.rose,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(e.value)
                      ])))),
              if (snapshot.hasError)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Partner reveal/result details will appear when the backend result contains them.',
                        style: TextStyle(color: AppColors.muted))),
            ],
          ),
        ),
      );
}
