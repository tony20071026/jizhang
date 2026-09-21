import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 顶部汇总卡片：大字号「本月支出」+「本月收入」+ 结余胶囊。
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.expense,
    required this.income,
    required this.count,
    required this.month,
  });

  final double expense;
  final double income;
  final int count;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final double balance = income - expense;
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final double daily = expense / daysInMonth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: <BoxShadow>[AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '本月支出',
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _BalancePill(value: balance),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.money(expense),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.palette.expense,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.palette.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _MiniStat(
                    label: '本月收入',
                    value: Formatters.money(income),
                    color: context.palette.income,
                  ),
                ),
                _VerticalGap(),
                Expanded(
                  child: _MiniStat(
                    label: '日均支出',
                    value: Formatters.money(daily),
                    color: context.palette.textPrimary,
                  ),
                ),
                _VerticalGap(),
                Expanded(
                  child: _MiniStat(
                    label: '本月笔数',
                    value: '$count 笔',
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final bool positive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? context.palette.incomeSoft : context.palette.expenseSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '结余 ${value >= 0 ? '+' : '-'}¥${Formatters.amount(value.abs())}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: positive ? context.palette.income : context.palette.expense,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalGap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: context.palette.hairline,
    );
  }
}
