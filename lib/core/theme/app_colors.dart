import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ivory = Color(0xFFFFF9F5);
  static const paper = Color(0xFFFFFCFA);
  static const blush = Color(0xFFFFECEF);
  static const blushStrong = Color(0xFFFFDCE4);
  static const rose = Color(0xFFE95D78);
  static const roseDark = Color(0xFFC73C5A);
  static const wine = Color(0xFF34436A);
  static const ink = Color(0xFF17213F);
  static const muted = Color(0xFF6F7892);
  static const peach = Color(0xFFFFEEE7);
  static const lavender = Color(0xFFEFE6FF);
  static const sky = Color(0xFFE2F0FF);
  static const butter = Color(0xFFFFF0CF);
  static const divider = Color(0xFFE6E8F0);

  static const darkBackground = Color(0xFF100D18);
  static const darkSurface = Color(0xFF1B1625);
  static const darkSurfaceHigh = Color(0xFF282033);
  static const darkBlush = Color(0xFF371E2B);
  static const darkPeach = Color(0xFF32201F);
  static const darkBorder = Color(0xFF41354B);
  static const darkInk = Color(0xFFFFF7FA);
  static const darkMuted = Color(0xFFC8BDCD);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static LinearGradient heroGradient(BuildContext context) => LinearGradient(
        colors: isDark(context)
            ? const [Color(0xFF332333), Color(0xFF242034)]
            : const [blush, peach],
      );

  static Color softSurface(BuildContext context) =>
      isDark(context) ? darkSurfaceHigh : blush;

  static Color cardSurface(BuildContext context) =>
      isDark(context) ? darkSurfaceHigh : paper;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? darkMuted : muted;
}
