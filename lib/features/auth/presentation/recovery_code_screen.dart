import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/auth_ui.dart';

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
    return AuthScaffold(
      eyebrow: 'One important step',
      title: 'Save your recovery code',
      subtitle:
          'This one-time code is the private key back into your account if you forget your password.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthCardHeading(
            title: 'Your private code',
            subtitle: 'Write it down or keep it in a trusted password manager.',
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEEF1), Color(0xFFF0E9FF)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.blushStrong),
            ),
            child: Column(
              children: [
                const Icon(Icons.key_rounded, color: AppColors.rose, size: 30),
                const SizedBox(height: 12),
                SelectableText(
                  widget.code.isEmpty
                      ? 'Recovery code unavailable'
                      : widget.code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.15,
                    color: AppColors.wine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const SecurityNote(
            title: 'Shown only once',
            body:
                '143 cannot display this code again. Never send it to anyone, including support.',
            icon: Icons.visibility_off_outlined,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: saved,
            onChanged: (value) => setState(() => saved = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.rose,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text("I've saved my recovery code"),
          ),
          const SizedBox(height: 12),
          GradientActionButton(
            label: 'Continue safely',
            icon: Icons.arrow_forward_rounded,
            onPressed: saved ? () => context.go('/recovery-confirm') : null,
          ),
        ],
      ),
    );
  }
}
