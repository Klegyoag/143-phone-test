import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.label = 'Loading your little world…'});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.rose),
        const SizedBox(height: 16),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
      ]),
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.rose, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ]),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => AppEmptyState(
    icon: Icons.cloud_off_rounded,
    title: 'We couldn’t load this',
    message: message,
    action: onRetry == null ? null : FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
  );
}


class AppSkeletonLine extends StatefulWidget {
  const AppSkeletonLine({super.key, this.width = double.infinity, this.height = 14, this.radius = 10});
  final double width, height, radius;
  @override
  State<AppSkeletonLine> createState() => _AppSkeletonLineState();
}

class _AppSkeletonLineState extends State<AppSkeletonLine> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() { super.initState(); controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .35, end: .75).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
    child: Container(width: widget.width, height: widget.height, decoration: BoxDecoration(color: AppColors.blushStrong, borderRadius: BorderRadius.circular(widget.radius))),
  );
}

class AppCardSkeleton extends StatelessWidget {
  const AppCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      AppSkeletonLine(width: 120, height: 16), SizedBox(height: 12), AppSkeletonLine(height: 12), SizedBox(height: 8), AppSkeletonLine(width: 220, height: 12),
    ])),
  );
}
