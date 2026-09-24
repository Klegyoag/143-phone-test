import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'device_security_screen.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool loading = true, working = false;
  Map<String, dynamic> status = {};
  List<Map<String, dynamic>> backups = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = ref.read(advancedRepositoryProvider);
      final x = await Future.wait([r.backupStatus(), r.backups()]);
      status = x[0] as Map<String, dynamic>;
      backups = x[1] as List<Map<String, dynamic>>;
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _requestBackup() async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Encrypted backup boundary'), content: const Text('The backend can track backup jobs, but this frontend does not yet have a security-reviewed encrypted archive format. Creating an empty “encrypted backup” would be misleading. You can create a pending backup record only for integration testing.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create integration record'))])) ?? false;
    if (!yes) return;
    setState(() => working = true);
    try {
      await ref.read(advancedRepositoryProvider).createBackup({'metadata': {'frontend_state': 'security_review_required', 'requested_from': 'flutter'}});
      await _load();
    } finally { if (mounted) setState(() => working = false); }
  }

  Future<void> _restore(String id) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Request restore?'), content: const Text('This requests restore state from the backend. Decryption/import must still pass the reviewed client-side encryption layer before any private data is replaced.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Request restore'))])) ?? false;
    if (!yes) return;
    await ref.read(advancedRepositoryProvider).restoreBackup(id);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup & Migration')),
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 100), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(26)), child: Column(children: [const Icon(Icons.cloud_lock_outlined, color: AppColors.rose, size: 42), const SizedBox(height: 10), Text('Protect your shared history', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), const Text('Backup UX is ready, but private archives must not be called encrypted until a reviewed cryptographic format is integrated.', textAlign: TextAlign.center)])),
        const SizedBox(height: 14),
        Card(child: ListTile(leading: const Icon(Icons.info_outline, color: AppColors.rose), title: Text('Latest status: ${status['status'] ?? 'No backup yet'}'), subtitle: Text('${status['updated_at'] ?? status['created_at'] ?? 'Backup has not been created.'}'))),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: working ? null : _requestBackup, icon: const Icon(Icons.cloud_upload_outlined), label: const Text('Create backup integration record')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceMigrationScreen())), icon: const Icon(Icons.phonelink_ring), label: const Text('Move to a new device')),
        const SizedBox(height: 20),
        Text('Backup history', style: Theme.of(context).textTheme.titleLarge),
        if (backups.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No backups yet.', style: TextStyle(color: AppColors.muted))),
        ...backups.map((b) => Card(child: ListTile(leading: Icon('${b['status']}' == 'completed' ? Icons.cloud_done_outlined : Icons.cloud_queue, color: AppColors.rose), title: Text('${b['status'] ?? 'pending'}'), subtitle: Text('${b['created_at'] ?? ''}'), trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'restore') await _restore('${b['id']}'); if (v == 'delete') { await ref.read(advancedRepositoryProvider).deleteBackup('${b['id']}'); _load(); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'restore', child: Text('Request restore')), PopupMenuItem(value: 'delete', child: Text('Delete backup record'))])))),
        const SizedBox(height: 16),
        const Card(child: ListTile(leading: Icon(Icons.security_rounded, color: AppColors.rose), title: Text('SECURITY REVIEW REQUIRED'), subtitle: Text('Identity keys, secure private-key storage, session establishment, message/media encryption, encrypted backup archive format and recovery-key handling require a reviewed protocol/library and device QA. No custom cryptography has been invented here.'))),
      ]),
    ),
  );
}

class WidgetsScreen extends ConsumerStatefulWidget {
  const WidgetsScreen({super.key});
  @override
  ConsumerState<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends ConsumerState<WidgetsScreen> {
  bool loading = true, saving = false;
  Map<String, dynamic> config = {}, preview = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = ref.read(advancedRepositoryProvider);
      final x = await Future.wait([r.widgetConfig(), r.widgetData()]);
      config = _flatten(x[0] as Map<String, dynamic>);
      preview = x[1] as Map<String, dynamic>;
    } catch (_) {
      config = {'partner_status': true, 'anniversary': true, 'next_date': true, 'memory': true, 'mood': true, 'quick_ping': true, 'lock_screen_sensitive_text': false};
    } finally { if (mounted) setState(() => loading = false); }
  }

  Map<String, dynamic> _flatten(Map<String, dynamic> m) => m['data'] is Map ? (m['data'] as Map).cast<String, dynamic>() : m;

  bool _v(String key, [bool fallback = false]) => config[key] is bool ? config[key] as bool : fallback;

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await ref.read(advancedRepositoryProvider).updateWidgetConfig(config);
      preview = await ref.read(homeWidgetServiceProvider).sync();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Widget preferences saved and native widget data refreshed.')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home & Lock Screen Widgets')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 100), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(26)), child: Column(children: [const Icon(Icons.widgets_rounded, color: AppColors.rose, size: 42), const SizedBox(height: 8), Text('A little piece of “us” outside the app', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), const Text('Choose only what is safe to show. Highly sensitive text stays hidden on the lock screen by default.', textAlign: TextAlign.center)])),
      const SizedBox(height: 14),
      _toggle('partner_status', 'Partner status', Icons.person_pin_circle_outlined),
      _toggle('anniversary', 'Days together / anniversary', Icons.favorite_outline),
      _toggle('next_date', 'Next date', Icons.event_outlined),
      _toggle('memory', 'On this day memory', Icons.photo_album_outlined),
      _toggle('mood', 'Partner mood', Icons.mood_outlined),
      _toggle('quick_ping', 'Quick Ping', Icons.touch_app_outlined),
      SwitchListTile(value: _v('lock_screen_sensitive_text'), title: const Text('Allow sensitive text on lock screen'), subtitle: const Text('Off by default. Keep this disabled unless both partners explicitly want it.'), secondary: const Icon(Icons.lock_outline, color: AppColors.rose), onChanged: (v) => setState(() => config['lock_screen_sensitive_text'] = v)),
      const SizedBox(height: 12),
      if (saving) const LinearProgressIndicator(),
      FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('Save widget preferences')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () async { final synced = await ref.read(homeWidgetServiceProvider).sync(); if (mounted) setState(() => preview = synced); }, icon: const Icon(Icons.sync), label: const Text('Refresh native widget'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: () async { await ref.read(advancedRepositoryProvider).widgetPing(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quick Ping sent through the backend.'))); }, icon: const Icon(Icons.favorite_rounded), label: const Text('Test Quick Ping'))),
      ]),
      const SizedBox(height: 20),
      Text('Widget preview data', style: Theme.of(context).textTheme.titleLarge),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${preview['partner_status'] ?? 'Partner status'}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('${preview['anniversary'] ?? preview['days_together'] ?? 'Days together'}'), Text('${preview['next_date'] ?? ''}', style: const TextStyle(color: AppColors.muted))]))),
      const SizedBox(height: 12),
      const Text('Native host templates are included for Android and iOS. Final widget signing/App Group configuration must be completed in the platform projects and tested on physical devices.', style: TextStyle(color: AppColors.muted)),
    ]),
  );

  Widget _toggle(String key, String title, IconData icon) => SwitchListTile(value: _v(key, true), title: Text(title), secondary: Icon(icon, color: AppColors.rose), onChanged: (v) => setState(() => config[key] = v));
}
