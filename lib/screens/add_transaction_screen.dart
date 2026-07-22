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
      _amountController.text = e.amount.toStringAsFixed(e.amount.truncateToDouble() == e.amount ? 0 : 2);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredCategories = provider.categories.where((c) => c.type == _type).toList();

    if (_accountId == null && provider.accounts.isNotEmpty) {
      _accountId = provider.accounts.first.id;
    }
    if (!_isTransfer && _categoryId == null && filteredCategories.isNotEmpty) {
      _categoryId = filteredCategories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Transaction' : 'Edit Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              onPressed: () async {
                await provider.deleteTransaction(widget.existing!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (!_isTransfer)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = CategoryType.expense;
                          _categoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == CategoryType.expense ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: _type == CategoryType.expense ? Colors.white : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == CategoryType.expense ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = CategoryType.income;
                          _categoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == CategoryType.income ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                                color: _type == CategoryType.income ? Colors.white : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Income',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == CategoryType.income ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          provider.currencySymbol,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Transfer between accounts', style: TextStyle(fontWeight: FontWeight.w600)),
              value: _isTransfer,
              onChanged: (v) => setState(() => _isTransfer = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Grocery shopping'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 14),
            if (!_isTransfer)
              DropdownButtonFormField<String>(
                initialValue: filteredCategories.any((c) => c.id == _categoryId) ? _categoryId : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: filteredCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(c.icon, size: 16, color: c.color),
                              ),
                              const SizedBox(width: 10),
                              Text(c.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
            if (!_isTransfer) const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: provider.accounts.any((a) => a.id == _accountId) ? _accountId : null,
              decoration: InputDecoration(labelText: _isTransfer ? 'From Account' : 'Account'),
              items: provider.accounts
                  .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Row(
                          children: [
                            Icon(a.icon, size: 18, color: a.color),
                            const SizedBox(width: 8),
                            Text(a.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Select an account' : null,
            ),
            if (_isTransfer) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: provider.accounts.any((a) => a.id == _toAccountId) ? _toAccountId : null,
                decoration: const InputDecoration(labelText: 'To Account'),
                items: provider.accounts
                    .where((a) => a.id != _accountId)
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) => _isTransfer && v == null ? 'Select destination account' : null,
              ),
            ],
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Text(Formatters.date(_date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (!_isTransfer)
              DropdownButtonFormField<RecurrenceInterval>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'Repeat'),
                items: RecurrenceInterval.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(_recurrenceLabel(r))))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v!),
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Add extra details...'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                onPressed: () => _submit(provider),
                child: Text(
                  widget.existing == null ? 'Save Transaction' : 'Update Transaction',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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

