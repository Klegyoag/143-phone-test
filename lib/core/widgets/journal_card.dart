import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = dark
        ? switch (color) {
            AppColors.blush => AppColors.darkBlush,
            AppColors.blushStrong => AppColors.darkBlush,
            AppColors.peach => AppColors.darkPeach,
            _ => AppColors.darkSurface,
          }
        : (color ?? AppColors.paper);
    final border = dark ? AppColors.darkBorder : AppColors.divider;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .24 : .045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(24), child: card);
  }
}
