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

  void showDocument(LegalDocumentInfo document) {
    final privacy = document.type.toLowerCase().contains('privacy');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(privacy ? Icons.shield_outlined : Icons.description_outlined,
                  color: AppColors.rose),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      privacy ? 'Privacy Policy' : 'Terms and Conditions',
                      style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  document.content.trim().isEmpty
                      ? 'This document is temporarily unavailable. Please try again.'
                      : document.content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.55),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
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
                          'Please review and accept the current Terms and Privacy Policy.',
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
                                title: InkWell(
                                  onTap: () => showDocument(d),
                                  child: Text(
                                    d.type.toLowerCase().contains('privacy')
                                        ? 'Privacy Policy'
                                        : 'Terms and Conditions',
                                    style: const TextStyle(
                                      color: AppColors.rose,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.rose,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                subtitle: Text(already
                                    ? 'Already accepted'
                                    : 'Tap the title to read before agreeing'),
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
