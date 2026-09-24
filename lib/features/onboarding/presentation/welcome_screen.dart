import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/widgets/auth_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'Your little world',
      title: 'Love lives in the little things',
      subtitle:
          'Remember, talk, play, plan and stay close — in one private place made for two.',
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded,
              size: 54, color: Color(0xFFF06D89)),
          const SizedBox(height: 16),
          Text(
            'A private home for your story',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep meaningful moments close and make room for more of them — together.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          GradientActionButton(
            label: 'Create our space',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/register'),
          ),
          const SizedBox(height: 10),
          AuthFooterLink(
            prompt: 'Already have an account?',
            action: 'Sign in',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
