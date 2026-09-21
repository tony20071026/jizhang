import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/models/category_item.dart';
import 'package:jizhang/models/transaction_item.dart';
import 'package:jizhang/services/webdav_service.dart';

void main() {
  group('TransactionItem 序列化', () {
    test('toJson / fromJson 往返一致', () {
      final TransactionItem item = TransactionItem(
        id: 'abc-1',
        title: '餐饮',
        amount: 38.5,
        date: DateTime(2026, 9, 16, 12, 30),
        isExpense: true,
        note: '午饭',
      );

      final TransactionItem restored = TransactionItem.fromJson(item.toJson());

      expect(restored.id, 'abc-1');
      expect(restored.title, '餐饮');
      expect(restored.amount, 38.5);
      expect(restored.date, DateTime(2026, 9, 16, 12, 30));
      expect(restored.isExpense, isTrue);
      expect(restored.note, '午饭');
      expect(restored.signedAmount, -38.5);
    });

    test('缺失字段时回退到安全默认值', () {
      final TransactionItem item = TransactionItem.fromJson(<String, dynamic>{});

      expect(item.title, '其他');
      expect(item.amount, 0.0);
      expect(item.isExpense, isFalse);
      expect(item.note, isNull);
    });
  });

  group('分类表', () {
    test('33 个默认支出分类，前 8 个为常驻位', () {
      expect(CategoryDefaults.expenseNames.length, 33);
      expect(CategoryDefaults.pinnedCount, 8);
      expect(CategoryDefaults.expenseNames.take(8).toList(), <String>[
        '餐饮',
        '购物',
        '日用',
        '交通',
        '水果',
        '零食',
        '运动',
        '娱乐',
      ]);
    });

    test('分类名称唯一，图标数量与名称一一对应', () {
      final Set<String> expenseNames = CategoryDefaults.expenseNames.toSet();
      expect(expenseNames.length, CategoryDefaults.expenseNames.length);
      expect(
        CategoryDefaults.expenseIcons.length,
        CategoryDefaults.expenseNames.length,
      );

      final Set<String> incomeNames = CategoryDefaults.incomeNames.toSet();
      expect(incomeNames.length, CategoryDefaults.incomeNames.length);
      expect(
        CategoryDefaults.incomeIcons.length,
        CategoryDefaults.incomeNames.length,
      );
    });

    test('图标 codePoint 能反查回常量 IconData，未命中回退到其他', () {
      for (final IconData icon in CategoryDefaults.expenseIcons) {
        expect(CategoryIcons.resolve(icon.codePoint).codePoint, icon.codePoint);
      }
      expect(CategoryIcons.resolve(-999), Icons.more_horiz_rounded);
    });

    test('默认分类可构建且字段完整', () {
      final List<CategoryItem> items = CategoryDefaults.build(true);
      expect(items.length, 33);
      expect(items.first.name, '餐饮');
      expect(items.first.builtIn, isTrue);
      expect(items.first.isExpense, isTrue);
      expect(items.first.sortIndex, 0);
      expect(items.first.icon, Icons.restaurant_rounded);
    });

    test('分类 JSON 往返一致', () {
      final CategoryItem item = CategoryDefaults.build(false).first;
      final CategoryItem restored = CategoryItem.fromJson(item.toJson());
      expect(restored.name, item.name);
      expect(restored.iconCodePoint, item.iconCodePoint);
      expect(restored.colorValue, item.colorValue);
      expect(restored.isExpense, item.isExpense);
      expect(restored.builtIn, item.builtIn);
    });
  });

  group('WebDAV 备份包', () {
    test('BackupBundle 可完整往返', () {
      final BackupBundle bundle = BackupBundle(
        exportedAt: DateTime(2026, 9, 16, 23, 0),
        items: <TransactionItem>[
          TransactionItem(
            id: 'x1',
            title: '交通',
            amount: 12,
            date: DateTime(2026, 9, 16),
            isExpense: true,
          ),
          TransactionItem(
            id: 'x2',
            title: '工资',
            amount: 12000,
            date: DateTime(2026, 9, 10),
            isExpense: false,
          ),
        ],
      );

      final BackupBundle decoded = BackupBundle.fromJson(bundle.toJson());

      expect(decoded.items.length, 2);
      expect(decoded.items.first.title, '交通');
      expect(decoded.items.last.title, '工资');
      expect(decoded.exportedAt, DateTime(2026, 9, 16, 23, 0));
    });
  });
}
