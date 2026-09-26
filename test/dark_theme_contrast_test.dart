import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/theme/app_colors.dart';
import 'package:one_four_three/core/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  testWidgets('dark hero and cards keep readable foreground contrast',
      (tester) async {
    late LinearGradient gradient;
    late Color card;
    late Color secondary;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(builder: (context) {
        gradient = AppColors.heroGradient(context);
        card = AppColors.cardSurface(context);
        secondary = AppColors.secondaryText(context);
        return const SizedBox();
      }),
    ));

    for (final color in gradient.colors) {
      expect(_contrast(color, AppColors.darkInk), greaterThanOrEqualTo(4.5));
      expect(_contrast(color, secondary), greaterThanOrEqualTo(4.5));
    }
    expect(_contrast(card, AppColors.darkInk), greaterThanOrEqualTo(4.5));
  });
}
