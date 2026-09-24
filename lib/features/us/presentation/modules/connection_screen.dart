import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/advanced_repository.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  String mood = 'loved';
  bool holding = false;
  bool moodShared = true;
  bool loadingPrivacy = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPrivacy);
  }

  Future<void> _loadPrivacy() async {
    try {
      final permissions =
          await ref.read(advancedRepositoryProvider).privacyPermissions();
      if (mounted)
        setState(() {
          moodShared = permissions['mood_shared'] != false;
          loadingPrivacy = false;
        });
    } catch (_) {
      if (mounted) setState(() => loadingPrivacy = false);
    }
  }

  Future<void> _setMoodPrivacy(bool value) async {
    final before = moodShared;
    setState(() => moodShared = value);
    try {
      await ref.read(relationshipToolsRepositoryProvider).setMoodPrivacy(value);
    } catch (e) {
      if (mounted) {
        setState(() => moodShared = before);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _sendNeedYou() async {
    await ref
        .read(relationshipToolsRepositoryProvider)
        .sendNeedYou(message: 'I need you right now ♡');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('needYouSent'))),
      );
    }
  }

  Future<void> _shareMood() async {
    await ref
        .read(relationshipToolsRepositoryProvider)
        .sendMood(mood: mood, visibility: moodShared ? 'partner' : 'private');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('moodShared'))),
      );
    }
  }

  void _down(TapDownDetails _) {
    setState(() => holding = true);
    if (ref.read(appPreferencesProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _up(TapUpDetails _) {
    setState(() => holding = false);
    if (ref.read(appPreferencesProvider).hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    ref
        .read(relationshipToolsRepositoryProvider)
        .sendNeedYou(message: 'Touch ♡');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(appPreferencesProvider);
    final duration =
        prefs.reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('moodNeedYouTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blush, AppColors.peach],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.rose,
                  size: 42,
                ),
                Text(
                  l.t('tinySignalTitle'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  l.t('tinySignalBody'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.t('howFeeling'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'loved',
              'happy',
              'soft',
              'tired',
              'missing_you',
              'need_space',
            ]
                .map(
                  (x) => ChoiceChip(
                    label: Text(x.replaceAll('_', ' ')),
                    selected: mood == x,
                    onSelected: (_) => setState(() => mood = x),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary:
                const Icon(Icons.visibility_outlined, color: AppColors.rose),
            title: const Text('Share mood with partner'),
            subtitle: Text(moodShared
                ? 'Your current mood can be shared with your partner.'
                : 'New mood updates stay private to you.'),
            value: moodShared,
            onChanged: loadingPrivacy ? null : _setMoodPrivacy,
          ),
          FilledButton.icon(
            onPressed: _shareMood,
            icon: const Icon(Icons.sentiment_satisfied_alt),
            label: Text(l.t('shareMood')),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l.t('needYou'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    l.t('needYouGentleBody'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sendNeedYou,
                    icon: const Icon(Icons.waving_hand),
                    label: Text(l.t('sendNeedYou')),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l.t('messageAction')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.t('callFromChatHint'))),
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: Text(l.t('callAction')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(advancedRepositoryProvider)
                            .rawPost('/pings', {'type': 'love'}),
                        icon: const Icon(Icons.favorite_border),
                        label: Text(l.t('sendLoveAction')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.t('touchHold'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Center(
            child: Semantics(
              button: true,
              label: l.t('touchHold'),
              hint: l.t('touchHoldHint'),
              liveRegion: holding,
              value: holding ? l.t('touchActive') : l.t('touchReady'),
              child: GestureDetector(
                onTapDown: _down,
                onTapUp: _up,
                onTapCancel: () => setState(() => holding = false),
                child: AnimatedContainer(
                  duration: duration,
                  width: holding ? 150 : 130,
                  height: holding ? 150 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: holding ? AppColors.rose : AppColors.blush,
                    boxShadow: holding && !prefs.reduceMotion
                        ? [
                            BoxShadow(
                              color: AppColors.rose.withOpacity(.25),
                              blurRadius: 28,
                              spreadRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 56,
                    color: holding ? Colors.white : AppColors.rose,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              l.t('touchHoldHint'),
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
