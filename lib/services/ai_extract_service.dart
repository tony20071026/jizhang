import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'category_service.dart';
import 'db_service.dart';

/// 从支付截图里识别出来的一笔记账草稿。
class AiTransactionDraft {
  const AiTransactionDraft({
    required this.isExpense,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final bool isExpense;
  final double amount;

  /// 已对齐到本地已有分类名（保证记账弹窗里能选中）。
  final String category;
  final DateTime date;
  final String? note;
}

class AiExtractException implements Exception {
  const AiExtractException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 多模态截图记账：把支付截图发给大模型，解析出金额 / 分类 / 时间 / 备注。
///
/// 采用 OpenAI 兼容的 `/chat/completions` 接口，图片以 base64 data URL 传入。
/// 配置项存于本地 Hive（`settingsBox`），不上传任何服务器。
class AiExtractService {
  AiExtractService._();

  // -------------------------------------------------------------- 配置项 Key
  static const String keyEnabled = 'ai_enabled';
  static const String keyApiKey = 'ai_api_key';
  static const String keyBaseUrl = 'ai_base_url';
  static const String keyModel = 'ai_model';

  /// 阿里云百炼 OpenAI 兼容端点（可在设置里改为自己的工作空间地址）。
  static const String defaultBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';

  /// 默认多模态模型。
  static const String defaultModel = 'qwen3.8-flash';

  static bool get enabled =>
      DBService.readSetting<bool>(keyEnabled, fallback: false) ?? false;

  static String get apiKey =>
      (DBService.readSetting<String>(keyApiKey) ?? '').trim();

  static String get baseUrl {
    final String value = (DBService.readSetting<String>(keyBaseUrl) ?? '')
        .trim();
    return value.isEmpty ? defaultBaseUrl : value;
  }

  static String get model {
    final String value = (DBService.readSetting<String>(keyModel) ?? '').trim();
    return value.isEmpty ? defaultModel : value;
  }

  /// 是否已具备识别条件（开关打开且填了 Key）。
  static bool get isConfigured => enabled && apiKey.isNotEmpty;

  // ------------------------------------------------------------------ 识别

  /// 识别一张支付截图。失败抛 [AiExtractException]。
  static Future<AiTransactionDraft> extract(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (apiKey.isEmpty) {
      throw const AiExtractException('尚未填写 API Key');
    }
    final String dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
    final String prompt = _buildPrompt();
    final Map<String, dynamic> payload = <String, dynamic>{
      'model': model,
      'temperature': 0,
      'messages': <dynamic>[
        <String, dynamic>{
          'role': 'user',
          'content': <dynamic>[
            <String, dynamic>{
              'type': 'image_url',
              'image_url': <String, dynamic>{'url': dataUrl},
            },
            <String, dynamic>{'type': 'text', 'text': prompt},
          ],
        },
      ],
    };

    final String content = await _postChat(payload, timeout: 60);
    final Map<String, dynamic> json = _extractJsonObject(content);
    return _toDraft(json);
  }

  /// 用一条极小的文本请求验证 Key / 端点 / 模型是否可用。
  static Future<void> testConnection() async {
    if (apiKey.isEmpty) {
      throw const AiExtractException('尚未填写 API Key');
    }
    final Map<String, dynamic> payload = <String, dynamic>{
      'model': model,
      'temperature': 0,
      'messages': <dynamic>[
        <String, dynamic>{'role': 'user', 'content': '只回复两个字：收到'},
      ],
    };
    await _postChat(payload, timeout: 20);
  }

  // ---------------------------------------------------------------- 内部

  static Future<String> _postChat(
    Map<String, dynamic> payload, {
    required int timeout,
  }) async {
    final Uri uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
    );
    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: timeout));
    } catch (e) {
      throw AiExtractException('网络请求失败：$e');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiExtractException(
        '接口返回 ${response.statusCode}：${_short(response.body)}',
      );
    }
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final dynamic choices = (decoded is Map) ? decoded['choices'] : null;
    if (choices is! List || choices.isEmpty) {
      throw const AiExtractException('接口返回内容为空');
    }
    final dynamic message = choices.first['message'];
    final dynamic content = (message is Map) ? message['content'] : null;
    if (content is String) {
      return content;
    }
    // 少数模型把 content 返回成 [{type:text,text:...}] 的分段数组。
    if (content is List) {
      final StringBuffer buffer = StringBuffer();
      for (final dynamic part in content) {
        if (part is Map && part['text'] is String) {
          buffer.write(part['text']);
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }
    throw const AiExtractException('无法解析模型回复');
  }

  static String _buildPrompt() {
    final String expense = CategoryService.expense()
        .map((dynamic c) => c.name)
        .join('、');
    final String income = CategoryService.income()
        .map((dynamic c) => c.name)
        .join('、');
    return '你是记账助手。请从这张支付或转账截图中提取一笔账目，并只输出一个 JSON 对象，不要任何解释。\n'
        '字段：\n'
        '- type: "expense"（支出）或 "income"（收入）\n'
        '- amount: 金额数字（只取「实际支付 / 实付」的金额；忽略原价、优惠、红包、积分、余额等其它数字）\n'
        '- category: 从下面分类中原样选一个最贴切的，选不出就用「其他」\n'
        '  支出分类：$expense\n'
        '  收入分类：$income\n'
        '- datetime: 交易时间，格式 "YYYY-MM-DD HH:MM:SS"；截图中没有就用当前时间\n'
        '- note: 商户 / 对方名称，可带支付方式，如「星巴克·余额宝」\n'
        '当前时间：${_nowText()}\n'
        '示例：{"type":"expense","amount":23.5,"category":"餐饮",'
        '"datetime":"2026-10-04 18:32:15","note":"星巴克·余额宝"}';
  }

  static String _nowText() {
    final DateTime now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  static AiTransactionDraft _toDraft(Map<String, dynamic> json) {
    final bool isExpense =
        (json['type'] ?? 'expense').toString().toLowerCase() != 'income';

    final dynamic rawAmount = json['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0;

    final String rawCategory = (json['category'] ?? '').toString();
    final String category = _resolveCategory(rawCategory, isExpense);

    final DateTime date =
        DateTime.tryParse((json['datetime'] ?? '').toString()) ??
        DateTime.now();

    final String note = (json['note'] ?? '').toString().trim();

    return AiTransactionDraft(
      isExpense: isExpense,
      amount: amount,
      category: category,
      date: date,
      note: note.isEmpty ? null : note,
    );
  }

  /// 把模型给的分类名对齐到本地分类；对不上就模糊匹配，再不行回退「其他」。
  static String _resolveCategory(String raw, bool isExpense) {
    final List<dynamic> list = CategoryService.of(isExpense);
    if (list.isEmpty) {
      return raw.trim().isEmpty ? '其他' : raw.trim();
    }
    final String name = raw.trim();
    for (final dynamic c in list) {
      if (c.name == name) return c.name as String;
    }
    if (name.isNotEmpty) {
      for (final dynamic c in list) {
        final String cn = c.name as String;
        if (cn.contains(name) || name.contains(cn)) return cn;
      }
    }
    for (final dynamic c in list) {
      if (c.name == '其他') return '其他';
    }
    return list.first.name as String;
  }

  static Map<String, dynamic> _extractJsonObject(String text) {
    String body = text.trim();
    body = body
        .replaceAll(RegExp(r'^```(?:json)?\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '');
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // 继续尝试从文本里抠出第一个 {...}
    }
    final int start = body.indexOf('{');
    final int end = body.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final dynamic decoded = jsonDecode(body.substring(start, end + 1));
      if (decoded is Map) return decoded.cast<String, dynamic>();
    }
    throw const AiExtractException('模型没有返回可解析的 JSON');
  }

  static String _short(String s) {
    final String t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= 160 ? t : '${t.substring(0, 160)}…';
  }
}
