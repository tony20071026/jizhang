import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category_item.dart';
import '../models/transaction_item.dart';
import '../screens/category_manage_screen.dart';
import '../services/category_service.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 大圆角记账弹窗：支出 / 收入 Tab 切换 + 网格化分类 + 金额 + 日期 + 备注。
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.initialDate});

  final DateTime? initialDate;

  /// 弹出记账面板。
  static Future<TransactionItem?> show(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<TransactionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x33000000),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: AddTransactionSheet(initialDate: initialDate),
        );
      },
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isExpense = true;
  late String _category;
  late DateTime _date;
  bool _saving = false;

  /// 是否展开了「更多分类」（默认只显示前 8 个常驻分类）。
  bool _expanded = false;

  List<CategoryItem> get _categories => CategoryService.of(_isExpense);

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _category = _categories.first.name;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _switchType(bool isExpense) {
    if (_isExpense == isExpense) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isExpense = isExpense;
      _expanded = false;
      _category = CategoryService.of(isExpense).first.name;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.palette.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    final DateTime now = DateTime.now();
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
        now.second,
      );
    });
  }

  Future<void> _submit() async {
    final String raw = _amountController.text.trim();
    final double? amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      _toast('请输入大于 0 的金额');
      return;
    }
    if (amount > 99999999) {
      _toast('金额太大啦，请检查输入');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      final TransactionItem item = await DBService.add(
        title: _category,
        amount: amount,
        date: _date,
        isExpense: _isExpense,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(item);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('保存失败：$e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            _DragHandle(),
            _buildHeader(),
            const SizedBox(height: 4),
            _buildTypeTabs(),
            Flexible(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: <Widget>[
          Text(
            '记一笔',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: context.palette.textSecondary,
            style: IconButton.styleFrom(
              backgroundColor: context.palette.surfaceMuted,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            _TypeTab(
              label: '支出',
              selected: _isExpense,
              activeColor: context.palette.expense,
              onTap: () => _switchType(true),
            ),
            _TypeTab(
              label: '收入',
              selected: !_isExpense,
              activeColor: context.palette.income,
              onTap: () => _switchType(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildAmountField(),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              const _SectionLabel(text: '选择分类'),
              const Spacer(),
              _buildManageEntry(),
            ],
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
          const SizedBox(height: 22),
          const _SectionLabel(text: '日期'),
          const SizedBox(height: 10),
          _DateTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 18),
          const _SectionLabel(text: '备注'),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLength: 60,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: 15, color: context.palette.textPrimary),
            decoration: InputDecoration(
              hintText: '选填，例如「和朋友聚餐」',
              counterText: '',
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: context.palette.textHint,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final Color accent = _isExpense ? context.palette.expense : context.palette.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            '¥',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}\.?\d{0,2}')),
              ],
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: accent,
                letterSpacing: -0.6,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
    );
  }

  /// 默认只铺前 8 个常驻分类（两行四列），其余折叠在「更多分类」之后。
  Widget _buildCategoryGrid() {
    final List<CategoryItem> all = _categories;
    final int pinned = CategoryDefaults.pinnedCount;
    final bool collapsible = all.length > pinned;
    final List<CategoryItem> visible = (!_expanded && collapsible)
        ? all.take(pinned).toList()
        : all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (BuildContext context, int index) {
            final CategoryItem category = visible[index];
            return _CategoryCell(
              category: category,
              selected: category.name == _category,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _category = category.name);
              },
            );
          },
        ),
        if (collapsible) _buildExpandToggle(all.length),
      ],
    );
  }

  /// 「管理」入口：跳到分类管理页，返回后同步改名 / 排序 / 新增的结果。
  Widget _buildManageEntry() {
    final AppPalette palette = context.palette;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext _) =>
                CategoryManageScreen(initialIsExpense: _isExpense),
          ),
        );
        if (!mounted) return;
        setState(() {
          final List<CategoryItem> list = CategoryService.of(_isExpense);
          if (list.isNotEmpty && !list.any((CategoryItem c) => c.name == _category)) {
            _category = list.first.name;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.tune_rounded, size: 15, color: palette.primary),
          const SizedBox(width: 4),
          Text(
            '管理',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandToggle(int total) {
    final AppPalette palette = context.palette;
    final int rest = total - CategoryDefaults.pinnedCount;
    return Center(
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          setState(() => _expanded = !_expanded);
        },
        icon: AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: palette.textSecondary,
          ),
        ),
        label: Text(_expanded ? '收起分类' : '更多分类（$rest）'),
        style: TextButton.styleFrom(
          foregroundColor: palette.textSecondary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _isExpense ? context.palette.expense : context.palette.income,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: context.palette.onPrimary,
                    ),
                  )
                : Text('保存${_isExpense ? '支出' : '收入'}'),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: context.palette.hairline,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.palette.textSecondary,
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? context.palette.onPrimary : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryItem category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? category.softColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? category.color : category.softColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                category.icon,
                size: 21,
                color: selected ? context.palette.onPrimary : category.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? category.color : context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                '${Formatters.fullDate(date)}  ${Formatters.dayLabel(date)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.palette.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: context.palette.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
