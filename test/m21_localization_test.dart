import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/l10n/app_localizations.dart';

void main() {
  test('critical accessibility strings exist in all supported locales', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(locale);
      expect(l10n.t('appearanceAccessibility'), isNot('appearanceAccessibility'));
      expect(l10n.t('higherContrast'), isNot('higherContrast'));
      expect(l10n.t('languageAppliesImmediately'), isNot('languageAppliesImmediately'));
    }
  });

  test('supported locales remain English Tamil Sinhala', () {
    expect(AppLocalizations.supportedLocales, const [Locale('en'), Locale('ta'), Locale('si')]);
  });
}
