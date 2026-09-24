import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  final pin = TextEditingController();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(appLockServiceProvider).initialize());
    timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    timer?.cancel();
    pin.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(appLockServiceProvider).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockServiceProvider);
    if (!lock.initialized || !lock.locked) return widget.child;
    final wait = lock.retryAfter;
    return Material(
      color: const Color(0xFFFDF7F5),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircleAvatar(radius: 42, backgroundColor: AppColors.blush, child: Icon(Icons.favorite_rounded, color: AppColors.rose, size: 38)),
                const SizedBox(height: 20),
                Text(context.l10n.t('lockedTitle'), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(context.l10n.t('lockedBody'), textAlign: TextAlign.center),
                if (lock.hasPin) ...[
                  const SizedBox(height: 22),
                  TextField(
                    controller: pin,
                    enabled: wait == Duration.zero,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(labelText: wait > Duration.zero ? 'Try again in ${wait.inSeconds + 1}s' : '143 PIN', counterText: ''),
                    onSubmitted: (_) => _pinUnlock(),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(onPressed: wait > Duration.zero ? null : _pinUnlock, icon: const Icon(Icons.pin_rounded), label: Text(context.l10n.t('unlockPin'))),
                ],
                if (lock.biometricEnabled) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: lock.unlock,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(context.l10n.t('useDeviceAuth')),
                  ),
                ],
                if (wait > Duration.zero) ...[
                  const SizedBox(height: 12),
                  Text(context.l10n.t('tooManyAttempts'), style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pinUnlock() async {
    final ok = await ref.read(appLockServiceProvider).unlockWithPin(pin.text);
    pin.clear();
    if (!ok && mounted && ref.read(appLockServiceProvider).retryAfter == Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.t('pinMismatch'))));
    }
  }
}
