import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  static const pages = [
    (Icons.favorite_rounded, 'A private home for two', '143 keeps your shared world calm, intimate and easy to return to.'),
    (Icons.photo_library_outlined, 'Remember the little things', 'Keep moments, letters, milestones, albums and Time Capsules together.'),
    (Icons.forum_outlined, 'Stay close every day', 'Chat, call, share moods, answer daily questions and send small signs of love.'),
    (Icons.auto_awesome_outlined, 'Play, plan and grow together', 'Games, dates, goals, journeys and shared plans live inside one simple space.'),
    (Icons.shield_outlined, 'Private by design', 'Sensitive permissions are explained first, requested only when needed, and can be revoked.'),
  ];

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/welcome');
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(children: [
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: finish, child: const Text('Skip'))),
        Expanded(child: PageView.builder(
          controller: controller,
          itemCount: pages.length,
          onPageChanged: (v) => setState(() => page = v),
          itemBuilder: (_, i) {
            final item = pages[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 132,height: 132,decoration: const BoxDecoration(shape: BoxShape.circle,color: AppColors.blush),child: Icon(item.$1,size: 54,color: AppColors.rose)),
                const SizedBox(height: 30),
                Text(item.$2,textAlign: TextAlign.center,style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                Text(item.$3,textAlign: TextAlign.center,style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted,height: 1.5)),
              ]),
            );
          },
        )),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pages.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.all(4), width: i==page?22:8, height:8, decoration: BoxDecoration(color:i==page?AppColors.rose:AppColors.blushStrong,borderRadius:BorderRadius.circular(8))))),
        Padding(padding: const EdgeInsets.all(24), child: SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () { if(page==pages.length-1) finish(); else controller.nextPage(duration: const Duration(milliseconds:300),curve:Curves.easeOut); },
          child: Text(page==pages.length-1?'Enter 143':'Continue'),
        ))),
      ]),
    ),
  );
}
