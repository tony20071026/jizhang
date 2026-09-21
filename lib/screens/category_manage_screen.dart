import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category_item.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

/// 分类管理：拖拽排序、新建、改名、换图标与配色。
class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key, this.initialIsExpense = true});

  final bool initialIsExpense;

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  late bool _isExpense = widget.initialIsExpense;
  late List<CategoryItem> _items = CategoryService.of(_isExpense);

  void _reload() {
    setState(() => _items = CategoryService.of(_isExpense));
  }

  void _switchType(bool isExpense) {
    if (_isExpense == isExpense) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isExpense = isExpense;
      _items = CategoryService.of(isExpense);
    });
  }

  /// `onReorderItem` 已经替我们修正过 newIndex（移除原项后的插入位），
  /// 因此这里不再手动 `newIndex -= 1`。
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    HapticFeedback.mediumImpact();
    final CategoryItem moved = _items.removeAt(oldIndex);
    _items.insert(newIndex, moved);
    setState(() {});
    await CategoryService.reorder(_isExpense, _items);
  }

  Future<void> _resetOrder() async {
    HapticFeedback.lightImpact();
    await CategoryService.resetOrder(_isExpense);
    _reload();
  }

  Future<void> _openEditor({CategoryItem? editing}) async {
    HapticFeedback.lightImpact();
    final _CategoryDraft? draft = await showModalBottomSheet<_CategoryDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _CategoryEditorSheet(
        isExpense: _isExpense,
        editing: editing,
      ),
    );
    if (draft == null) return;

    if (editing == null) {
      await CategoryService.add(
        name: draft.name,
        icon: draft.icon,
        color: draft.color,
        isExpense: _isExpense,
      );
    } else {
      await CategoryService.updateMeta(
        editing,
        name: draft.name,
        icon: draft.icon,
        color: draft.color,
      );
    }
    _reload();
  }

  Future<void> _delete(CategoryItem item) async {
    final AppPalette palette = context.palette;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text(
          '「${item.name}」将从分类列表中移除。已记录的流水不会被删除，'
          '但在统计里会显示为「其他」。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('删除', style: TextStyle(color: palette.expense)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CategoryService.remove(item);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(),
            _buildTypeTabs(),
            const SizedBox(height: 10),
            Expanded(child: _buildList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            color: palette.textPrimary,
          ),
          Text(
            '分类管理',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _resetOrder,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('恢复默认顺序'),
            style: TextButton.styleFrom(
              foregroundColor: palette.textSecondary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Row(
          children: <Widget>[
            _TypeTab(
              label: '支出',
              selected: _isExpense,
              activeColor: palette.expense,
              onTap: () => _switchType(true),
            ),
            _TypeTab(
              label: '收入',
              selected: !_isExpense,
              activeColor: palette.income,
              onTap: () => _switchType(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final AppPalette palette = context.palette;
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.category_outlined,
        title: '还没有分类',
        subtitle: '点击下方按钮创建第一个分类',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        4,
        AppSpacing.page,
        12,
      ),
      itemCount: _items.length,
      onReorderItem: _onReorder,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          color: Colors.transparent,
          child: Transform.scale(scale: 1.02, child: child),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        final CategoryItem item = _items[index];
        return Padding(
          key: ValueKey<int>(item.key as int),
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: palette.isDark
                  ? Border.all(color: palette.hairline)
                  : null,
              boxShadow: palette.isDark
                  ? null
                  : <BoxShadow>[AppShadows.card],
            ),
            child: Row(
              children: <Widget>[
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: palette.textHint,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.softColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, size: 20, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      if (index < CategoryDefaults.pinnedCount)
                        _PinnedBadge(palette: palette),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openEditor(editing: item),
                  icon: const Icon(Icons.edit_rounded, size: 19),
                  color: palette.textSecondary,
                ),
                IconButton(
                  onPressed: () => _delete(item),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: palette.textHint,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        4,
        AppSpacing.page,
        16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '排序后，前 ${CategoryDefaults.pinnedCount} 个会在记账时直接显示，'
            '其余收在「更多分类」里',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.textHint),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('新建分类'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '常驻',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: palette.primary,
        ),
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
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected
                  ? context.palette.onPrimary
                  : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 编辑器返回的草稿。
class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

/// 新建 / 编辑分类的底部面板：名称 + 图标网格 + 配色。
class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.isExpense, this.editing});

  final bool isExpense;
  final CategoryItem? editing;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.editing?.name ?? '',
  );
  late IconData _icon = widget.editing?.icon ?? CategoryIcons.choices.first;
  late Color _color =
      widget.editing?.color ??
      CategoryDefaults.palette[
          CategoryService.of(widget.isExpense).length %
              CategoryDefaults.palette.length];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('请填写分类名称'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (CategoryService.nameExists(
      name,
      widget.isExpense,
      except: widget.editing,
    )) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('已存在同名分类「$name」'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      _CategoryDraft(name: name, icon: _icon, color: _color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isNew = widget.editing == null;
    final String title = isNew
        ? '新建${widget.isExpense ? '支出' : '收入'}分类'
        : '编辑分类';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.hairline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: palette.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: palette.surfaceMuted,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _preview(palette),
                    const SizedBox(height: 20),
                    _label('名称', palette),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      maxLength: 8,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: TextStyle(fontSize: 15, color: palette.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '例如「健身」「宠物粮」',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _label('颜色', palette),
                    const SizedBox(height: 10),
                    _colorPicker(),
                    const SizedBox(height: 18),
                    _label('图标', palette),
                    const SizedBox(height: 10),
                    _iconPicker(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                    ),
                    child: Text(isNew ? '创建分类' : '保存修改'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(AppPalette palette) {
    return Row(
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(_icon, size: 26, color: _color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (BuildContext context, TextEditingValue value, Widget? _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value.text.trim().isEmpty ? '未命名' : value.text.trim(),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '效果预览',
                    style: TextStyle(fontSize: 12, color: palette.textHint),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _label(String text, AppPalette palette) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: palette.textSecondary,
      ),
    );
  }

  Widget _colorPicker() {
    final AppPalette palette = context.palette;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: CategoryDefaults.palette.map((Color color) {
        final bool selected = color.toARGB32() == _color.toARGB32();
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _color = color);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.textPrimary : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: palette.onPrimary,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _iconPicker() {
    final AppPalette palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: SizedBox(
        height: 216,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: CategoryIcons.choices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (BuildContext context, int index) {
            final IconData icon = CategoryIcons.choices[index];
            final bool selected = icon.codePoint == _icon.codePoint;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _icon = icon);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? _color.withValues(alpha: 0.16)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _color : palette.hairline,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: selected ? _color : palette.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
