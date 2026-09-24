import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.blush),
                child: const Center(child: Text('143', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.rose))),
              ),
              const SizedBox(height: 30),
              Text('A private place\nfor just the two of you.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 14),
              Text('Remember, talk, play, plan and stay close — all in one gentle little space.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
              const Spacer(),
              FilledButton(onPressed: () => context.go('/login'), child: const Text('Get started')),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.go('/login'), child: const Text('I already have an account')),
            ],
          ),
        ),
      ),
    );
  }
}
