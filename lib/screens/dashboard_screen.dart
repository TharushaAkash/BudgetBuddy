import 'dart:async';
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
import 'installments_screen.dart';
import 'petty_cash_screen.dart';
import 'transactions_screen.dart';
import 'goals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceHidden = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incPct = provider.lastMonthIncome > 0
        ? ((provider.monthlyIncome - provider.lastMonthIncome) / provider.lastMonthIncome) * 100
        : (provider.monthlyIncome > 0 ? 100.0 : 0.0);

    final expPct = provider.lastMonthExpense > 0
        ? ((provider.monthlyExpense - provider.lastMonthExpense) / provider.lastMonthExpense) * 100
        : (provider.monthlyExpense > 0 ? 100.0 : 0.0);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.userName.isEmpty ? 'Finance Tracker' : provider.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              title: const Text('Petty Cash'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PettyCashScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment_rounded, color: AppColors.primary),
              title: const Text('Installments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: AppColors.primary),
              title: const Text('Goals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward_rounded, color: AppColors.income),
              title: const Text('Income'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen(initialType: CategoryType.income)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward_rounded, color: AppColors.expense),
              title: const Text('Expenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen(initialType: CategoryType.expense)));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  provider.userName.isEmpty ? 'BudgetBuddy' : provider.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              provider.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
            ),
            onPressed: () {
              final newMode = provider.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              provider.setThemeMode(newMode);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _buildHeroBalanceCard(context, provider),
            const SizedBox(height: 16),
            _buildQuickActionsRow(context),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(initialType: CategoryType.income),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: SummaryCard(
                      label: 'Income this month',
                      amount: Formatters.currency(provider.monthlyIncome, provider.currencySymbol),
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.income,
                      subtitle: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (incPct >= 0 ? AppColors.income : AppColors.expense)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${incPct >= 0 ? '+' : ''}${incPct.toStringAsFixed(1)}% vs last month',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: incPct >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(initialType: CategoryType.expense),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: SummaryCard(
                      label: 'Expense this month',
                      amount: Formatters.currency(provider.monthlyExpense, provider.currencySymbol),
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.expense,
                      subtitle: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (expPct > 0 ? AppColors.expense : AppColors.income)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${expPct >= 0 ? '+' : ''}${expPct.toStringAsFixed(1)}% vs last month',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: expPct > 0 ? AppColors.expense : AppColors.income,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentsScreen())),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.installmentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.credit_score_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remaining Installments',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(provider.totalRemainingInstallments, provider.currencySymbol),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (provider.closestNextPaymentDate != null) ...[
                            const SizedBox(height: 4),
                            _LiveCountdown(dueDate: provider.closestNextPaymentDate!),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTrendChart(context, provider),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              'Recent Transactions',
              onSeeAll: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
              },
            ),
            const SizedBox(height: 10),
            if (provider.recentTransactions.isEmpty)
              _emptyState('No transactions yet. Tap + to add one.')
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  children: provider.recentTransactions
                      .map((t) => TransactionTile(
                            transaction: t,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton.extended(
          heroTag: 'dash_fab',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHeroBalanceCard(BuildContext context, FinanceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.income,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'TOTAL NET WORTH',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    _isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isBalanceHidden
                ? '••••••••'
                : Formatters.currency(provider.totalBalance, provider.currencySymbol),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
          Row(
            children: provider.accounts
                .where((a) => a.type == AccountType.cash || a.type == AccountType.bank || a.type == AccountType.petty_cash)
                .take(3)
                .map((a) {
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(a.icon, color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            a.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceHidden
                          ? '••••'
                          : Formatters.currencyCompact(provider.accountBalance(a.id), provider.currencySymbol),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildQuickActionsRow(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.arrow_upward_rounded,
        label: 'Expense',
        color: AppColors.expense,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.arrow_downward_rounded,
        label: 'Income',
        color: AppColors.income,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Petty Cash',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PettyCashScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.credit_score_rounded,
        label: 'Loans',
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InstallmentsScreen()),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((act) {
        return InkWell(
          onTap: act.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: act.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: act.color.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Icon(act.icon, color: act.color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                act.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendChart(BuildContext context, FinanceProvider provider) {
    final trend = provider.dailyTrend(7);
    final maxVal = trend.map((e) => e.value.abs()).fold(1.0, (a, b) => a > b ? a : b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spending Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Last 7 Days',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                minY: -maxVal * 1.25,
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
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            Formatters.weekday(trend[idx].key),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
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
                          borderRadius: BorderRadius.circular(6),
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
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
      ],
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _LiveCountdown extends StatefulWidget {
  final DateTime dueDate;
  const _LiveCountdown({required this.dueDate});

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Calculate difference to the end of the due date (23:59:59)
    final due = DateTime(widget.dueDate.year, widget.dueDate.month, widget.dueDate.day, 23, 59, 59);
    final diff = due.difference(now);
    
    String dueText = '';
    bool isUrgent = false;
    
    if (diff.isNegative) {
      dueText = 'Overdue by ${diff.inDays.abs()}d ${diff.inHours.abs() % 24}h';
      isUrgent = true;
    } else {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final mins = diff.inMinutes % 60;
      dueText = 'Next due in ${days}d ${hours}h ${mins}m';
      isUrgent = days <= 3;
    }

    return Text(
      dueText,
      style: TextStyle(
        color: isUrgent ? Colors.redAccent.shade100 : Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

