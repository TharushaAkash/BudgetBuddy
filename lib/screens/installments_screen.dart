import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/installment_model.dart';
import '../providers/finance_provider.dart';
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
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _filterChip('All', _platformFilter == null, () => setState(() => _platformFilter = null)),
                ...InstallmentPlatform.values.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _filterChip(
                        kPlatformNames[p] ?? p.name,
                        _platformFilter == p,
                        () => setState(() => _platformFilter = p),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text('No installments found', style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return _buildInstallmentCard(context, item, provider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddInstallmentSheet(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildInstallmentCard(BuildContext context, InstallmentModel item, FinanceProvider provider) {
    final color = kPlatformColors[item.platform] ?? Colors.grey;
    final nextDate = item.nextPaymentDate;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      radius: 16,
                      child: Icon(Icons.shopping_bag, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kPlatformNames[item.platform] ?? 'Unknown',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => provider.deleteInstallment(item.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(item.item, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Shop: ${item.shop}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoStat('Paid', Formatters.currency(item.paidAmount, provider.currencySymbol), Colors.green),
                _infoStat('Remaining', Formatters.currency(item.remainingAmount, provider.currencySymbol), Colors.orange),
                _infoStat('Total', Formatters.currency(item.totalAmount, provider.currencySymbol), null),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: item.months > 0 ? item.paidMonths / item.months : 0,
              backgroundColor: Colors.grey.shade800,
              color: color,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.paidMonths} / ${item.months} months paid', style: const TextStyle(fontSize: 12)),
                if (!item.isCompleted && nextDate != null)
                  Text(
                    'Next: ${Formatters.currency(item.monthlyAmount, provider.currencySymbol)} on ${nextDate.day}/${nextDate.month}/${nextDate.year}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  )
                else if (item.isCompleted)
                  const Text('Completed 🎉', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoStat(String label, String value, Color? valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: const _AddInstallmentForm(),
        ),
      ),
    );
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add Installment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
        TextField(
          controller: _shopCtrl,
          decoration: const InputDecoration(labelText: 'Shop Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _itemCtrl,
          decoration: const InputDecoration(labelText: 'Item Name'),
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
          value: _platform,
          decoration: const InputDecoration(labelText: 'Platform'),
          items: InstallmentPlatform.values.map((p) {
            return DropdownMenuItem(value: p, child: Text(kPlatformNames[p] ?? p.name));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _platform = v);
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('First Payment Date'),
          subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) setState(() => _date = d);
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
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
            child: const Text('Save Installment'),
          ),
        )
      ],
      ),
    );
  }
}
