import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class PersonalizationScreen extends ConsumerWidget {
  const PersonalizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('appearanceAccessibility'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _section(context, l10n.t('appearance')),
          Card(
            child: Column(children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: prefs.themeMode,
                title: Text(l10n.t('systemTheme')),
                secondary: const Icon(Icons.settings_suggest_outlined),
                onChanged: (v) { if (v != null) prefs.setThemeMode(v); },
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: prefs.themeMode,
                title: Text(l10n.t('lightTheme')),
                secondary: const Icon(Icons.light_mode_outlined),
                onChanged: (v) { if (v != null) prefs.setThemeMode(v); },
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: prefs.themeMode,
                title: Text(l10n.t('darkTheme')),
                secondary: const Icon(Icons.dark_mode_outlined),
                onChanged: (v) { if (v != null) prefs.setThemeMode(v); },
              ),
            ]),
          ),
          _section(context, l10n.t('textSize')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Semantics(
                  label: '${l10n.t('textSize')}: ${(prefs.fontScale * 100).round()} percent',
                  slider: true,
                  value: '${(prefs.fontScale * 100).round()}%',
                  child: Row(children: [
                    const ExcludeSemantics(child: Text('A', style: TextStyle(fontSize: 13))),
                    Expanded(
                      child: Slider(
                        value: prefs.fontScale,
                        min: .85,
                        max: 1.35,
                        divisions: 10,
                        label: '${(prefs.fontScale * 100).round()}%',
                        onChanged: prefs.setFontScale,
                      ),
                    ),
                    const ExcludeSemantics(child: Text('A', style: TextStyle(fontSize: 22))),
                  ]),
                ),
                Text(l10n.t('readableLoveSample'), style: Theme.of(context).textTheme.bodyLarge),
              ]),
            ),
          ),
          _section(context, l10n.t('accessibility')),
          Card(
            child: SwitchListTile(
              value: prefs.highContrast,
              title: Text(l10n.t('higherContrast')),
              subtitle: Text(l10n.t('higherContrastBody')),
              secondary: const Icon(Icons.contrast_rounded, color: AppColors.rose),
              onChanged: prefs.setHighContrast,
            ),
          ),
          _section(context, l10n.t('language')),
          Card(
            child: DropdownButtonFormField<String>(
              value: prefs.language,
              decoration: InputDecoration(border: InputBorder.none, prefixIcon: const Icon(Icons.language_rounded), semanticCounterText: l10n.t('language')),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                DropdownMenuItem(value: 'si', child: Text('සිංහල')),
              ],
              onChanged: (v) { if (v != null) prefs.setLanguage(v); },
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(l10n.t('languageAppliesImmediately'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}
