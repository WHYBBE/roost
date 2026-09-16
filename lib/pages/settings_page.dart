import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.themeTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ThemeSetting>(
                segments: [
                  ButtonSegment(
                    value: ThemeSetting.system,
                    label: Text(l.themeSystem),
                    icon: const Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeSetting.light,
                    label: Text(l.themeLight),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeSetting.dark,
                    label: Text(l.themeDark),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {settings.theme},
                onSelectionChanged: (s) => settings.setTheme(s.first),
              ),
              const SizedBox(height: 24),
              Text(l.languageTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<LanguageSetting>(
                segments: [
                  ButtonSegment(
                    value: LanguageSetting.system,
                    label: Text(l.languageSystem),
                    icon: const Icon(Icons.public),
                  ),
                  ButtonSegment(
                    value: LanguageSetting.zh,
                    label: Text(l.languageZh),
                  ),
                  ButtonSegment(
                    value: LanguageSetting.en,
                    label: Text(l.languageEn),
                  ),
                ],
                selected: {settings.language},
                onSelectionChanged: (s) => settings.setLanguage(s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
