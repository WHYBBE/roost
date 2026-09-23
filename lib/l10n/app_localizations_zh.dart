// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '思栖';

  @override
  String get navHome => '思绪';

  @override
  String get navCalendar => '日历';

  @override
  String get navWander => '漫步';

  @override
  String get navSettings => '设置';

  @override
  String get newThought => '新的思绪';

  @override
  String get editThought => '编辑思绪';

  @override
  String get thoughtHint => '此刻在想什么？';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get confirmDeleteTitle => '删除这条思绪？';

  @override
  String get confirmDeleteBody => '删除后无法恢复。';

  @override
  String get emptyThoughts => '还没有思绪。\n写下第一条吧。';

  @override
  String get emptyDay => '这一天没有记录。';

  @override
  String get addEntry => '记一条';

  @override
  String get recordDay => '记录日';

  @override
  String get moodLabel => '心情';

  @override
  String get tagEditorTitle => '编辑标签';

  @override
  String get tagName => '名称';

  @override
  String get tagIcon => '图标';

  @override
  String get tagEmoji => 'Emoji';

  @override
  String get glyphHint => '输入任意字符或 Emoji';

  @override
  String get glyphOnlyOne => '只能输入一个字符或一个 Emoji';

  @override
  String get noIcon => '无';

  @override
  String get tagColor => '颜色';

  @override
  String get defaultColor => '默认';

  @override
  String get kindMood => '心情';

  @override
  String get kindNormal => '标签';

  @override
  String get createMoodTag => '新建心情';

  @override
  String get searchHint => '搜索思绪…';

  @override
  String get wanderTitle => '每日漫步';

  @override
  String get onThisDayHeader => '那年今日';

  @override
  String get randomHeader => '随机漫游';

  @override
  String get thisWeekTitle => '本周回顾';

  @override
  String get thisMonthTitle => '本月回顾';

  @override
  String get recapEmpty => '这段时间还没有记录。';

  @override
  String get showAll => '显示全部';

  @override
  String get collapse => '收起';

  @override
  String get templatesTitle => '写作模板';

  @override
  String get templatesHint => '预设多行文本（如“今日三问”），写思绪时一键插入。';

  @override
  String get manageTemplates => '管理模板';

  @override
  String get insertTemplate => '插入模板';

  @override
  String get pickTemplate => '选择模板';

  @override
  String get newTemplate => '新建模板';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get templateName => '模板名称';

  @override
  String get templateContent => '内容';

  @override
  String get templateHint => '可含多行；插入后可自由编辑。';

  @override
  String get templatesEmpty => '还没有模板。\n点右下角 + 新建一个，如“今日三问”。';

  @override
  String get templateNameEmpty => '模板名不能为空';

  @override
  String get templateContentEmpty => '模板内容不能为空';

  @override
  String get deleteTemplateTitle => '删除这个模板？';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String onThisDay(int years) {
    return '$years 年前的今天';
  }

  @override
  String get noMemories => '还没有可以回味的记忆。\n写一段时间后再来看看。';

  @override
  String get shuffle => '换一换';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记录',
      zero: '无记录',
    );
    return '$_temp0';
  }

  @override
  String streak(int days) {
    return '连续 $days 天';
  }

  @override
  String totalEntries(int count) {
    return '共 $count 条';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTabAppearance => '外观';

  @override
  String get settingsTabGeneral => '通用';

  @override
  String get settingsTabWriting => '写作';

  @override
  String get settingsTabSecurity => '安全';

  @override
  String get settingsTabData => '数据';

  @override
  String get themeTitle => '主题';

  @override
  String get themeColorTitle => '主题色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get less => '少';

  @override
  String get more => '多';

  @override
  String get today => '今天';

  @override
  String get saved => '已保存';

  @override
  String get todayEntryExists => '今天已经写过啦，不错。';

  @override
  String wordCount(int count) {
    return '$count 字';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterByMood => '按心情筛选';

  @override
  String get navTags => '标签';

  @override
  String get tagsEmpty => '还没有标签。\n给思绪添加标签后会显示在这里。';

  @override
  String get tagHint => '标签（用空格分隔）';

  @override
  String get tagAdd => '添加';

  @override
  String get renameTag => '重命名标签';

  @override
  String get deleteTag => '删除标签';

  @override
  String deleteTagBody(int count) {
    return '该标签将从 $count 条思绪中移除，思绪本身不会被删除。';
  }

  @override
  String get tagNameEmpty => '标签名不能为空';

  @override
  String get tagExists => '已存在同名标签';

  @override
  String get addTag => '新建标签';

  @override
  String get addMood => '新建心情';

  @override
  String get moodManagement => '心情管理';

  @override
  String moodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个心情',
    );
    return '$_temp0';
  }

  @override
  String get moodsEmpty => '还没有心情。\n点右上角 + 新建一个。';

  @override
  String get viewEntries => '查看思绪';

  @override
  String yearTotal(int year, int count) {
    return '$year 年 · $count 条';
  }

  @override
  String get keepWriting => '继续记录';

  @override
  String longestStreak(Object days) {
    return '最长 $days 天';
  }

  @override
  String get longestStreakLabel => '最长连击';

  @override
  String get confirm => '确认';

  @override
  String get keepGoing => '继续';

  @override
  String get vaultTitle => '保险库';

  @override
  String get vaultSectionHint => '每个保险库的思绪与标签完全独立。';

  @override
  String get vaultActive => '当前';

  @override
  String get createVault => '新建保险库';

  @override
  String get vaultNameHint => '保险库名称';

  @override
  String get vaultCreated => '已创建并切换到新保险库';

  @override
  String get renameVault => '重命名保险库';

  @override
  String get deleteVault => '删除保险库';

  @override
  String deleteVaultBody(String name) {
    return '将永久删除「$name」中的全部数据，且无法恢复。';
  }

  @override
  String get vaultDeleted => '已删除保险库';

  @override
  String get lastVaultWarn => '至少保留一个保险库';

  @override
  String get dataSection => '数据';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据（合并）';

  @override
  String get resetMoodTags => '重置心情标签';

  @override
  String get resetAllData => '清空全部数据';

  @override
  String get exportDone => '已导出';

  @override
  String get exportUnsupported => '当前平台不支持导出';

  @override
  String get importMergeBody => '导入的思绪与标签将合并到现有数据中。';

  @override
  String importDone(int count) {
    return '已导入 $count 条';
  }

  @override
  String get importInvalid => '文件格式不正确';

  @override
  String get resetMoodBody => '将删除全部心情标签及其标记，然后恢复预设心情。普通标签与思绪不受影响。';

  @override
  String get resetAllBody1 => '将删除全部思绪、标签与心情，此操作无法撤销。';

  @override
  String get doubleConfirmTitle => '二次确认';

  @override
  String get doubleConfirmClear => '再确认一次：真的要清空本地数据吗？';

  @override
  String get confirmClear => '确认清空';

  @override
  String get resetDone => '已重置';

  @override
  String get opFailed => '操作失败';

  @override
  String get dataCorruptTitle => '数据异常';

  @override
  String get dataCorruptBody => '本地数据无法读取，可能已损坏。清理后应用将重置为初始状态（恢复预设心情），此操作无法撤销。';

  @override
  String get cleanData => '清理数据';

  @override
  String get attachments => '附件';

  @override
  String get commentsLabel => '评论';

  @override
  String get commentHint => '写下评论…';

  @override
  String get addComment => '添加评论';

  @override
  String get deleteComment => '删除评论';

  @override
  String get reactionsLabel => '反应';

  @override
  String get addReaction => '添加反应';

  @override
  String get deleteReaction => '移除反应';

  @override
  String get archiveTrashTitle => '归档与回收站';

  @override
  String get archiveTab => '归档';

  @override
  String get trashTab => '回收站';

  @override
  String get archive => '归档';

  @override
  String get unarchive => '取消归档';

  @override
  String get moveToTrash => '删除';

  @override
  String get restore => '恢复';

  @override
  String get deleteForever => '永久删除';

  @override
  String get deleteForeverBody => '永久删除后无法恢复。';

  @override
  String get emptyTrash => '清空回收站';

  @override
  String get emptyTrashBody => '将永久删除回收站中的全部思绪，无法恢复。';

  @override
  String get emptyArchiveHint => '还没有归档的思绪';

  @override
  String get emptyTrashHint => '回收站是空的';

  @override
  String get trashRetentionHint => '回收站中的思绪将在 7 天后自动清除。';

  @override
  String get movedToTrash => '已移入回收站';

  @override
  String get undo => '撤销';

  @override
  String get archiveHint => '归档 ≠ 删除：归档的思绪会一直保留在这里，可随时取消归档。';

  @override
  String get navInsights => '洞察';

  @override
  String get insightsTitle => '洞察';

  @override
  String get insightsOverview => '概览';

  @override
  String get totalThoughts => '总思绪';

  @override
  String get totalWords => '总字数';

  @override
  String get activeDays => '活跃天数';

  @override
  String get currentStreak => '当前连击';

  @override
  String daysValue(num count) {
    return '$count 天';
  }

  @override
  String get insightsMonthly => '月度趋势';

  @override
  String get seriesThoughts => '条数';

  @override
  String get seriesWords => '字数';

  @override
  String get insightsMood => '心情';

  @override
  String get moodDistribution => '心情分布';

  @override
  String get insightsTags => '标签 Top';

  @override
  String get insightsWritingTime => '写作时段';

  @override
  String get insightsCalendar => '日历洞察';

  @override
  String get eventTotal => '事件总数';

  @override
  String get eventTypeDistribution => '类型分布';

  @override
  String get insightsEmpty => '暂无数据';

  @override
  String get addImage => '添加图片';

  @override
  String get recordAudio => '录音';

  @override
  String get recordHint => '点按开始录音';

  @override
  String get recording => '录音中';

  @override
  String get stopRecord => '停止';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get attachmentTooLarge => '文件过大（单个最多 20 MB）';

  @override
  String get micPermissionDenied => '未获得麦克风权限';

  @override
  String get specialDaysTitle => '特殊日子';

  @override
  String get specialDaysHint => '以特殊思绪记录（万物皆思绪），每年同日循环出现。';

  @override
  String get specialDayEmpty => '还没有特殊日子';

  @override
  String get addSpecialDay => '添加特殊日子';

  @override
  String get specialDayNameHint => '名称，如：妈妈的生日';

  @override
  String get specialDayDate => '日期';

  @override
  String get holidayPlanTitle => '放假安排';

  @override
  String get holidayPlanHint => '周六日默认休息；点按日期可设为休/班，国家法定假日与调休手动录入。';

  @override
  String get restLabel => '休';

  @override
  String get workLabel => '班';

  @override
  String get clearFlag => '清除标记';

  @override
  String get defaultRestLabel => '默认休';

  @override
  String get glyphRest => '休';

  @override
  String get glyphWork => '班';

  @override
  String get weekStartTitle => '每周起始日';

  @override
  String get weekStartSunday => '周日';

  @override
  String get weekStartMonday => '周一';

  @override
  String get calendarManageTitle => '日历管理';

  @override
  String get dayEventsLabel => '事件';

  @override
  String get eventTypesSection => '事件类型';

  @override
  String get specialThoughtsSection => '特殊日子（思绪）';

  @override
  String get addEventType => '新建类型';

  @override
  String get editType => '编辑类型';

  @override
  String get typeNameHint => '名称，如：2026 法定节假日';

  @override
  String get markNone => '无';

  @override
  String get cornerGlyphHint => '字符角标（可选）';

  @override
  String get statusPresetTitle => '状态预设';

  @override
  String get statusLabel => '状态';

  @override
  String get statusNameHint => '状态名（如：已完成）';

  @override
  String get statusGlyphHint => '字符';

  @override
  String get addStatus => '添加状态';

  @override
  String get statusRest => '放假';

  @override
  String get statusMakeup => '补班';

  @override
  String get addEvent => '添加事件';

  @override
  String get editEvent => '编辑事件';

  @override
  String get deleteEvent => '删除事件';

  @override
  String get eventTitleHint => '标题（可选，默认用类型名）';

  @override
  String get startDateLabel => '开始日期';

  @override
  String get endDateLabel => '结束日期（可选，长按清除）';

  @override
  String get annualRecur => '每年循环';

  @override
  String get recordAsThought => '同时记录为思绪';

  @override
  String get deleteType => '删除类型';

  @override
  String deleteTypeBody(String name) {
    return '将删除\"$name\"及其下全部事件。';
  }

  @override
  String get emptyTypes => '还没有类型，点右下角新建';

  @override
  String eventsCount(int count) {
    return '$count 个事件';
  }

  @override
  String get presetHoliday => '法定节假日';

  @override
  String get presetMakeup => '调休补班';

  @override
  String get presetBirthday => '生日';

  @override
  String get presetPeriod => '月经周期';

  @override
  String get presetTravel => '旅行';

  @override
  String get counterType => '计数器';

  @override
  String get counterHint => '每天可 +1 计次（打卡、次数统计），不涉及日期区间';

  @override
  String get counterLabel => '计数器';

  @override
  String get addOne => '+1';

  @override
  String totalCount(int count) {
    return '累计 $count 次';
  }

  @override
  String get presetCheckIn => '打卡';

  @override
  String get kindHoliday => '法定节假日（含调休）';

  @override
  String get kindCustom => '自定义';

  @override
  String get typeNameSimpleHint => '名称';

  @override
  String get holidayMakeupHint => '将同时创建\"调休补班\"类型（颜色与休/班标记自动设定）。';

  @override
  String get instancesHint => '上方为显示在日历上的实例；下方仅定义类型（如\"生日\"下建\"妈妈的生日\"实例）。';

  @override
  String get emptyEvents => '还没有事件，点下方\"添加事件\"';

  @override
  String get pickTypeTitle => '选择类型';

  @override
  String get noEventTypes => '请先在下方创建类型';

  @override
  String get calendarLink => '关联到日历';

  @override
  String get addToCalendar => '添加到日历';

  @override
  String get unlinkEvent => '取消关联';

  @override
  String get newEvent => '新建事件';

  @override
  String get linkExistingHint => '当天已有事件（可直接关联）';

  @override
  String get navTodos => '待办';

  @override
  String get todosTitle => '待办';

  @override
  String get todoBadgeHint => '标记为完成态的状态（如：已完成）；未完成的事件会汇总在待办视图。';

  @override
  String get statusDoneToggle => '完成态';

  @override
  String get todosEmpty => '没有待办。给类型加一个完成态状态，事件未完成时就会出现在这里。';

  @override
  String get todoComplete => '完成';

  @override
  String todoCompleted(String title) {
    return '已完成「$title」';
  }

  @override
  String get todoNoStatus => '无状态';

  @override
  String get lockTitle => '应用锁';

  @override
  String get lockSectionHint => '为应用设置密码；上锁的思绪不参与搜索，查看详情需先解锁。';

  @override
  String get lockChooseMethod => '选择解锁方式';

  @override
  String get lockPin => 'PIN 码';

  @override
  String get lockPattern => '九宫格图案';

  @override
  String get lockSetPin => '设置 PIN 码';

  @override
  String get lockSetPattern => '设置图案';

  @override
  String get lockEnterPinHint => '输入 4-8 位数字';

  @override
  String get lockConfirmHint => '再输入一次确认';

  @override
  String get lockPatternHint => '连接至少 4 个点';

  @override
  String get lockMismatch => '两次输入不一致';

  @override
  String get lockWrong => '密码错误';

  @override
  String get lockPatternShort => '至少连接 4 个点';

  @override
  String get lockVerifyTitle => '已上锁';

  @override
  String get lockPrivate => '设为私密';

  @override
  String get lockUnlockEntry => '取消私密';

  @override
  String get lockChange => '更换密码';

  @override
  String get lockTurnOff => '关闭应用锁';

  @override
  String get lockTurnOffBody => '关闭后，私密思绪将不再需要解锁即可查看（私密标记仍保留）。';

  @override
  String get lockLockNow => '立即上锁';

  @override
  String get lockedBadge => '私密';

  @override
  String get lockProtectedHint => '私密思绪不出现在搜索与漫步中。';

  @override
  String get advancedTagsSection => '高级标签';

  @override
  String get advancedTagsHint => '给思绪按需添加标签组；组内可单选或多选。';

  @override
  String get advancedTagsEmpty => '还没有添加标签组';

  @override
  String get addTagCategory => '添加标签组';

  @override
  String get removeTagCategory => '移除标签组';

  @override
  String get allTagCategoriesAdded => '已添加全部标签组';

  @override
  String get addOption => '新建选项';

  @override
  String get optionsEmpty => '还没有选项，点右上角 + 新建';

  @override
  String optionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个选项',
      zero: '无选项',
    );
    return '$_temp0';
  }

  @override
  String get categorySingle => '单选';

  @override
  String get categoryMulti => '多选';

  @override
  String get editTagCategory => '编辑标签组';

  @override
  String get deleteTagCategory => '删除标签组';

  @override
  String deleteTagCategoryBody(String name) {
    return '将删除「$name」及其全部选项，相关思绪上的该组标签值也会一并移除。';
  }

  @override
  String get normalTagsSection => '普通标签';
}
