import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onChanged);
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
      home: const ResponsiveShell(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    const seed = Color(0xFF5C7C6D);
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
