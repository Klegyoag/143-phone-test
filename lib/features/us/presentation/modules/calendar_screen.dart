import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarState();
}

class _CalendarState extends ConsumerState<CalendarScreen> {
  bool loading = true;
  List<Map<String, dynamic>> events = [];
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      events = await ref.read(coupleLifeRepositoryProvider).calendarEvents();
    } catch (e) {
      _toast('$e');
    }
    if (mounted) setState(() => loading = false);
  }

  void _toast(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editor([Map<String, dynamic>? existing]) async {
    final data = existing?['data'] is Map
        ? (existing!['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final title = TextEditingController(text: '${existing?['title'] ?? ''}');
    final note = TextEditingController(text: '${data['note'] ?? ''}');
    final location = TextEditingController(text: '${data['location'] ?? ''}');
    DateTime when =
        DateTime.tryParse('${existing?['starts_at'] ?? ''}')?.toLocal() ??
            DateTime.now().add(const Duration(days: 1));
    String type = '${existing?['type'] ?? 'date_night'}';
    String recurrence =
        '${data['recurrence'] ?? (data['recurring'] == true ? 'yearly' : 'none')}';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    existing == null
                        ? 'Plan something together ♡'
                        : 'Edit our plan',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextField(
                    controller: title,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'date_night', child: Text('Date night')),
                    DropdownMenuItem(
                        value: 'birthday', child: Text('Birthday')),
                    DropdownMenuItem(
                        value: 'anniversary', child: Text('Anniversary')),
                    DropdownMenuItem(value: 'trip', child: Text('Trip')),
                    DropdownMenuItem(
                        value: 'special', child: Text('Special day')),
                  ],
                  onChanged: (value) => setSheetState(() => type = value!),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: AppColors.rose),
                  title: Text(MaterialLocalizations.of(sheetContext)
                      .formatFullDate(when)),
                  subtitle:
                      Text(TimeOfDay.fromDateTime(when).format(sheetContext)),
                  onTap: () async {
                    final date = await showDatePicker(
                        context: sheetContext,
                        initialDate: when,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (date == null) return;
                    final time = await showTimePicker(
                        context: sheetContext,
                        initialTime: TimeOfDay.fromDateTime(when));
                    if (time != null)
                      setSheetState(() => when = DateTime(date.year, date.month,
                          date.day, time.hour, time.minute));
                  },
                ),
                TextField(
                    controller: location,
                    decoration: const InputDecoration(
                        labelText: 'Location (optional)')),
                const SizedBox(height: 10),
                TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Note')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: recurrence,
                  decoration: const InputDecoration(labelText: 'Repeat'),
                  items: const [
                    DropdownMenuItem(
                        value: 'none', child: Text('Does not repeat')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => recurrence = value!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(
                            existing == null ? 'Save plan' : 'Save changes'))),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;

    final payload = {
      'title': title.text.trim(),
      'type': type,
      'starts_at': when.toUtc().toIso8601String(),
      'data': {
        'recurring': recurrence != 'none',
        'recurrence': recurrence,
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
        if (location.text.trim().isNotEmpty) 'location': location.text.trim(),
      },
    };
    try {
      if (existing == null) {
        await ref.read(coupleLifeRepositoryProvider).createCalendarEvent(
              title: title.text.trim(),
              startsAt: when,
              type: type,
              note: note.text,
              location: location.text,
              recurring: recurrence != 'none',
              recurrence: recurrence,
            );
      } else {
        await ref
            .read(coupleLifeRepositoryProvider)
            .updateCalendarEvent('${existing['id']}', payload);
      }
      await _load();
    } catch (e) {
      _toast('Could not save plan: $e');
    }
  }

  Future<void> _details(Map<String, dynamic> event) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CalendarDetailScreen(
                event: event, onEdit: () => _editor(event))));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = events.where((event) {
      final date = DateTime.tryParse('${event['starts_at'] ?? ''}')?.toLocal();
      return date == null ||
          (date.year == month.year && date.month == month.month);
    }).toList()
      ..sort((a, b) =>
          '${a['starts_at'] ?? ''}'.compareTo('${b['starts_at'] ?? ''}'));

    return Scaffold(
      appBar: AppBar(title: const Text('Our Calendar'), actions: [
        IconButton(
            onPressed: () => _editor(),
            tooltip: 'Add plan',
            icon: const Icon(Icons.add_rounded))
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                children: [
                  Semantics(
                    label:
                        '${_monthName(month.month)} ${month.year}, ${visible.length} plans',
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          gradient: AppColors.heroGradient(context),
                          borderRadius: BorderRadius.circular(26)),
                      child: Row(children: [
                        IconButton(
                            onPressed: () => setState(() =>
                                month = DateTime(month.year, month.month - 1)),
                            tooltip: 'Previous month',
                            icon: const Icon(Icons.chevron_left)),
                        Expanded(
                            child: Column(children: [
                          const Icon(Icons.favorite_outline,
                              color: AppColors.rose),
                          Text('${_monthName(month.month)} ${month.year}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 20)),
                          Text('${visible.length} plans this month',
                              style: TextStyle(
                                  color: AppColors.secondaryText(context),
                                  fontSize: 12))
                        ])),
                        IconButton(
                            onPressed: () => setState(() =>
                                month = DateTime(month.year, month.month + 1)),
                            tooltip: 'Next month',
                            icon: const Icon(Icons.chevron_right)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (visible.isEmpty)
                    const Padding(
                        padding: EdgeInsets.only(top: 90),
                        child: Center(
                            child: Text(
                                'No plans this month. Add your next little adventure ♡')))
                  else
                    ...visible.map((event) =>
                        _EventCard(event: event, onTap: () => _details(event))),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _editor(),
          tooltip: 'Add a shared plan',
          child: const Icon(Icons.add_rounded)),
    );
  }

  String _monthName(int value) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][value - 1];
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final Map<String, dynamic> event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${event['starts_at'] ?? ''}')?.toLocal();
    final data = event['data'] is Map ? event['data'] as Map : const {};
    return Semantics(
      button: true,
      label:
          '${event['title'] ?? 'Plan'}, ${event['type'] ?? ''}, ${date == null ? '' : MaterialLocalizations.of(context).formatFullDate(date)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.cardSurface(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: Row(children: [
            Container(
                width: 52,
                height: 58,
                decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${date?.day ?? '♡'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppColors.rose)),
                      if (date != null)
                        Text('${date.month}/${date.year}',
                            style: const TextStyle(fontSize: 9))
                    ])),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${event['title'] ?? 'Our plan'}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      '${event['type'] ?? 'special'} • ${event['status'] ?? 'planned'}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  if ('${data['recurrence'] ?? 'none'}' != 'none')
                    Text('Repeats ${data['recurrence']}',
                        style: const TextStyle(
                            color: AppColors.rose, fontSize: 11))
                ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

class CalendarDetailScreen extends ConsumerStatefulWidget {
  const CalendarDetailScreen(
      {super.key, required this.event, required this.onEdit});
  final Map<String, dynamic> event;
  final Future<void> Function() onEdit;

  @override
  ConsumerState<CalendarDetailScreen> createState() => _CalendarDetailState();
}

class _CalendarDetailState extends ConsumerState<CalendarDetailScreen> {
  List<Map<String, dynamic>> comments = [];
  List<Map<String, dynamic>> reminders = [];
  final List<Map<String, dynamic>> photos = [];
  final Map<String, String?> photoUrls = {};
  bool loading = true;
  bool working = false;
  String get id => '${widget.event['id']}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(coupleLifeRepositoryProvider);
      final result = await Future.wait([
        repo.calendarComments(id),
        repo.reminders(),
        repo.calendarPhotos(id)
      ]);
      comments = result[0] as List<Map<String, dynamic>>;
      reminders = (result[1] as List<Map<String, dynamic>>).where((reminder) {
        final data =
            reminder['data'] is Map ? reminder['data'] as Map : const {};
        return '${data['calendar_event_id'] ?? reminder['calendar_event_id'] ?? ''}' ==
            id;
      }).toList();
      var serverPhotos = result[2] as List<Map<String, dynamic>>;
      if (serverPhotos.isEmpty)
        serverPhotos = await ref.read(calendarPhotoLocalCacheProvider).read(id);
      photos
        ..clear()
        ..addAll(serverPhotos);
      if (photos.isNotEmpty)
        await ref.read(calendarPhotoLocalCacheProvider).write(id, photos);
      for (final photo in photos) {
        final mediaId = '${photo['media_id'] ?? photo['id'] ?? ''}';
        if (mediaId.isEmpty || photoUrls.containsKey(mediaId)) continue;
        try {
          photoUrls[mediaId] =
              await ref.read(mediaUrlCacheProvider).resolve(mediaId);
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('Delete this plan?'),
                    content: const Text(
                        'This removes the shared calendar event. Existing memories are not deleted.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'))
                    ])) ??
        false;
    if (!ok) return;
    await ref.read(coupleLifeRepositoryProvider).deleteCalendarEvent(id);
    await ref.read(calendarPhotoLocalCacheProvider).clear(id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _comment() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Add a comment'),
                content: TextField(controller: controller, maxLines: 3),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Add'))
                ]));
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(coupleLifeRepositoryProvider)
          .addCalendarComment(id, controller.text.trim());
      await _load();
    }
  }

  Future<void> _reflection() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('How was your date?'),
                content: TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        hintText: 'A little reflection…')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'))
                ]));
    if (ok == true && controller.text.trim().isNotEmpty)
      await ref
          .read(coupleLifeRepositoryProvider)
          .addCalendarReflection(id, controller.text.trim());
  }

  Future<void> _addReminder() async {
    final eventTime =
        DateTime.tryParse('${widget.event['starts_at'] ?? ''}')?.toLocal();
    if (eventTime == null) return;
    Duration offset = const Duration(hours: 1);
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(
              title: Text('Remind us before this plan'),
              subtitle: Text(
                  'The reminder is stored by the 143 backend and can feed push notifications when provider delivery is configured.')),
          ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('30 minutes before'),
              onTap: () => Navigator.pop(context, '30m')),
          ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('1 hour before'),
              onTap: () => Navigator.pop(context, '1h')),
          ListTile(
              leading: const Icon(Icons.today_outlined),
              title: const Text('1 day before'),
              onTap: () => Navigator.pop(context, '1d')),
        ]),
      ),
    );
    if (selection == null) return;
    offset = switch (selection) {
      '30m' => const Duration(minutes: 30),
      '1d' => const Duration(days: 1),
      _ => const Duration(hours: 1)
    };
    final at = eventTime.subtract(offset);
    if (at.isBefore(DateTime.now())) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('That reminder time has already passed.')));
      return;
    }
    await ref.read(coupleLifeRepositoryProvider).createReminder(
        title: '${widget.event['title'] ?? 'Our plan'} reminder',
        scheduledAt: at,
        calendarEventId: id);
    await _load();
  }

  Future<void> _deleteReminder(String reminderId) async {
    await ref.read(coupleLifeRepositoryProvider).deleteReminder(reminderId);
    await _load();
  }

  Future<void> _addPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null) return;
    setState(() => working = true);
    try {
      final bytes = await picked.readAsBytes();
      final mime =
          lookupMimeType(picked.name, headerBytes: bytes.take(16).toList()) ??
              'image/jpeg';
      final upload = await ref.read(mediaRepositoryProvider).upload(
          filename: picked.name,
          mime: mime,
          bytes: bytes,
          metadata: {'context': 'calendar_event', 'calendar_event_id': id});
      final linked = await ref
          .read(coupleLifeRepositoryProvider)
          .addCalendarPhoto(id, upload.id);
      photos.add(linked);
      await ref.read(calendarPhotoLocalCacheProvider).write(id, photos);
      try {
        photoUrls[upload.id] =
            await ref.read(mediaUrlCacheProvider).resolve(upload.id);
      } catch (_) {}
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not attach photo: $e')));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _removePhoto(Map<String, dynamic> photo) async {
    final mediaId =
        '${photo['media_id'] ?? (photo['data'] is Map ? photo['data']['media_id'] : '')}';
    if (mediaId.isEmpty) return;
    await ref
        .read(coupleLifeRepositoryProvider)
        .deleteCalendarPhoto(id, mediaId);
    photos.remove(photo);
    photoUrls.remove(mediaId);
    await ref.read(calendarPhotoLocalCacheProvider).write(id, photos);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final data =
        widget.event['data'] is Map ? widget.event['data'] as Map : const {};
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event['title'] ?? 'Our plan'}'),
        actions: [
          IconButton(
              onPressed: () async {
                await widget.onEdit();
                if (mounted) Navigator.pop(context);
              },
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              onPressed: _delete,
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.blush,
                borderRadius: BorderRadius.circular(24)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  '${widget.event['type'] ?? 'special'}'
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.rose,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
              const SizedBox(height: 8),
              Text('${widget.event['starts_at'] ?? ''}'),
              if ('${data['location'] ?? ''}'.isNotEmpty)
                Text('${data['location']}',
                    style: const TextStyle(color: AppColors.muted)),
              if ('${data['recurrence'] ?? 'none'}' != 'none')
                Text('Repeats ${data['recurrence']}',
                    style: const TextStyle(color: AppColors.rose)),
            ]),
          ),
          if (working)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator()),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(
                label: const Text('Complete'),
                avatar: const Icon(Icons.check, size: 18),
                onPressed: () async {
                  await ref
                      .read(coupleLifeRepositoryProvider)
                      .completeCalendarEvent(id);
                  if (mounted) Navigator.pop(context);
                }),
            ActionChip(
                label: const Text('Turn into Memory'),
                avatar: const Icon(Icons.photo_album_outlined, size: 18),
                onPressed: () async {
                  await ref
                      .read(coupleLifeRepositoryProvider)
                      .convertCalendarEventToMemory(id);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Saved as a milestone memory ♡')));
                }),
            ActionChip(
                label: const Text('Reminder'),
                avatar: const Icon(Icons.notifications_none, size: 18),
                onPressed: _addReminder),
            ActionChip(
                label: const Text('Add photo'),
                avatar:
                    const Icon(Icons.add_photo_alternate_outlined, size: 18),
                onPressed: _addPhoto),
            ActionChip(
                label: const Text('Reflection'),
                avatar: const Icon(Icons.edit_note, size: 18),
                onPressed: _reflection),
            ActionChip(
                label: const Text('Comment'),
                avatar: const Icon(Icons.chat_bubble_outline, size: 18),
                onPressed: _comment),
          ]),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text('Event photos',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final photo = photos[index];
                  final mediaId =
                      '${photo['media_id'] ?? (photo['data'] is Map ? photo['data']['media_id'] : '')}';
                  return Stack(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                            width: 126,
                            height: 126,
                            child: photoUrls[mediaId] == null
                                ? Container(
                                    color: AppColors.blush,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.rose))
                                : Image.network(photoUrls[mediaId]!,
                                    fit: BoxFit.cover))),
                    Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton.filledTonal(
                            onPressed: () => _removePhoto(photo),
                            tooltip: 'Remove photo',
                            icon: const Icon(Icons.close, size: 16))),
                  ]);
                },
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(
                child: Text('Reminders',
                    style: TextStyle(fontWeight: FontWeight.w900))),
            TextButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Add'))
          ]),
          if (reminders.isEmpty)
            const Text('No reminders yet.',
                style: TextStyle(color: AppColors.muted))
          else
            ...reminders.map((reminder) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.rose),
                title: Text('${reminder['title'] ?? 'Plan reminder'}'),
                subtitle: Text(
                    '${reminder['scheduled_at'] ?? (reminder['data'] is Map ? reminder['data']['scheduled_at'] : '')}'),
                trailing: IconButton(
                    onPressed: () => _deleteReminder('${reminder['id']}'),
                    tooltip: 'Remove reminder',
                    icon: const Icon(Icons.delete_outline)))),
          const SizedBox(height: 22),
          const Text('Comments', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (loading)
            const LinearProgressIndicator()
          else if (comments.isEmpty)
            const Text('No comments yet.',
                style: TextStyle(color: AppColors.muted))
          else
            ...comments.map((comment) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    child: Icon(Icons.favorite_outline, size: 17)),
                title: Text('${comment['body'] ?? ''}'),
                subtitle: Text('${comment['created_at'] ?? ''}'))),
          const SizedBox(height: 16),
          const Card(
              child: ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.rose),
                  title: Text('Photo reload boundary'),
                  subtitle: Text(
                      'The current backend can add and remove calendar-event photos, but it does not expose a calendar-photo collection read route. Attached photos stay visible in this session; server-authoritative reload remains integration pending.'))),
        ],
      ),
    );
  }
}
