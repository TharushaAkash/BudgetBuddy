import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  CategoryType _type = CategoryType.expense;
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  RecurrenceInterval _recurrence = RecurrenceInterval.none;
  bool _isTransfer = false;
  String? _toAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _noteController.text = e.note;
      _type = e.type;
      _categoryId = e.categoryId;
      _accountId = e.accountId;
      _date = e.date;
      _recurrence = e.recurrence;
      _isTransfer = e.isTransfer;
      _toAccountId = e.toAccountId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final filteredCategories = provider.categories.where((c) => c.type == _type).toList();

    if (_accountId == null && provider.accounts.isNotEmpty) {
      _accountId = provider.accounts.first.id;
    }
    if (!_isTransfer && _categoryId == null && filteredCategories.isNotEmpty) {
      _categoryId = filteredCategories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await provider.deleteTransaction(widget.existing!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isTransfer)
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(value: CategoryType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: CategoryType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _categoryId = null;
                }),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('This is a transfer between accounts'),
              value: _isTransfer,
              onChanged: (v) => setState(() => _isTransfer = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${provider.currencySymbol} ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (!_isTransfer)
              DropdownButtonFormField<String>(
                value: filteredCategories.any((c) => c.id == _categoryId) ? _categoryId : null,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: filteredCategories
                    .map((c) => DropdownMenuItem(value: c.id, child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(c.icon, size: 18, color: c.color),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        )))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
            if (!_isTransfer) const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: provider.accounts.any((a) => a.id == _accountId) ? _accountId : null,
              decoration: InputDecoration(labelText: _isTransfer ? 'From Account' : 'Account', border: const OutlineInputBorder()),
              items: provider.accounts
                  .map((a) => DropdownMenuItem(value: a.id, child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.icon, size: 18, color: a.color),
                          const SizedBox(width: 8),
                          Text(a.name),
                        ],
                      )))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Select an account' : null,
            ),
            if (_isTransfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: provider.accounts.any((a) => a.id == _toAccountId) ? _toAccountId : null,
                decoration: const InputDecoration(labelText: 'To Account', border: OutlineInputBorder()),
                items: provider.accounts
                    .where((a) => a.id != _accountId)
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) => _isTransfer && v == null ? 'Select a destination account' : null,
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(Formatters.date(_date)),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const Divider(),
            if (!_isTransfer)
              DropdownButtonFormField<RecurrenceInterval>(
                value: _recurrence,
                decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()),
                items: RecurrenceInterval.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(_recurrenceLabel(r))))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v!),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _submit(provider),
                child: Text(widget.existing == null ? 'Save Transaction' : 'Update Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(RecurrenceInterval r) {
    switch (r) {
      case RecurrenceInterval.none:
        return 'Does not repeat';
      case RecurrenceInterval.daily:
        return 'Daily';
      case RecurrenceInterval.weekly:
        return 'Weekly';
      case RecurrenceInterval.monthly:
        return 'Monthly';
      case RecurrenceInterval.yearly:
        return 'Yearly';
    }
  }

  Future<void> _submit(FinanceProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);

    final transaction = TransactionModel(
      id: widget.existing?.id ?? provider.newId(),
      title: _titleController.text.trim(),
      amount: amount,
      type: _isTransfer ? CategoryType.expense : _type,
      categoryId: _isTransfer ? 'transfer' : _categoryId!,
      accountId: _accountId!,
      date: _date,
      note: _noteController.text.trim(),
      recurrence: _isTransfer ? RecurrenceInterval.none : _recurrence,
      toAccountId: _isTransfer ? _toAccountId : null,
    );

    if (widget.existing == null) {
      await provider.addTransaction(transaction);
    } else {
      await provider.updateTransaction(transaction);
    }

    if (mounted) Navigator.pop(context);
  }
}
