import 'package:flutter/material.dart';

import '../models/category_item.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 统计页的分类明细行：图标 + 名称 + 占比进度条 + 金额。
class CategoryProgressTile extends StatelessWidget {
  const CategoryProgressTile({
    super.key,
    required this.categoryName,
    required this.isExpense,
    required this.amount,
    required this.ratio,
    this.onTap,
  });

  final String categoryName;
  final bool isExpense;
  final double amount;

  /// 0 ~ 1
  final double ratio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final CategoryItem category = CategoryService.resolve(categoryName, isExpense);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: category.softColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(category.icon, color: category.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(ratio * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: context.palette.hairline,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          category.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    Formatters.money(amount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.palette.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isExpense ? '支出' : '收入',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
