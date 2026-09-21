import 'package:intl/intl.dart';

/// 金额 / 日期格式化。
///
/// 金额使用显式 `en_US` 的千分位模式，避免依赖未初始化的本地化数据。
/// 日期全部走数字模式，同样无需 `initializeDateFormatting`。
class Formatters {
  const Formatters._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _moneyCompact = NumberFormat('#,##0', 'en_US');

  /// 1234.5 -> "1,234.50"
  static String amount(double value) => _money.format(value);

  /// 带货币符号：1234.5 -> "¥1,234.50"
  static String money(double value) => '¥${_money.format(value)}';

  /// 带符号：支出 "-¥12.00"，收入 "+¥12.00"
  static String signedMoney(double value) {
    final String sign = value < 0 ? '-' : '+';
    return '$sign¥${_money.format(value.abs())}';
  }

  /// 不带小数，用于大号汇总数字以外的紧凑场景。
  static String moneyNoDecimal(double value) => '¥${_moneyCompact.format(value)}';

  /// 2026-09-16 -> "09月16日"
  static String monthDay(DateTime date) =>
      '${_two(date.month)}月${_two(date.day)}日';

  /// 2026-09-16 -> "2026年09月16日"
  static String fullDate(DateTime date) =>
      '${date.year}年${_two(date.month)}月${_two(date.day)}日';

  /// 2026-09-16 -> "2026年9月"
  static String yearMonth(DateTime date) => '${date.year}年${date.month}月';

  /// 2026-09-16 -> "2026-09-16"
  static String isoDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  /// 2026-09-16 23:40 -> "2026-09-16 23:40"
  static String dateTime(DateTime date) =>
      '${isoDate(date)} ${_two(date.hour)}:${_two(date.minute)}';

  /// 今天是今天 / 昨天 / 周三 / 09月16日
  static String dayLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);
    final int diff = target.difference(today).inDays;
    if (diff == 0) {
      return '今天';
    }
    if (diff == -1) {
      return '昨天';
    }
    if (diff == 1) {
      return '明天';
    }
    if (diff < 0 && diff >= -6) {
      return _weekday(date.weekday);
    }
    return monthDay(date);
  }

  static String _weekday(int weekday) {
    const List<String> names = <String>[
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
