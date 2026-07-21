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
          ? Center(child: Text('No budgets set yet.\nTap + to create one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = provider.budgets[i];
                return BudgetProgressTile(
                  budget: b,
                  onTap: () => _showBudgetSheet(context, provider, existing: b),
                  onDelete: () => provider.deleteBudget(b.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showBudgetSheet(context, provider),
        child: const Icon(Icons.add),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existing == null ? 'New Budget' : 'Edit Budget', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: expenseCategories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Budget limit', prefixText: '${provider.currencySymbol} ', border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BudgetPeriod>(
                    value: period,
                    decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                    items: BudgetPeriod.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name[0].toUpperCase() + p.name.substring(1))))
                        .toList(),
                    onChanged: (v) => setState(() => period = v!),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: const Text('Save Budget'),
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
