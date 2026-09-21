import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_item.dart';
import '../theme/app_theme.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/pill_bottom_bar.dart';
import 'ledger_home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// 全局导航壳：药丸式底部导航 + 首页记账 FAB。
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(created.isExpense ? '已记录一笔支出' : '已记录一笔收入'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.palette.background,
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: _openAddSheet,
              backgroundColor: context.palette.primary,
              foregroundColor: context.palette.onPrimary,
              elevation: 0,
              highlightElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add_rounded, size: 30),
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
