import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/navigation/deep_link_target.dart';
import 'package:one_four_three/l10n/app_localizations.dart';

void main() {
  test('unknown legacy links fall back safely to Home', () {
    final target =
        DeepLinkTarget.fromUri(Uri.parse('onefourthree://legacy/old-link'));
    expect(target.location, '/app?tab=0');
    expect(target.tabIndex, 0);
  });

  test('Tamil and Sinhala navigation labels are real localized values', () {
    expect(AppLocalizations(const Locale('ta')).t('home'), 'முகப்பு');
    expect(AppLocalizations(const Locale('si')).t('us'), 'අපි');
  });
}
