import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'installments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceHidden = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    
    final incPct = provider.lastMonthIncome > 0 
        ? ((provider.monthlyIncome - provider.lastMonthIncome) / provider.lastMonthIncome) * 100 
        : (provider.monthlyIncome > 0 ? 100.0 : 0.0);
        
    final expPct = provider.lastMonthExpense > 0 
        ? ((provider.monthlyExpense - provider.lastMonthExpense) / provider.lastMonthExpense) * 100 
        : (provider.monthlyExpense > 0 ? 100.0 : 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey)),
            Text(provider.userName.isEmpty ? 'Overview' : provider.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            _buildBalanceCard(context, provider),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen(initialType: CategoryType.income))),
                    borderRadius: BorderRadius.circular(18),
                    child: SummaryCard(
                      label: 'Income this month',
                      amount: Formatters.currency(provider.monthlyIncome, provider.currencySymbol),
                      icon: Icons.arrow_downward,
                      color: AppColors.income,
                      subtitle: Text(
                        '${incPct >= 0 ? '+' : ''}${incPct.toStringAsFixed(1)}% vs last month',
                        style: TextStyle(fontSize: 10, color: incPct >= 0 ? Colors.green : Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen(initialType: CategoryType.expense))),
                    borderRadius: BorderRadius.circular(18),
                    child: SummaryCard(
                      label: 'Expense this month',
                      amount: Formatters.currency(provider.monthlyExpense, provider.currencySymbol),
                      icon: Icons.arrow_upward,
                      color: AppColors.expense,
                      subtitle: Text(
                        '${expPct >= 0 ? '+' : ''}${expPct.toStringAsFixed(1)}% vs last month',
                        style: TextStyle(fontSize: 10, color: expPct > 0 ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentsScreen())),
              borderRadius: BorderRadius.circular(18),
              child: SummaryCard(
                label: 'Total Remaining Installments',
                amount: Formatters.currency(provider.totalRemainingInstallments, provider.currencySymbol),
                icon: Icons.credit_score,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(height: 24),
            _buildTrendChart(context, provider),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Recent Transactions', onSeeAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
            }),
            const SizedBox(height: 8),
            if (provider.recentTransactions.isEmpty)
              _emptyState('No transactions yet. Tap + to add one.')
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: provider.recentTransactions
                      .map((t) => TransactionTile(transaction: t))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
              InkWell(
                onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                child: Icon(
                  _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isBalanceHidden 
                ? '****' 
                : Formatters.currency(provider.totalBalance, provider.currencySymbol),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: provider.accounts
                .where((a) => a.type == AccountType.cash || a.type == AccountType.bank || a.type == AccountType.petty_cash)
                .take(3)
                .map((a) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(a.icon, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(a.name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currencyCompact(provider.accountBalance(a.id), provider.currencySymbol),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, FinanceProvider provider) {
    final trend = provider.dailyTrend(7);
    final maxVal = trend.map((e) => e.value.abs()).fold(1.0, (a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.3,
                minY: -maxVal * 1.3,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            Formatters.weekday(trend[idx].key),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < trend.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: trend[i].value,
                          color: trend[i].value >= 0 ? AppColors.income : AppColors.expense,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }
}
