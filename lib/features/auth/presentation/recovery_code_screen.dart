import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/journal_card.dart';

class RecoveryCodeScreen extends StatefulWidget {
  const RecoveryCodeScreen({super.key, required this.code});
  final String code;

  @override
  State<RecoveryCodeScreen> createState() => _RecoveryCodeScreenState();
}

class _RecoveryCodeScreenState extends State<RecoveryCodeScreen> {
  bool saved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              const Icon(Icons.shield_outlined, size: 44, color: AppColors.rose),
              const SizedBox(height: 18),
              Text('Your recovery code', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text('Save this somewhere private. You may need it to recover your account.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 26),
              JournalCard(
                color: AppColors.blush,
                child: Center(
                  child: SelectableText(widget.code.isEmpty ? 'Recovery code unavailable' : widget.code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.wine)),
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: saved,
                onChanged: (v) => setState(() => saved = v ?? false),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.rose,
                title: const Text("I've saved my recovery code"),
              ),
              const Spacer(),
              FilledButton(onPressed: saved ? () => context.go('/recovery-confirm') : null, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
