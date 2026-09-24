import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/legal_repository.dart';

class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key});
  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen> {
  LegalState? state;
  bool loading = true, saving = false;
  final accepted = <String, bool>{};
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final s = await ref.read(legalRepositoryProvider).currentState();
      if (mounted)
        setState(() {
          state = s;
          loading = false;
          for (final d in s.requiredDocuments) {
            accepted[d.id] = s.acceptedDocumentIds.contains(d.id);
          }
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = '$e';
          loading = false;
        });
    }
  }

  Future<void> save() async {
    final s = state;
    if (s == null) return;
    setState(() => saving = true);
    try {
      for (final d in s.requiredDocuments) {
        if (!s.acceptedDocumentIds.contains(d.id) && accepted[d.id] == true) {
          await ref.read(legalRepositoryProvider).accept(d);
        }
      }
      if (mounted) context.go('/bootstrap');
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null)
      return Scaffold(
          body: SafeArea(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton(
                            onPressed: load, child: const Text('Retry'))
                      ])))));
    final docs = state?.requiredDocuments ?? const <LegalDocumentInfo>[];
    final allAccepted =
        docs.isNotEmpty && docs.every((d) => accepted[d.id] == true);
    return Scaffold(
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Text('Before we make it yours…',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 10),
                      Text(
                          '143 checks the current Terms and Privacy versions, so already-compliant users are not asked again.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.muted)),
                      const SizedBox(height: 26),
                      Expanded(
                          child: ListView(
                              children: docs.map((d) {
                        final already =
                            state!.acceptedDocumentIds.contains(d.id);
                        return Card(
                            child: CheckboxListTile(
                                value: accepted[d.id] ?? false,
                                onChanged: already
                                    ? null
                                    : (v) => setState(
                                        () => accepted[d.id] = v ?? false),
                                title: Text(d.title.isEmpty ? d.type : d.title),
                                subtitle: Text(
                                    'Version ${d.version.isEmpty ? 'current' : d.version}${already ? ' • already accepted' : ''}'),
                                secondary: Icon(
                                    d.type.toLowerCase().contains('privacy')
                                        ? Icons.shield_outlined
                                        : Icons.description_outlined,
                                    color: AppColors.rose)));
                      }).toList())),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: allAccepted && !saving ? save : null,
                              child: Text(
                                  saving ? 'Saving…' : 'Accept & continue'))),
                    ]))));
  }
}
