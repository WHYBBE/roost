import 'package:flutter_test/flutter_test.dart';
import 'package:roost/data/app_database.dart';
import 'package:roost/settings/app_settings.dart';
import 'package:roost/settings/lock_session.dart';
import 'package:roost/ui/lock_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hashSecret 确定性，盐与密码不同则哈希不同', () {
    expect(hashSecret('salt', '1234'), hashSecret('salt', '1234'));
    expect(hashSecret('salt', '1234'), isNot(hashSecret('salt', '1235')));
    expect(hashSecret('salt', '1234'), isNot(hashSecret('other', '1234')));
  });

  test('AppSettings：设置/校验/清除应用锁（PIN 与图案）', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppSettings.instance;
    await s.load();
    expect(s.lockConfigured, isFalse);

    await s.setLockSecret(LockMethod.pin, '1234');
    expect(s.lockConfigured, isTrue);
    expect(s.lockMethod, LockMethod.pin);
    expect(s.matchesLockSecret('1234'), isTrue);
    expect(s.matchesLockSecret('4321'), isFalse);

    // 图案：点序以逗号连接
    await s.setLockSecret(LockMethod.pattern, '0,1,2,5');
    expect(s.lockMethod, LockMethod.pattern);
    expect(s.matchesLockSecret('0,1,2,5'), isTrue);
    expect(s.matchesLockSecret('0,1,2,4'), isFalse);

    await s.clearLock();
    expect(s.lockConfigured, isFalse);
    expect(s.matchesLockSecret('0,1,2,5'), isFalse);
  });

  test('LockSession：未配置恒解锁，配置后需会话解锁', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppSettings.instance;
    await s.load();
    final session = LockSession.instance;
    session.reset();

    expect(session.unlocked, isTrue);
    expect(session.needsUnlock, isFalse);

    await s.setLockSecret(LockMethod.pin, '1234');
    session.reset();
    expect(session.unlocked, isFalse);
    expect(session.needsUnlock, isTrue);

    session.unlock();
    expect(session.unlocked, isTrue);
    expect(session.needsUnlock, isFalse);

    session.lock();
    expect(session.needsUnlock, isTrue);

    // 关闭应用锁后恒解锁
    await s.clearLock();
    session.reset();
    expect(session.unlocked, isTrue);
  });

  test('遮罩判定：未配置锁不遮罩；配置且未解锁遮罩，解锁后恢复', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppSettings.instance;
    await s.load();
    final session = LockSession.instance;
    session.reset();

    final lockedEntry = const ThoughtEntry(
      id: 1,
      content: '私密',
      day: '2026-09-20',
      createdAt: 0,
      updatedAt: 0,
      locked: true,
    );
    final publicEntry = const ThoughtEntry(
      id: 2,
      content: '公开',
      day: '2026-09-20',
      createdAt: 0,
      updatedAt: 0,
      locked: false,
    );
    const event = CalendarEvent(
      id: 1,
      typeId: 1,
      title: '私密内容',
      startDate: '2026-09-20',
      annual: false,
      count: 1,
      thoughtId: 1,
    );

    // 未配置锁：一律不遮罩
    expect(isEntryMasked(lockedEntry), isFalse);
    expect(isEventTitleMasked(event, const {1}), isFalse);

    await s.setLockSecret(LockMethod.pin, '1234');
    session.reset();
    expect(isEntryMasked(lockedEntry), isTrue);
    expect(isEntryMasked(publicEntry), isFalse);
    expect(isEventTitleMasked(event, const {1}), isTrue);
    expect(isEventTitleMasked(event, const {}), isFalse);
    expect(eventDisplayTitle(event, '类型', const {1}), '类型');
    expect(eventDisplayTitle(event, '类型', const {}), '私密内容');

    session.unlock();
    expect(isEntryMasked(lockedEntry), isFalse);
    expect(isEventTitleMasked(event, const {1}), isFalse);

    await s.clearLock();
    session.reset();
  });
}
