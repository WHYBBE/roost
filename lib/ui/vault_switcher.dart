import 'package:flutter/material.dart';

import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';

/// 移动端 AppBar 左上角切换入口；桌面端（宽屏）改在导航栏左下角显示
Widget? appBarVaultSwitcher(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 720
        ? null
        : const VaultSwitchButton.leading();

/// 保险库快速切换：点按弹出清单，选中即切换当前保险库
class VaultSwitchButton extends StatelessWidget {
  /// 导航栏底部窄条样式（图标+名称竖排）
  const VaultSwitchButton.rail({super.key}) : _style = _VaultStyle.rail;

  /// AppBar leading 样式：仅图标的圆角方块（leading 宽度有限，放不下名称）
  const VaultSwitchButton.leading({super.key}) : _style = _VaultStyle.leading;

  final _VaultStyle _style;

  Future<void> _switch(BuildContext context, String id) async {
    final store = DataStore.instance;
    if (id == store.currentVault?.id) return;
    try {
      await store.switchVault(id);
      await store.checkHealth();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;
    final current = store.currentVault;
    if (current == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final Widget label;
    switch (_style) {
      case _VaultStyle.rail:
        label = SizedBox(
          width: 72,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 22, color: scheme.primary),
              const SizedBox(height: 2),
              Text(
                current.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
              ),
            ],
          ),
        );
      case _VaultStyle.leading:
        // 与 AppBar 其他图标按钮（右侧 +）一致：无底色，悬浮时才有圆角水波纹；
        // Align 突破 leading 槽位的紧约束，让水波纹贴住图标本身而不是整个槽位
        label = Align(
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.inventory_2_outlined,
              size: 24,
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
    }

    return PopupMenuButton<String>(
      // AppBar leading 与导航栏宽度都有限，悬浮水波纹用圆角矩形
      borderRadius: BorderRadius.circular(12),
      tooltip: _style == _VaultStyle.leading ? current.name : l.vaultTitle,
      onSelected: (id) => _switch(context, id),
      itemBuilder: (context) => [
        for (final vault in store.vaults)
          CheckedPopupMenuItem(
            value: vault.id,
            checked: vault.id == current.id,
            child: Text(vault.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      child: label,
    );
  }
}

enum _VaultStyle { rail, leading }
