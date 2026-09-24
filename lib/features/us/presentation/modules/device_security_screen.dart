import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class LinkedDevicesScreen extends ConsumerStatefulWidget {
  const LinkedDevicesScreen({super.key});
  @override
  ConsumerState<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends ConsumerState<LinkedDevicesScreen> {
  bool loading = true, working = false;
  List<Map<String, dynamic>> devices = [];
  Map<String, dynamic>? intent;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try { devices = await ref.read(advancedRepositoryProvider).linkedDevices(); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _createIntent() async {
    setState(() => working = true);
    try {
      final id = ref.read(deviceIdentityServiceProvider);
      intent = await ref.read(advancedRepositoryProvider).createLinkIntent({'device_name': id.defaultName});
      if (mounted) setState(() {});
    } finally { if (mounted) setState(() => working = false); }
  }

  Future<void> _scanAndConfirm() async {
    final payload = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const DeviceQrScannerScreen(title: 'Scan device-link QR')));
    if (payload == null) return;
    final parsed = _parse(payload, 'device-link');
    if (parsed == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is not a valid 143 device-link QR.')));
      return;
    }
    setState(() => working = true);
    try {
      final identity = ref.read(deviceIdentityServiceProvider);
      await ref.read(advancedRepositoryProvider).confirmLinkIntent(parsed.$1, {
        'link_token': parsed.$2,
        'device_id': await identity.deviceId(),
        'device_name': identity.defaultName,
        'platform': identity.platform,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This device is now linked.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => working = false); }
  }

  (String, String)? _parse(String raw, String segment) {
    try {
      final u = Uri.parse(raw);
      if (u.scheme != '143') return null;
      final parts = u.pathSegments;
      String? id;
      if (u.host == segment && parts.isNotEmpty) id = parts.first;
      if (parts.length >= 2 && parts.first == segment) id = parts[1];
      final token = u.queryParameters['token'];
      if (id == null || id.isEmpty || token == null || token.isEmpty) return null;
      return (id, token);
    } catch (_) { return null; }
  }

  Future<void> _revoke(String id) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Revoke linked device?'), content: const Text('That device will lose its linked-device status. This does not silently delete your account data.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Revoke'))])) ?? false;
    if (!yes) return;
    await ref.read(advancedRepositoryProvider).revokeLinkedDevice(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Linked Devices')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.phonelink_lock_rounded, color: AppColors.rose, size: 34),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Link another signed-in device using a short-lived QR token. You can revoke linked devices at any time.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: working ? null : _createIntent,
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Show linking QR'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: working ? null : _scanAndConfirm,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR'),
                        ),
                      ),
                    ],
                  ),
                  if (intent != null) ...[
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            const Text(
                              'Scan on the new device',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            QrImageView(
                              data: '${intent!['qr_payload'] ?? ''}',
                              size: 210,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Expires: ${intent!['expires_at'] ?? 'soon'}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text('Linked devices', style: Theme.of(context).textTheme.titleLarge),
                  if (devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No linked devices yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ...devices.map(
                    (d) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.devices_rounded, color: AppColors.rose),
                        title: Text(
                          '${d['title'] ?? d['name'] ?? d['device_name'] ?? 'Linked device'}',
                        ),
                        subtitle: Text(
                          '${d['status'] ?? 'active'} • ${d['data'] is Map ? d['data']['platform'] ?? '' : ''}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Revoke device',
                          icon: const Icon(Icons.link_off),
                          onPressed: () => _revoke('${d['id']}'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class DeviceMigrationScreen extends ConsumerStatefulWidget {
  const DeviceMigrationScreen({super.key});
  @override
  ConsumerState<DeviceMigrationScreen> createState() => _DeviceMigrationScreenState();
}

class _DeviceMigrationScreenState extends ConsumerState<DeviceMigrationScreen> {
  Map<String, dynamic>? prepared;
  bool working = false;

  Future<void> _prepare() async {
    setState(() => working = true);
    try {
      final device = ref.read(deviceIdentityServiceProvider);
      prepared = await ref.read(advancedRepositoryProvider).prepareMigration({'from_device': {'device_id': await device.deviceId(), 'name': device.defaultName, 'platform': device.platform}});
      if (mounted) setState(() {});
    } finally { if (mounted) setState(() => working = false); }
  }

  Future<void> _scanConfirm() async {
    final raw = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const DeviceQrScannerScreen(title: 'Scan migration QR')));
    if (raw == null) return;
    final parsed = _parseMigration(raw);
    if (parsed == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or incomplete migration QR.'))); return; }
    setState(() => working = true);
    try {
      final d = ref.read(deviceIdentityServiceProvider);
      await ref.read(advancedRepositoryProvider).confirmMigration({'migration_id': parsed.$1, 'transfer_token': parsed.$2, 'new_device': {'device_id': await d.deviceId(), 'name': d.defaultName, 'platform': d.platform}});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Migration handoff confirmed. Encrypted payload transfer still requires the reviewed encryption layer.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => working = false); }
  }

  (String, String)? _parseMigration(String raw) {
    try {
      final u = Uri.parse(raw);
      if (u.scheme != '143') return null;
      String? id;
      if (u.host == 'migration' && u.pathSegments.isNotEmpty) id = u.pathSegments.first;
      if (u.pathSegments.length >= 2 && u.pathSegments.first == 'migration') id = u.pathSegments[1];
      final token = u.queryParameters['token'];
      if (id == null || token == null) return null;
      return (id, token);
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Move to a New Device')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(26)), child: const Column(children: [Icon(Icons.phonelink_ring_rounded, color: AppColors.rose, size: 42), SizedBox(height: 10), Text('Private device handoff', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), SizedBox(height: 6), Text('The backend provides a short-lived migration token. Private content must only be transferred after a reviewed encrypted-transfer implementation is available.', textAlign: TextAlign.center)])),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: working ? null : _prepare, icon: const Icon(Icons.qr_code_2), label: const Text('Prepare on old device')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: working ? null : _scanConfirm, icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan on new device')),
      if (prepared != null) ...[
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [QrImageView(data: '${prepared!['qr_payload'] ?? ''}', size: 220, backgroundColor: Colors.white), const SizedBox(height: 10), Text('Expires: ${prepared!['expires_at'] ?? 'soon'}')]))),
      ],
      const SizedBox(height: 18),
      const Card(child: ListTile(leading: Icon(Icons.security_rounded, color: AppColors.rose), title: Text('SECURITY REVIEW REQUIRED'), subtitle: Text('The QR/token coordination is real. End-to-end encrypted payload transfer and recovery-key cryptography are not claimed complete until a reviewed protocol/library is integrated and device-tested.'))),
    ]),
  );
}

class DeviceQrScannerScreen extends StatefulWidget {
  const DeviceQrScannerScreen({super.key, required this.title});
  final String title;
  @override
  State<DeviceQrScannerScreen> createState() => _DeviceQrScannerScreenState();
}

class _DeviceQrScannerScreenState extends State<DeviceQrScannerScreen> {
  bool done = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: MobileScanner(onDetect: (capture) {
      if (done) return;
      final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
      if (value == null || value.isEmpty) return;
      done = true;
      Navigator.pop(context, value);
    }),
  );
}
