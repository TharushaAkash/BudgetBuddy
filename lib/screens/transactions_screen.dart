import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _query = '';
  String? _categoryFilter;
  CategoryType? _typeFilter;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final results = provider.searchTransactions(
      query: _query,
      categoryId: _categoryFilter,
      type: _typeFilter,
      start: _selectedDate != null ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) : null,
      end: _selectedDate != null ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59) : null,
    );

    // Group by date (day) for section headers.
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in results) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDate = null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All', _typeFilter == null, () => setState(() => _typeFilter = null)),
                const SizedBox(width: 8),
                _filterChip('Income', _typeFilter == CategoryType.income,
                    () => setState(() => _typeFilter = CategoryType.income)),
                const SizedBox(width: 8),
                _filterChip('Expense', _typeFilter == CategoryType.expense,
                    () => setState(() => _typeFilter = CategoryType.expense)),
                const SizedBox(width: 8),
                ...provider.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _filterChip(
                        c.name,
                        _categoryFilter == c.id,
                        () => setState(() => _categoryFilter = _categoryFilter == c.id ? null : c.id),
                      ),
                    )),
              ],
            ),
          ),
          if (_selectedDate != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Petty Cash remaining on ${_formatGroupDate(_selectedDate!)}:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${provider.currencySymbol}${provider.getPettyCashBalanceAt(_selectedDate).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey.shade500)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: grouped.entries.map((entry) {
                      final dayTx = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              _formatGroupDate(dayTx.first.date),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                          ),
                          ...dayTx.map((t) => TransactionTile(
                                transaction: t,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
