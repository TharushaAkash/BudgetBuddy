import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import '../utils/translations.dart';

class TransactionsScreen extends StatefulWidget {
  final CategoryType? initialType;
  const TransactionsScreen({super.key, this.initialType});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  CategoryType? _typeFilter;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final results = provider.searchTransactions(
      query: _query,
      categoryId: _categoryFilter,
      type: _typeFilter,
      start: _selectedDate != null ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) : null,
      end: _selectedDate != null ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59) : null,
    );

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in results) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions'.tr(context)),
        actions: [
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => setState(() => _selectedDate = null),
              tooltip: 'Clear Date Filter',
            ),
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: _selectedDate != null ? AppColors.primary : null,
            ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search'.tr(context),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterPill('All', _typeFilter == null && _categoryFilter == null, () {
                  setState(() {
                    _typeFilter = null;
                    _categoryFilter = null;
                  });
                }, isDark),
                const SizedBox(width: 8),
                _buildFilterPill('Income', _typeFilter == CategoryType.income, () {
                  setState(() => _typeFilter = _typeFilter == CategoryType.income ? null : CategoryType.income);
                }, isDark, color: AppColors.income),
                const SizedBox(width: 8),
                _buildFilterPill('Expense', _typeFilter == CategoryType.expense, () {
                  setState(() => _typeFilter = _typeFilter == CategoryType.expense ? null : CategoryType.expense);
                }, isDark, color: AppColors.expense),
                const SizedBox(width: 8),
                ...provider.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterPill(
                        c.name,
                        _categoryFilter == c.id,
                        () => setState(() => _categoryFilter = _categoryFilter == c.id ? null : c.id),
                        isDark,
                        color: c.color,
                      ),
                    )),
              ],
            ),
          ),
          if (_selectedDate != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Petty Cash on ${_formatGroupDate(_selectedDate!)}:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${provider.currencySymbol}${provider.getPettyCashBalanceAt(_selectedDate).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No transactions found', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: grouped.entries.map((entry) {
                      final dayTx = entry.value;
                      final dayTotal = dayTx.fold(0.0, (sum, t) => t.isTransfer ? sum : sum + (t.type == CategoryType.income ? t.amount : -t.amount));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatGroupDate(dayTx.first.date),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(dayTotal.abs(), provider.currencySymbol),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: dayTotal >= 0 ? AppColors.income : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 12),
                            ...dayTx.map((t) => TransactionTile(
                                  transaction: t,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
                                  ),
                                )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          heroTag: 'tx_fab',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
          child: const Icon(Icons.add_rounded),
        ),
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
}

