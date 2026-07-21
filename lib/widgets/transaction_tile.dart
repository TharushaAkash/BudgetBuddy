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
        ? Colors.blueGrey
        : (category?.color ?? (isIncome ? AppColors.income : AppColors.expense));
    final icon = transaction.isTransfer ? Icons.swap_horiz : (category?.icon ?? Icons.category);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${category?.name ?? 'Transfer'} • ${Formatters.dateShort(transaction.date)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${Formatters.currency(transaction.amount, provider.currencySymbol)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: transaction.isTransfer ? Colors.blueGrey : (isIncome ? AppColors.income : AppColors.expense),
        ),
      ),
    );
  }
}
