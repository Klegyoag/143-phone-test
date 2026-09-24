import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/memory_repository.dart';

class MemoryCreateScreen extends ConsumerStatefulWidget {
  const MemoryCreateScreen({super.key, this.initialType = 'moment', this.existing});
  final String initialType;
  final MemoryItem? existing;

  @override
  ConsumerState<MemoryCreateScreen> createState() => _State();
}

class _State extends ConsumerState<MemoryCreateScreen> {
  late String type;
  final title = TextEditingController();
  final body = TextEditingController();
  final tags = TextEditingController();
  final picker = ImagePicker();
  final List<MemoryAttachment> attachments = [];
  bool saving = false;
  String? uploadingLabel;
  double? uploadProgress;
  MemoryLocation? location;
  DateTime? revealAt;

  bool get editing => widget.existing != null;
  bool get isCapsule => type == 'time_capsule';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    type = e?.type ?? widget.initialType;
    title.text = e?.title ?? '';
    body.text = e?.body ?? '';
    tags.text = e?.tags.join(', ') ?? '';
    revealAt = e?.revealAt;
    attachments.addAll(e?.attachments ?? const []);
    location = e?.location;
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(editing ? 'Edit memory' : 'Create memory'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: const {
                'moment': 'Moment',
                'letter': 'Letter',
                'time_capsule': 'Time Capsule',
                'love_note': 'Love Note',
                'promise': 'Promise',
                'milestone': 'Milestone',
              }.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: editing ? null : (v) => setState(() => type = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: body,
              minLines: 7,
              maxLines: 14,
              decoration: const InputDecoration(labelText: 'Write from the heart…', alignLabelWithHint: true),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tags,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'trip, anniversary, silly moment',
                helperText: 'Separate tags with commas.',
              ),
            ),
            if (isCapsule) ...[
              const SizedBox(height: 18),
              _CapsuleDateCard(
                revealAt: revealAt,
                onPick: _pickRevealDate,
                onClear: () => setState(() => revealAt = null),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(onPressed: saving ? null : _showAttachmentSheet, icon: const Icon(Icons.add_rounded), label: const Text('Add')),
              ],
            ),
            if (uploadingLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10), Expanded(child: Text(uploadingLabel!))]),
                  if (uploadProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: uploadProgress),
                  ],
                ]),
              ),
            if (attachments.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.blush.withValues(alpha: .45), borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [Icon(Icons.collections_outlined, color: AppColors.rose), SizedBox(width: 12), Expanded(child: Text('Add photos, videos, documents or files to this memory.'))]),
              )
            else
              ...attachments.asMap().entries.map((entry) => _AttachmentTile(
                    attachment: entry.value,
                    onRemove: () => setState(() => attachments.removeAt(entry.key)),
                  )),
            if (location != null) ...[
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.blush, child: Icon(Icons.location_on_outlined, color: AppColors.rose)),
                  title: Text(location!.label ?? 'Memory location'),
                  subtitle: Text('${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)}'),
                  trailing: IconButton(onPressed: () => setState(() => location = null), icon: const Icon(Icons.close_rounded)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : () => _save(false),
              icon: const Icon(Icons.favorite_border),
              label: Text(saving ? 'Saving…' : editing ? 'Save changes' : 'Save memory'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: saving ? null : () => _save(true),
              child: const Text('Save as draft', style: TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      );

  Future<void> _showAttachmentSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () => Navigator.pop(context, 'camera')),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photos'), onTap: () => Navigator.pop(context, 'photos')),
          ListTile(leading: const Icon(Icons.videocam_outlined), title: const Text('Video'), onTap: () => Navigator.pop(context, 'video')),
          ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Document'), onTap: () => Navigator.pop(context, 'document')),
          ListTile(leading: const Icon(Icons.attach_file_rounded), title: const Text('File'), onTap: () => Navigator.pop(context, 'file')),
          ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Current location'), onTap: () => Navigator.pop(context, 'location')),
        ]),
      ),
    );
    if (action == null) return;
    if (action == 'camera') return _pickImage(ImageSource.camera);
    if (action == 'photos') return _pickImage(ImageSource.gallery);
    if (action == 'video') return _pickVideo();
    if (action == 'document') return _pickFile(allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf']);
    if (action == 'location') return _attachLocation();
    return _pickFile();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await picker.pickImage(source: source, imageQuality: 92);
    if (file == null) return;
    await _upload(file.name, lookupMimeType(file.name) ?? 'image/jpeg', await file.readAsBytes());
  }

  Future<void> _pickVideo() async {
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _upload(file.name, lookupMimeType(file.name) ?? 'video/mp4', await file.readAsBytes());
  }

  Future<void> _pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) {
      _snack('Could not read that file.');
      return;
    }
    await _upload(file.name, lookupMimeType(file.name) ?? 'application/octet-stream', file.bytes!);
  }

  Future<void> _upload(String filename, String mime, List<int> bytes) async {
    setState(() { uploadingLabel = 'Uploading $filename…'; uploadProgress = 0; });
    try {
      final media = await ref.read(mediaRepositoryProvider).upload(
            filename: filename,
            mime: mime,
            bytes: Uint8List.fromList(bytes),
            metadata: {'source': 'memory'},
            onProgress: (value) { if (mounted) setState(() => uploadProgress = value); },
          );
      if (!mounted) return;
      setState(() {
        attachments.add(MemoryAttachment(mediaId: media.id, filename: filename, mime: mime, size: media.size));
        uploadingLabel = null;
        uploadProgress = null;
      });
    } catch (e) {
      if (mounted) setState(() { uploadingLabel = null; uploadProgress = null; });
      _snack('Upload failed: $e');
    }
  }

  Future<void> _attachLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Turn on location services to attach your current location.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _snack('Location permission is required only when you choose to attach a location.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() => location = MemoryLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            label: 'Saved location',
            capturedAt: DateTime.now(),
          ));
    } catch (e) {
      _snack('Could not get your location: $e');
    }
  }

  Future<void> _pickRevealDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      initialDate: revealAt?.toLocal() ?? now.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(revealAt?.toLocal() ?? const TimeOfDay(hour: 9, minute: 0).toDateTime(date)));
    if (time == null) return;
    setState(() => revealAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save(bool draft) async {
    if (title.text.trim().isEmpty && body.text.trim().isEmpty) {
      _snack('Add a title or a little note first.');
      return;
    }
    if (isCapsule && !draft && revealAt != null && !revealAt!.isAfter(DateTime.now())) {
      _snack('Choose a future reveal time for the Time Capsule.');
      return;
    }
    setState(() => saving = true);
    final parsedTags = tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    try {
      if (editing) {
        await ref.read(memoryRepositoryProvider).update(
              widget.existing!.id,
              title: title.text.trim(),
              body: body.text.trim(),
              tags: parsedTags,
              attachments: attachments,
              location: location,
              clearLocation: location == null && widget.existing?.location != null,
              draft: draft,
              revealAt: revealAt,
            );
      } else {
        final created = await ref.read(memoryRepositoryProvider).create(
              type: type,
              title: title.text.trim(),
              body: body.text.trim(),
              tags: parsedTags,
              attachments: attachments,
              location: location,
              draft: draft,
              revealAt: revealAt,
            );
        if (isCapsule && !draft && revealAt != null) {
          await ref.read(memoryRepositoryProvider).scheduleCapsule(created.id, revealAt!);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.onRemove});
  final MemoryAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.blush,
            child: Icon(
              attachment.isImage ? Icons.image_outlined : attachment.isVideo ? Icons.videocam_outlined : attachment.isAudio ? Icons.mic_none_rounded : attachment.isDocument ? Icons.description_outlined : Icons.attach_file_rounded,
              color: AppColors.rose,
            ),
          ),
          title: Text(attachment.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${attachment.mime} • ${_prettyBytes(attachment.size)}'),
          trailing: IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded)),
        ),
      );
}

class _CapsuleDateCard extends StatelessWidget {
  const _CapsuleDateCard({required this.revealAt, required this.onPick, required this.onClear});
  final DateTime? revealAt;
  final VoidCallback onPick, onClear;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.peach.withValues(alpha: .7), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const Icon(Icons.lock_clock_outlined, color: AppColors.rose),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reveal time', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(revealAt == null ? 'Choose when this memory can be opened.' : _formatDateTime(revealAt!), style: const TextStyle(color: AppColors.muted)),
          ])),
          if (revealAt != null) IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
          TextButton(onPressed: onPick, child: Text(revealAt == null ? 'Choose' : 'Change')),
        ]),
      );
}

String _prettyBytes(int value) {
  if (value < 1024) return '$value B';
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDateTime(DateTime d) {
  final x = d.toLocal();
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')} ${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
}

extension on TimeOfDay {
  DateTime toDateTime(DateTime date) => DateTime(date.year, date.month, date.day, hour, minute);
}
