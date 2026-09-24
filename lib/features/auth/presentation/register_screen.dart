import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_username.text.trim().isEmpty || _password.text.length < 10) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.register(username: _username.text.trim(), password: _password.text);
      await repo.persist(session);
      if (!mounted) return;
      context.go('/recovery-code', extra: session.recoveryCode ?? '');
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(height: 18),
              Text('Make a tiny home\nfor your big story.', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 10),
              Text('Choose a username and a strong password.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 30),
              TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 14),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', helperText: 'Use at least 10 characters.')),
              const SizedBox(height: 24),
              FilledButton(onPressed: _loading ? null : _register, child: Text(_loading ? 'Creating…' : 'Create account')),
            ],
          ),
        ),
      ),
    );
  }
}
