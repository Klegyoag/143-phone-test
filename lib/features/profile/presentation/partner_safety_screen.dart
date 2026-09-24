import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';

class PartnerSafetyScreen extends ConsumerStatefulWidget {
  const PartnerSafetyScreen({super.key});
  @override
  ConsumerState<PartnerSafetyScreen> createState() =>
      _PartnerSafetyScreenState();
}

class _PartnerSafetyScreenState extends ConsumerState<PartnerSafetyScreen> {
  bool loading = true, blocked = false;
  String? error, userId, partnerName;

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
      final bundle = await ref.read(homeRepositoryProvider).load();
      final home = bundle.home;
      final partner = home['partner'] is Map
          ? (home['partner'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      userId = partner['id']?.toString();
      partnerName =
          '${partner['display_name'] ?? partner['username'] ?? 'Partner'}';
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Block & Report')),
        body: loading
            ? const AppLoadingState()
            : error != null
                ? AppErrorState(message: error!, onRetry: _load)
                : userId == null
                    ? const AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'No partner linked',
                        message:
                            'These controls become available after a partner is linked.')
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  color: AppColors.blush,
                                  borderRadius: BorderRadius.circular(24)),
                              child: const Text(
                                  'Use these controls only when needed. Blocking and reporting are explicit safety actions and are sent to the backend.')),
                          const SizedBox(height: 16),
                          Card(
                              child: SwitchListTile(
                                  secondary: const Icon(Icons.block_rounded,
                                      color: AppColors.rose),
                                  title: Text(blocked
                                      ? 'Unblock $partnerName'
                                      : 'Block $partnerName'),
                                  subtitle: const Text(
                                      'Block or unblock this user through your private account controls.'),
                                  value: blocked,
                                  onChanged: _setBlocked)),
                          const SizedBox(height: 8),
                          Card(
                              child: ListTile(
                                  leading: const Icon(Icons.flag_outlined,
                                      color: Colors.redAccent),
                                  title: const Text('Report user'),
                                  subtitle: const Text(
                                      'Send a reason and optional details to the backend.'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _report)),
                        ],
                      ),
      );

  Future<void> _setBlocked(bool v) async {
    try {
      if (v)
        await ref.read(profileRepositoryProvider).blockUser(userId!);
      else
        await ref.read(profileRepositoryProvider).unblockUser(userId!);
      if (mounted) setState(() => blocked = v);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _report() async {
    String reason = 'safety_concern';
    final details = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (context, setLocal) => AlertDialog(
                  title: const Text('Report user'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<String>(
                        value: reason,
                        decoration: const InputDecoration(labelText: 'Reason'),
                        items: const [
                          DropdownMenuItem(
                              value: 'safety_concern',
                              child: Text('Safety concern')),
                          DropdownMenuItem(
                              value: 'harassment', child: Text('Harassment')),
                          DropdownMenuItem(
                              value: 'spam', child: Text('Spam / misuse')),
                          DropdownMenuItem(value: 'other', child: Text('Other'))
                        ],
                        onChanged: (v) {
                          if (v != null) setLocal(() => reason = v);
                        }),
                    const SizedBox(height: 12),
                    TextField(
                        controller: details,
                        maxLines: 4,
                        decoration: const InputDecoration(
                            labelText: 'Optional details')),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Submit report'))
                  ],
                )));
    if (ok == true) {
      try {
        await ref.read(profileRepositoryProvider).reportUser(
            userId: userId!, reason: reason, details: details.text.trim());
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Report submitted.')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    details.dispose();
  }
}
