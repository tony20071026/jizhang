import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 药丸式浮动底部导航（明细 / 统计 / 设置）。
class PillBottomBar extends StatelessWidget {
  const PillBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      icon: Icons.receipt_long_rounded,
      activeIcon: Icons.receipt_long_rounded,
      label: '明细',
    ),
    _NavItem(icon: Icons.pie_chart_rounded, activeIcon: Icons.pie_chart_rounded, label: '统计'),
    _NavItem(icon: Icons.settings_rounded, activeIcon: Icons.settings_rounded, label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: <BoxShadow>[AppShadows.floating],
        ),
        child: Row(
          children: List<Widget>.generate(_items.length, (int index) {
            final _NavItem item = _items[index];
            final bool selected = index == currentIndex;
            return Expanded(
              child: _NavButton(
                item: item,
                selected: selected,
                onTap: () {
                  if (selected) return;
                  HapticFeedback.lightImpact();
                  onTap(index);
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? context.palette.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected ? context.palette.primary : context.palette.textHint,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: selected ? 42 : 0,
                  child: Center(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? context.palette.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
