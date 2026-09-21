import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/category_item.dart';
import '../models/transaction_item.dart';
import 'category_service.dart';
import 'db_service.dart';

/// 导出结果。
class ExportResult {
  const ExportResult({required this.path, required this.count});

  final String path;
  final int count;
}

/// 导入结果。
class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.replaced,
  });

  final int added;
  final int skipped;
  final bool replaced;
}

/// 一份备份文件解析后的内容。
class ImportPayload {
  const ImportPayload({
    required this.items,
    required this.categories,
    this.exportedAt,
  });

  final List<TransactionItem> items;
  final List<CategoryItem> categories;
  final DateTime? exportedAt;

  bool get isEmpty => items.isEmpty && categories.isEmpty;
}

/// 本地 JSON 导入 / 导出（与 WebDAV 备份共用同一份文件结构，可互相恢复）。
class ExportService {
  ExportService._();

  /// 当前备份格式版本。1 = 仅流水；2 = 流水 + 分类。
  static const int schemaVersion = 2;

  /// 组装备份内容。
  static Map<String, dynamic> buildPayload({bool includeCategories = true}) {
    final List<TransactionItem> items = DBService.allSorted();
    return <String, dynamic>{
      'app': 'jizhang',
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'count': items.length,
      'transactions': items
          .map((TransactionItem e) => e.toJson())
          .toList(growable: false),
      if (includeCategories)
        'categories': <Map<String, dynamic>>[
          ...CategoryService.expense().map((CategoryItem e) => e.toJson()),
          ...CategoryService.income().map((CategoryItem e) => e.toJson()),
        ],
    };
  }

  /// 让用户选择保存位置并写出 JSON 文件。用户取消时返回 null。
  static Future<ExportResult?> exportToFile({
    bool includeCategories = true,
  }) async {
    final String json = const JsonEncoder.withIndent(
      '  ',
    ).convert(buildPayload(includeCategories: includeCategories));
    final Uint8List bytes = Uint8List.fromList(utf8.encode(json));
    final String fileName = 'qingzhang-${_stamp()}.json';

    // file_picker 13.x：saveFile 由平台直接落盘，返回目标 Uri，取消时为 null。
    final Uri? saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: '导出账单 JSON',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    if (saved == null) {
      return null; // 用户取消
    }

    return ExportResult(path: saved.toFilePath(), count: DBService.count);
  }

  /// 选择一个 JSON 文件并解析。
  static Future<ImportPayload?> pickAndParse() async {
    // file_picker 13.x：pickFile 返回单个文件，取消时为 null。
    final PlatformFile? picked = await FilePicker.pickFile(
      dialogTitle: '导入账单 JSON',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    if (picked == null) {
      return null; // 用户取消
    }

    final Uint8List bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('无法读取所选文件');
    }

    final Object? decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('不是有效的备份文件');
    }
    return parsePayload(decoded);
  }

  /// 解析备份 Map（本地文件与 WebDAV 备份共用）。
  static ImportPayload parsePayload(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        (json['transactions'] as List<dynamic>?) ?? <dynamic>[];
    final List<TransactionItem> items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(TransactionItem.fromJson)
        .toList();

    final List<dynamic> rawCategories =
        (json['categories'] as List<dynamic>?) ?? <dynamic>[];
    final List<CategoryItem> categories = rawCategories
        .whereType<Map<String, dynamic>>()
        .map(CategoryItem.fromJson)
        .toList();

    return ImportPayload(
      items: items,
      categories: categories,
      exportedAt: DateTime.tryParse((json['exportedAt'] ?? '').toString()),
    );
  }

  /// 应用导入。[replace] 为 true 时覆盖本地流水，否则按 id 去重合并。
  static Future<ImportResult> apply(
    ImportPayload payload, {
    required bool replace,
    bool importCategories = true,
  }) async {
    final int added = replace
        ? await DBService.replaceAll(payload.items)
        : await DBService.mergeAll(payload.items);

    if (importCategories && payload.categories.isNotEmpty) {
      await _mergeCategories(payload.categories);
    }

    return ImportResult(
      added: added,
      skipped: replace ? 0 : payload.items.length - added,
      replaced: replace,
    );
  }

  /// 合并分类：同名同方向视为已存在，只补缺失的，避免打乱用户自定义顺序。
  static Future<void> _mergeCategories(List<CategoryItem> incoming) async {
    for (final CategoryItem item in incoming) {
      if (CategoryService.nameExists(item.name, item.isExpense)) {
        continue;
      }
      await CategoryService.add(
        name: item.name,
        icon: item.icon,
        color: item.color,
        isExpense: item.isExpense,
      );
    }
  }

  static String _stamp() {
    final DateTime now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
