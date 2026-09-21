import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/transaction_item.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/month_switcher.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';

/// 明细（首页）：汇总卡片 + 按日分组的流水列表（左滑删除）。
class LedgerHomeScreen extends StatefulWidget {
  const LedgerHomeScreen({super.key});

  @override
  State<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends State<LedgerHomeScreen> {
  late DateTime _month = _thisMonth();

  static DateTime _thisMonth() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void _onMonthChanged(DateTime month) => setState(() => _month = month);

  /// 左滑删除 + 撤销。
  Future<bool> _handleDelete(TransactionItem item) async {
    final dynamic key = item.key;
    final String label = item.title;

    await DBService.remove(item);
    if (!mounted) return true;

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('已删除「$label」'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '撤销',
            textColor: context.palette.primary,
            onPressed: () => DBService.restoreAt(key, item),
          ),
        ),
      );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<Box<TransactionItem>>(
        valueListenable: DBService.listenable,
        builder: (BuildContext context, Box<TransactionItem> box, Widget? _) {
          final List<TransactionItem> items = DBService.byMonth(_month);
          final double expense = DBService.monthExpense(_month);
          final double income = DBService.monthIncome(_month);

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.page,
              right: AppSpacing.page,
              top: 6,
              bottom: 140,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: <Widget>[
              ScreenHeader(
                title: '明细',
                subtitle: '${DBService.count} 笔记录 · ${_rangeHint()}',
                trailing: MonthSwitcher(
                  month: _month,
                  onChanged: _onMonthChanged,
                ),
              ),
              const SizedBox(height: 14),
              SummaryCard(
                expense: expense,
                income: income,
                count: items.length,
                month: _month,
              ),
              const SizedBox(height: AppSpacing.gap),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.note_alt_outlined,
                  title: '本月还没有记账',
                  subtitle: '点击右下角按钮，记录第一笔收支吧',
                )
              else
                _buildDayGroups(items),
            ],
          );
        },
      ),
    );
  }

  String _rangeHint() {
    final int days = DateTime(_month.year, _month.month + 1, 0).day;
    return '${Formatters.monthDay(DateTime(_month.year, _month.month, 1))} - '
        '${Formatters.monthDay(DateTime(_month.year, _month.month, days))}';
  }

  Widget _buildDayGroups(List<TransactionItem> items) {
    final List<_DayGroup> groups = <_DayGroup>[];
    for (final TransactionItem item in items) {
      final DateTime day = DateTime(item.date.year, item.date.month, item.date.day);
      if (groups.isEmpty || !_isSameDay(groups.last.day, day)) {
        groups.add(_DayGroup(day, <TransactionItem>[item]));
      } else {
        groups.last.items.add(item);
      }
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final _DayGroup group in groups) ...<Widget>[
            DaySectionHeader(
              date: group.day,
              expense: DBService.dayExpense(group.day),
              income: DBService.dayIncome(group.day),
            ),
            ...group.items.map(
              (TransactionItem item) => DismissibleTransactionTile(
                item: item,
                onDelete: _handleDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayGroup {
  _DayGroup(this.day, this.items);

  final DateTime day;
  final List<TransactionItem> items;
}
