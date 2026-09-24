import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/navigation/deep_link_target.dart';
import '../../../core/realtime/realtime_events.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<AppNotification>> future;
  StreamSubscription? realtimeSub;

  @override
  void initState() {
    super.initState();
    future = _load();
    realtimeSub = ref.read(realtimeCoordinatorProvider).events.listen((event) {
      if (event.name == RealtimeEvents.notificationCreated) reload();
    });
  }

  @override
  void dispose() { realtimeSub?.cancel(); super.dispose(); }

  Future<List<AppNotification>> _load() => ref.read(notificationRepositoryProvider).list();
  void reload() => setState(() => future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('notifications')),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).readAll();
              reload();
            },
            child: Text(context.l10n.t('readAll')),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => reload(),
        child: FutureBuilder<List<AppNotification>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  const Icon(Icons.notifications_none_rounded, size: 52, color: AppColors.rose),
                  const SizedBox(height: 12),
                  Center(child: Text(context.l10n.t('allQuiet'))),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = items[index];
                return Semantics(
                  button: true,
                  readOnly: notification.isRead,
                  label: notification.title,
                  value: notification.isRead ? 'read' : 'unread',
                  hint: notification.body.isEmpty ? 'Open notification' : notification.body,
                  child: Card(
                  color: notification.isRead ? Colors.white : AppColors.blush,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.blushStrong,
                      child: Icon(_icon(notification.type), color: AppColors.rose),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.body.isNotEmpty) Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          notification.createdAt?.toLocal().toString().split('.').first ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!notification.isRead) {
                        await ref.read(notificationRepositoryProvider).read(notification.id);
                      }
                      if (!context.mounted) return;
                      final target = DeepLinkTarget.fromPayload(notification.navigationPayload);
                      context.go(target.location);
                    },
                  ),
                ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _icon(String type) {
    if (type.contains('memory')) return Icons.photo_library_outlined;
    if (type.contains('message')) return Icons.chat_bubble_outline;
    if (type.contains('call')) return Icons.call_outlined;
    if (type.contains('ping')) return Icons.favorite_outline;
    return Icons.notifications_none_rounded;
  }
}
