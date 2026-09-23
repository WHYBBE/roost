import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roost/data/app_database.dart';
import 'package:roost/l10n/app_localizations.dart';
import 'package:roost/pages/tags_page.dart';

Widget _harness() {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () => showTagEditor(
            context,
            tag: Tag(
              id: 1,
              name: '测试',
              icon: null,
              glyph: null,
              color: null,
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

BoxDecoration? _optionDecoration(WidgetTester tester, Finder inner) {
  final container = tester.widget<Container>(
    find.ancestor(of: inner, matching: find.byType(Container)).first,
  );
  return container.decoration as BoxDecoration?;
}

void main() {
  testWidgets('material 图标可点选', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 初始：无 选中（primaryContainer 高亮）
    final noneBefore = _optionDecoration(
      tester,
      find.text('无').first,
    );
    expect(noneBefore?.color, isNotNull);

    // 点选 spa 图标
    await tester.tap(find.byIcon(Icons.spa));
    await tester.pump();

    final spaAfter = _optionDecoration(tester, find.byIcon(Icons.spa));
    final noneAfter = _optionDecoration(tester, find.text('无').first);
    // 选中态应为 primaryContainer 色且带边框
    expect(spaAfter?.border, isNotNull,
        reason: '点击后 spa 应处于选中态（带边框）');
    expect(noneAfter?.border, isNull, reason: '点击后 无 应取消选中');
  });

  testWidgets('emoji 可点选且颜色始终可用', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 切到 Emoji 标签页
    await tester.tap(find.text('Emoji'));
    await tester.pumpAndSettle();

    // 自定义字符输入框存在，且颜色区始终可点（无禁用提示）
    expect(find.text('输入任意字符或 Emoji'), findsOneWidget);
    expect(find.text('Emoji 不支持自定义颜色'), findsNothing);

    await tester.ensureVisible(find.text('😀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😀'));
    await tester.pump();

    final emojiAfter = _optionDecoration(tester, find.text('😀'));
    expect(emojiAfter?.border, isNotNull, reason: '点击后 😀 应处于选中态');
  });

  testWidgets('字符图标：单字位通过，多字位拦截', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emoji'));
    await tester.pumpAndSettle();
    final field = find.byType(TextField).at(1);

    // 单个普通字符：无错误
    await tester.enterText(field, '好');
    await tester.pump();
    expect(find.text('只能输入一个字符或一个 Emoji'), findsNothing);

    // 多码点单 emoji（旗帜/ZWJ 序列）：无错误
    await tester.enterText(field, '🇨🇳');
    await tester.pump();
    expect(find.text('只能输入一个字符或一个 Emoji'), findsNothing);

    await tester.enterText(field, '👨‍👩‍👧');
    await tester.pump();
    expect(find.text('只能输入一个字符或一个 Emoji'), findsNothing);

    // 多个字位：显示错误，保存被阻止（弹窗保持打开）
    await tester.enterText(field, '哈哈');
    await tester.pump();
    expect(find.text('只能输入一个字符或一个 Emoji'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('编辑标签'), findsOneWidget, reason: '非法输入应阻止保存并保持弹窗');
  });
}
