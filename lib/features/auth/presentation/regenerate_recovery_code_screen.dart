import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';

class RegenerateRecoveryCodeScreen extends ConsumerStatefulWidget {
  const RegenerateRecoveryCodeScreen({super.key});

  @override
  ConsumerState<RegenerateRecoveryCodeScreen> createState() => _RegenerateRecoveryCodeScreenState();
}

class _RegenerateRecoveryCodeScreenState extends ConsumerState<RegenerateRecoveryCodeScreen> {
  final password = TextEditingController();
  final confirmCode = TextEditingController();
  String? generatedCode;
  bool busy = false;
  bool saved = false;
  bool obscure = true;

  @override
  void dispose() {
    password.dispose();
    confirmCode.dispose();
    super.dispose();
  }

  Future<void> _regenerate() async {
    if (password.text.isEmpty) {
      _message('Enter your current password first.');
      return;
    }
    setState(() => busy = true);
    try {
      final code = await ref.read(authRepositoryProvider).regenerateRecoveryCode(password.text);
      if (code.isEmpty) throw const FormatException('The backend did not return the one-time recovery code.');
      if (!mounted) return;
      password.clear();
      setState(() {
        generatedCode = code;
        saved = false;
        confirmCode.clear();
      });
    } on ApiException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _confirm() async {
    final expected = generatedCode?.trim().toUpperCase() ?? '';
    final entered = confirmCode.text.trim().toUpperCase();
    if (!saved) {
      _message('Confirm that you saved the new recovery code.');
      return;
    }
    if (entered.isEmpty || entered != expected) {
      _message('Re-enter the exact new recovery code to prove it was saved.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).confirmRecovery(entered);
      if (!mounted) return;
      _message('New recovery code confirmed.');
      context.pop();
    } on ApiException catch (e) {
      _message(e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final code = generatedCode;
    return PopScope(
      canPop: code == null,
      child: Scaffold(
        appBar: AppBar(title: const Text('Regenerate recovery code')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            JournalCard(
              color: AppColors.blush,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.key_rounded, color: AppColors.rose, size: 34),
                  SizedBox(height: 10),
                  Text('One-time security step', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('Regenerating invalidates your old recovery code. The backend blocks normal protected APIs until the new code is confirmed.'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (code == null) ...[
              TextField(
                controller: password,
                obscureText: obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _regenerate(),
                decoration: InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy ? null : _regenerate,
                icon: const Icon(Icons.autorenew_rounded),
                label: Text(busy ? 'Generating…' : 'Generate new recovery code'),
              ),
            ] else ...[
              const Text('Save this new code now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              JournalCard(
                child: Center(
                  child: SelectableText(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.wine, letterSpacing: 1.2),
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.rose,
                value: saved,
                onChanged: busy ? null : (v) => setState(() => saved = v ?? false),
                title: const Text('I saved the new recovery code somewhere private'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCode,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Re-enter new recovery code',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy ? null : _confirm,
                icon: const Icon(Icons.verified_rounded),
                label: Text(busy ? 'Confirming…' : 'Confirm new recovery code'),
              ),
              const SizedBox(height: 8),
              const Text(
                'For your safety, you cannot leave this step after regeneration until the new code has been confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
