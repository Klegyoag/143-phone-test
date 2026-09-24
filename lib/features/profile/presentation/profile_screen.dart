import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final displayName = TextEditingController();
  final username = TextEditingController();
  final bio = TextEditingController();
  final timezone = TextEditingController();
  final locale = TextEditingController();
  bool loading = true, saving = false, photoBusy = false;
  String? error, photoPath, photoUrl;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { displayName.dispose(); username.dispose(); bio.dispose(); timezone.dispose(); locale.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final me = await ref.read(profileRepositoryProvider).me();
      displayName.text = '${me['display_name'] ?? me['name'] ?? ''}';
      username.text = '${me['username'] ?? ''}';
      bio.text = '${me['bio'] ?? ''}';
      timezone.text = '${me['timezone'] ?? ''}';
      locale.text = '${me['locale'] ?? 'en'}';
      photoPath = me['photo_path']?.toString();
      if ((photoPath ?? '').isNotEmpty) {
        try { photoUrl = (await ref.read(profileRepositoryProvider).profilePhoto())?['url']?.toString(); } catch (_) { photoUrl = null; }
      } else { photoUrl = null; }
    } catch (e) { error = '$e'; }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateMe({
        'display_name': displayName.text.trim(), 'username': username.text.trim(), 'bio': bio.text.trim(),
        'timezone': timezone.text.trim(), 'locale': locale.text.trim().isEmpty ? 'en' : locale.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved ♡')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length > 10 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo must be 10 MB or smaller.')));
      return;
    }
    final edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => _ProfilePhotoEditorScreen(bytes: Uint8List.fromList(bytes))),
    );
    if (edited == null || edited.isEmpty) return;
    setState(() => photoBusy = true);
    try {
      final data = await ref.read(profileRepositoryProvider).uploadPhoto(filename: 'profile-photo.png', bytes: edited);
      photoPath = '${data['path'] ?? ''}';
      try { photoUrl = (await ref.read(profileRepositoryProvider).profilePhoto())?['url']?.toString(); } catch (_) { photoUrl = null; }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated ♡')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    if (mounted) setState(() => photoBusy = false);
  }

  Future<void> _deletePhoto() async {
    setState(() => photoBusy = true);
    try {
      await ref.read(profileRepositoryProvider).deletePhoto();
      photoPath = null;
      photoUrl = null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    if (mounted) setState(() => photoBusy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile')),
    body: loading ? const AppLoadingState(label: 'Opening your profile…') : error != null ? AppErrorState(message: error!, onRetry: _load) : ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Center(child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.blush,
              backgroundImage: (photoUrl ?? '').isNotEmpty ? NetworkImage(photoUrl!) : null,
              child: photoBusy ? const CircularProgressIndicator() : (photoUrl ?? '').isEmpty ? const Icon(Icons.person_rounded, size: 48, color: AppColors.rose) : null,
            ),
            Positioned(right: -2, bottom: -2, child: Container(decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle), child: IconButton(onPressed: photoBusy ? null : _pickPhoto, icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18))))
          ]),
          if ((photoPath ?? '').isNotEmpty) TextButton.icon(onPressed: photoBusy ? null : _deletePhoto, icon: const Icon(Icons.delete_outline), label: const Text('Remove photo')),
        ])),
        const SizedBox(height: 22),
        TextField(controller: displayName, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.favorite_border_rounded))),
        const SizedBox(height: 14),
        TextField(controller: username, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded))),
        const SizedBox(height: 14),
        TextField(controller: bio, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Bio', hintText: 'A little bit about you…', alignLabelWithHint: true, prefixIcon: Icon(Icons.edit_note_rounded))),
        const SizedBox(height: 14),
        TextField(controller: timezone, decoration: const InputDecoration(labelText: 'Timezone', hintText: 'Asia/Colombo', prefixIcon: Icon(Icons.schedule_rounded))),
        const SizedBox(height: 14),
        TextField(controller: locale, decoration: const InputDecoration(labelText: 'Locale', hintText: 'en', prefixIcon: Icon(Icons.language_rounded))),
        const SizedBox(height: 22),
        FilledButton.icon(onPressed: saving ? null : _save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded), label: Text(saving ? 'Saving…' : 'Save profile')),
      ],
    ),
  );
}

class _ProfilePhotoEditorScreen extends StatefulWidget {
  const _ProfilePhotoEditorScreen({required this.bytes});
  final Uint8List bytes;

  @override
  State<_ProfilePhotoEditorScreen> createState() => _ProfilePhotoEditorScreenState();
}

class _ProfilePhotoEditorScreenState extends State<_ProfilePhotoEditorScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  int quarterTurns = 0;
  bool exporting = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _rotate() {
    setState(() {
      quarterTurns = (quarterTurns + 1) % 4;
      _transform.value = Matrix4.identity();
    });
  }

  void _reset() => setState(() {
        quarterTurns = 0;
        _transform.value = Matrix4.identity();
      });

  Future<void> _save() async {
    setState(() => exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Photo editor is not ready yet.');
      final image = await boundary.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data?.buffer.asUint8List();
      if (!mounted || bytes == null || bytes.isEmpty) return;
      Navigator.pop(context, bytes);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not finish photo edit: $e')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Edit profile photo'),
          actions: [
            IconButton(onPressed: exporting ? null : _reset, tooltip: 'Reset', icon: const Icon(Icons.restart_alt_rounded)),
            TextButton(onPressed: exporting ? null : _save, child: Text(exporting ? 'Saving…' : 'Use photo', style: const TextStyle(color: Colors.white))),
          ],
        ),
        body: SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: Text('Pinch to zoom and drag to reposition. The square preview is the final crop.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, constraints) {
                  final size = constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight;
                  final side = (size - 32).clamp(220.0, 520.0).toDouble();
                  return Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(border: Border.all(color: Colors.white54, width: 2)),
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transform,
                          minScale: 1,
                          maxScale: 5,
                          boundaryMargin: EdgeInsets.zero,
                          child: RotatedBox(
                            quarterTurns: quarterTurns,
                            child: Image.memory(widget.bytes, width: side, height: side, fit: BoxFit.cover, gaplessPlayback: true),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton.icon(
                  onPressed: exporting ? null : _rotate,
                  icon: const Icon(Icons.rotate_right_rounded),
                  label: const Text('Rotate'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                ),
              ]),
            ),
          ]),
        ),
      );
}

