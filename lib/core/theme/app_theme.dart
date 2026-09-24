import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) =>
      _build(Brightness.light, highContrast: highContrast);
  static ThemeData dark({bool highContrast = false}) =>
      _build(Brightness.dark, highContrast: highContrast);

  static ThemeData _build(Brightness brightness, {required bool highContrast}) {
    final dark = brightness == Brightness.dark;
    final background = dark ? AppColors.darkBackground : AppColors.ivory;
    final surface = dark ? AppColors.darkSurface : AppColors.paper;
    final ink = dark ? AppColors.darkInk : AppColors.ink;
    final muted = dark ? AppColors.darkMuted : AppColors.muted;
    final divider = highContrast
        ? (dark ? Colors.white54 : AppColors.wine)
        : (dark ? AppColors.darkBorder : AppColors.divider);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: dark
          ? const ColorScheme.dark(
              primary: Color(0xFFFF6F91),
              onPrimary: Colors.white,
              secondary: Color(0xFFFFB5C5),
              onSecondary: Color(0xFF351322),
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkInk,
              onSurfaceVariant: AppColors.darkMuted,
              outline: AppColors.darkBorder,
              error: Color(0xFFFF8A98),
            )
          : ColorScheme.fromSeed(
              seedColor: AppColors.rose,
              brightness: brightness,
              primary: AppColors.rose,
              secondary: AppColors.wine,
              surface: surface),
    );
    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displaySmall: GoogleFonts.playfairDisplay(
            fontSize: 38,
            fontWeight: FontWeight.w600,
            color: ink,
            height: 1.12),
        headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 28, fontWeight: FontWeight.w600, color: ink),
        titleLarge: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w600, color: ink),
        titleMedium: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: ink, height: 1.45),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: muted, height: 1.4),
      ),
      dividerColor: divider,
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: dark
              ? AppColors.darkSurfaceHigh
              : Colors.white.withValues(alpha: .78),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(color: divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(color: divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide:
                  const BorderSide(color: Color(0xFF62AEDD), width: 1.6)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              textStyle: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 15))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
      iconButtonTheme: const IconButtonThemeData(
          style:
              ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48)))),
      cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side:
                  highContrast ? BorderSide(color: divider) : BorderSide.none),
          margin: EdgeInsets.zero),
      navigationBarTheme: NavigationBarThemeData(
          height: 76,
          backgroundColor: dark
              ? const Color(0xFF191421)
              : Colors.white.withValues(alpha: .96),
          indicatorColor: dark ? const Color(0xFF49283B) : AppColors.sky,
          labelTextStyle: WidgetStateProperty.all(
              GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700))),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AppColors.darkSurfaceHigh : AppColors.ink,
        contentTextStyle:
            TextStyle(color: dark ? AppColors.darkInk : Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
