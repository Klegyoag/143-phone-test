import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/navigation/deep_link_target.dart';
import '../core/navigation/native_deep_link_coordinator.dart';
import '../core/security/app_lock_gate.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class OneFourThreeApp extends ConsumerStatefulWidget {
  const OneFourThreeApp({super.key});

  @override
  ConsumerState<OneFourThreeApp> createState() => _OneFourThreeAppState();
}

class _OneFourThreeAppState extends ConsumerState<OneFourThreeApp> {
  NativeDeepLinkCoordinator? _links;
  StreamSubscription<Map<String, dynamic>>? _pushOpenSub;

  @override
  void initState() {
    super.initState();
    _links = NativeDeepLinkCoordinator(appRouter);
    Future.microtask(() async {
      try { await _links?.start(); } catch (_) {}
      // Firebase is optional in local/dev builds. Failure is retained by the
      // bridge and does not block the rest of 143.
      final push = ref.read(nativePushBridgeProvider);
      _pushOpenSub = push.openedNotifications.listen((payload) {
        final target = DeepLinkTarget.fromPayload(payload);
        appRouter.go(target.location);
      });
      await push.bootstrap();
    });
  }

  @override
  void dispose() {
    _links?.dispose();
    _pushOpenSub?.cancel();
    ref.read(nativePushBridgeProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '143',
      theme: AppTheme.light(highContrast: prefs.highContrast),
      darkTheme: AppTheme.dark(highContrast: prefs.highContrast),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      routerConfig: appRouter,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(prefs.fontScale),
            disableAnimations: prefs.reduceMotion || media.disableAnimations,
          ),
          child: AppLockGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
