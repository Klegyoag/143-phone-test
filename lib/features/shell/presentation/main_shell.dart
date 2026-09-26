import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/navigation/deep_link_target.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/realtime/realtime_events.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../calls/presentation/call_session_screen.dart';
import '../../create/presentation/create_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../memories/presentation/memories_screen.dart';
import '../../us/presentation/us_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  late int index;
  static const pages = [
    HomeScreen(),
    MemoriesScreen(),
    CreateScreen(),
    ChatScreen(),
    UsScreen()
  ];
  StreamSubscription<RealtimeEvent>? realtimeSub;
  StreamSubscription<Map<String, dynamic>>? foregroundPushSub;
  Timer? incomingCallPoll;
  final Set<String> handledIncomingCalls = <String>{};
  bool incomingDialogOpen = false;
  bool checkingIncomingCalls = false;
  int unreadMessages = 0;
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex.clamp(0, 4).toInt();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      incomingCallPoll = Timer.periodic(
          const Duration(seconds: 5), (_) => _checkIncomingCalls());
      unawaited(_checkIncomingCalls());
      final realtime = ref.read(realtimeCoordinatorProvider);
      realtimeSub = realtime.events.listen(_handleRealtimeEvent);
      unawaited(realtime.start().catchError((_) {}));
      unawaited(ref
          .read(pushCoordinatorProvider)
          .registerConfiguredToken()
          .catchError((_) => false));
      unawaited(ref
          .read(nativePushBridgeProvider)
          .registerCurrentToken()
          .catchError((_) => false));
      foregroundPushSub = ref
          .read(nativePushBridgeProvider)
          .foregroundNotifications
          .listen(_handleForegroundPush);
      unawaited(_refreshUnread());
    });
  }

  Future<void> _checkIncomingCalls() async {
    if (!mounted || incomingDialogOpen || checkingIncomingCalls) return;
    checkingIncomingCalls = true;
    try {
      final calls = await ref.read(advancedRepositoryProvider).incomingCalls();
      for (final call in calls) {
        final id = '${call['id'] ?? ''}';
        if (id.isNotEmpty && !handledIncomingCalls.contains(id)) {
          await _showIncomingCall(id, '${call['type'] ?? 'audio'}');
          break;
        }
      }
    } catch (_) {
      // Realtime may still deliver an incoming call while HTTP is unavailable.
    } finally {
      checkingIncomingCalls = false;
    }
  }

  Future<void> _showIncomingCall(String callId, String type) async {
    if (!mounted || incomingDialogOpen || handledIncomingCalls.contains(callId))
      return;
    incomingDialogOpen = true;
    handledIncomingCalls.add(callId);
    try {
      final accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: Text(type == 'video'
              ? context.l10n.t('incomingVideoCall')
              : context.l10n.t('incomingAudioCall')),
          content: Text(context.l10n.t('personCalling')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(context.l10n.t('decline'))),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(context.l10n.t('answer'))),
          ],
        ),
      );
      if (!mounted) return;
      if (accept == true) {
        await ref.read(advancedRepositoryProvider).acceptCall(callId);
        if (mounted)
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CallSessionScreen(
                      callId: callId, type: type, incoming: true)));
      } else {
        await ref.read(advancedRepositoryProvider).declineCall(callId);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not answer call: $error')));
    } finally {
      incomingDialogOpen = false;
    }
  }

  void _handleForegroundPush(Map<String, dynamic> payload) {
    if (!mounted) return;
    final title =
        '${payload['_notification_title'] ?? context.l10n.t('newNotification')}';
    final body = '${payload['_notification_body'] ?? ''}'.trim();
    final target = DeepLinkTarget.fromPayload(payload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        action: SnackBarAction(
          label: context.l10n.t('open'),
          onPressed: () => context.go(target.location),
        ),
      ),
    );
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final summary =
          await ref.read(discoveryRepositoryProvider).unreadSummary();
      if (!mounted) return;
      setState(() {
        unreadMessages = summary['messages'] ?? 0;
        unreadNotifications = summary['notifications'] ?? 0;
      });
    } catch (_) {
      // Badges are enhancement-only; the tab content remains usable offline.
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) async {
    if (!mounted) return;
    if (event.name == RealtimeEvents.sessionRevoked) {
      await ref.read(apiClientProvider).secureStore.clearTokens();
      await ref.read(localCacheProvider).clearAll();
      ref.read(mediaUrlCacheProvider).clear();
      if (mounted) context.go('/login');
      return;
    }

    if ({
      RealtimeEvents.notificationCreated,
      RealtimeEvents.chatMessageCreated,
      RealtimeEvents.chatMessageRead,
      RealtimeEvents.chatMessageDeleted
    }.contains(event.name)) {
      _refreshUnread();
    }

    if (event.name == RealtimeEvents.notificationCreated) {
      final target = DeepLinkTarget.fromPayload(event.payload);
      final targetTab = target.tabIndex;
      if (targetTab != null) {
        setState(() => index = targetTab.clamp(0, 4).toInt());
      }
    }

    if (event.name == RealtimeEvents.callIncoming) {
      final realtime = ref.read(realtimeCoordinatorProvider);
      final fromUser = '${event.payload['from_user_id'] ?? ''}';
      final callId = '${event.payload['call_id'] ?? ''}';
      final type = '${event.payload['type'] ?? 'audio'}';
      if (callId.isNotEmpty &&
          fromUser.isNotEmpty &&
          fromUser != realtime.userId) {
        await _showIncomingCall(callId, type);
      }
      return;
    }

    if ({RealtimeEvents.pingReceived, RealtimeEvents.needYouReceived}
            .contains(event.name) &&
        ref.read(appPreferencesProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }

    final message = switch (event.name) {
      RealtimeEvents.pingReceived => context.l10n.t('pingReceived'),
      RealtimeEvents.needYouReceived => context.l10n.t('needYouReceived'),
      RealtimeEvents.achievementUnlocked =>
        context.l10n.t('achievementUnlocked'),
      RealtimeEvents.dailyRevealReady => context.l10n.t('dailyRevealReady'),
      RealtimeEvents.surpriseUnlocked => context.l10n.t('surpriseUnlocked'),
      _ => null,
    };
    if (message != null) {
      final needYouId = event.name == RealtimeEvents.needYouReceived
          ? '${event.payload['id'] ?? event.payload['need_you_id'] ?? ''}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: needYouId.isNotEmpty
              ? SnackBarAction(
                  label: "I'm here",
                  onPressed: () async {
                    try {
                      await ref
                          .read(relationshipToolsRepositoryProvider)
                          .respondNeedYou(needYouId);
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Sent: I'm here ♡")));
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(realtimeCoordinatorProvider).onAppLifecycle(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    incomingCallPoll?.cancel();
    realtimeSub?.cancel();
    foregroundPushSub?.cancel();
    ref.read(realtimeCoordinatorProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(
            icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                    unreadNotifications > 99 ? '99+' : '$unreadNotifications'),
                child: const Icon(Icons.home_outlined)),
            selectedIcon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                    unreadNotifications > 99 ? '99+' : '$unreadNotifications'),
                child: const Icon(Icons.home_rounded, color: AppColors.rose)),
            label: AppLocalizations.of(context).t('home'),
          ),
          NavigationDestination(
              icon: const Icon(Icons.photo_library_outlined),
              selectedIcon: const Icon(Icons.photo_library_rounded,
                  color: AppColors.rose),
              label: AppLocalizations.of(context).t('memories')),
          NavigationDestination(
              icon: const CircleAvatar(
                  backgroundColor: AppColors.rose,
                  child: Icon(Icons.add_rounded, color: Colors.white)),
              selectedIcon: const CircleAvatar(
                  backgroundColor: AppColors.rose,
                  child: Icon(Icons.add_rounded, color: Colors.white)),
              label: AppLocalizations.of(context).t('create')),
          NavigationDestination(
            icon: Badge(
                isLabelVisible: unreadMessages > 0,
                label: Text(unreadMessages > 99 ? '99+' : '$unreadMessages'),
                child: const Icon(Icons.chat_bubble_outline_rounded)),
            selectedIcon: Badge(
                isLabelVisible: unreadMessages > 0,
                label: Text(unreadMessages > 99 ? '99+' : '$unreadMessages'),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: AppColors.rose)),
            label: AppLocalizations.of(context).t('chat'),
          ),
          NavigationDestination(
              icon: const Icon(Icons.favorite_border_rounded),
              selectedIcon:
                  const Icon(Icons.favorite_rounded, color: AppColors.rose),
              label: AppLocalizations.of(context).t('us')),
        ],
      ),
    );
  }
}
