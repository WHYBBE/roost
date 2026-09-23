import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roost/data/app_database.dart';
import 'package:roost/data/database_provider.dart';
import 'package:roost/data/tag_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('roost-vault-test');
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  // 每个库名对应临时目录下的独立 sqlite 文件，模拟 vault 文件隔离
  AppDatabase openVault(String name) =>
      AppDatabase.connect(NativeDatabase(File('${tempDir.path}/$name.sqlite')));

  test('保险库创建/切换/删除/重命名，数据完全隔离', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DataStore.forTest(open: openVault);
    await store.init();
    expect(store.ready, isTrue);
    expect(store.corrupted, isFalse);

    // 默认库：首个保险库沿用默认文件名，写入一条思绪与标签
    expect(store.vaults, hasLength(1));
    expect(store.currentVault, isNotNull);
    final dbA = store.db;
    await dbA.insertThought(
      content: 'A 库的思绪',
      day: '2026-09-19',
      createdAt: DateTime(2026, 9, 19, 8),
    );
    await dbA.getOrCreateTag('A标签');

    // 新建保险库：自动切换，内容为空且仅含预设心情
    await store.createVault('B 库');
    expect(store.vaults, hasLength(2));
    expect(store.currentVault!.name, 'B 库');
    final dbB = store.db;
    expect(await dbB.select(dbB.thoughts).get(), isEmpty);
    final moodCat = await dbB.watchMoodCategory().first;
    expect(await dbB.categoryTags(moodCat!.id), hasLength(moodPresets.length));

    // 切回默认库：数据原样保留（完全隔离）
    await store.switchVault(store.vaults.first.id);
    final reopenedA = store.db;
    final aThoughts = await reopenedA.select(reopenedA.thoughts).get();
    expect(aThoughts.single.content, 'A 库的思绪');
    expect(aThoughts.single.day, '2026-09-19');

    // 重命名
    final vaultB = store.vaults.last;
    await store.renameVault(vaultB.id, 'B 改');
    expect(store.vaults.last.name, 'B 改');

    // 删除当前所在的库：自动回到剩余库
    await store.switchVault(vaultB.id);
    await store.deleteVault(vaultB.id);
    expect(store.vaults, hasLength(1));
    expect(store.currentVault!.id, store.vaults.first.id);

    // 仅剩一个库时不可删除
    await store.deleteVault(store.vaults.first.id);
    expect(store.vaults, hasLength(1));

    // 注册表持久化：新实例读到相同清单与数据
    await store.renameVault(store.vaults.first.id, '主库');
    final store2 = DataStore.forTest(open: openVault);
    await store2.init();
    expect(store2.vaults, hasLength(1));
    expect(store2.vaults.single.name, '主库');
    final db2 = store2.db;
    final persisted = await db2.select(db2.thoughts).get();
    expect(persisted.single.content, 'A 库的思绪');

    await store.db.close();
    await db2.close();
  });
}
