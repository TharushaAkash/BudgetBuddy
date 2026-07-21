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
    final isOver = spent > budget.limit;
    final progressColor = isOver
        ? AppColors.expense
        : (ratio > 0.8 ? Colors.orange : (category?.color ?? AppColors.primary));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category?.icon ?? Icons.category, color: category?.color ?? AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(category?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio > 1 ? 1 : ratio,
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Formatters.currency(spent, provider.currencySymbol)} spent',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'of ${Formatters.currency(budget.limit, provider.currencySymbol)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (isOver)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Over budget by ${Formatters.currency(spent - budget.limit, provider.currencySymbol)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
