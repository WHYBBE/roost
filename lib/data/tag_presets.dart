import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 内置心情标签预设（用于初始化种子数据）
class MoodPreset {
  final String nameZh;
  final String nameEn;
  final IconData icon;
  final int color;

  const MoodPreset(this.nameZh, this.nameEn, this.icon, this.color);
}

const moodPresets = [
  MoodPreset('平静', 'Calm', Icons.spa, 0xFF009688),
  MoodPreset('开心', 'Happy', Icons.sentiment_very_satisfied, 0xFFFFB300),
  MoodPreset('一般', 'Neutral', Icons.sentiment_neutral, 0xFF607D8B),
  MoodPreset('低落', 'Down', Icons.sentiment_dissatisfied, 0xFF3F51B5),
  MoodPreset('焦虑', 'Anxious', Icons.waving_hand, 0xFFFF5722),
];

/// 标签图标候选（编辑器图标选择器；Material Icons 私用区 codepoint，可着色）
const tagIconChoices = <IconData>[
  // 心情/情绪
  Icons.spa,
  Icons.sentiment_very_satisfied,
  Icons.sentiment_neutral,
  Icons.sentiment_dissatisfied,
  Icons.sentiment_satisfied,
  Icons.sentiment_very_dissatisfied,
  Icons.mood,
  Icons.mood_bad,
  Icons.waving_hand,
  Icons.self_improvement,
  Icons.psychology,
  Icons.favorite,
  Icons.favorite_border,
  // 符号
  Icons.star,
  Icons.star_border,
  Icons.bolt,
  Icons.auto_awesome,
  Icons.diamond,
  Icons.verified,
  // 生活
  Icons.home,
  Icons.coffee,
  Icons.restaurant,
  Icons.local_pizza,
  Icons.local_cafe,
  Icons.wine_bar,
  Icons.cake,
  Icons.pets,
  Icons.park,
  Icons.eco,
  Icons.forest,
  Icons.local_florist,
  Icons.fitness_center,
  Icons.directions_run,
  Icons.hiking,
  Icons.beach_access,
  // 学习/工作
  Icons.work,
  Icons.school,
  Icons.menu_book,
  Icons.article,
  Icons.description,
  Icons.event,
  Icons.schedule,
  Icons.timer,
  Icons.bookmark,
  Icons.push_pin,
  Icons.label,
  // 创作与娱乐
  Icons.music_note,
  Icons.headphones,
  Icons.mic,
  Icons.movie,
  Icons.camera_alt,
  Icons.image,
  Icons.brush,
  Icons.palette,
  Icons.color_lens,
  Icons.sports_esports,
  // 运动与户外
  Icons.sports_soccer,
  Icons.sports_basketball,
  Icons.pool,
  // 科技
  Icons.laptop_mac,
  Icons.phone_iphone,
  Icons.devices,
  Icons.keyboard,
  Icons.code,
  Icons.terminal,
  Icons.bug_report,
  Icons.build,
  Icons.rocket_launch,
  // 出行
  Icons.flight,
  Icons.explore,
  Icons.map,
  Icons.location_on,
  Icons.flag,
  Icons.cloud,
  Icons.light_mode,
  Icons.dark_mode,
  Icons.water_drop,
  Icons.recycling,
  // 社交与家庭
  Icons.handshake,
  Icons.volunteer_activism,
  Icons.groups,
  Icons.family_restroom,
  Icons.child_care,
  // 财务
  Icons.shopping_bag,
  Icons.shopping_cart,
  Icons.card_giftcard,
  Icons.payments,
  Icons.savings,
  Icons.trending_up,
  // 健康
  Icons.medication,
  Icons.science,
  // 沟通
  Icons.chat_bubble,
  Icons.mail,
  Icons.call,
  // 庆祝与成就
  Icons.celebration,
  Icons.emoji_events,
  Icons.workspace_premium,
  Icons.grade,
  Icons.thumb_up,
  Icons.thumb_down,
  Icons.local_fire_department,
  Icons.whatshot,
  Icons.ac_unit,
  Icons.umbrella,
  Icons.water,
  Icons.air,
  Icons.wb_twilight,
  Icons.nights_stay,
  Icons.sunny,
  Icons.cyclone,
  // 自然与天气
  Icons.grass,
  Icons.landscape,
  Icons.terrain,
  Icons.waves,
  Icons.filter_drama,
  Icons.cruelty_free,
  // 食物
  Icons.rice_bowl,
  Icons.ramen_dining,
  Icons.icecream,
  Icons.emoji_food_beverage,
  Icons.breakfast_dining,
  Icons.dinner_dining,
  // 场所
  Icons.storefront,
  Icons.store,
  Icons.apartment,
  Icons.cottage,
  Icons.castle,
  // 交通
  Icons.train,
  Icons.subway,
  Icons.directions_boat,
  Icons.two_wheeler,
  Icons.electric_car,
  // 学习与灵感
  Icons.history_edu,
  Icons.translate,
  Icons.extension,
  Icons.lightbulb,
  Icons.fact_check,
  // 工作与职业
  Icons.badge,
  Icons.corporate_fare,
  Icons.engineering,
  Icons.agriculture,
  Icons.medical_services,
  Icons.construction,
  // 硬件与设备
  Icons.memory,
  Icons.router,
  Icons.wifi,
  Icons.bluetooth,
  Icons.smart_toy,
  // 工具与服务
  Icons.handyman,
  Icons.plumbing,
  Icons.electrical_services,
  Icons.cleaning_services,
  Icons.local_laundry_service,
  // 购物
  Icons.local_mall,
  Icons.loyalty,
  Icons.local_offer,
  // 相机与影音
  Icons.photo_camera,
  Icons.videocam,
  Icons.queue_music,
  Icons.library_music,
  Icons.volume_up,
  // 运动项目
  Icons.sports_martial_arts,
  Icons.surfing,
  Icons.snowboarding,
  Icons.skateboarding,
  Icons.kayaking,
  Icons.downhill_skiing,
  // 符号状态
  Icons.auto_fix_high,
  Icons.warning_amber,
  Icons.info_outline,
  Icons.help_outline,
  Icons.check_circle,
  Icons.cancel,
  Icons.block,
  Icons.priority_high,
];

/// 标签 Emoji 候选（单码点 emoji，不可着色，以原色渲染）
const tagEmojiChoices = <String>[
  // 表情
  '😀', '😄', '😆', '😂', '🙂', '😉', '😍', '🤩', '😎', '🤔',
  '😴', '😪', '😶', '😔', '🙃', '😢', '😭', '😤', '😠', '😡',
  '🤯', '🥵', '🥶', '😱', '🥺', '🤗', '😇', '🥰', '🤠', '🤖',
  // 手势
  '👍', '👎', '👌', '👏', '🙌', '🤝', '🙏', '💪',
  // 符号
  '✨', '🎉', '🔥', '⚡', '⭐', '💡', '✅', '💯',
  // 心
  '❤', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
  // 自然
  '☀', '🌙', '🌈', '🌸', '🌻', '🍀', '🌊', '🌿',
  // 生活
  '☕', '🍜', '🍰', '📚', '📝', '🎵', '🎮', '🏠',
  '✈', '🚀', '🏃', '🧘', '💼', '🎯', '🏆', '🌱',
];

/// 标签颜色候选（编辑器颜色选择器）
const tagColorChoices = <int>[
  0xFF009688, // teal
  0xFFFFB300, // amber
  0xFF607D8B, // blueGrey
  0xFF3F51B5, // indigo
  0xFFFF5722, // deepOrange
  0xFFE91E63, // pink
  0xFF9C27B0, // purple
  0xFF2196F3, // blue
  0xFF4CAF50, // green
  0xFF795548, // brown
];

/// 迁移时的种子语言判断
bool get seedUseChinese => Intl.systemLocale.startsWith('zh');
