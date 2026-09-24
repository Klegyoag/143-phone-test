import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import 'widgets/auth_ui.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_username.text.trim().length < 3 ||
        _password.text.length < 10 ||
        _password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Use a valid username and matching passwords of at least 10 characters.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.register(
          username: _username.text.trim(), password: _password.text);
      await repo.persist(session);
      if (!mounted) return;
      context.go('/recovery-code', extra: session.recoveryCode ?? '');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'A place for two',
      title: 'Begin your 143 story',
      subtitle:
          'Create your private account now. You can invite your person safely after setup.',
      onBack: () => context.go('/login'),
      compactHeader: true,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthCardHeading(
              title: 'Create account',
              subtitle:
                  'A gentle space for your memories, messages and everyday love.',
              badge: _PrivateBadge(),
            ),
            const SizedBox(height: 22),
            AuthTextField(
              controller: _username,
              label: 'Username',
              hint: 'Choose a unique username',
              icon: Icons.person_add_alt_1_outlined,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newUsername],
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _password,
              label: 'Password',
              helper: 'Use at least 10 characters.',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmPassword,
              label: 'Confirm password',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 18),
            const SecurityNote(
              title: 'Secure & private',
              body:
                  'After creating your account, we’ll give you one recovery code to save safely.',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 18),
            GradientActionButton(
              label: 'Create account',
              loading: _loading,
              onPressed: _loading ? null : _register,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 12),
            const Divider(),
            AuthFooterLink(
              prompt: 'Already have an account?',
              action: 'Sign in',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateBadge extends StatelessWidget {
  const _PrivateBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F8F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.shield_outlined,
            color: Color(0xFF148D84), size: 21),
      );
}
