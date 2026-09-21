import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction_item.dart';

/// 本地数据库封装（Local-First 单一数据源）。
///
/// 对外只暴露两个入口：
/// * [DBService.listenable] —— 交给 `ValueListenableBuilder` 实现无感局部刷新；
/// * 各类 CRUD / 聚合静态方法。
class DBService {
  DBService._();

  static const String transactionsBoxName = 'transactionsBox';
  static const String settingsBoxName = 'settingsBox';

  /// WebDAV 云同步入口开关（可在「设置」页隐藏整个云同步区块）。
  static const String keyWebDavEnabled = 'webdav_enabled';
  static const String keyWebDavUrl = 'webdav_url';
  static const String keyWebDavUser = 'webdav_user';
  static const String keyWebDavPassword = 'webdav_password';
  static const String keyLastBackupAt = 'webdav_last_backup_at';

  static late Box<TransactionItem> _transactions;
  static late Box<dynamic> _settings;

  /// 流水 Box（只读暴露）。
  static Box<TransactionItem> get transactions => _transactions;

  /// 键值配置 Box（WebDAV 配置、最近备份时间等）。
  static Box<dynamic> get settings => _settings;

  /// 监听流水的可监听对象，数据变动即触发 UI 局部刷新。
  static ValueListenable<Box<TransactionItem>> get listenable =>
      _transactions.listenable();

  /// 必须在 `runApp` 之前调用。
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
    _transactions = await Hive.openBox<TransactionItem>(transactionsBoxName);
    _settings = await Hive.openBox<dynamic>(settingsBoxName);
  }

  // ---------------------------------------------------------------- 读取

  /// 全部流水，按日期倒序（新的在前）。
  static List<TransactionItem> allSorted() {
    final List<TransactionItem> list = _transactions.values.toList();
    _sortDesc(list);
    return list;
  }

  /// 指定月份的全部流水，按日期倒序。
  static List<TransactionItem> byMonth(DateTime month) {
    final List<TransactionItem> list = _transactions.values
        .where(
          (TransactionItem t) =>
              t.date.year == month.year && t.date.month == month.month,
        )
        .toList();
    _sortDesc(list);
    return list;
  }

  /// 全部月份（倒序，每个元素为该月 1 号），用于月份切换器边界判断。
  static List<DateTime> availableMonths() {
    final Set<String> keys = <String>{};
    for (final TransactionItem t in _transactions.values) {
      keys.add('${t.date.year}-${t.date.month}');
    }
    final List<DateTime> months = keys.map((String k) {
      final List<String> parts = k.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList();
    months.sort((DateTime a, DateTime b) => b.compareTo(a));
    return months;
  }

  // ---------------------------------------------------------------- 聚合

  /// 当月总支出。
  static double monthExpense(DateTime month) {
    double total = 0;
    for (final TransactionItem t in _transactions.values) {
      if (t.isExpense && _inMonth(t.date, month)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// 当月总收入。
  static double monthIncome(DateTime month) {
    double total = 0;
    for (final TransactionItem t in _transactions.values) {
      if (!t.isExpense && _inMonth(t.date, month)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// 当月结余（收入 - 支出）。
  static double monthBalance(DateTime month) =>
      monthIncome(month) - monthExpense(month);

  /// 按分类汇总（支出 / 收入），返回值已按金额从大到小排序。
  static Map<String, double> categoryTotals(DateTime month, bool isExpense) {
    final Map<String, double> result = <String, double>{};
    for (final TransactionItem t in _transactions.values) {
      if (t.isExpense == isExpense && _inMonth(t.date, month)) {
        result[t.title] = (result[t.title] ?? 0) + t.amount;
      }
    }
    return _sortMapDesc(result);
  }

  /// 指定某一天的支出合计。
  static double dayExpense(DateTime day) {
    double total = 0;
    for (final TransactionItem t in _transactions.values) {
      if (t.isExpense && _sameDay(t.date, day)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// 指定某一天的收入合计。
  static double dayIncome(DateTime day) {
    double total = 0;
    for (final TransactionItem t in _transactions.values) {
      if (!t.isExpense && _sameDay(t.date, day)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// 以 [endMonth] 为终点，向前取 [months] 个月的月份序列（正序，终点在最后）。
  ///
  /// `DateTime(year, month - n)` 会自动跨年归一，无需手动处理。
  static List<DateTime> recentMonths(DateTime endMonth, int months) {
    return List<DateTime>.generate(months, (int index) {
      final int offset = months - 1 - index;
      return DateTime(endMonth.year, endMonth.month - offset);
    });
  }

  /// 近 [months] 个月的支出 / 收入趋势，顺序与 [recentMonths] 一一对应。
  static List<double> monthlyTrend(
    DateTime endMonth,
    int months,
    bool isExpense,
  ) {
    return recentMonths(endMonth, months)
        .map((DateTime m) => isExpense ? monthExpense(m) : monthIncome(m))
        .toList();
  }

  /// 本地流水总笔数。
  static int get count => _transactions.length;

  // ---------------------------------------------------------------- 写入

  /// 新增一笔。返回写入后的实体（已带 Hive key）。
  static Future<TransactionItem> add({
    required String title,
    required double amount,
    required DateTime date,
    required bool isExpense,
    String? note,
  }) async {
    final TransactionItem item = TransactionItem(
      id: _generateId(),
      title: title,
      amount: amount,
      date: date,
      isExpense: isExpense,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    await _transactions.add(item);
    return item;
  }

  /// 修改一笔（实体需来自本 Box）。
  static Future<void> update(
    TransactionItem item, {
    String? title,
    double? amount,
    DateTime? date,
    bool? isExpense,
    String? note,
    bool clearNote = false,
  }) async {
    if (title != null) item.title = title;
    if (amount != null) item.amount = amount;
    if (date != null) item.date = date;
    if (isExpense != null) item.isExpense = isExpense;
    if (clearNote) {
      item.note = null;
    } else if (note != null) {
      item.note = note.trim().isEmpty ? null : note.trim();
    }
    await item.save();
  }

  /// 删除一笔（滑动删除）。
  static Future<void> remove(TransactionItem item) => item.delete();

  /// 撤销删除：按原 key 重新写回，保持原有顺序语义。
  static Future<void> restoreAt(dynamic key, TransactionItem item) =>
      _transactions.put(key, item);

  /// 清空全部本地流水。
  static Future<void> clearAll() => _transactions.clear();

  /// 全量替换（WebDAV 恢复时使用）。返回写入条数。
  static Future<int> replaceAll(List<TransactionItem> items) async {
    await _transactions.clear();
    await _transactions.addAll(items);
    return items.length;
  }

  /// 按 id 去重合并（云端数据合并到本地，已存在则跳过）。返回新增条数。
  static Future<int> mergeAll(List<TransactionItem> items) async {
    final Set<String> existing = _transactions.values
        .map((TransactionItem t) => t.id)
        .toSet();
    int added = 0;
    for (final TransactionItem item in items) {
      if (existing.contains(item.id)) {
        continue;
      }
      await _transactions.add(item);
      existing.add(item.id);
      added++;
    }
    return added;
  }

  // ---------------------------------------------------------------- 配置

  static T? readSetting<T>(String key, {T? fallback}) {
    final dynamic value = _settings.get(key);
    if (value is T) return value;
    return fallback;
  }

  static Future<void> writeSetting(String key, dynamic value) =>
      _settings.put(key, value);

  // ---------------------------------------------------------------- 内部

  static void _sortDesc(List<TransactionItem> list) {
    list.sort((TransactionItem a, TransactionItem b) => b.date.compareTo(a.date));
  }

  static bool _inMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Map<String, double> _sortMapDesc(Map<String, double> source) {
    final List<MapEntry<String, double>> entries = source.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    return <String, double>{
      for (final MapEntry<String, double> e in entries) e.key: e.value,
    };
  }

  static String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_transactions.length}';
}
