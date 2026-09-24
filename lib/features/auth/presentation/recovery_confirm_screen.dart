import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../legal/data/legal_repository.dart';
import 'widgets/auth_ui.dart';

class RecoveryConfirmScreen extends ConsumerStatefulWidget {
  const RecoveryConfirmScreen({super.key, this.savedCode = ''});

  final String savedCode;

  @override
  ConsumerState<RecoveryConfirmScreen> createState() =>
      _RecoveryConfirmScreenState();
}

class _RecoveryConfirmScreenState extends ConsumerState<RecoveryConfirmScreen> {
  final code = TextEditingController();
  final accepted = <String, bool>{};
  List<LegalDocumentInfo> documents = const [];
  bool loading = false;
  bool loadingLegal = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLegal);
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  bool get valid {
    final value = code.text.trim().toUpperCase();
    return value.startsWith('143-') && value.length >= 20;
  }

  bool get legalAccepted =>
      documents.isNotEmpty && documents.every((d) => accepted[d.id] == true);

  Future<void> _loadLegal() async {
    try {
      final legal = await ref.read(legalRepositoryProvider).currentState();
      if (!mounted) return;
      setState(() {
        documents = legal.requiredDocuments;
        for (final document in documents) {
          accepted[document.id] =
              legal.acceptedDocumentIds.contains(document.id);
        }
        loadingLegal = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => loadingLegal = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _confirm() async {
    if (!valid || !legalAccepted) return;
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).confirmRecovery(code.text);
      for (final document in documents) {
        if (accepted[document.id] == true) {
          await ref.read(legalRepositoryProvider).accept(document);
        }
      }
      if (mounted) context.go('/bootstrap');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _backToCode() {
    if (widget.savedCode.isNotEmpty) {
      context.go('/recovery-code', extra: widget.savedCode);
      return;
    }
    context.go('/bootstrap');
  }

  void _showDocument(LegalDocumentInfo document) {
    final privacy = document.type.toLowerCase().contains('privacy');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(
                    privacy
                        ? Icons.shield_outlined
                        : Icons.description_outlined,
                    color: AppColors.rose,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      privacy ? 'Privacy Policy' : 'Terms and Conditions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    document.content.trim().isEmpty
                        ? 'This document is temporarily unavailable. Please try again.'
                        : document.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.55,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'Almost there',
      title: 'Confirm your code',
      subtitle: 'Check your recovery code and choose your privacy settings.',
      compactHeader: true,
      onBack: _backToCode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthCardHeading(
            title: 'Recovery check',
            subtitle:
                'Forgot to save it? Use the back button to see and save it again.',
          ),
          const SizedBox(height: 22),
          AuthTextField(
            controller: code,
            label: 'Recovery code',
            hint: '143-XXXX-XXXX-XXXX-XXXX-XXXX',
            helper: 'Enter the complete code, including 143-.',
            icon: Icons.shield_outlined,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.oneTimeCode],
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 22),
          Text('Your choices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (loadingLegal)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else
            ...documents.map((document) {
              final privacy = document.type.toLowerCase().contains('privacy');
              final label = privacy ? 'Privacy Policy' : 'Terms and Conditions';
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: accepted[document.id] ?? false,
                onChanged: (value) =>
                    setState(() => accepted[document.id] = value ?? false),
                title: Wrap(
                  children: [
                    Text(privacy ? 'I agree to the ' : 'I agree to the '),
                    InkWell(
                      onTap: () => _showDocument(document),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.rose,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.rose,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  privacy
                      ? 'See how 143 protects and uses your data.'
                      : 'Read the rules that keep the shared space safe.',
                ),
              );
            }),
          const SizedBox(height: 14),
          const SecurityNote(
            title: 'You stay in control',
            body: 'Tap either document name to read it here before you agree.',
          ),
          const SizedBox(height: 20),
          GradientActionButton(
            label: 'Agree & finish setup',
            loading: loading,
            onPressed: loading || loadingLegal || !valid || !legalAccepted
                ? null
                : _confirm,
            icon: Icons.verified_rounded,
          ),
        ],
      ),
    );
  }
}
