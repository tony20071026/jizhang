import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/transaction_item.dart';
import '../services/ai_extract_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/pill_bottom_bar.dart';
import 'ledger_home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// 全局导航壳：药丸式底部导航 + 首页记账 FAB。
///
/// FAB 单击 = 手动记账；长按 = 上传支付截图，AI 识别后预填记账。
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  bool _loading = false;

  late final List<Widget> _pages = const <Widget>[
    LedgerHomeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  void _onNavTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _index = index);
  }

  Future<void> _openAddSheet() async {
    final TransactionItem? created = await AddTransactionSheet.show(context);
    if (!mounted || created == null) return;
    _snack(created.isExpense ? '已记录一笔支出' : '已记录一笔收入');
  }

  // -------------------------------------------------------------- AI 截图记账

  Future<void> _openAiAddSheet() async {
    HapticFeedback.mediumImpact();
    if (!AiExtractService.isConfigured) {
      _snack('请先在「设置 → AI 识别」里开启并填写 API Key', error: true);
      return;
    }
    final ImageSource? source = await _pickImageSource();
    if (source == null) return;

    final XFile? file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    _showLoading();
    try {
      final Uint8List bytes = await file.readAsBytes();
      final AiTransactionDraft draft = await AiExtractService.extract(
        bytes,
        mimeType: _mimeOf(file.name),
      );
      _dismissLoading();
      if (!mounted) return;
      final TransactionItem? created = await AddTransactionSheet.show(
        context,
        initialExpense: draft.isExpense,
        initialAmount: draft.amount,
        initialCategory: draft.category,
        initialDate: draft.date,
        initialNote: draft.note,
      );
      if (!mounted || created == null) return;
      _snack('已记录一笔${created.isExpense ? '支出' : '收入'}');
    } catch (e) {
      _dismissLoading();
      if (!mounted) return;
      _snack(e is AiExtractException ? e.message : '识别失败：$e', error: true);
    }
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (BuildContext sheetContext) {
        final AppPalette palette = sheetContext.palette;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: palette.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI 截图记账',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: palette.primary,
                ),
                title: const Text('从相册选择支付截图'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_rounded,
                  color: palette.primary,
                ),
                title: const Text('拍摄支付截图'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showLoading() {
    setState(() => _loading = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: dialogContext.palette.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'AI 识别中…',
                    style: TextStyle(
                      fontSize: 14,
                      color: dialogContext.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _dismissLoading() {
    if (!_loading) return;
    _loading = false;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: error ? 3200 : 1400),
          backgroundColor: error ? const Color(0xFFD9534F) : null,
        ),
      );
  }

  static String _mimeOf(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.palette.background,
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index == 0
          ? GestureDetector(
              onLongPress: _openAiAddSheet,
              child: FloatingActionButton(
                onPressed: _openAddSheet,
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
                elevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add_rounded, size: 30),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: PillBottomBar(
        currentIndex: _index,
        onTap: _onNavTap,
      ),
    );
  }
}
