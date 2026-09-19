import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/database_provider.dart';
import '../data/data_io.dart';

import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _exportData(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  try {
    final content = jsonEncode(await appDb.exportData());
    final ok = await saveJsonToFile(content);
    if (!context.mounted) return;
    _snack(context, ok ? l.exportDone : l.exportUnsupported);
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

Future<void> _importData(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final content = await pickAndReadJson();
  if (content == null || !context.mounted) return;
  Map<String, dynamic> data;
  try {
    final decoded = jsonDecode(content);
    if (decoded is! Map || decoded['app'] != 'roost') {
      throw const FormatException();
    }
    data = Map<String, dynamic>.from(decoded);
  } catch (_) {
    if (context.mounted) _snack(context, l.importInvalid);
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.importData),
      content: Text(l.importMergeBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.importData),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final count = await appDb.importData(data);
    if (!context.mounted) return;
    _snack(context, l.importDone(count));
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  bool danger = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: scheme.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? AppLocalizations.of(context)!.confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<void> _resetMoodTags(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  if (!await _confirm(context, title: l.resetMoodTags, body: l.resetMoodBody)) {
    return;
  }
  try {
    await appDb.resetMoodTags();
    if (context.mounted) _snack(context, l.resetDone);
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

Future<void> _resetAllData(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  // 二次确认
  final first = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.resetAllData),
      content: Text(l.resetAllBody1),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.keepGoing),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return;
  final second = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.doubleConfirmTitle),
      content: Text(l.doubleConfirmClear),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.confirmClear),
        ),
      ],
    ),
  );
  if (second != true) return;
  try {
    await appDb.resetAllData();
    if (context.mounted) _snack(context, l.resetDone);
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

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
              Text(
                l.themeTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
              Text(
                l.languageTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
              const SizedBox(height: 24),
              Text(
                l.dataSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.save_alt_outlined),
                      title: Text(l.exportData),
                      onTap: () => _exportData(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text(l.importData),
                      onTap: () => _importData(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_outlined),
                      title: Text(l.resetMoodTags),
                      onTap: () => _resetMoodTags(context),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        l.resetAllData,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () => _resetAllData(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
