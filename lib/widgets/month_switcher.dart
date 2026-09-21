import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 月份切换器（左右箭头 + 当前年月）。
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.allowFuture = false,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final bool allowFuture;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool canGoNext =
        allowFuture ||
        month.year < now.year ||
        (month.year == now.year && month.month < now.month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: true,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(DateTime(month.year, month.month - 1));
          },
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 118,
          child: Center(
            child: Text(
              Formatters.yearMonth(month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(DateTime(month.year, month.month + 1));
          },
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 22, color: context.palette.textPrimary),
          ),
        ),
      ),
    );
  }
}
