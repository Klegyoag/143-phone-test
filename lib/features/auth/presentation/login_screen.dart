import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import 'widgets/auth_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.login(
          username: _username.text.trim(), password: _password.text);
      await repo.persist(session);
      if (!mounted) return;
      // Bootstrap verifies recovery, current legal-document versions, couple
      // availability and any pending invite instead of trusting a stale login flag.
      context.go('/bootstrap');
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
      eyebrow: 'Good to see you',
      title: 'Welcome back',
      subtitle: 'Sign in and return to the private little world you share.',
      onBack: () => context.go('/welcome'),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthCardHeading(
              title: 'Sign in',
              subtitle: 'Your person, your moments, your 143 — all waiting.',
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _username,
              label: 'Username',
              hint: 'your_username',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/recover-account'),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 6),
            GradientActionButton(
              label: 'Sign in',
              loading: _loading,
              onPressed: _loading ? null : _submit,
              icon: Icons.favorite_outline_rounded,
            ),
            const SizedBox(height: 18),
            const SecurityNote(
              title: 'Private by design',
              body: 'Your shared space is protected and never made public.',
            ),
            const SizedBox(height: 12),
            const Divider(),
            AuthFooterLink(
              prompt: 'New to 143?',
              action: 'Create an account',
              onPressed: () => context.go('/register'),
            ),
          ],
        ),
      ),
    );
  }
}
