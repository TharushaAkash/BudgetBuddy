import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final category = provider.categoryById(transaction.categoryId);
    final isIncome = transaction.type == CategoryType.income;
    final color = transaction.isTransfer
        ? Colors.indigo
        : (category?.color ?? (isIncome ? AppColors.income : AppColors.expense));
    final icon = transaction.isTransfer ? Icons.swap_horiz_rounded : (category?.icon ?? Icons.category_rounded);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE2E8F0),
        ),
      ),
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category?.name ?? (transaction.isTransfer ? 'Transfer' : 'General')} • ${Formatters.dateShort(transaction.date)}, ${Formatters.time(transaction.date)}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: (transaction.isTransfer
                              ? Colors.indigo
                              : (isIncome ? AppColors.income : AppColors.expense))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          transaction.isTransfer ? Icons.swap_horiz_rounded : Icons.local_offer_rounded,
                          size: 11,
                          color: transaction.isTransfer ? Colors.indigo : (isIncome ? AppColors.income : AppColors.expense),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction.isTransfer ? 'Transfer' : (isIncome ? 'Income' : 'Expense'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: transaction.isTransfer ? Colors.indigo : (isIncome ? AppColors.income : AppColors.expense),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (transaction.isTransfer
                        ? Colors.indigo
                        : (isIncome ? AppColors.income : AppColors.expense))
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${isIncome ? '+' : '-'}${Formatters.currency(transaction.amount, provider.currencySymbol)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: transaction.isTransfer
                      ? Colors.indigo
                      : (isIncome ? AppColors.income : AppColors.expense),
                ),
              ),
            ),
          ],
        ),
      ),
     ),
    );
  }
}

