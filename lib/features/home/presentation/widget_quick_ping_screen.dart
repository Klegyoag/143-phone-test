import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

/// Safe Quick Ping entry launched from a native widget.
/// The widget never sends in the background: the user explicitly confirms in-app.
class WidgetQuickPingScreen extends ConsumerStatefulWidget {
  const WidgetQuickPingScreen({super.key});

  @override
  ConsumerState<WidgetQuickPingScreen> createState() =>
      _WidgetQuickPingScreenState();
}

class _WidgetQuickPingScreenState extends ConsumerState<WidgetQuickPingScreen> {
  bool sending = false;
  bool sent = false;
  String? error;

  Future<void> _send() async {
    if (sending || sent) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await ref.read(homeRepositoryProvider).sendWidgetPing();
      if (mounted) setState(() => sent = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Connect your partner before sending a ping.');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('quickPing'))),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: JournalCard(
              color: AppColors.blush,
              child: Semantics(
                liveRegion: true,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      sent
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.rose,
                      size: 52),
                  const SizedBox(height: 14),
                  Text(sent ? l.t('pingSent') : l.t('sendLittleLove'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(sent ? l.t('pingSentDetail') : l.t('quickPingConsent'),
                      textAlign: TextAlign.center),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => context.go('/couple-setup'),
                      child: const Text('Connect partner'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (!sent)
                    FilledButton.icon(
                      onPressed: sending ? null : _send,
                      icon: sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.favorite_rounded),
                      label: Text(sending ? l.t('sending') : l.t('sendPing')),
                    )
                  else
                    FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(l.t('done'))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
