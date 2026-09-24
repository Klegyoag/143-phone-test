import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../memories/presentation/memory_create_screen.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  static const items = [
    (Icons.photo_camera_back_outlined, 'Memory', 'moment'),
    (Icons.mail_outline_rounded, 'Letter', 'letter'),
    (Icons.auto_awesome_outlined, 'Moment', 'moment'),
    (Icons.hourglass_bottom_rounded, 'Time Capsule', 'time_capsule'),
    (Icons.favorite_border_rounded, 'Love Note', 'love_note'),
    (Icons.handshake_outlined, 'Promise', 'promise'),
    (Icons.emoji_events_outlined, 'Milestone', 'milestone'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Create'), backgroundColor: Colors.transparent),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [AppColors.darkBackground, Color(0xFF17101E)]
                : const [AppColors.ivory, AppColors.paper],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoryCreateScreen(initialType: item.$3),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: dark
                      ? (index.isEven
                          ? AppColors.darkBlush
                          : AppColors.darkSurface)
                      : (index.isEven ? AppColors.blush : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : AppColors.divider,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? .16 : .04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color:
                            AppColors.rose.withValues(alpha: dark ? .18 : .11),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(item.$1, color: AppColors.rose, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
