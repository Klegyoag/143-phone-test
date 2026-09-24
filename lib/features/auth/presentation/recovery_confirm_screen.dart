import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import 'widgets/auth_ui.dart';

class RecoveryConfirmScreen extends ConsumerStatefulWidget {
  const RecoveryConfirmScreen({super.key});

  @override
  ConsumerState<RecoveryConfirmScreen> createState() =>
      _RecoveryConfirmScreenState();
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
        const SnackBar(
            content:
                Text('Re-enter the recovery code exactly as you saved it.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).confirmRecovery(code.text);
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'Almost there',
      title: 'Confirm your code',
      subtitle:
          'Re-enter the recovery code to make sure it was saved correctly.',
      compactHeader: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthCardHeading(
            title: 'Recovery check',
            subtitle:
                'This protects you from finishing setup without a way back in.',
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
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 18),
          const SecurityNote(
            title: 'Keep it somewhere safe',
            body:
                'Once confirmed, your account becomes active and setup can continue.',
          ),
          const SizedBox(height: 20),
          GradientActionButton(
            label: 'Confirm recovery code',
            loading: loading,
            onPressed: loading || !valid ? null : _confirm,
            icon: Icons.verified_rounded,
          ),
        ],
      ),
    );
  }
}
