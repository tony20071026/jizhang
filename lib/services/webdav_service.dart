import 'dart:convert';
import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart' as webdav;

import '../models/transaction_item.dart';

/// WebDAV 连接配置。
class WebDavConfig {
  const WebDavConfig({
    required this.url,
    required this.user,
    required this.password,
  });

  /// 服务器地址，例如 `https://dav.jianguoyun.com/dav/`
  final String url;
  final String user;

  /// 应用授权码 / 应用专用密码
  final String password;

  bool get isValid => url.trim().isNotEmpty && user.trim().isNotEmpty;

  WebDavConfig copyWith({String? url, String? user, String? password}) {
    return WebDavConfig(
      url: url ?? this.url,
      user: user ?? this.user,
      password: password ?? this.password,
    );
  }
}

/// 备份文件的整体结构。
class BackupBundle {
  const BackupBundle({required this.exportedAt, required this.items});

  final DateTime exportedAt;
  final List<TransactionItem> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'app': 'jizhang',
    'version': 1,
    'exportedAt': exportedAt.toIso8601String(),
    'count': items.length,
    'transactions': items
        .map((TransactionItem e) => e.toJson())
        .toList(growable: false),
  };

  factory BackupBundle.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw =
        (json['transactions'] as List<dynamic>?) ?? <dynamic>[];
    final List<TransactionItem> items = raw
        .whereType<Map<String, dynamic>>()
        .map(TransactionItem.fromJson)
        .toList();
    final DateTime exportedAt =
        DateTime.tryParse((json['exportedAt'] ?? '').toString()) ??
        DateTime.now();
    return BackupBundle(exportedAt: exportedAt, items: items);
  }
}

/// 基于 WebDAV 的全量 JSON 备份与还原。
class WebDavService {
  WebDavService._();

  static const String remoteDir = '/my_ledger';
  static const String remoteFile = '/my_ledger/backup.json';

  static webdav.Client _buildClient(WebDavConfig config) {
    final webdav.Client client = webdav.newClient(
      config.url.trim(),
      user: config.user.trim(),
      password: config.password,
      debug: false,
    );
    client.setConnectTimeout(15000);
    client.setSendTimeout(60000);
    client.setReceiveTimeout(60000);
    return client;
  }

  /// 测试连接（PROPFIND 探测），失败会抛出带可读信息的异常。
  static Future<void> testConnection(WebDavConfig config) async {
    if (!config.isValid) {
      throw const WebDavException('请先填写服务器地址与用户名');
    }
    final webdav.Client client = _buildClient(config);
    try {
      await client.ping();
    } catch (e) {
      throw WebDavException('连接失败：${_describe(e)}');
    }
  }

  /// 一键备份：把全部本地流水写成 `/my_ledger/backup.json`。
  static Future<int> backup(
    WebDavConfig config,
    List<TransactionItem> items,
  ) async {
    if (!config.isValid) {
      throw const WebDavException('请先填写服务器地址与用户名');
    }
    final webdav.Client client = _buildClient(config);
    final BackupBundle bundle = BackupBundle(
      exportedAt: DateTime.now(),
      items: items,
    );
    final Uint8List payload = Uint8List.fromList(
      utf8.encode(jsonEncode(bundle.toJson())),
    );

    try {
      await client.ping();
      // 目录已存在时部分服务端返回 405，忽略即可。
      try {
        await client.mkdir(remoteDir);
      } catch (_) {
        // ignore
      }
      await client.write(remoteFile, payload);
    } catch (e) {
      throw WebDavException('备份失败：${_describe(e)}');
    }
    return items.length;
  }

  /// 从云端拉取并解析备份。
  static Future<BackupBundle> restore(WebDavConfig config) async {
    if (!config.isValid) {
      throw const WebDavException('请先填写服务器地址与用户名');
    }
    final webdav.Client client = _buildClient(config);
    late List<int> bytes;
    try {
      bytes = await client.read(remoteFile);
    } catch (e) {
      throw WebDavException('读取失败：${_describe(e)}');
    }

    try {
      final Object? decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const WebDavException('备份文件格式不正确');
      }
      return BackupBundle.fromJson(decoded);
    } on WebDavException {
      rethrow;
    } catch (e) {
      throw WebDavException('解析失败：${_describe(e)}');
    }
  }

  /// 把 Dio / 网络异常压缩成一句人类可读的提示。
  static String _describe(Object e) {
    final String text = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.contains('401') || text.contains('Unauthorized')) {
      return '授权失败，请检查用户名与应用授权码';
    }
    if (text.contains('404') || text.contains('Not Found')) {
      return '资源不存在（404）';
    }
    if (text.contains('403') || text.contains('Forbidden')) {
      return '没有访问权限（403）';
    }
    if (text.contains('Connection timed out') ||
        text.contains('TimeoutException')) {
      return '连接超时，请检查网络或服务器地址';
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      return '无法连接服务器，请检查地址与网络';
    }
    if (text.contains('HandshakeException') ||
        text.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'HTTPS 证书校验失败';
    }
    return text.length > 140 ? '${text.substring(0, 140)}…' : text;
  }
}

/// 统一的 WebDAV 业务异常，UI 层直接展示 [message]。
class WebDavException implements Exception {
  const WebDavException(this.message);

  final String message;

  @override
  String toString() => message;
}
