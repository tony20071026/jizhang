import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 统一的模块化卡片：20 圆角 + 微弱弥散投影，无边框、无分割线。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.color,
    this.onTap,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color background = color ?? palette.surface;
    // 深色下弥散投影几乎不可见，改用 1px 描边勾勒卡片边界。
    final bool useShadow = !palette.isDark && color == null;

    final Widget card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: useShadow ? null : Border.all(color: palette.hairline),
        boxShadow: useShadow ? <BoxShadow>[AppShadows.card] : null,
      ),
      child: child,
    );

    final Widget content = onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: card,
            ),
          );

    if (margin == null) {
      return content;
    }
    return Padding(padding: margin!, child: content);
  }
}

/// 页面统一的标题（替代 AppBar，避免生硬分割线）。
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page + 4,
        8,
        AppSpacing.page + 4,
        4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 不用 `?trailing` 的 null-aware element 语法：hive_generator 内置的
          // 旧 analyzer（语言版本 3.4）无法解析它，会导致 build_runner 直接失败。
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 空状态占位。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.palette.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: context.palette.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
