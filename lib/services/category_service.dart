import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category_item.dart';
import 'db_service.dart';

/// 分类仓储：内置分类播种、增删改查、拖拽排序。
class CategoryService {
  CategoryService._();

  static const String boxName = 'categoriesBox';

  static late Box<CategoryItem> _box;

  /// 分类变化（新增 / 改名 / 排序 / 删除）都会触发，供 UI 局部刷新。
  static ValueListenable<Box<CategoryItem>> get listenable =>
      _box.listenable();

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryItemAdapter());
    }
    _box = await Hive.openBox<CategoryItem>(boxName);
    await _seedBuiltIns();
  }

  /// 首次启动写入内置分类；后续启动仅在某一侧为空时补齐，
  /// 因此不会覆盖用户已经调过的顺序与自定义分类。
  static Future<void> _seedBuiltIns() async {
    final List<CategoryItem> seed = <CategoryItem>[];
    if (!_box.values.any((CategoryItem c) => c.isExpense)) {
      seed.addAll(CategoryDefaults.build(true));
    }
    if (!_box.values.any((CategoryItem c) => !c.isExpense)) {
      seed.addAll(CategoryDefaults.build(false));
    }
    if (seed.isEmpty) {
      return;
    }
    await _box.addAll(seed);
  }

  // ---------------------------------------------------------------- 查询

  /// 指定方向的分类，按 sortIndex 升序。
  static List<CategoryItem> of(bool isExpense) {
    final List<CategoryItem> list = _box.values
        .where((CategoryItem c) => c.isExpense == isExpense)
        .toList();
    list.sort(
      (CategoryItem a, CategoryItem b) => a.sortIndex.compareTo(b.sortIndex),
    );
    return list;
  }

  static List<CategoryItem> expense() => of(true);

  static List<CategoryItem> income() => of(false);

  static CategoryItem? findByName(String name, bool isExpense) {
    for (final CategoryItem c in _box.values) {
      if (c.name == name && c.isExpense == isExpense) {
        return c;
      }
    }
    return null;
  }

  /// 名称反查完整分类对象；找不到时返回一个「其他」占位（未落库），
  /// 供只读展示场景直接取 `icon` / `color`。
  static CategoryItem resolve(String name, bool isExpense) {
    final CategoryItem? found = findByName(name, isExpense);
    if (found != null) {
      return found;
    }
    return CategoryItem(
      name: name.isEmpty ? '其他' : name,
      iconCodePoint: Icons.more_horiz_rounded.codePoint,
      colorValue:
          (isExpense ? const Color(0xFF9AA0A6) : const Color(0xFF2EB872))
              .toARGB32(),
      isExpense: isExpense,
    );
  }

  /// 名称反查图标；找不到时回退「其他」，保证 UI 永不崩。
  static IconData iconFor(String name, bool isExpense) =>
      findByName(name, isExpense)?.icon ?? Icons.more_horiz_rounded;

  /// 名称反查颜色；找不到时回退中性色。
  static Color colorFor(String name, bool isExpense) {
    final CategoryItem? item = findByName(name, isExpense);
    if (item != null) {
      return item.color;
    }
    return isExpense ? const Color(0xFF9AA0A6) : const Color(0xFF2EB872);
  }

  static bool nameExists(
    String name,
    bool isExpense, {
    CategoryItem? except,
  }) {
    final String target = name.trim();
    for (final CategoryItem c in _box.values) {
      if (c.isExpense == isExpense && c.name == target && c != except) {
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------- 写入

  static Future<CategoryItem> add({
    required String name,
    required IconData icon,
    required Color color,
    required bool isExpense,
  }) async {
    final List<CategoryItem> siblings = of(isExpense);
    final CategoryItem item = CategoryItem(
      name: name.trim(),
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
      isExpense: isExpense,
      sortIndex: siblings.isEmpty ? 0 : siblings.last.sortIndex + 1,
    );
    await _box.add(item);
    return item;
  }

  static Future<void> updateMeta(
    CategoryItem item, {
    required String name,
    required IconData icon,
    required Color color,
  }) async {
    final String oldName = item.name;
    item.name = name.trim();
    item.iconCodePoint = icon.codePoint;
    item.colorValue = color.toARGB32();
    await item.save();
    if (oldName != item.name) {
      await _renameInTransactions(oldName, item.name, item.isExpense);
    }
  }

  static Future<void> remove(CategoryItem item) => item.delete();

  /// 拖拽排序结果落库（列表顺序即 sortIndex）。
  static Future<void> reorder(
    bool isExpense,
    List<CategoryItem> ordered,
  ) async {
    for (int i = 0; i < ordered.length; i++) {
      ordered[i].sortIndex = i;
      await ordered[i].save();
    }
  }

  /// 恢复出厂顺序：内置分类按默认表排列，自定义分类保持相对顺序排到末尾。
  static Future<void> resetOrder(bool isExpense) async {
    final List<String> names = isExpense
        ? CategoryDefaults.expenseNames
        : CategoryDefaults.incomeNames;
    final List<CategoryItem> items = of(isExpense);
    final List<CategoryItem> builtIn = items
        .where((CategoryItem c) => c.builtIn)
        .toList();
    final List<CategoryItem> custom = items
        .where((CategoryItem c) => !c.builtIn)
        .toList();

    builtIn.sort((CategoryItem a, CategoryItem b) {
      final int ia = names.indexOf(a.name);
      final int ib = names.indexOf(b.name);
      return (ia < 0 ? names.length : ia).compareTo(
        ib < 0 ? names.length : ib,
      );
    });

    await reorder(isExpense, <CategoryItem>[...builtIn, ...custom]);
  }

  /// 分类改名后，把历史流水里的旧分类名一并迁移，避免统计断档。
  static Future<void> _renameInTransactions(
    String oldName,
    String newName,
    bool isExpense,
  ) async {
    for (final item in DBService.transactions.values) {
      if (item.isExpense == isExpense && item.title == oldName) {
        item.title = newName;
        await item.save();
      }
    }
  }
}
