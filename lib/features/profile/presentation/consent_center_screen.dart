import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';

class ConsentCenterScreen extends ConsumerStatefulWidget {
  const ConsentCenterScreen({super.key});

  @override
  ConsumerState<ConsentCenterScreen> createState() => _ConsentCenterScreenState();
}

class _ConsentCenterScreenState extends ConsumerState<ConsentCenterScreen> {
  Map<String, dynamic> permissions = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      permissions = await ref.read(advancedRepositoryProvider).privacyPermissions();
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission & Consent Center')),
      body: loading
          ? const AppLoadingState(label: 'Checking your permissions…')
          : error != null
              ? AppErrorState(message: error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(24)),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.privacy_tip_outlined, color: AppColors.rose),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sensitive features stay opt-in. You can revoke backend permissions here; the phone’s OS permission must also be changed when a feature uses camera, microphone, location, biometrics or notifications.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...permissions.entries.where((e) => e.value is bool).map(
                      (entry) => Card(
                        child: SwitchListTile(
                          value: entry.value as bool,
                          title: Text(_pretty(entry.key)),
                          subtitle: Text(_description(entry.key)),
                          secondary: Icon(_icon(entry.key), color: AppColors.rose),
                          onChanged: (value) => _setPermission(entry.key, value),
                        ),
                      ),
                    ),
                    if (!permissions.values.any((v) => v is bool))
                      const AppEmptyState(
                        icon: Icons.verified_user_outlined,
                        title: 'No permission switches returned',
                        message: 'The backend did not return any boolean privacy permissions for this account.',
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Device permission note',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This milestone keeps OS permissions explicit instead of auto-requesting them on launch. Native permission prompts should only appear at the moment a user chooses the related feature.',
                    ),
                  ],
                ),
    );
  }

  Future<void> _setPermission(String key, bool value) async {
    final old = permissions[key];
    setState(() => permissions[key] = value);
    try {
      await ref.read(advancedRepositoryProvider).updatePrivacyPermissions({key: value});
    } catch (e) {
      if (!mounted) return;
      setState(() => permissions[key] = old);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  IconData _icon(String key) {
    final k = key.toLowerCase();
    if (k.contains('location')) return Icons.location_on_outlined;
    if (k.contains('camera') || k.contains('media')) return Icons.photo_camera_outlined;
    if (k.contains('microphone') || k.contains('audio')) return Icons.mic_none_rounded;
    if (k.contains('ai')) return Icons.auto_awesome_outlined;
    if (k.contains('backup')) return Icons.cloud_outlined;
    if (k.contains('notification')) return Icons.notifications_none_rounded;
    return Icons.shield_outlined;
  }

  String _description(String key) {
    final k = key.toLowerCase();
    if (k.contains('location')) return 'Controls location-based couple features and sharing sessions.';
    if (k.contains('ai')) return 'Controls whether optional AI features may use the approved context.';
    if (k.contains('backup')) return 'Controls encrypted backup/synchronization features where configured.';
    if (k.contains('media')) return 'Controls access to sensitive private media features.';
    return 'Backend privacy permission. You can turn it off again at any time.';
  }
}
