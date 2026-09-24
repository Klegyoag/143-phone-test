import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/realtime/realtime_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/consent_center_screen.dart';
import '../../../notifications/presentation/notification_preferences_screen.dart';
import '../../../security/presentation/encryption_status_screen.dart';
import '../../../security/presentation/integration_readiness_screen.dart';
import '../../../support/presentation/app_update_screen.dart';
import '../../../../l10n/app_localizations.dart';
import 'device_security_screen.dart';

class SettingsHubScreen extends ConsumerStatefulWidget {
  const SettingsHubScreen({super.key});
  @override
  ConsumerState<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends ConsumerState<SettingsHubScreen> {
  Map<String, dynamic> privacy = {};
  List<Map<String, dynamic>> sessions = [], devices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = ref.read(advancedRepositoryProvider);
    setState(() => loading = true);
    try {
      final x = await Future.wait([
        r.privacyPermissions(),
        r.sessions(),
        r.linkedDevices(),
      ]);
      privacy = x[0] as Map<String, dynamic>;
      sessions = x[1] as List<Map<String, dynamic>>;
      devices = x[2] as List<Map<String, dynamic>>;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final realtime = ref.watch(realtimeCoordinatorProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _title('Connection & sync'),
                  Card(
                    child: Column(children: [
                      ListTile(
                        leading: Icon(realtime.connected ? Icons.bolt_rounded : Icons.bolt_outlined, color: AppColors.rose),
                        title: Text(_realtimeTitle(realtime.state)),
                        subtitle: Text(realtime.enabled
                            ? 'Private user/couple events use Laravel Reverb when available. HTTP refresh remains as fallback.'
                            : 'Add REVERB_APP_KEY at build time to enable websocket realtime.'),
                        trailing: realtime.enabled
                            ? IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: realtime.reconnect)
                            : null,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.system_update_alt_rounded, color: AppColors.rose),
                        title: Text(context.l10n.t('appUpdates')),
                        subtitle: Text(context.l10n.t('appUpdatesSubtitle')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppUpdateScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: const Text('Clear offline cache'),
                        subtitle: const Text('Removes cached Home and chat data from this device. Tokens stay in secure storage.'),
                        onTap: () async {
                          await ref.read(localCacheProvider).clearAll();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline cache cleared.')));
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.rose),
                        title: const Text('Push delivery setup'),
                        subtitle: Text(ref.read(pushCoordinatorProvider).hasConfiguredToken
                            ? 'A push token is configured for backend registration on app start.'
                            : 'No native push token is configured yet. Realtime/in-app notifications still work.'),
                        trailing: ref.read(pushCoordinatorProvider).hasConfiguredToken
                            ? const Icon(Icons.check_circle_outline, color: AppColors.rose)
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          final push = ref.read(pushCoordinatorProvider);
                          final ok = await push.registerConfiguredToken();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok
                                ? 'Push device registered with the backend.'
                                : push.hasConfiguredToken
                                    ? (push.lastError ?? 'Push registration failed.')
                                    : 'Native FCM/APNs token bridge is still required on this device.')));
                          }
                        },
                      ),
                    ]),
                  ),
                  _title('Device permissions'),
                  Card(
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.rose),
                        title: const Text('Native push notifications'),
                        subtitle: Text(() {
                          final bridge = ref.read(nativePushBridgeProvider);
                          if (!bridge.initialized) return bridge.lastError ?? 'Firebase native configuration is not active yet.';
                          if (bridge.permissionGranted) return 'FCM/APNs is ready and device permission is ${bridge.permissionLabel}.';
                          return 'Firebase is initialized without requesting permission. Enable notifications explicitly when you want them.';
                        }()),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: () async {
                            final bridge = ref.read(nativePushBridgeProvider);
                            final ok = bridge.permissionGranted
                                ? await bridge.bootstrap()
                                : await bridge.requestPermissionAndActivate();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Push bridge is ready.' : (bridge.lastError ?? 'Push setup failed.'))));
                            setState(() {});
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.perm_device_information_outlined),
                        title: const Text('Review OS permissions'),
                        subtitle: const Text('Camera, microphone, photos, location and notifications are requested only when needed.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showNativePermissions,
                      ),
                    ]),
                  ),
                  _title('Privacy permissions'),
                  Card(
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined, color: AppColors.rose),
                        title: const Text('Permission & Consent Center'),
                        subtitle: const Text('Review sensitive feature permissions with clearer explanations.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsentCenterScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_none_rounded, color: AppColors.rose),
                        title: const Text('Notification preferences'),
                        subtitle: const Text('Choose which couple moments may notify you.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded, color: AppColors.rose),
                        title: const Text('Private encryption status'),
                        subtitle: const Text('Inspect backend public-key/prekey readiness without exposing private keys.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EncryptionStatusScreen())),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.fact_check_outlined, color: AppColors.rose),
                        title: Text(context.l10n.t('providerReadiness')),
                        subtitle: const Text('See which provider/native boundaries are configured, pending credentials, or blocked by security review.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntegrationReadinessScreen())),
                      ),
                    ]),
                  ),
                  ...privacy.entries.where((e) => e.value is bool).map((e) => SwitchListTile(
                        value: e.value as bool,
                        title: Text(e.key.replaceAll('_', ' ')),
                        onChanged: (v) => _privacy(e.key, v),
                      )),
                  _title('Active sessions'),
                  if (sessions.isEmpty) const ListTile(title: Text('No other active sessions found.')),
                  ...sessions.map((s) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.devices, color: AppColors.rose),
                          title: Text('${s['device_name'] ?? s['name'] ?? 'Session'}'),
                          subtitle: Text('${s['last_active_at'] ?? s['created_at'] ?? ''}'),
                          trailing: IconButton(icon: const Icon(Icons.logout), onPressed: () => _revoke('${s['id']}')),
                        ),
                      )),
                  _title('Linked devices'),
                  Card(child: ListTile(leading: const Icon(Icons.phonelink_lock, color: AppColors.rose), title: const Text('Manage linked devices'), subtitle: const Text('Create/scan a secure short-lived QR and revoke devices.'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkedDevicesScreen())))),
                  if (devices.isEmpty) const ListTile(title: Text('No linked devices yet.')),
                  ...devices.map((d) => ListTile(
                        leading: const Icon(Icons.phonelink_lock),
                        title: Text('${d['name'] ?? d['device_name'] ?? 'Linked device'}'),
                      )),
                ],
              ),
            ),
    );
  }

  String _realtimeTitle(RealtimeConnectionState state) => switch (state) {
        RealtimeConnectionState.connected => 'Realtime connected',
        RealtimeConnectionState.connecting => 'Connecting realtime…',
        RealtimeConnectionState.reconnecting => 'Reconnecting realtime…',
        RealtimeConnectionState.disabled => 'Realtime not configured',
        RealtimeConnectionState.disconnected => 'Realtime disconnected',
      };

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Future<void> _showNativePermissions() async {
    final service = ref.read(nativePermissionServiceProvider);
    final statuses = await service.currentStatuses();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ListTile(title: Text('Device permissions', style: TextStyle(fontWeight: FontWeight.w800))),
            ...statuses.entries.map((e) => ListTile(
              leading: Icon(e.value.isGranted ? Icons.check_circle_outline : Icons.circle_outlined, color: e.value.isGranted ? AppColors.rose : null),
              title: Text(e.key),
              trailing: Text(e.value.name),
            )),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: () async { await service.openSettings(); }, icon: const Icon(Icons.settings_outlined), label: const Text('Open device settings')),
          ]),
        ),
      ),
    );
  }

  Future<void> _privacy(String k, bool v) async {
    setState(() => privacy[k] = v);
    try {
      await ref.read(advancedRepositoryProvider).updatePrivacyPermissions({k: v});
    } catch (_) {
      if (mounted) setState(() => privacy[k] = !v);
    }
  }

  Future<void> _revoke(String id) async {
    await ref.read(advancedRepositoryProvider).revokeSession(id);
    setState(() => sessions.removeWhere((e) => '${e['id']}' == id));
  }
}
