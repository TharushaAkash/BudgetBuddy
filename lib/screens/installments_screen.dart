import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/installment_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  InstallmentPlatform? _platformFilter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final results = _platformFilter == null
        ? provider.installments
        : provider.installments.where((e) => e.platform == _platformFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans & Installments'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterPill('All', _platformFilter == null, () => setState(() => _platformFilter = null), isDark),
                ...InstallmentPlatform.values.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildFilterPill(
                        kPlatformNames[p] ?? p.name,
                        _platformFilter == p,
                        () => setState(() => _platformFilter = p),
                        isDark,
                        color: kPlatformColors[p],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card_off_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No installments found', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return _buildInstallmentCard(context, item, provider, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          heroTag: 'inst_fab',
          onPressed: () => _showAddInstallmentSheet(context, provider),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, bool selected, VoidCallback onTap, bool isDark, {Color? color}) {
    final pillColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? pillColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentCard(BuildContext context, InstallmentModel item, FinanceProvider provider, bool isDark) {
    final color = kPlatformColors[item.platform] ?? Colors.purple;
    final nextDate = item.nextPaymentDate;
    final progress = item.months > 0 ? (item.paidMonths / item.months).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_rounded, color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      kPlatformNames[item.platform] ?? 'BNPL',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                onPressed: () => provider.deleteInstallment(item.id),
                visualDensity: VisualDensity.compact,
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(item.item, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('Shop: ${item.shop}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoStat('Paid', Formatters.currency(item.paidAmount, provider.currencySymbol), AppColors.income),
              _infoStat('Remaining', Formatters.currency(item.remainingAmount, provider.currencySymbol), AppColors.warning),
              _infoStat('Total', Formatters.currency(item.totalAmount, provider.currencySymbol), isDark ? Colors.white : Colors.black),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     '${item.paidMonths} / ${item.months} months paid',
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                   ),
                   if (!item.isCompleted && nextDate != null)
                     Container(
                       margin: const EdgeInsets.only(top: 8),
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(
                         color: AppColors.expense.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.event_rounded, size: 14, color: AppColors.expense),
                           const SizedBox(width: 6),
                           Text(
                             '${Formatters.currency(item.monthlyAmount, provider.currencySymbol)} due ${Formatters.dateShort(nextDate)}',
                             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.expense),
                           ),
                         ],
                       ),
                     ),
                ],
              ),
              if (!item.isCompleted)
                ElevatedButton(
                  onPressed: () => _markAsPaid(context, item, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Mark Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Completed 🎉', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.income)),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  void _showAddInstallmentSheet(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: const _AddInstallmentForm(),
        ),
      ),
    );
  }

  void _markAsPaid(BuildContext context, InstallmentModel item, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Payment Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...provider.accounts.map((acc) => ListTile(
                    leading: Icon(acc.icon, color: AppColors.primary),
                    title: Text(acc.name),
                    subtitle: Text('Balance: ${Formatters.currencyCompact(provider.accountBalance(acc.id), provider.currencySymbol)}'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _processInstallmentPayment(item, provider, acc);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _processInstallmentPayment(InstallmentModel item, FinanceProvider provider, AccountModel acc) async {
    final catName = kPlatformNames[item.platform] ?? item.platform.name;
    var category = provider.categories.firstWhere(
      (c) => c.name.toLowerCase().contains(catName.toLowerCase()) || c.name.toLowerCase().contains('loan') || c.name.toLowerCase().contains('installment'),
      orElse: () => provider.categories.firstWhere((c) => c.type == CategoryType.expense, orElse: () => provider.categories.first),
    );

    final tx = TransactionModel(
      id: provider.newId(),
      title: 'Paid Installment: ${item.item}',
      amount: item.monthlyAmount,
      type: CategoryType.expense,
      categoryId: category.id,
      accountId: acc.id,
      date: DateTime.now(),
      note: 'Paid via ${kPlatformNames[item.platform]} - ${item.shop}',
    );

    await provider.addTransaction(tx);

    final updatedItem = item.copyWith(paidMonths: item.paidMonths + 1);
    await provider.updateInstallment(updatedItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Installment paid successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

class _AddInstallmentForm extends StatefulWidget {
  const _AddInstallmentForm();

  @override
  State<_AddInstallmentForm> createState() => _AddInstallmentFormState();
}

class _AddInstallmentFormState extends State<_AddInstallmentForm> {
  final _shopCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  InstallmentPlatform _platform = InstallmentPlatform.koko;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _shopCtrl.dispose();
    _itemCtrl.dispose();
    _amountCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Installment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shopCtrl,
            decoration: const InputDecoration(labelText: 'Shop Name', hintText: 'e.g. Daraz / Singer'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemCtrl,
            decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Smartphone / TV'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _monthsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Months (e.g. 3)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<InstallmentPlatform>(
            initialValue: _platform,
            decoration: const InputDecoration(labelText: 'Platform'),
            items: InstallmentPlatform.values.map((p) {
              return DropdownMenuItem(value: p, child: Text(kPlatformNames[p] ?? p.name));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _platform = v);
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _date = d);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('First Payment Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                ],
              ),
            ),
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
              onPressed: () {
                final amount = double.tryParse(_amountCtrl.text) ?? 0;
                final months = int.tryParse(_monthsCtrl.text) ?? 0;
                if (_shopCtrl.text.isEmpty || _itemCtrl.text.isEmpty || amount <= 0 || months <= 0) {
                  return;
                }
                final provider = context.read<FinanceProvider>();
                provider.addInstallment(InstallmentModel(
                  id: provider.newId(),
                  shop: _shopCtrl.text,
                  item: _itemCtrl.text,
                  platform: _platform,
                  totalAmount: amount,
                  months: months,
                  firstPaymentDate: _date,
                ));
                Navigator.pop(context);
              },
              child: const Text('Save Installment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
