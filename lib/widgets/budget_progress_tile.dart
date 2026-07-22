import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class BudgetProgressTile extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BudgetProgressTile({super.key, required this.budget, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final category = provider.categoryById(budget.categoryId);
    final spent = provider.spentForBudget(budget);
    final ratio = budget.limit == 0 ? 0.0 : (spent / budget.limit).clamp(0.0, 1.5);
    final pctInt = (ratio * 100).toInt();
    final isOver = spent > budget.limit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor = isOver
        ? AppColors.expense
        : (ratio > 0.8 ? AppColors.warning : (category?.color ?? AppColors.primary));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (category?.color ?? AppColors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category?.icon ?? Icons.category_rounded,
                    color: category?.color ?? AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Category',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${budget.period.name[0].toUpperCase()}${budget.period.name.substring(1)} Budget',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pctInt%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: progressColor,
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: ratio > 1 ? 1 : ratio,
                minHeight: 10,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Formatters.currency(spent, provider.currencySymbol)} spent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Limit: ${Formatters.currency(budget.limit, provider.currencySymbol)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (isOver) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.expense),
                  const SizedBox(width: 4),
                  Text(
                    'Over budget by ${Formatters.currency(spent - budget.limit, provider.currencySymbol)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

