import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:one_four_three/core/settings/app_preferences.dart';
import 'package:one_four_three/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('haptics and reduce-motion preferences persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPreferences();
    await Future<void>.delayed(Duration.zero);

    await prefs.setHapticsEnabled(false);
    await prefs.setReduceMotion(true);

    expect(prefs.hapticsEnabled, isFalse);
    expect(prefs.reduceMotion, isTrue);

    final stored = await SharedPreferences.getInstance();
    expect(stored.getBool('app_haptics_enabled'), isFalse);
    expect(stored.getBool('app_reduce_motion'), isTrue);
  });

  test('critical notification and connection labels are localized', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = AppLocalizations(locale);
      for (final key in [
        'notificationPreferences',
        'hapticsVibration',
        'reduceMotion',
        'moodNeedYouTitle',
        'touchHoldHint',
      ]) {
        expect(l.t(key), isNot(equals(key)), reason: '${locale.languageCode}: $key');
      }
    }
  });
}
