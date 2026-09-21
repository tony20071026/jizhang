import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_item.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import '../services/webdav_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import 'category_manage_screen.dart';

/// 设置页：WebDAV 同步（测试连接 / 备份 / 恢复）+ 本地数据管理。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _keyUrl = 'webdav_url';
  static const String _keyUser = 'webdav_user';
  static const String _keyPwd = 'webdav_password';
  static const String _keyLastBackup = 'last_backup_at';

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();

  bool _obscure = true;
  String? _busyTask;
  DateTime? _lastBackup;

  /// 云同步入口开关：关闭后整个 WebDAV 区块不再显示。
  bool _webdavEnabled = true;

  bool get _busy => _busyTask != null;

  @override
  void initState() {
    super.initState();
    _webdavEnabled =
        DBService.readSetting<bool>(
          DBService.keyWebDavEnabled,
          fallback: true,
        ) ??
        true;
    _urlController.text = DBService.readSetting<String>(_keyUrl) ?? '';
    _userController.text = DBService.readSetting<String>(_keyUser) ?? '';
    _pwdController.text = DBService.readSetting<String>(_keyPwd) ?? '';
    final String? stamp = DBService.readSetting<String>(_keyLastBackup);
    if (stamp != null) {
      _lastBackup = DateTime.tryParse(stamp);
    }
  }

  Future<void> _toggleWebDav(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _webdavEnabled = value);
    await DBService.writeSetting(DBService.keyWebDavEnabled, value);
    _toast(value ? '已开启云同步入口' : '已隐藏云同步入口');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  WebDavConfig get _config => WebDavConfig(
    url: _urlController.text.trim(),
    user: _userController.text.trim(),
    password: _pwdController.text,
  );

  Future<void> _persistConfig() async {
    await DBService.writeSetting(_keyUrl, _urlController.text.trim());
    await DBService.writeSetting(_keyUser, _userController.text.trim());
    await DBService.writeSetting(_keyPwd, _pwdController.text);
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: error ? 3200 : 1800),
          backgroundColor: error ? const Color(0xFFD9534F) : null,
        ),
      );
  }

  Future<void> _run({
    required String task,
    required Future<void> Function() action,
  }) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busyTask = task);
    try {
      await action();
    } catch (e) {
      _toast(e is WebDavException ? e.message : '操作失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _busyTask = null);
    }
  }

  Future<void> _testConnection() => _run(
    task: 'test',
    action: () async {
      await _persistConfig();
      await WebDavService.testConnection(_config);
      _toast('连接成功，可以开始同步了');
    },
  );

  Future<void> _backup() => _run(
    task: 'backup',
    action: () async {
      await _persistConfig();
      final List<TransactionItem> items = DBService.allSorted();
      if (items.isEmpty) {
        _toast('本地还没有数据，无需备份', error: true);
        return;
      }
      final int count = await WebDavService.backup(_config, items);
      final DateTime now = DateTime.now();
      await DBService.writeSetting(_keyLastBackup, now.toIso8601String());
      if (mounted) setState(() => _lastBackup = now);
      _toast('已备份 $count 笔到 /my_ledger/backup.json');
    },
  );

  Future<void> _restore() async {
    if (_busy) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('从云端恢复'),
          content: const Text(
            '将下载 /my_ledger/backup.json 并覆盖当前设备上的全部流水，是否继续？',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('覆盖恢复'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await _run(
      task: 'restore',
      action: () async {
        await _persistConfig();
        final BackupBundle bundle = await WebDavService.restore(_config);
        final int count = await DBService.replaceAll(bundle.items);
        _toast('已恢复 $count 笔（备份于 ${Formatters.dateTime(bundle.exportedAt)}）');
      },
    );
  }

  Future<void> _clearLocal() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('清空本地数据'),
          content: const Text('将删除本设备上全部流水，且无法撤销。建议先备份到云端。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                '确认清空',
                style: TextStyle(color: context.palette.expense),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await DBService.clearAll();
    _toast('本地数据已清空');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.page,
          right: AppSpacing.page,
          top: 6,
          bottom: 130,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: <Widget>[
          ScreenHeader(
            title: '设置',
            subtitle: _webdavEnabled
                ? 'WebDAV 备份与本地数据管理'
                : '本地数据管理 · 云同步已隐藏',
          ),
          const SizedBox(height: 14),
          _buildSyncToggleCard(),
          const SizedBox(height: AppSpacing.gap),
          if (_webdavEnabled) ...<Widget>[
            _buildServerCard(),
            const SizedBox(height: AppSpacing.gap),
          ],
          _buildDataCard(),
          const SizedBox(height: AppSpacing.gap),
          _buildAboutCard(),
        ],
      ),
    );
  }

  /// 云同步总开关：控制 WebDAV 配置区块的显示与隐藏。
  Widget _buildSyncToggleCard() {
    final AppPalette palette = context.palette;
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _webdavEnabled
                  ? palette.primarySoft
                  : palette.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.cloud_sync_rounded,
              size: 20,
              color: _webdavEnabled ? palette.primary : palette.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'WebDAV 云同步',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _webdavEnabled
                      ? '备份 / 恢复入口已显示'
                      : '入口已隐藏，本地数据不受影响',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: _webdavEnabled, onChanged: _toggleWebDav),
        ],
      ),
    );
  }

  Widget _buildServerCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'WebDAV 服务器',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '备份文件将保存在 /my_ledger/backup.json',
            style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: '服务器地址',
            child: TextField(
              controller: _urlController,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14.5),
              decoration: const InputDecoration(
                hintText: 'https://dav.example.com/dav/',
                prefixIcon: Icon(Icons.cloud_outlined, size: 19),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: '用户名',
            child: TextField(
              controller: _userController,
              enabled: !_busy,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14.5),
              decoration: const InputDecoration(
                hintText: '登录邮箱 / 用户名',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 19),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: '应用授权码',
            child: TextField(
              controller: _pwdController,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 14.5),
              decoration: InputDecoration(
                hintText: '第三方应用专用密码',
                prefixIcon: const Icon(Icons.key_outlined, size: 19),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: context.palette.textHint,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TaskButton(
            label: '测试连接',
            icon: Icons.wifi_tethering_rounded,
            busy: _busyTask == 'test',
            disabled: _busy,
            outlined: true,
            onPressed: _testConnection,
          ),
          const SizedBox(height: 10),
          _TaskButton(
            label: '一键备份至云端',
            icon: Icons.cloud_upload_rounded,
            busy: _busyTask == 'backup',
            disabled: _busy,
            onPressed: _backup,
          ),
          const SizedBox(height: 10),
          _TaskButton(
            label: '从云端拉取恢复',
            icon: Icons.cloud_download_rounded,
            busy: _busyTask == 'restore',
            disabled: _busy,
            color: context.palette.primaryDark,
            onPressed: _restore,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Icon(
                Icons.history_rounded,
                size: 15,
                color: context.palette.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                _lastBackup == null
                    ? '尚未备份过'
                    : '最近备份：${Formatters.dateTime(_lastBackup!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: context.palette.hairline),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : _disableWebDav,
            icon: const Icon(Icons.power_settings_new_rounded, size: 18),
            label: const Text('关闭云同步并隐藏此入口'),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textSecondary,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// 彻底关闭云同步：停用开关并隐藏整个 WebDAV 区块（配置保留，随时可再打开）。
  Future<void> _disableWebDav() async {
    final AppPalette palette = context.palette;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('关闭云同步'),
        content: const Text(
          '关闭后「WebDAV 云同步」入口将从设置页隐藏，'
          '已填写的服务器地址与授权码会保留，下次开启即可继续使用。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('确认关闭', style: TextStyle(color: palette.expense)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    setState(() => _webdavEnabled = false);
    await DBService.writeSetting(DBService.keyWebDavEnabled, false);
    _toast('已关闭云同步，入口已隐藏');
  }

  Widget _buildDataCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '本地数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _DataStat(
                  label: '流水总数',
                  value: '${DBService.count} 笔',
                ),
              ),
              Expanded(
                child: _DataStat(
                  label: '分类数量',
                  value: '${_usedCategories()} 个',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _exportJson,
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('导出 JSON'),
                    style: _secondaryButtonStyle(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _importJson,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('导入 JSON'),
                    style: _secondaryButtonStyle(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _openCategoryManage,
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('分类管理（排序 / 自定义）'),
              style: _secondaryButtonStyle(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _clearLocal,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.expense,
                side: BorderSide(
                  color: context.palette.expense.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
              child: const Text('清空本地数据'),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    final AppPalette palette = context.palette;
    return OutlinedButton.styleFrom(
      foregroundColor: palette.textPrimary,
      side: BorderSide(color: palette.hairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  /// 手动导出：走系统文件选择器，用户自选保存位置。
  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() => _busyTask = 'export');
    try {
      final ExportResult? result = await ExportService.exportToFile();
      if (result == null) {
        _toast('已取消导出');
      } else {
        _toast('已导出 ${result.count} 笔流水');
      }
    } catch (e) {
      _toast('导出失败：$e', error: true);
    } finally {
      if (mounted) {
        setState(() => _busyTask = null);
      }
    }
  }

  /// 手动导入：读取任意 JSON 备份，可选覆盖或合并。
  Future<void> _importJson() async {
    if (_busy) return;
    setState(() => _busyTask = 'import');
    try {
      final ImportPayload? payload = await ExportService.pickAndParse();
      if (payload == null) {
        _toast('已取消导入');
        return;
      }
      if (payload.isEmpty) {
        _toast('文件里没有可导入的数据', error: true);
        return;
      }
      if (!mounted) return;
      final bool? replace = await _askImportMode(payload);
      if (replace == null) return;

      final ImportResult result = await ExportService.apply(
        payload,
        replace: replace,
      );
      final String tail = replace
          ? '已覆盖为 ${result.added} 笔'
          : '新增 ${result.added} 笔，跳过重复 ${result.skipped} 笔';
      _toast('导入完成：$tail');
    } catch (e) {
      _toast('导入失败：$e', error: true);
    } finally {
      if (mounted) {
        setState(() => _busyTask = null);
      }
    }
  }

  Future<bool?> _askImportMode(ImportPayload payload) {
    final AppPalette palette = context.palette;
    final String exported = payload.exportedAt == null
        ? ''
        : '\n导出时间：${Formatters.dateTime(payload.exportedAt!)}';
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('选择导入方式'),
        content: Text(
          '文件包含 ${payload.items.length} 笔流水$exported\n\n'
          '合并：按 ID 去重追加，保留本地已有数据\n'
          '覆盖：清空本地流水后写入文件内容',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('合并'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('覆盖', style: TextStyle(color: palette.expense)),
          ),
        ],
      ),
    );
  }

  Future<void> _openCategoryManage() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => const CategoryManageScreen(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  int _usedCategories() => DBService.allSorted()
      .map((TransactionItem t) => t.title)
      .toSet()
      .length;

  Widget _buildAboutCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '关于',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _InfoRow(title: '应用', value: '轻账 · Local-First 记账'),
          const SizedBox(height: 8),
          const _InfoRow(title: '存储', value: 'Hive 本地数据库'),
          const SizedBox(height: 8),
          const _InfoRow(title: '同步', value: 'WebDAV 全量 JSON'),
          const SizedBox(height: 12),
          Text(
            '所有数据默认只保存在本机，只有你主动点击备份时才会上传到自己的 WebDAV 服务器。',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.palette.textSecondary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TaskButton extends StatelessWidget {
  const _TaskButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.disabled,
    required this.onPressed,
    this.outlined = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final bool disabled;
  final VoidCallback onPressed;
  final bool outlined;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? context.palette.primary;
    final Widget content = busy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: outlined ? base : context.palette.onPrimary,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: base,
            side: BorderSide(color: base.withValues(alpha: 0.55)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: disabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: base,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
        child: content,
      ),
    );
  }
}

class _DataStat extends StatelessWidget {
  const _DataStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 13.5, color: context.palette.textPrimary),
        ),
      ],
    );
  }
}
