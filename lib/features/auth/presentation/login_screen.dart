import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';

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

  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.login(username: _username.text.trim(), password: _password.text);
      await repo.persist(session);
      if (!mounted) return;
      // Bootstrap verifies recovery, current legal-document versions, couple
      // availability and any pending invite instead of trusting a stale login flag.
      context.go('/bootstrap');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: () => context.go('/'), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(height: 30),
              Text('Welcome back,\nmy favorite person.', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 10),
              Text('Your shared little world is waiting.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 34),
              TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded))),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Signing in…' : 'Sign in')),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.go('/recover-account'), child: const Text('Forgot password?'))),
              Center(child: TextButton(onPressed: () => context.go('/register'), child: const Text("New here? Create your 143 account"))),
            ],
          ),
        ),
      ),
    );
  }
}
