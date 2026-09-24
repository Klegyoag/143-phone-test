import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';

class CoupleSettingsScreen extends ConsumerStatefulWidget {
  const CoupleSettingsScreen({super.key});

  @override
  ConsumerState<CoupleSettingsScreen> createState() => _CoupleSettingsScreenState();
}

class _CoupleSettingsScreenState extends ConsumerState<CoupleSettingsScreen> {
  bool loading = true;
  Map<String, dynamic> current = const {};
  Map<String, dynamic> relationship = const {};
  List<Map<String, dynamic>> presence = const [];
  Map<String, dynamic>? invite;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final repo = ref.read(coupleRepositoryProvider);
      final values = await Future.wait([repo.current(), repo.relationship(), repo.presence()]);
      if (!mounted) return;
      setState(() {
        current = values[0] ?? <String, dynamic>{};
        relationship = values[1] ?? <String, dynamic>{};
        presence = values[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load couple settings: $e')));
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _editRelationship() async {
    final anniversaryRaw = '${relationship['anniversary_date'] ?? ''}';
    DateTime? anniversary = DateTime.tryParse(anniversaryRaw);
    bool absence = relationship['absence_mode'] == true || relationship['absence_mode'] == 1;
    String distance = '${relationship['distance_status'] ?? 'With you'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Relationship settings'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite_outline, color: AppColors.rose),
              title: const Text('Anniversary date'),
              subtitle: Text(anniversary == null ? 'Not set' : '${anniversary!.year}-${anniversary!.month.toString().padLeft(2,'0')}-${anniversary!.day.toString().padLeft(2,'0')}'),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: anniversary ?? DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime.now().add(const Duration(days: 3650)));
                if (picked != null) setD(() => anniversary = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: absence,
              onChanged: (v) => setD(() => absence = v),
              title: const Text('Absence Mode'),
              subtitle: const Text('A gentle status for times when one of you is away.'),
            ),
            DropdownButtonFormField<String>(
              value: ['With you','A bit far'].contains(distance) ? distance : 'With you',
              decoration: const InputDecoration(labelText: 'Relationship distance status'),
              items: const [DropdownMenuItem(value: 'With you', child: Text('With you')), DropdownMenuItem(value: 'A bit far', child: Text('A bit far'))],
              onChanged: (v) => setD(() => distance = v ?? distance),
            ),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(coupleRepositoryProvider).updateRelationship({
      'anniversary_date': anniversary == null ? null : '${anniversary!.year}-${anniversary!.month.toString().padLeft(2,'0')}-${anniversary!.day.toString().padLeft(2,'0')}',
      'absence_mode': absence,
      'distance_status': distance,
    });
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relationship settings updated ♡'))); _load(); }
  }

  Future<void> _createInvite() async {
    final value = await ref.read(coupleRepositoryProvider).createInvite();
    if (mounted) setState(() => invite = value);
  }

  Future<void> _regenerate() async {
    final id = '${invite?['invite_id'] ?? ''}';
    if (id.isEmpty) return _createInvite();
    final value = await ref.read(coupleRepositoryProvider).regenerateInvite(id);
    if (mounted) setState(() => invite = value);
  }

  Future<void> _revoke() async {
    final id = '${invite?['invite_id'] ?? ''}';
    if (id.isEmpty) return;
    await ref.read(coupleRepositoryProvider).revokeInvite(id);
    if (mounted) { setState(() => invite = null); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite revoked.'))); }
  }

  Future<void> _leave() async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Leave this couple space?'),
      content: const Text('You will be unlinked from this private space. Shared data is not silently deleted by this action.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave space'))],
    ));
    if (yes != true) return;
    await ref.read(coupleRepositoryProvider).leaveCurrent();
    if (mounted) context.go('/couple-setup');
  }

  @override
  Widget build(BuildContext context) {
    final space = current['space'] is Map ? (current['space'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final members = current['members'] is List ? (current['members'] as List).whereType<Map>().toList() : const <Map>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Our Space Settings'), backgroundColor: Colors.transparent),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 80), children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(28)),
            child: Column(children: [
              const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 40),
              const SizedBox(height: 8),
              Text('${space['name'] ?? 'Our little world'}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text('${members.length} of 2 people linked', style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
          if (loading) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(minHeight: 2)),
          const SizedBox(height: 18),
          Card(child: ListTile(leading: const Icon(Icons.tune_rounded, color: AppColors.rose), title: const Text('Relationship settings', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${relationship['distance_status'] ?? 'With you'} • Anniversary ${relationship['anniversary_date'] ?? 'not set'}'), trailing: const Icon(Icons.chevron_right), onTap: _editRelationship)),
          const SizedBox(height: 8),
          const Text('Presence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          if (presence.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Presence will appear when devices report online/away state.', style: TextStyle(color: AppColors.muted)))) else ...presence.map((p) => Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.blush, child: Icon('${p['status']}' == 'online' ? Icons.circle : Icons.schedule, color: AppColors.rose, size: 18)),
            title: Text('Partner/device ${p['user_id'] ?? ''}'),
            subtitle: Text('${p['status'] ?? 'unknown'} • last seen ${p['last_seen_at'] ?? ''}'),
          ))),
          const SizedBox(height: 16),
          Row(children: [const Expanded(child: Text('Partner invite', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), TextButton.icon(onPressed: members.length >= 2 ? null : _createInvite, icon: const Icon(Icons.add_link), label: const Text('New invite'))]),
          if (members.length >= 2)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('This couple space is full — 143 allows exactly two people.', style: TextStyle(color: AppColors.muted))))
          else if (invite == null)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Generate a short-lived invite when your partner is ready.')))
          else
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              Container(color: Colors.white, padding: const EdgeInsets.all(10), child: QrImageView(data: '143://invite/${invite!['token'] ?? ''}', size: 150)),
              const SizedBox(height: 10),
              Text('${invite!['join_code'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.rose, letterSpacing: 3, fontSize: 18)),
              Text('Expires ${invite!['expires_at'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: _regenerate, icon: const Icon(Icons.refresh), label: const Text('Regenerate')), TextButton.icon(onPressed: _revoke, icon: const Icon(Icons.link_off), label: const Text('Revoke'))]),
            ]))),
          const SizedBox(height: 22),
          OutlinedButton.icon(onPressed: _leave, icon: const Icon(Icons.heart_broken_outlined), label: const Text('Leave / unlink couple space')),
        ]),
      ),
    );
  }
}
