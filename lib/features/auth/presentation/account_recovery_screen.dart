import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/auth_ui.dart';

class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  final username = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  bool obscure = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    username.dispose();
    code.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (username.text.trim().isEmpty ||
        code.text.trim().isEmpty ||
        password.text.length < 10 ||
        password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check the username, saved recovery code, and matching 10+ character password.',
          ),
        ),
      );
      return;
    }

    setState(() => busy = true);
    try {
      final newCode =
          await ref.read(authRepositoryProvider).resetPasswordWithRecovery(
                username: username.text,
                recoveryCode: code.text,
                password: password.text,
              );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Password reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your previous sessions were closed. Save this new one-time recovery code before signing in again.',
              ),
              const SizedBox(height: 16),
              SelectableText(
                newCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.rose,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('I saved it'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/login');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        eyebrow: 'You can come back',
        title: 'Recover your account',
        subtitle:
            'Use the private recovery code you saved when you created your 143 account.',
        onBack: () => context.go('/login'),
        compactHeader: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthCardHeading(
              title: 'Reset password',
              subtitle:
                  'No email shortcut — your recovery code keeps this process private.',
            ),
            const SizedBox(height: 22),
            AuthTextField(
              controller: username,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: code,
              label: 'Recovery code',
              hint: '143-XXXX-XXXX-XXXX-XXXX-XXXX',
              icon: Icons.key_outlined,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: password,
              label: 'New password',
              helper: 'Use at least 10 characters.',
              icon: Icons.lock_outline_rounded,
              obscureText: obscure,
              onToggleObscure: () => setState(() => obscure = !obscure),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: confirm,
              label: 'Confirm new password',
              icon: Icons.lock_reset_rounded,
              obscureText: obscureConfirm,
              onToggleObscure: () =>
                  setState(() => obscureConfirm = !obscureConfirm),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 18),
            const SecurityNote(
              title: 'Your code is the key',
              body: '143 cannot retrieve or bypass a lost recovery code.',
              icon: Icons.key_rounded,
            ),
            const SizedBox(height: 18),
            GradientActionButton(
              label: 'Reset password',
              loading: busy,
              onPressed: busy ? null : submit,
            ),
            const SizedBox(height: 12),
            AuthFooterLink(
              prompt: 'Remembered your password?',
              action: 'Back to sign in',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      );
}
