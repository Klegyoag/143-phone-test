import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/l10n/app_localizations.dart';

void main() {
  test('five primary navigation labels are translated in all required locales', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(locale);
      for (final key in ['home', 'memories', 'create', 'chat', 'us']) {
        expect(l10n.t(key), isNotEmpty);
        expect(l10n.t(key), isNot(key));
      }
    }
  });

  test('required locale set remains English Tamil Sinhala', () {
    expect(AppLocalizations.supportedLocales.map((e) => e.languageCode).toSet(), {'en', 'ta', 'si'});
  });

  test('unknown localization key falls back safely', () {
    expect(AppLocalizations(const Locale('en')).t('unknown_key'), 'unknown_key');
  });
}
