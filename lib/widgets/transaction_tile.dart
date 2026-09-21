import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category_item.dart';
import '../models/transaction_item.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 单条流水行（不含删除手势，便于在统计页等场景复用）。
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.item,
    this.showTime = false,
    this.onTap,
  });

  final TransactionItem item;
  final bool showTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final CategoryItem category = CategoryService.resolve(item.title, item.isExpense);
    final bool hasNote = item.note != null && item.note!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.softColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasNote
                          ? item.note!.trim()
                          : (showTime
                                ? Formatters.dateTime(item.date)
                                : _categoryHint(item)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Formatters.signedMoney(item.signedAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: item.isExpense ? context.palette.expense : context.palette.income,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryHint(TransactionItem item) =>
      item.isExpense ? '支出' : '收入';
}

/// 带左滑删除的流水项（Dismissible + 触感反馈）。
class DismissibleTransactionTile extends StatelessWidget {
  const DismissibleTransactionTile({
    super.key,
    required this.item,
    required this.onDelete,
    this.onTap,
  });

  final TransactionItem item;

  /// 返回 true 表示确实删除；返回 false 表示取消。
  final Future<bool> Function(TransactionItem item) onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (DismissDirection direction) async {
        HapticFeedback.mediumImpact();
        return onDelete(item);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: context.palette.expenseSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.palette.expense,
          size: 22,
        ),
      ),
      child: TransactionRow(item: item, onTap: onTap),
    );
  }
}

/// 某一天的分组标题（日期 + 当日合计）。
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({
    super.key,
    required this.date,
    required this.expense,
    required this.income,
  });

  final DateTime date;
  final double expense;
  final double income;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[];
    if (expense > 0) parts.add('支出 ${Formatters.money(expense)}');
    if (income > 0) parts.add('收入 ${Formatters.money(income)}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
      child: Row(
        children: <Widget>[
          Text(
            Formatters.dayLabel(date),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.monthDay(date),
            style: TextStyle(fontSize: 12, color: context.palette.textHint),
          ),
          const Spacer(),
          if (parts.isNotEmpty)
            Text(
              parts.join('   '),
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
