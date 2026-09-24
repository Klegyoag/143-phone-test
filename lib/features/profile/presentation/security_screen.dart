import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import 'partner_safety_screen.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});
  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  Map<String, dynamic> settings = {};
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try { settings = await ref.read(profileRepositoryProvider).securitySettings(); }
    catch (e) { error = '$e'; }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Security')),
    body: loading ? const AppLoadingState(label: 'Checking your security…') : error != null ? AppErrorState(message: error!, onRetry: _load) : ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(24)), child: const Row(children: [Icon(Icons.lock_rounded, color: AppColors.rose), SizedBox(width: 12), Expanded(child: Text('Security controls stay calm and clear. Sensitive actions always require an explicit choice.'))])),
        const SizedBox(height: 16),
        Consumer(builder: (context, ref, _) {
          final lock = ref.watch(appLockServiceProvider);
          return Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.screen_lock_portrait_rounded, color: AppColors.rose),
                title: const Text('Device app lock'),
                subtitle: const Text('Lock 143 when it leaves the foreground.'),
                value: lock.enabled,
                onChanged: (v) async { try { await lock.setEnabled(v); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.rose),
                title: const Text('Biometric / device authentication'),
                subtitle: const Text('Uses Face ID, fingerprint, or your device lock through the OS.'),
                value: lock.biometricEnabled,
                onChanged: lock.enabled
                    ? (v) async {
                        try { await lock.setBiometricEnabled(v); }
                        catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
                      }
                    : null,
              ),
            ]),
          );
        }),
        Consumer(builder: (context, ref, _) {
          final lock = ref.watch(appLockServiceProvider);
          return Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.pin_rounded, color: AppColors.rose), title: Text(lock.hasPin ? 'Change local PIN' : 'Set local PIN'), subtitle: const Text('4–6 digits, stored as a one-way hash in OS secure storage.'), trailing: const Icon(Icons.chevron_right), onTap: _setPin),
            if (lock.hasPin) ...[const Divider(height: 1), ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Remove local PIN'), onTap: _removePin)],
          ]));
        }),
        ListTile(leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.rose), title: const Text('Block & report'), subtitle: const Text('Partner safety controls'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerSafetyScreen()))),
        const SizedBox(height: 8),
        ...settings.entries.where((e) => e.value is bool).map((e) => SwitchListTile(
          value: e.value as bool,
          title: Text(_pretty(e.key)),
          onChanged: (v) => _toggle(e.key, v),
        )),
        ListTile(
          leading: const Icon(Icons.key_rounded, color: AppColors.rose),
          title: const Text('Regenerate recovery code'),
          subtitle: const Text('Replaces the old code and requires immediate save + confirmation.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async { await context.push('/regenerate-recovery-code'); if (mounted) _load(); },
        ),
        ListTile(leading: const Icon(Icons.password_rounded, color: AppColors.rose), title: const Text('Change password'), trailing: const Icon(Icons.chevron_right), onTap: _changePassword),
        ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Log out of this device'), subtitle: const Text('Ends only the current session.'), onTap: _logoutCurrent),
        ListTile(leading: const Icon(Icons.devices_other_rounded), title: const Text('Log out from all devices'), onTap: _logoutAll),
        const Divider(height: 32),
        ListTile(leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent), title: const Text('Delete account', style: TextStyle(color: Colors.redAccent)), subtitle: const Text('Permanent and cannot be undone.'), onTap: _deleteAccount),
      ],
    ),
  );

  String _pretty(String s) => s.replaceAll('_', ' ').split(' ').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  Future<void> _toggle(String key, bool value) async {
    setState(() => settings[key] = value);
    try { await ref.read(profileRepositoryProvider).updateSecuritySettings({key: value}); }
    catch (e) { if (mounted) { setState(() => settings[key] = !value); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
  }


  Future<void> _setPin() async {
    final a = TextEditingController(); final b = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Set 143 PIN'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: a, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: '4–6 digit PIN')), TextField(controller: b, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Confirm PIN'))]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save PIN'))]));
    if (ok == true) {
      if (a.text != b.text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match.'))); }
      else { try { await ref.read(appLockServiceProvider).setPin(a.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local PIN saved.'))); } catch(e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
    }
    a.dispose(); b.dispose();
  }
  Future<void> _removePin() async { await ref.read(appLockServiceProvider).clearPin(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local PIN removed.'))); }

  Future<void> _changePassword() async {
    final old = TextEditingController(); final next = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Change password'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), const SizedBox(height: 12), TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password'))]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Update'))]));
    if (ok == true) {
      try { await ref.read(profileRepositoryProvider).changePassword(currentPassword: old.text, password: next.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.'))); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    }
    old.dispose(); next.dispose();
  }


  Future<void> _logoutCurrent() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Log out of this device?'), content: const Text('Your other active sessions will stay signed in.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out'))]));
    if (ok == true) { await ref.read(authRepositoryProvider).logout(); if (mounted) context.go('/login'); }
  }

  Future<void> _logoutAll() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Log out everywhere?'), content: const Text('Every active session will be signed out, including this device.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out all'))]));
    if (ok == true) { await ref.read(profileRepositoryProvider).logoutAll(); if (mounted) context.go('/login'); }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete account?'), content: const Text('This is permanent. Your account and associated data will be handled according to the backend deletion policy.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep account')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))]));
    if (ok == true) { try { await ref.read(profileRepositoryProvider).deleteAccount(); if (mounted) context.go('/'); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
  }
}
