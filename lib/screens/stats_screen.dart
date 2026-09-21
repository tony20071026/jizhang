import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/category_item.dart';
import '../models/transaction_item.dart';
import '../services/category_service.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/category_progress_tile.dart';
import '../widgets/month_switcher.dart';

/// 统计分析：环形饼图 + 分类明细（占比进度条）。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  /// 趋势折线图向前回溯的月份数。
  static const int _trendMonths = 6;

  late DateTime _month;
  bool _showExpense = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<Box<TransactionItem>>(
        valueListenable: DBService.listenable,
        builder: (BuildContext context, Box<TransactionItem> box, Widget? _) {
          final Map<String, double> totals = DBService.categoryTotals(
            _month,
            _showExpense,
          );
          final double total = totals.values.fold<double>(
            0,
            (double sum, double v) => sum + v,
          );
          final List<TransactionItem> monthItems = DBService.byMonth(_month);

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.page,
              right: AppSpacing.page,
              top: 6,
              bottom: 120,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: <Widget>[
              ScreenHeader(
                title: '统计',
                subtitle: '本月 ${monthItems.length} 笔 · ${Formatters.yearMonth(_month)}',
                trailing: MonthSwitcher(
                  month: _month,
                  onChanged: (DateTime m) => setState(() => _month = m),
                ),
              ),
              const SizedBox(height: 14),
              _buildChartCard(totals, total),
              const SizedBox(height: AppSpacing.gap),
              _buildTrendCard(),
              const SizedBox(height: AppSpacing.gap),
              _buildDetailCard(totals, total),
            ],
          );
        },
      ),
    );
  }

  /// 近半年支出 / 收入趋势折线图。
  Widget _buildTrendCard() {
    final List<DateTime> months = DBService.recentMonths(_month, _trendMonths);
    final List<double> values = DBService.monthlyTrend(
      _month,
      _trendMonths,
      _showExpense,
    );

    double peak = 0;
    for (final double v in values) {
      if (v > peak) {
        peak = v;
      }
    }
    final double sum = values.fold<double>(0, (double s, double v) => s + v);
    final Color accent = _showExpense ? context.palette.expense : context.palette.income;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '近半年趋势',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '合计 ${Formatters.money(sum)}',
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_showExpense ? '支出' : '收入'} · 月均 ${Formatters.money(sum / _trendMonths)}',
            style: TextStyle(fontSize: 12, color: context.palette.textHint),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 176,
            child: peak <= 0
                ? Center(
                    child: Text(
                      '近 $_trendMonths 个月暂无数据',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  )
                : LineChart(
                    _buildLineData(values, months, peak, accent),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineData(
    List<double> values,
    List<DateTime> months,
    double peak,
    Color accent,
  ) {
    final double maxY = peak * 1.25;
    final double interval = maxY / 3;

    return LineChartData(
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (double value) => FlLine(
          color: context.palette.hairline,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final int index = value.toInt();
              if (index < 0 || index >= months.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${months[index].month}月',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textHint,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) => context.palette.textPrimary,
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((LineBarSpot spot) {
              return LineTooltipItem(
                Formatters.money(spot.y),
                TextStyle(
                  color: context.palette.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          spots: List<FlSpot>.generate(
            values.length,
            (int i) => FlSpot(i.toDouble(), values[i]),
          ),
          isCurved: true,
          curveSmoothness: 0.32,
          color: accent,
          barWidth: 3,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter:
                (
                  FlSpot spot,
                  double percent,
                  LineChartBarData bar,
                  int index,
                ) => FlDotCirclePainter(
                  radius: 3.5,
                  color: context.palette.surface,
                  strokeWidth: 2.5,
                  strokeColor: accent,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                accent.withValues(alpha: 0.24),
                accent.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(Map<String, double> totals, double total) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(child: _buildToggle(total)),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: totals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.donut_large_rounded,
                          size: 54,
                          color: context.palette.textHint.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '本月暂无数据',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2.5,
                          centerSpaceRadius: 74,
                          startDegreeOffset: -90,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, PieTouchResponse? res) {
                                  if (!event.isInterestedForInteractions) {
                                    setState(() => _touchedIndex = -1);
                                    return;
                                  }
                                  setState(() {
                                    _touchedIndex =
                                        res?.touchedSection?.touchedSectionIndex ??
                                        -1;
                                  });
                                },
                          ),
                          sections: _buildSections(totals, total),
                        ),
                      ),
                      _buildCenter(totals, total),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter(Map<String, double> totals, double total) {
    final bool touched = _touchedIndex >= 0 && _touchedIndex < totals.length;
    final String focusName = touched
        ? totals.keys.elementAt(_touchedIndex)
        : (_showExpense ? '本月支出' : '本月收入');
    final double focusValue = touched
        ? totals.values.elementAt(_touchedIndex)
        : total;

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            focusName,
            style: TextStyle(
              fontSize: 12.5,
              color: context.palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.money(focusValue),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _showExpense ? context.palette.expense : context.palette.income,
              letterSpacing: -0.6,
            ),
          ),
          if (_touchedIndex < 0 && total > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${totals.length} 个分类',
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.palette.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<String, double> totals,
    double total,
  ) {
    final List<MapEntry<String, double>> entries = totals.entries.toList();
    return List<PieChartSectionData>.generate(entries.length, (int index) {
      final MapEntry<String, double> entry = entries[index];
      final CategoryItem category = CategoryService.resolve(
        entry.key,
        _showExpense,
      );
      final bool touched = index == _touchedIndex;
      final double radius = touched ? 46 : 40;
      return PieChartSectionData(
        value: entry.value,
        color: category.color,
        radius: radius,
        showTitle: false,
        borderSide: BorderSide.none,
      );
    });
  }

  Widget _buildToggle(double total) {
    return Container(
      padding: const EdgeInsets.all(4),
      width: 208,
      height: 38,
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: <Widget>[
          _ToggleChip(
            label: '支出',
            selected: _showExpense,
            activeColor: context.palette.expense,
            onTap: () {
              if (_showExpense) return;
              HapticFeedback.selectionClick();
              setState(() {
                _showExpense = true;
                _touchedIndex = -1;
              });
            },
          ),
          _ToggleChip(
            label: '收入',
            selected: !_showExpense,
            activeColor: context.palette.income,
            onTap: () {
              if (!_showExpense) return;
              HapticFeedback.selectionClick();
              setState(() {
                _showExpense = false;
                _touchedIndex = -1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(Map<String, double> totals, double total) {
    if (totals.isEmpty) {
      return const EmptyState(
        icon: Icons.insert_chart_outlined_rounded,
        title: '还没有可统计的数据',
        subtitle: '记录几笔之后，这里会展示分类占比与趋势',
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '分类明细',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '合计 ${Formatters.money(total)}',
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...totals.entries.map(
            (MapEntry<String, double> entry) => CategoryProgressTile(
              categoryName: entry.key,
              isExpense: _showExpense,
              amount: entry.value,
              ratio: total <= 0 ? 0 : entry.value / total,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? context.palette.onPrimary : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
