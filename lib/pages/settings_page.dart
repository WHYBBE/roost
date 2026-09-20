import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/database_provider.dart';
import '../data/data_io.dart';
import '../data/tag_presets.dart';
import '../settings/app_settings.dart';
import '../ui/vault_switcher.dart';

import '../l10n/app_localizations.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

/// 主题种子色圆点：统一尺寸圆形，选中带描边+对勾；默认项带“默”字标识与 Tooltip
Widget _seedSwatch(
  BuildContext context, {
  required Color color,
  required bool selected,
  required VoidCallback onTap,
  bool isDefault = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  Widget dot = InkWell(
    customBorder: const CircleBorder(),
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : isDefault
                ? Text(
                    '默',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  )
                : null,
      ),
    ),
  );
  // Tooltip 要求 message 非空，仅默认项包裹
  if (isDefault) {
    dot = Tooltip(
      message: AppLocalizations.of(context)!.defaultColor,
      child: dot,
    );
  }
  return dot;
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

/// 弹窗输入一段文本（取消返回 null）
Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: hint),
        onSubmitted: (_) => Navigator.pop(context, true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.confirm),
        ),
      ],
    ),
  );
  return ok == true ? controller.text.trim() : null;
}

/// 新建保险库：输入名称后创建并切换过去
Future<void> _createVault(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final store = DataStore.instance;
  final name = await _promptText(
    context,
    title: l.createVault,
    hint: l.vaultNameHint,
  );
  if (name == null || !context.mounted) return;
  try {
    await store.createVault(name);
    await store.checkHealth();
    if (context.mounted) _snack(context, l.vaultCreated);
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

Future<void> _renameVault(BuildContext context, VaultMeta vault) async {
  final l = AppLocalizations.of(context)!;
  final store = DataStore.instance;
  final name = await _promptText(
    context,
    title: l.renameVault,
    initial: vault.name,
    hint: l.vaultNameHint,
  );
  if (name == null) return;
  try {
    await store.renameVault(vault.id, name);
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

Future<void> _deleteVault(BuildContext context, VaultMeta vault) async {
  final l = AppLocalizations.of(context)!;
  final store = DataStore.instance;
  if (store.vaults.length <= 1) {
    _snack(context, l.lastVaultWarn);
    return;
  }
  if (!await _confirm(
    context,
    title: l.deleteVault,
    body: l.deleteVaultBody(vault.name),
    confirmLabel: l.deleteVault,
    danger: true,
  )) {
    return;
  }
  try {
    await store.deleteVault(vault.id);
    if (context.mounted) _snack(context, l.vaultDeleted);
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
}

/// 切换保险库后对新库做健康检查
Future<void> _switchVault(BuildContext context, VaultMeta vault) async {
  final l = AppLocalizations.of(context)!;
  final store = DataStore.instance;
  try {
    await store.switchVault(vault.id);
    await store.checkHealth();
  } catch (_) {
    if (context.mounted) _snack(context, l.opFailed);
  }
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

  Widget _buildVaultTile(BuildContext context, VaultMeta vault) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final store = DataStore.instance;
    final active = store.currentVault?.id == vault.id;
    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(vault.name),
      subtitle: active
          ? Text(
              l.vaultActive,
              style: TextStyle(color: scheme.primary, fontSize: 12),
            )
          : null,
      onTap: active ? null : () => _switchVault(context, vault),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => switch (action) {
          'rename' => _renameVault(context, vault),
          'delete' => _deleteVault(context, vault),
          _ => null,
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: Text(l.renameVault),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(
              l.deleteVault,
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(
        // 桌面端内嵌为根页时展示保险库切换；移动端经路由推入时保留默认返回键
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? null
            : appBarVaultSwitcher(context),
        title: Text(l.settingsTitle),
      ),
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
                l.themeColorTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // 统一圆形网格：两行（默认+5 / 5），点阵对齐
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _seedSwatch(
                        context,
                        color: const Color(defaultSeedColor),
                        selected: settings.seedColor == defaultSeedColor,
                        isDefault: true,
                        onTap: () => settings.setSeedColor(defaultSeedColor),
                      ),
                      for (final c in tagColorChoices.take(5)) ...[
                        const SizedBox(width: 10),
                        _seedSwatch(
                          context,
                          color: Color(c),
                          selected: settings.seedColor == c,
                          onTap: () => settings.setSeedColor(c),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final c in tagColorChoices.skip(5)) ...[
                        _seedSwatch(
                          context,
                          color: Color(c),
                          selected: settings.seedColor == c,
                          onTap: () => settings.setSeedColor(c),
                        ),
                        if (c != tagColorChoices.last)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ],
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
                l.weekStartTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<WeekStart>(
                segments: [
                  ButtonSegment(
                    value: WeekStart.sunday,
                    label: Text(l.weekStartSunday),
                  ),
                  ButtonSegment(
                    value: WeekStart.monday,
                    label: Text(l.weekStartMonday),
                  ),
                ],
                selected: {settings.weekStart},
                onSelectionChanged: (s) => settings.setWeekStart(s.first),
              ),
              const SizedBox(height: 24),
              Text(
                l.vaultTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l.vaultSectionHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final vault in DataStore.instance.vaults)
                      _buildVaultTile(context, vault),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text(l.createVault),
                      onTap: () => _createVault(context),
                    ),
                  ],
                ),
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
