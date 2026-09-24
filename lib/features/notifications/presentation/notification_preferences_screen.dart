import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, dynamic> values = {};
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      values = await ref.read(notificationRepositoryProvider).preferences();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(appPreferencesProvider);
    final knownKeys = <(String, String, String)>[
      ('messages', l.t('messagesPref'), l.t('messagesPrefBody')),
      ('pings', l.t('pingsPref'), l.t('pingsPrefBody')),
      ('memories', l.t('memoriesPref'), l.t('memoriesPrefBody')),
      ('calls', l.t('callsPref'), l.t('callsPrefBody')),
      ('calendar', l.t('calendarPref'), l.t('calendarPrefBody')),
      ('daily', l.t('dailyPref'), l.t('dailyPrefBody')),
      (
        'achievements',
        l.t('achievementsPref'),
        l.t('achievementsPrefBody'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.t('notificationPreferences'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: AppColors.blush,
                  child: ListTile(
                    leading: const Icon(
                      Icons.favorite_outline_rounded,
                      color: AppColors.rose,
                    ),
                    title: Text(
                      l.t('stayCloseWithoutNoise'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(l.t('notificationPrefsBody')),
                  ),
                ),
                const SizedBox(height: 12),
                _DeviceNotificationPermissionCard(
                  saving: saving,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                Semantics(
                  toggled: prefs.hapticsEnabled,
                  label: l.t('hapticsVibration'),
                  hint: l.t('hapticsBody'),
                  child: SwitchListTile(
                    value: prefs.hapticsEnabled,
                    secondary: const Icon(Icons.vibration_rounded),
                    title: Text(l.t('hapticsVibration')),
                    subtitle: Text(l.t('hapticsBody')),
                    onChanged: saving
                        ? null
                        : (value) async {
                            await ref
                                .read(appPreferencesProvider)
                                .setHapticsEnabled(value);
                            // If the Laravel deployment exposes the haptics
                            // preference, keep it synchronized. A deployment
                            // that does not expose this key must not prevent
                            // the local accessibility/haptic preference.
                            try {
                              values = await ref
                                  .read(notificationRepositoryProvider)
                                  .updatePreferences({'haptics': value});
                            } catch (_) {}
                            if (mounted) setState(() {});
                          },
                  ),
                ),
                Semantics(
                  toggled: prefs.reduceMotion,
                  label: l.t('reduceMotion'),
                  hint: l.t('reduceMotionBody'),
                  child: SwitchListTile(
                    value: prefs.reduceMotion,
                    secondary: const Icon(Icons.motion_photos_off_outlined),
                    title: Text(l.t('reduceMotion')),
                    subtitle: Text(l.t('reduceMotionBody')),
                    onChanged: (value) => ref
                        .read(appPreferencesProvider)
                        .setReduceMotion(value),
                  ),
                ),
                const Divider(height: 28),
                ...knownKeys.map((entry) {
                  final current = values[entry.$1];
                  final enabled = current is bool ? current : true;
                  return Semantics(
                    toggled: enabled,
                    label: entry.$2,
                    hint: entry.$3,
                    child: SwitchListTile(
                      value: enabled,
                      title: Text(entry.$2),
                      subtitle: Text(entry.$3),
                      onChanged: saving ? null : (v) => _set(entry.$1, v),
                    ),
                  );
                }),
                if (values.entries.any(
                  (e) =>
                      e.value is bool &&
                      !knownKeys.any((k) => k.$1 == e.key) &&
                      e.key != 'haptics',
                )) ...[
                  const Divider(),
                  ...values.entries
                      .where(
                        (e) =>
                            e.value is bool &&
                            !knownKeys.any((k) => k.$1 == e.key) &&
                            e.key != 'haptics',
                      )
                      .map(
                        (e) => SwitchListTile(
                          value: e.value as bool,
                          title: Text(e.key.replaceAll('_', ' ')),
                          onChanged: saving ? null : (v) => _set(e.key, v),
                        ),
                      ),
                ],
              ],
            ),
    );
  }

  Future<void> _set(String key, bool value) async {
    final old = values[key];
    setState(() {
      values[key] = value;
      saving = true;
    });
    try {
      values = await ref
          .read(notificationRepositoryProvider)
          .updatePreferences({key: value});
    } catch (_) {
      values[key] = old ?? !value;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}


class _DeviceNotificationPermissionCard extends ConsumerWidget {
  const _DeviceNotificationPermissionCard({
    required this.saving,
    required this.onChanged,
  });

  final bool saving;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final bridge = ref.read(nativePushBridgeProvider);
    final granted = bridge.permissionGranted;
    final statusText = switch (bridge.permissionLabel) {
      'authorized' => l.t('pushAuthorized'),
      'provisional' => l.t('pushProvisional'),
      'denied' => l.t('pushDenied'),
      _ => l.t('pushNotRequested'),
    };

    return Semantics(
      container: true,
      label: l.t('deviceNotifications'),
      hint: l.t('deviceNotificationsBody'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ListTile(
            leading: Icon(
              granted
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.rose,
            ),
            title: Text(
              l.t('deviceNotifications'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${l.t('deviceNotificationsBody')}\n$statusText'),
            isThreeLine: true,
            trailing: granted
                ? const Icon(Icons.check_circle_rounded, color: AppColors.rose)
                : FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final ok = await bridge.requestPermissionAndActivate();
                            if (!context.mounted) return;
                            onChanged();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? l.t('pushEnabled')
                                      : (bridge.lastError ?? l.t('pushEnableFailed')),
                                ),
                              ),
                            );
                          },
                    child: Text(l.t('enable')),
                  ),
          ),
        ),
      ),
    );
  }
}
