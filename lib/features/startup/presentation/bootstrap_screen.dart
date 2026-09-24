import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';

class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    // The current backend handoff defines GET /bootstrap as the public contract
    // snapshot. Treat it as a best-effort preflight only; offline safe startup
    // must still be possible when this request cannot be reached. Cache it in
    // the background so a slow cold server never holds the first usable page.
    unawaited(_cacheBackendSnapshot());
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    if (!onboardingDone) return _go('/onboarding');

    final api = ref.read(apiClientProvider);
    final tokens = await Future.wait([
      api.secureStore.accessToken(),
      api.secureStore.refreshToken(),
    ]);
    final access = tokens[0];
    final refresh = tokens[1];
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      return _go('/welcome');
    }

    try {
      await api.get('/me');

      final startupChecks = await Future.wait<dynamic>([
        ref.read(authRepositoryProvider).recoveryStatus(),
        ref.read(legalRepositoryProvider).currentState(),
        _currentCoupleOrNull(),
      ]);
      final recovery = startupChecks[0] as Map<String, dynamic>;
      final recoveryData = recovery['data'];
      final recoveryConfirmed = recoveryData is Map &&
          (recoveryData['confirmed'] == true ||
              recoveryData['recovery_confirmed'] == true);
      if (!recoveryConfirmed) return _go('/recovery-confirm');

      final legal = startupChecks[1];
      if (legal.acceptanceRequired) return _go('/legal');

      final pendingInvite = prefs.getString('pending_invite_token');
      if (pendingInvite != null && pendingInvite.isNotEmpty) {
        return _go('/invite/${Uri.encodeComponent(pendingInvite)}');
      }

      final couple = startupChecks[2] as Map<String, dynamic>?;
      if (couple == null || couple.isEmpty) return _go('/couple-setup');

      await ref.read(localCacheProvider).putJson('last_safe_route', '/app');
      return _go('/app');
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await api.secureStore.clearTokens();
        return _go('/login');
      }
      if (e.statusCode == 403 && (e.code?.contains('account') ?? false)) {
        return _go('/account-unavailable');
      }
      if (e.statusCode == 428) {
        if (e.code == 'recovery_confirmation_required') {
          return _go('/recovery-confirm');
        }
        if (e.code == 'legal_acceptance_required') {
          return _go('/legal');
        }
      }
      final cached = await ref
          .read(localCacheProvider)
          .getJson<String>('last_safe_route', maxAge: const Duration(days: 7));
      if (cached == '/app' &&
          (access?.isNotEmpty == true || refresh?.isNotEmpty == true)) {
        return _go('/app?offline=1');
      }
      _retrySilently();
    } catch (_) {
      _retrySilently();
    }
  }

  Future<void> _cacheBackendSnapshot() async {
    try {
      final backend = await ref.read(apiClientProvider).get('/bootstrap');
      final data = backend['data'];
      if (data is Map) {
        await ref.read(localCacheProvider).putJson(
              'backend_bootstrap_snapshot',
              Map<String, dynamic>.from(data),
            );
      }
    } catch (_) {
      // Startup never depends on this best-effort cache refresh.
    }
  }

  Future<Map<String, dynamic>?> _currentCoupleOrNull() async {
    try {
      return await ref.read(coupleRepositoryProvider).current();
    } on ApiException catch (e) {
      if (e.statusCode == 404 ||
          e.code == 'couple_space_not_found' ||
          e.code == 'couple_space_required') {
        return null;
      }
      rethrow;
    }
  }

  void _retrySilently() {
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) _bootstrap();
    });
  }

  void _go(String location) {
    if (mounted) context.go(location);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.05, -.2),
              radius: 1.15,
              colors: [
                Color(0xFFFFFBF8),
                Color(0xFFFFE6EC),
                Color(0xFFF8B9C9),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .92, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/143_logo_transparent.png',
                      width: 224,
                      height: 224,
                      fit: BoxFit.contain,
                      semanticLabel: '143',
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: 74,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.white.withValues(alpha: .5),
                        color: AppColors.rose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class AccountUnavailableScreen extends StatelessWidget {
  const AccountUnavailableScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StartupStateScreen(
        icon: Icons.person_off_outlined,
        title: 'Account unavailable',
        body:
            'This account cannot be opened right now. Sign in again or contact support if the problem continues.',
        action: 'Back to sign in',
        route: '/login',
      );
}

class OfflineStartupScreen extends StatelessWidget {
  const OfflineStartupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 58, color: AppColors.rose),
                const SizedBox(height: 18),
                Text('You’re offline',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                const Text(
                    '143 can open previously cached, safe content. Sending, editing and sensitive actions stay unavailable until the server can verify your session.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: () => context.go('/app?offline=1'),
                    child: const Text('Open cached home')),
                TextButton(
                    onPressed: () => context.go('/bootstrap'),
                    child: const Text('Try connection again')),
              ],
            ),
          ),
        ),
      );
}

class CoupleSpaceUnavailableScreen extends StatelessWidget {
  const CoupleSpaceUnavailableScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StartupStateScreen(
        icon: Icons.favorite_border_rounded,
        title: 'Couple space unavailable',
        body:
            'Your private couple space is not available yet. Create one or join your partner with an invite.',
        action: 'Set up our space',
        route: '/couple-setup',
      );
}

class _StartupStateScreen extends StatelessWidget {
  const _StartupStateScreen(
      {required this.icon,
      required this.title,
      required this.body,
      required this.action,
      required this.route});
  final IconData icon;
  final String title, body, action, route;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 58, color: AppColors.rose),
              const SizedBox(height: 18),
              Text(title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () => context.go(route), child: Text(action)),
            ]),
          ),
        ),
      );
}
