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
import '../providers/auth_provider.dart';
import '../utils/translations.dart';

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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incPct = provider.lastMonthIncome > 0
        ? ((provider.monthlyIncome - provider.lastMonthIncome) / provider.lastMonthIncome) * 100
        : (provider.monthlyIncome > 0 ? 100.0 : 0.0);

    final expPct = provider.lastMonthExpense > 0
        ? ((provider.monthlyExpense - provider.lastMonthExpense) / provider.lastMonthExpense) * 100
        : (provider.monthlyExpense > 0 ? 100.0 : 0.0);

    return Scaffold(
      drawer: _buildDrawer(context, provider, authProvider, user, isDark),
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primary,
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person_rounded, color: Colors.white, size: 22)
                  : null,
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
                  user?.displayName ?? (provider.userName.isEmpty ? 'BudgetBuddy' : provider.userName),
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
                      label: 'income_this_month'.tr(context),
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
                          '${incPct >= 0 ? '+' : ''}${incPct.toStringAsFixed(1)}% ${'vs_last_month'.tr(context)}',
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
                const SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(20),
                    child: SummaryCard(
                      label: 'expense_this_month'.tr(context),
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
                          '${expPct >= 0 ? '+' : ''}${expPct.toStringAsFixed(1)}% ${'vs_last_month'.tr(context)}',
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
              'recent_transactions'.tr(context),
              onSeeAll: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
              },
            ),
            const SizedBox(height: 10),
            if (provider.recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'no_transactions_yet'.tr(context),
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
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
          label: Text('add_transaction'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHeroBalanceCard(BuildContext context, FinanceProvider provider) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A3A2F), Color(0xFF155E4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A3A2F).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'total_net_worth'.tr(context).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.contactless_rounded, color: Colors.white70, size: 24),
                  ],
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBalanceHidden
                            ? '••••••••'
                            : Formatters.currency(provider.totalBalance, provider.currencySymbol),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '****  ****  ****  8888',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          letterSpacing: 3,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEMVChip(),
              ],
            ),
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
      ),
    );
  }

  Widget _buildEMVChip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFE5C158), Color(0xFFF6E27A), Color(0xFFE5C158)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: EMVChipPainter(),
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



  Widget _buildDrawer(BuildContext context, provider, authProvider, user, bool isDark) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0B0F17), Color(0xFF111827)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 52, bottom: 28, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with glow ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white24,
                      backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                      child: user?.photoUrl == null
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 38)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.displayName ?? (provider.userName.isEmpty ? 'BudgetBuddy' : provider.userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (user?.email != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      user!.email,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Quick stats strip
                  Row(
                    children: [
                      _drawerStat('Income', provider.currencySymbol + _shortNum(provider.monthlyIncome), Icons.arrow_downward_rounded, AppColors.income),
                      const SizedBox(width: 12),
                      _drawerStat('Expense', provider.currencySymbol + _shortNum(provider.monthlyExpense), Icons.arrow_upward_rounded, AppColors.expense),
                    ],
                  ),
                ],
              ),
            ),

            // ── Nav Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  _drawerLabel('NAVIGATE', isDark),
                  const SizedBox(height: 6),
                  _buildDrawerItem(context, Icons.account_balance_wallet_rounded, 'petty_cash'.tr(context), const PettyCashScreen(), isDark: isDark),
                  _buildDrawerItem(context, Icons.payment_rounded, 'loans'.tr(context), const InstallmentsScreen(), isDark: isDark),
                  _buildDrawerItem(context, Icons.flag_rounded, 'financial_goals'.tr(context), const GoalsScreen(), isDark: isDark),
                  const SizedBox(height: 16),
                  _drawerLabel('TRANSACTIONS', isDark),
                  const SizedBox(height: 6),
                  _buildDrawerItem(context, Icons.arrow_downward_rounded, 'income'.tr(context), const TransactionsScreen(initialType: CategoryType.income), color: AppColors.income, isDark: isDark),
                  _buildDrawerItem(context, Icons.arrow_upward_rounded, 'expense'.tr(context), const TransactionsScreen(initialType: CategoryType.expense), color: AppColors.expense, isDark: isDark),
                ],
              ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_graph_rounded, size: 16, color: AppColors.primaryLight.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    'BudgetBuddy v1.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _drawerStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 0.5)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _shortNum(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget destination, {Color? color, bool isDark = false}) {
    final itemColor = color ?? AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: itemColor.withValues(alpha: isDark ? 0.07 : 0.06),
              border: Border.all(
                color: itemColor.withValues(alpha: isDark ? 0.12 : 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [itemColor.withValues(alpha: 0.9), itemColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: itemColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
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

class EMVChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Center oval
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.2, w * 0.3, h * 0.6),
        const Radius.circular(5),
      ),
      paint,
    );
    
    // Horizontal lines
    canvas.drawLine(Offset(0, h * 0.35), Offset(w * 0.35, h * 0.35), paint);
    canvas.drawLine(Offset(0, h * 0.65), Offset(w * 0.35, h * 0.65), paint);
    
    canvas.drawLine(Offset(w * 0.65, h * 0.35), Offset(w, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.65, h * 0.65), Offset(w, h * 0.65), paint);

    // Vertical lines
    canvas.drawLine(Offset(w * 0.2, 0), Offset(w * 0.2, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.2, h * 0.65), Offset(w * 0.2, h), paint);
    
    canvas.drawLine(Offset(w * 0.8, 0), Offset(w * 0.8, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.8, h * 0.65), Offset(w * 0.8, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
