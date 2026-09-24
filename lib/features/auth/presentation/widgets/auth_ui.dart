import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';

class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.compactHeader = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final bool compactHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(appPreferencesProvider);
    final topColor = dark ? const Color(0xFF211A2F) : const Color(0xFFF7DEEA);
    final middleColor =
        dark ? const Color(0xFF382739) : const Color(0xFFFFD8CC);
    final bottomColor =
        dark ? const Color(0xFF17131F) : const Color(0xFFFFF7F4);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [topColor, middleColor, bottomColor],
                  stops: const [0, .48, 1],
                ),
              ),
              child: CustomPaint(painter: _LoveLandscapePainter(dark: dark)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    bottomColor.withValues(alpha: .08),
                    bottomColor.withValues(alpha: .42),
                  ],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      minHeight: math.max(0, constraints.maxHeight - 42),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (onBack != null)
                              _RoundIconButton(
                                icon: Icons.arrow_back_rounded,
                                tooltip: 'Back',
                                onPressed: onBack!,
                              )
                            else
                              const SizedBox(width: 46),
                            const Spacer(),
                            const Brand143(),
                            const Spacer(),
                            _ThemeButton(
                              dark: dark,
                              onPressed: () => prefs.setThemeMode(
                                dark ? ThemeMode.light : ThemeMode.dark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compactHeader ? 26 : 42),
                        Text(
                          eyebrow.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: dark
                                ? const Color(0xFFF7B8C8)
                                : AppColors.roseDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.2,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            color:
                                dark ? Colors.white : const Color(0xFF25152B),
                            fontSize: compactHeader ? 31 : 38,
                            height: 1.06,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: dark
                                  ? Colors.white.withValues(alpha: .72)
                                  : const Color(0xFF65546F),
                              fontSize: 15,
                              height: 1.42,
                            ),
                          ),
                        ),
                        SizedBox(height: compactHeader ? 26 : 38),
                        AuthCard(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Brand143 extends StatelessWidget {
  const Brand143({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '143',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF36F8C), Color(0xFFFFB29C)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rose.withValues(alpha: .24),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Text(
            '143',
            style: GoogleFonts.playfairDisplay(
              color: dark ? Colors.white : const Color(0xFF25152B),
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF251D2C).withValues(alpha: .94)
            : Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .09)
              : Colors.white.withValues(alpha: .8),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44243E).withValues(alpha: dark ? .30 : .12),
            blurRadius: 42,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthCardHeading extends StatelessWidget {
  const AuthCardHeading(
      {super.key, required this.title, required this.subtitle, this.badge});

  final String title;
  final String subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 10), badge!],
        ],
      );
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.helper,
    this.obscureText = false,
    this.onToggleObscure,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          prefixIcon: Icon(icon, color: AppColors.roseDark),
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
                  onPressed: onToggleObscure,
                  tooltip: obscureText ? 'Show password' : 'Hide password',
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
        ),
      );
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || loading ? 1 : .48,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4AAFE5), Color(0xFFF28AA9)],
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.rose.withValues(alpha: .22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(17),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 9),
                          ],
                          Text(
                            label,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecurityNote extends StatelessWidget {
  const SecurityNote(
      {super.key,
      required this.title,
      required this.body,
      this.icon = Icons.shield_outlined});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2E3544) : const Color(0xFFF1F7FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF168F88), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink(
      {super.key,
      required this.prompt,
      required this.action,
      required this.onPressed});

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
              child:
                  Text(prompt, style: Theme.of(context).textTheme.bodyMedium)),
          TextButton(onPressed: onPressed, child: Text(action)),
        ],
      );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton(
      {required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .72),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .7)),
        ),
        child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: Icon(icon, color: const Color(0xFF37243D))),
      );
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.dark, required this.onPressed});

  final bool dark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: dark ? .16 : .72),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
        ),
        child: IconButton(
          onPressed: onPressed,
          tooltip: dark ? 'Use light theme' : 'Use dark theme',
          icon: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: dark ? const Color(0xFFFFD681) : const Color(0xFF52628E),
          ),
        ),
      );
}

class _LoveLandscapePainter extends CustomPainter {
  const _LoveLandscapePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * .79, size.height * .30);
    canvas.drawCircle(
      sunCenter,
      size.width * .11,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF1BF).withValues(alpha: dark ? .32 : .88),
            const Color(0xFFFFD4AF).withValues(alpha: 0),
          ],
        ).createShader(
            Rect.fromCircle(center: sunCenter, radius: size.width * .11)),
    );

    final backHill = Path()
      ..moveTo(0, size.height * .39)
      ..quadraticBezierTo(size.width * .18, size.height * .29, size.width * .40,
          size.height * .40)
      ..quadraticBezierTo(
          size.width * .63, size.height * .27, size.width, size.height * .41)
      ..lineTo(size.width, size.height * .55)
      ..lineTo(0, size.height * .55)
      ..close();
    canvas.drawPath(
      backHill,
      Paint()
        ..color = (dark ? const Color(0xFF5A425F) : const Color(0xFFD69CAF))
            .withValues(alpha: .48),
    );

    final frontHill = Path()
      ..moveTo(0, size.height * .47)
      ..quadraticBezierTo(size.width * .23, size.height * .37, size.width * .49,
          size.height * .48)
      ..quadraticBezierTo(
          size.width * .73, size.height * .36, size.width, size.height * .46)
      ..lineTo(size.width, size.height * .62)
      ..lineTo(0, size.height * .62)
      ..close();
    canvas.drawPath(
      frontHill,
      Paint()
        ..color = (dark ? const Color(0xFF3C3049) : const Color(0xFFB5758C))
            .withValues(alpha: .36),
    );

    final waterRect =
        Rect.fromLTWH(0, size.height * .48, size.width, size.height * .23);
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [
                  const Color(0xFF38415E).withValues(alpha: .42),
                  Colors.transparent
                ]
              : [
                  const Color(0xFF8FC7D8).withValues(alpha: .42),
                  Colors.white.withValues(alpha: .08)
                ],
        ).createShader(waterRect),
    );

    final wave = Paint()
      ..color = Colors.white.withValues(alpha: dark ? .10 : .36)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.52 + i * .027);
      final path = Path()..moveTo(size.width * .07, y);
      for (var x = size.width * .07; x < size.width; x += 34) {
        path.quadraticBezierTo(x + 8, y - 3, x + 17, y);
        path.quadraticBezierTo(x + 25, y + 3, x + 34, y);
      }
      canvas.drawPath(path, wave);
    }

    final heartPaint = Paint()
      ..color = AppColors.rose.withValues(alpha: dark ? .17 : .23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    _drawHeart(
        canvas, Offset(size.width * .10, size.height * .23), 7, heartPaint);
    _drawHeart(
        canvas, Offset(size.width * .90, size.height * .17), 5, heartPaint);
    _drawHeart(
        canvas, Offset(size.width * .17, size.height * .57), 4, heartPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size)
      ..cubicTo(center.dx - size * 1.7, center.dy, center.dx - size,
          center.dy - size, center.dx, center.dy)
      ..cubicTo(center.dx + size, center.dy - size, center.dx + size * 1.7,
          center.dy, center.dx, center.dy + size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LoveLandscapePainter oldDelegate) =>
      oldDelegate.dark != dark;
}
