import 'package:hive/hive.dart';

part 'transaction_item.g.dart';

/// 单笔流水。
///
/// 继承 `HiveObject`，因此实例自带 `key` / `save()` / `delete()`。
/// `title` 承载「分类名称」（由记账弹窗的网格选择器写入），
/// 这样聚合结果天然就是 `Map<String, double>` 的分类汇总。
@HiveType(typeId: 1)
class TransactionItem extends HiveObject {
  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.note,
  });

  /// 全局唯一 ID（本地生成，WebDAV 恢复时保持 ID 稳定）。
  @HiveField(0)
  String id;

  /// 分类名称（如「餐饮」「工资」）。
  @HiveField(1)
  String title;

  /// 金额，恒为正数；方向由 [isExpense] 决定。
  @HiveField(2)
  double amount;

  /// 记账日期。
  @HiveField(3)
  DateTime date;

  /// true = 支出，false = 收入。
  @HiveField(4)
  bool isExpense;

  /// 备注，可为空。
  @HiveField(5)
  String? note;

  /// 带符号金额：支出为负、收入为正，便于直接求和。
  double get signedAmount => isExpense ? -amount : amount;

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    bool? isExpense,
    String? note,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'isExpense': isExpense,
    'note': note,
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '其他').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      isExpense: json['isExpense'] == true,
      note: json['note']?.toString(),
    );
  }

  @override
  String toString() =>
      'TransactionItem($title, $amount, ${date.toIso8601String()}, '
      '${isExpense ? '支出' : '收入'}）';
}
