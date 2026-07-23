import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({super.key});

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  late DateTime _selectedDate;
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
  }

  void _changeWeek(int delta) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: delta * 7));
      // Optionally auto-select the same weekday in the new week, or just let them pick
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pettyCashAccount = provider.accounts.firstWhere(
      (a) => a.type == AccountType.petty_cash,
      orElse: () => AccountModel(id: '', name: 'Petty Cash', type: AccountType.petty_cash, openingBalance: 0, colorValue: 0),
    );

    // Calculate balance at the end of the selected date
    final remainingAmount = provider.getPettyCashBalanceAt(_selectedDate);

    // Filter transactions for this day involving petty cash
    final nextDay = _selectedDate.add(const Duration(days: 1));
    final dailyTransactions = provider.transactions.where((t) {
      if (t.date.isBefore(_selectedDate) || !t.date.isBefore(nextDay)) return false;
      return t.accountId == pettyCashAccount.id || t.toAccountId == pettyCashAccount.id;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petty Cash History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Weekly Calendar Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => _changeWeek(-1)),
                    Text(
                      '${Formatters.dateShort(_startOfWeek)} - ${Formatters.dateShort(_startOfWeek.add(const Duration(days: 6)))}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => _changeWeek(1)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final dayDate = _startOfWeek.add(Duration(days: index));
                    final isSelected = dayDate.isAtSameMomentAs(_selectedDate);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = dayDate;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected 
                                    ? Colors.white 
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dayDate.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected 
                                    ? Colors.white 
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Remaining Balance Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Remaining at End of Day',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(remainingAmount, provider.currencySymbol),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: dailyTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No petty cash transactions on this day.', 
                          style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dailyTransactions.length,
                    itemBuilder: (context, index) {
                      final t = dailyTransactions[index];
                      return TransactionTile(
                        transaction: t,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
