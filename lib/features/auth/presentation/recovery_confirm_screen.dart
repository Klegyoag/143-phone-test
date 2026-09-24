import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';

class RecoveryConfirmScreen extends ConsumerStatefulWidget {
  const RecoveryConfirmScreen({super.key});

  @override
  ConsumerState<RecoveryConfirmScreen> createState() => _RecoveryConfirmScreenState();
}

class _RecoveryConfirmScreenState extends ConsumerState<RecoveryConfirmScreen> {
  final code = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  bool get valid {
    final value = code.text.trim().toUpperCase();
    return value.startsWith('143-') && value.length >= 20;
  }

  Future<void> _confirm() async {
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Re-enter the recovery code exactly as you saved it.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).confirmRecovery(code.text);
      if (mounted) context.go('/bootstrap');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on FormatException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 54),
              const Center(child: Icon(Icons.key_rounded, size: 58, color: AppColors.rose)),
              const SizedBox(height: 24),
              Text('Prove you saved it', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              const Text(
                'For your safety, re-enter the one-time recovery code you were shown. 143 cannot silently skip this step.',
              ),
              const SizedBox(height: 26),
              TextField(
                controller: code,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Recovery code',
                  hintText: '143-XXXX-XXXX-XXXX-XXXX-XXXX',
                  prefixIcon: Icon(Icons.shield_outlined),
                  helperText: 'Enter the complete code, including 143-.',
                ),
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading || !valid ? null : _confirm,
                  child: Text(loading ? 'Checking…' : 'Confirm recovery code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
