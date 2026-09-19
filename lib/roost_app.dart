import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/data_io.dart';
import 'data/database_provider.dart';
import 'l10n/app_localizations.dart';
import 'pages/calendar_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/tags_page.dart';
import 'pages/wander_page.dart';
import 'settings/app_settings.dart';

class RoostApp extends StatefulWidget {
  const RoostApp({super.key});

  @override
  State<RoostApp> createState() => _RoostAppState();
}

class _RoostAppState extends State<RoostApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onChanged);
    DataStore.instance.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHealth());
  }

  void _onChanged() => setState(() {});

  /// 启动健康检查：文件损坏/表结构不匹配时进入清理引导
  Future<void> _checkHealth() async {
    if (DataStore.instance.corrupted) return;
    final healthy = await appDb.isHealthy();
    if (!healthy) {
      DataStore.instance.setCorrupted(true);
    }
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onChanged);
    DataStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return MaterialApp(
      title: '思栖 Roost',
      debugShowCheckedModeBanner: false,
      themeMode: switch (settings.theme) {
        ThemeSetting.system => ThemeMode.system,
        ThemeSetting.light => ThemeMode.light,
        ThemeSetting.dark => ThemeMode.dark,
      },
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: switch (settings.language) {
        LanguageSetting.system => null,
        LanguageSetting.zh => const Locale('zh'),
        LanguageSetting.en => const Locale('en'),
      },
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 数据库实例被替换（清理/重置）时以 epoch 为 key 强制整树重建
      home: DataStore.instance.corrupted
          ? const _CorruptedDataView()
          : KeyedSubtree(
              key: ValueKey('db-epoch-${DataStore.instance.epoch}'),
              child: const ResponsiveShell(),
            ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final seed = Color(AppSettings.instance.seedColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      // 选中态靠底色与头像表达；勾选图标与头像重叠显乱
      chipTheme: const ChipThemeData(showCheckmark: false),
    );
  }
}

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _index = 0;

  static const _pages = [
    HomePage(),
    TagsPage(),
    CalendarPage(),
    WanderPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final destinations = [
      (icon: Icons.psychology_alt_outlined, selected: Icons.psychology_alt, label: l.navHome),
      (icon: Icons.sell_outlined, selected: Icons.sell, label: l.navTags),
      (icon: Icons.calendar_month_outlined, selected: Icons.calendar_month, label: l.navCalendar),
      (icon: Icons.explore_outlined, selected: Icons.explore, label: l.navWander),
      (icon: Icons.settings_outlined, selected: Icons.settings, label: l.navSettings),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          '思栖',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Roost',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
            Expanded(child: _pages[_index]),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}

/// 数据异常引导页：清理数据（二次确认后执行）
class _CorruptedDataView extends StatelessWidget {
  const _CorruptedDataView();

  Future<void> _clearData(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.dataCorruptTitle),
        content: Text(l.dataCorruptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.cleanData),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;
    // 二次确认
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
    // 依次尝试：SQL 清空 → 换新库实例 → 删除库文件重建
    try {
      await appDb.resetAllData();
    } catch (_) {
      await DataStore.instance.reopen();
      try {
        await appDb.resetAllData();
      } catch (_) {
        await deleteDataFiles();
        await DataStore.instance.reopen();
      }
    }
    DataStore.instance.setCorrupted(false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.appName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  l.dataCorruptTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l.dataCorruptBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: scheme.error),
                  onPressed: () => _clearData(context),
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text(l.cleanData),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
