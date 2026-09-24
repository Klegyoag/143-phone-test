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
    return Scaffold(
      appBar: AppBar(title: const Text('Create'), backgroundColor: Colors.transparent),
      body: GridView.builder(
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
            child: Container(
              decoration: BoxDecoration(
                color: index.isEven ? AppColors.blush : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, color: AppColors.rose, size: 34),
                  const SizedBox(height: 12),
                  Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
