import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'calendar_screen.dart';
import 'scheduled_love_screen.dart';

class RomanticInteractionScreen extends ConsumerStatefulWidget {
  const RomanticInteractionScreen({super.key});

  @override
  ConsumerState<RomanticInteractionScreen> createState() => _RomanticInteractionScreenState();
}

class _RomanticInteractionScreenState extends ConsumerState<RomanticInteractionScreen> {
  bool loading = true;
  bool sendingPing = false;
  DateTime? pingCooldownUntil;
  Timer? _timer;
  List<Map<String, dynamic>> pings = const [];
  List<Map<String, dynamic>> reminders = const [];
  List<Map<String, dynamic>> checkIns = const [];
  List<Map<String, dynamic>> streaks = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && pingCooldownUntil != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final repo = ref.read(relationshipToolsRepositoryProvider);
    try {
      final values = await Future.wait([repo.pings(), repo.reminders(), repo.checkIns(), repo.streaks()]);
      if (!mounted) return;
      setState(() {
        pings = values[0];
        reminders = values[1];
        checkIns = values[2];
        streaks = values[3];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not refresh connection tools: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Duration get _cooldownRemaining {
    final until = pingCooldownUntil;
    if (until == null) return Duration.zero;
    final d = until.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> _sendPing() async {
    if (_cooldownRemaining > Duration.zero || sendingPing) return;
    setState(() => sendingPing = true);
    try {
      await ref.read(relationshipToolsRepositoryProvider).sendPing();
      if (ref.read(appPreferencesProvider).hapticsEnabled) await HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() => pingCooldownUntil = DateTime.now().add(const Duration(seconds: 30)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A little love was sent ♡')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ping failed: $e')));
    } finally {
      if (mounted) setState(() => sendingPing = false);
    }
  }

  Future<void> _react(Map<String, dynamic> ping) async {
    final id = '${ping['id'] ?? ''}';
    if (id.isEmpty) return;
    final reaction = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['❤️', '🥰', '🫶', '😘', '✨']
                .map((r) => ActionChip(label: Text(r, style: const TextStyle(fontSize: 24)), onPressed: () => Navigator.pop(context, r)))
                .toList(),
          ),
        ),
      ),
    );
    if (reaction == null) return;
    await ref.read(relationshipToolsRepositoryProvider).reactToPing(id, reaction);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$reaction sent')));
      _load();
    }
  }

  Future<void> _checkIn() async {
    final note = TextEditingController();
    String mood = 'good';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('A little check-in'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: mood,
              decoration: const InputDecoration(labelText: 'How are we feeling?'),
              items: const [
                DropdownMenuItem(value: 'great', child: Text('🥰 Close & happy')),
                DropdownMenuItem(value: 'good', child: Text('🙂 Doing okay')),
                DropdownMenuItem(value: 'busy', child: Text('😮‍💨 Busy day')),
                DropdownMenuItem(value: 'need_time', child: Text('🌿 Need a little quiet')),
              ],
              onChanged: (v) => setD(() => mood = v ?? mood),
            ),
            const SizedBox(height: 12),
            TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Optional note')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Share check-in')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(relationshipToolsRepositoryProvider).createCheckIn({'type': 'couple_check_in', 'status': mood, 'body': note.text.trim(), 'data': {'mood': mood}});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in saved ♡')));
      _load();
    }
  }

  Future<void> _addReminder() async {
    final title = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(hours: 1));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('Create a couple reminder'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Reminder')),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded, color: AppColors.rose),
              title: Text('${when.toLocal()}'.split('.').first),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: when, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (d == null || !context.mounted) return;
                final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
                if (t == null) return;
                setD(() => when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save reminder')),
          ],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    await ref.read(relationshipToolsRepositoryProvider).createReminder({'title': title.text.trim(), 'type': 'couple_alert', 'scheduled_at': when.toIso8601String(), 'status': 'active'});
    if (mounted) _load();
  }

  String _value(Map<String, dynamic> row, List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && '$v'.trim().isNotEmpty) return '$v';
      final data = row['data'];
      if (data is Map && data[k] != null && '${data[k]}'.trim().isNotEmpty) return '${data[k]}';
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final cooldown = _cooldownRemaining;
    return Scaffold(
      appBar: AppBar(title: const Text('Connection & Romance'), backgroundColor: Colors.transparent),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(children: [
                Icon(Icons.favorite_rounded, color: AppColors.rose, size: 42),
                SizedBox(height: 8),
                Text('Small things that keep you close', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                SizedBox(height: 5),
                Text('Ping, check in, plan something sweet, or leave a reminder for the two of you.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ActionCard(icon: Icons.favorite_outline_rounded, title: cooldown > Duration.zero ? 'Ping • ${cooldown.inSeconds}s' : 'Romantic Ping', subtitle: 'Send a tiny signal', onTap: cooldown > Duration.zero ? null : _sendPing),
                _ActionCard(icon: Icons.volunteer_activism_outlined, title: 'Check In', subtitle: 'Share how today feels', onTap: _checkIn),
                _ActionCard(icon: Icons.calendar_month_outlined, title: 'Date Planner', subtitle: 'Plan time together', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
                _ActionCard(icon: Icons.card_giftcard_rounded, title: 'Surprise', subtitle: 'Create something secret', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledLoveScreen()))),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Connection streaks'),
            if (loading) const LinearProgressIndicator(minHeight: 2) else if (streaks.isEmpty)
              const _EmptyCard('Your connection streaks will appear here as you share moments together.')
            else
              ...streaks.take(4).map((x) => Card(child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.blush, child: Icon(Icons.local_fire_department_outlined, color: AppColors.rose)),
                    title: Text(_value(x, ['title', 'type'], 'Connection streak')),
                    subtitle: Text('${_value(x, ['current_count', 'count', 'days'], '0')} day progress'),
                    trailing: Text(_value(x, ['best_count', 'best', 'longest'], ''), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.rose)),
                  ))),
            const SizedBox(height: 18),
            Row(children: [const Expanded(child: _SectionTitle('Couple reminders')), IconButton(tooltip: 'Add reminder', onPressed: _addReminder, icon: const Icon(Icons.add_circle_outline, color: AppColors.rose))]),
            if (reminders.isEmpty)
              const _EmptyCard('No custom reminders yet.')
            else
              ...reminders.take(6).map((x) => Card(child: ListTile(
                    leading: const Icon(Icons.notifications_none_rounded, color: AppColors.rose),
                    title: Text(_value(x, ['title', 'body'], 'A little reminder')),
                    subtitle: Text(_value(x, ['scheduled_at', 'occurred_at'], '')),
                    trailing: IconButton(
                      tooltip: 'Delete reminder',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async { final id = '${x['id'] ?? ''}'; if (id.isNotEmpty) { await ref.read(relationshipToolsRepositoryProvider).deleteReminder(id); _load(); } },
                    ),
                  ))),
            const SizedBox(height: 18),
            const _SectionTitle('Recent pings'),
            if (pings.isEmpty)
              const _EmptyCard('Your first Romantic Ping will show here ♡')
            else
              ...pings.take(8).map((x) => Card(child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.blush, child: Icon(Icons.favorite_rounded, color: AppColors.rose)),
                    title: const Text('Romantic Ping'),
                    subtitle: Text(_value(x, ['created_at', 'occurred_at'], 'A tiny moment of connection')),
                    trailing: IconButton(tooltip: 'React', onPressed: () => _react(x), icon: const Icon(Icons.add_reaction_outlined, color: AppColors.rose)),
                  ))),
            const SizedBox(height: 18),
            const _SectionTitle('Check-in history'),
            if (checkIns.isEmpty)
              const _EmptyCard('No check-ins yet. Keep this space pressure-free and honest.')
            else
              ...checkIns.take(8).map((x) => Card(child: ListTile(
                    leading: const Icon(Icons.spa_outlined, color: AppColors.rose),
                    title: Text(_value(x, ['status', 'type'], 'Check-in')),
                    subtitle: Text(_value(x, ['body'], _value(x, ['created_at', 'occurred_at'], ''))),
                  ))),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: '$title. $subtitle',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: onTap == null ? Colors.grey.shade100 : AppColors.blush.withValues(alpha: .65), borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Icon(icon, color: onTap == null ? AppColors.muted : AppColors.rose),
              const SizedBox(width: 10),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, maxLines: 2, style: const TextStyle(fontSize: 12, color: AppColors.muted))])),
            ]),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)));
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(text, style: const TextStyle(color: AppColors.muted))));
}
