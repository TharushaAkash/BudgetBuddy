import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/budget_progress_tile.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: provider.budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No budgets set yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: provider.budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final b = provider.budgets[i];
                return BudgetProgressTile(
                  budget: b,
                  onTap: () => _showBudgetSheet(context, provider, existing: b),
                  onDelete: () => provider.deleteBudget(b.id),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          heroTag: 'budget_fab',
          onPressed: () => _showBudgetSheet(context, provider),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  void _showBudgetSheet(BuildContext context, FinanceProvider provider, {BudgetModel? existing}) {
    final expenseCategories = provider.categories.where((c) => c.type.name == 'expense').toList();
    String? categoryId = existing?.categoryId ?? (expenseCategories.isNotEmpty ? expenseCategories.first.id : null);
    BudgetPeriod period = existing?.period ?? BudgetPeriod.monthly;
    final limitController = TextEditingController(text: existing?.limit.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'New Budget' : 'Edit Budget',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: expenseCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(c.icon, size: 18, color: c.color),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Budget Limit',
                      prefixText: '${provider.currencySymbol} ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BudgetPeriod>(
                    initialValue: period,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: BudgetPeriod.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => period = v!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final limit = double.tryParse(limitController.text);
                        if (categoryId == null || limit == null || limit <= 0) return;
                        if (existing == null) {
                          await provider.addBudget(BudgetModel(
                            id: provider.newId(),
                            categoryId: categoryId!,
                            limit: limit,
                            period: period,
                          ));
                        } else {
                          existing.categoryId = categoryId!;
                          existing.limit = limit;
                          existing.period = period;
                          await provider.updateBudget(existing);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

